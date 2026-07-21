extends Node

# Dialogue Manager - Global Autoload Script
# Place this in your autoload scripts in Project Settings

signal dialogue_started
signal dialogue_finished
signal dialogue_next_line

# References to UI components
var dialogue_panel: Panel
var npc_label: Label
var dialogue_label: Label
var portrait: TextureRect
var animation_player: AnimationPlayer

# Dialogue data
var current_dialogue: Array = []
var current_line: int = 0
var current_text: String = ""
var is_typing: bool = false
var typing_speed: float = 0.05  # Time between words in seconds

# NPC data (for tracking encounters)
var current_location: String = ""
var current_npc: String = ""
var current_dialogue_resource = null  # Stores the current dialogue resource

# Dialogue animations
enum DialogueAnimations {
	FADE,      # Simple fade in/out
	TYPEWRITER # Type text word by word
}
var animation_type: int = DialogueAnimations.TYPEWRITER

func _ready():
	# Initial setup
	print("[DialogueManager] Initialized")
	set_process_input(true)

# Connect this to your dialogue UI elements
func setup_ui(panel: Panel, npc_name_label: Label, text_label: Label, npc_portrait: TextureRect = null, anim_player: AnimationPlayer = null):
	dialogue_panel = panel
	npc_label = npc_name_label
	dialogue_label = text_label
	portrait = npc_portrait
	animation_player = anim_player
	
	# Ensure dialogue panel is hidden initially
	if dialogue_panel:
		dialogue_panel.visible = false
	
	print("[DialogueManager] UI components connected")

# Start a dialogue sequence
func start_dialogue(location: String, npc: String, npc_name: String, dialogue_lines: Array, portrait_texture: Texture2D = null):
	if not dialogue_panel or not npc_label or not dialogue_label:
		printerr("[DialogueManager] ERROR: Dialogue UI not set up! Call setup_ui() first.")
		return
	
	# Store dialogue data
	current_dialogue = dialogue_lines
	current_line = 0
	current_location = location
	current_npc = npc
	
	# Set up UI
	dialogue_panel.visible = true
	npc_label.text = npc_name
	dialogue_label.text = ""
	
	# Set portrait if provided and portrait node exists
	if portrait and portrait_texture:
		portrait.texture = portrait_texture
	
	# Start dialogue sequence
	dialogue_started.emit()
	show_next_line()

# Start dialogue from a DialogueData resource
func start_dialogue_from_resource(location: String, npc: String, dialogue_resource):
	if not dialogue_resource:
		printerr("[DialogueManager] ERROR: Invalid dialogue resource!")
		return
	
	# Store the resource for later use
	current_dialogue_resource = dialogue_resource
	
	# Extract data from resource
	var npc_name = dialogue_resource.npc_name
	var dialogue_lines = dialogue_resource.dialogue_lines
	var portrait_texture = null
	
	# Try to load portrait if path is specified
	if dialogue_resource.has_method("get_portrait"):
		portrait_texture = dialogue_resource.get_portrait()
	elif "portrait_path" in dialogue_resource and !dialogue_resource.portrait_path.is_empty():
		portrait_texture = load(dialogue_resource.portrait_path)
	
	# Start dialogue with the extracted data
	start_dialogue(location, npc, npc_name, dialogue_lines, portrait_texture)

# Show the next line in the dialogue sequence
func show_next_line():
	if current_line >= current_dialogue.size():
		end_dialogue()
		return
	
	# Get the current line
	current_text = current_dialogue[current_line]
	
	# Reset text display
	dialogue_label.text = ""
	
	match animation_type:
		DialogueAnimations.FADE:
			_show_with_fade()
		DialogueAnimations.TYPEWRITER:
			_show_with_typewriter()
		_:
			dialogue_label.text = current_text
			dialogue_next_line.emit()
	
	current_line += 1

# End the dialogue sequence
func end_dialogue():
	if not dialogue_panel:
		return
	
	# Check if there's a next dialogue to play
	var next_dialogue_id = ""
	if current_dialogue_resource and "next_dialogue_id" in current_dialogue_resource:
		next_dialogue_id = current_dialogue_resource.next_dialogue_id
		print("[DialogueManager] Next dialogue ID found: " + next_dialogue_id)
	
	# Process quest triggers if using a resource
	if current_dialogue_resource:
		if "trigger_quest" in current_dialogue_resource and "quest_status_on_complete" in current_dialogue_resource:
			var trigger_quest = current_dialogue_resource.trigger_quest
			var quest_status = current_dialogue_resource.quest_status_on_complete
			
			if not trigger_quest.is_empty() and not quest_status.is_empty():
				if QuestManager.has_method("update_quest_status"):
					QuestManager.update_quest_status(trigger_quest, quest_status)
					print("[DialogueManager] Quest updated: " + trigger_quest + " -> " + quest_status)
	
	# Mark NPC as encountered in GameData
	if current_location != "" and current_npc != "":
		GameData.meet_npc(current_location, current_npc)
	
	# Hide the dialogue panel temporarily if we're chaining
	if not next_dialogue_id.is_empty():
		# Don't hide if chaining dialogues
		pass
	else:
		dialogue_panel.visible = false
	
	# Check if there's a next dialogue to chain to
	if not next_dialogue_id.is_empty():
		print("[DialogueManager] Loading next dialogue: " + next_dialogue_id)
		var next_resource = DialogueLoader.get_dialogue(next_dialogue_id)
		if next_resource:
			# Store current resource in case we need it
			var previous_resource = current_dialogue_resource
			current_dialogue_resource = null  # Clear current to avoid loops
			
			# Start the next dialogue
			start_dialogue_from_resource(current_location, current_npc, next_resource)
			return  # Don't emit dialogue_finished if we're chaining
		else:
			print("[DialogueManager] ERROR: Could not find next dialogue: " + next_dialogue_id)
			dialogue_panel.visible = false  # Hide panel if we can't chain
	
	# If we get here, dialogue is fully finished (no chaining)
	current_dialogue_resource = null
	dialogue_finished.emit()

# Handle player input to advance dialogue
func _input(event):
	if not dialogue_panel or not dialogue_panel.visible:
		return
	
	# Click or press key to advance
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if is_typing:
			# Skip typing and show full text immediately
			is_typing = false
			dialogue_label.text = current_text
		else:
			# Advance to next line
			show_next_line()

# Animation: Fade in/out
func _show_with_fade():
	if not animation_player:
		dialogue_label.text = current_text
		return
	
	dialogue_label.text = current_text
	dialogue_label.modulate.a = 0
	
	# Play fade-in animation
	animation_player.play("fade_in")
	await animation_player.animation_finished
	
	# Emit signal for other systems
	dialogue_next_line.emit()
	
	# Wait before allowing advancement
	await get_tree().create_timer(1.0).timeout

# Animation: Typewriter effect (word by word)
func _show_with_typewriter():
	is_typing = true
	var words = current_text.split(" ")
	var word_index = 0
	
	dialogue_label.text = ""
	
	while word_index < words.size() and is_typing:
		dialogue_label.text += words[word_index] + " "
		word_index += 1
		await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false
	dialogue_next_line.emit()
