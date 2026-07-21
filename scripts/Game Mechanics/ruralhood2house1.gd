extends Node2D

# References to scene components
@export var photos: Array[Sprite2D]        # All photo sprites in sequence
@export var minigames: Array[Control]      # All minigame controls
@export var click_areas: Array[Area2D]     # Click detection areas
@export var nope_label: Label              # "Wrong tool" message label

# Tool requirements for each step
@export var required_tools = {
	0: "slot1",  # Wire Cutter
	1: "slot2",  # Wire Stripper
	2: "slot3",  # RJ45
	3: "slot4",  # Crimping Tool
	4: "slot3",  # RJ45 (second use)
	5: "slot4",  # Crimping Tool (second use)
	6: "slot5",  # RJ45 Coupler
}

var dialogue_steps = {
	1: "stripping",
	2: "rj45",
	3: "crimping",
	6: "coupler",  # skipping 0, 4 and 5, no dialogue for those
}

@onready var dialogue_scene = preload("res://scenes/User Interface/UI_dialogues.tscn")

# State tracking
var current_step: int = 0
var locked: bool = false  # Prevents interaction during transitions

func _ready():
		
	# Load saved progress if available
	current_step = GameData.last_completed_photo
	
	# Initialize scene
	_initialize_scene()
	
	# Setup click area interactions
	_connect_click_areas()
	
	# If we're on step 7 or 8, go directly to the final photo
	if current_step >= 7:
		_show_final_photo()

func _start_dialogue_for_current_step():
	var quest_name = dialogue_steps.get(current_step, null)
	if quest_name and QuestManager.is_available(quest_name):
		await get_tree().create_timer(1).timeout
		DialogueLoader.start_dialogue_for_npc(quest_name, "mc")


# Initialize the scene
func _initialize_scene():
	# Hide all photos and minigames
	for photo in photos:
		if photo: photo.visible = false
		
	for minigame in minigames:
		if minigame: minigame.visible = false
	
	# Show current photo
	if current_step < photos.size() and photos[current_step]:
		photos[current_step].visible = true
	
	# Hide nope label
	if nope_label:
		nope_label.visible = false

# Connect click areas
func _connect_click_areas():
	for i in range(min(click_areas.size(), 7)):  # We only need interactions for photos 0-6
		if click_areas[i]:
			# Remove any existing connections to prevent duplicates
			if click_areas[i].is_connected("input_event", _on_area_clicked.bind(i)):
				click_areas[i].disconnect("input_event", _on_area_clicked.bind(i))
			# Connect the click handler
			click_areas[i].input_event.connect(_on_area_clicked.bind(i))

# Handle clicks on photo areas
func _on_area_clicked(_viewport, event, _shape_idx, index: int):
	# Only process left clicks and only when not locked
	if locked or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
		
	# Only respond if clicking on the current step
	if index != current_step:
		return
		
	# Check if player has the correct tool selected
	_check_tool(index)

# Check if player is using the correct tool
func _check_tool(step: int):
	var active_item = GameData.active_item
	var required_tool = required_tools.get(step, "")
	
	if active_item == required_tool:
		# Correct tool used, show minigame
		_show_minigame(step)
	else:
		# Wrong tool used, show error message
		_show_nope_message()

# Show the "nope" message briefly
func _show_nope_message():
	if nope_label:
		nope_label.visible = true
		await get_tree().create_timer(1.0).timeout
		nope_label.visible = false

# Show the appropriate minigame
func _show_minigame(step: int):
	locked = true  # Lock interaction while in minigame
	
	# Hide current photo
	if photos[step]: 
		photos[step].visible = false
	
	# Determine which minigame to show
	var minigame_index = step
	
	# For reused minigames, we need to map to the original minigame
	if step == 4:  # Second RJ45 usage
		minigame_index = 2
	elif step == 5:  # Second crimping usage
		minigame_index = 3
	
	# Show the minigame if it exists
	if minigame_index < minigames.size() and minigames[minigame_index]:
		# Connect completion signal
		_connect_minigame_signal(minigames[minigame_index])
		
		# Show the minigame
		minigames[minigame_index].visible = true
	else:
		# No minigame for this step, proceed to next step
		_advance_to_next_step()

# Connect minigame completion signal
func _connect_minigame_signal(minigame):
	# Disconnect any existing connection to avoid duplicates
	_disconnect_minigame_signal(minigame)
	
	# Try to connect to the appropriate signal
	if minigame.has_signal("minigame_completed"):
		minigame.connect("minigame_completed", _on_minigame_completed)
	elif minigame.has_signal("completed"):
		minigame.connect("completed", _on_minigame_completed)
	elif minigame.has_signal("finished"):
		minigame.connect("finished", _on_minigame_completed)
	else:
		print("Warning: No completion signal found for minigame")

# Disconnect minigame signal
func _disconnect_minigame_signal(minigame):
	var signals = ["minigame_completed", "completed", "finished"]
	
	for signal_name in signals:
		if minigame.has_signal(signal_name) and minigame.is_connected(signal_name, _on_minigame_completed):
			minigame.disconnect(signal_name, _on_minigame_completed)

# Handle minigame completion
func _on_minigame_completed():
	print("Minigame completed! Moving to next step.")
	
	# Hide all minigames
	for minigame in minigames:
		if minigame: 
			minigame.visible = false
	
	# Move to next step
	_advance_to_next_step()

# Advance to the next step
func _advance_to_next_step():
	current_step += 1
	GameData.last_completed_photo = current_step
	
	print("Advancing to step: ", current_step)
	
	# If we've completed the coupler minigame (step 6), skip directly to the final photo
	if current_step >= 7:
		# Simplified: Skip directly to the final photo
		_show_final_photo()
	else:
		# Show the next photo for steps 0-6
		for photo in photos:
			if photo: photo.visible = false
		
		if current_step < photos.size() and photos[current_step]:
			photos[current_step].visible = true
			_start_dialogue_for_current_step()
		
		locked = false  # Unlock for next interaction
		
		
var x = 0
	# Show the final photo (previously step 8, now shown right after step 6)
func _show_final_photo():
		print("Showing final photo")
		
		# Hide everything first
		for photo in photos:
			if photo: photo.visible = false
		
		# Make sure the final photo exists (now using index 8)
		if not photos[8]:
			print("Error: Final photo doesn't exist!")
			return
		
		# Get the final photo
		var final_photo = photos[8]
		
		# Set initially transparent
		final_photo.visible = true
		final_photo.modulate.a = 0.0
		
		# Fade in the final photo
		var tween = create_tween()
		tween.tween_property(final_photo, "modulate:a", 1.0, 0.5)
		await tween.finished
		
		# Only show dialogue if it hasn't been shown before
		
		if (x == 0):
			print("Starting completion dialogue")
			DialogueLoader.start_dialogue_for_npc("ruralhood2house1", "npc4")
			x = x + 1
		else:
			print("Completion dialogue already shown, skipping")
		
		locked = false
		
		print("Final photo shown.")
