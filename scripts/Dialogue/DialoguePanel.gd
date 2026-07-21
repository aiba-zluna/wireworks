extends Panel

# Export variables for easier configuration in the Inspector
@export_node_path("Label") var npc_name_path: NodePath = "NPCName"
@export_node_path("Label") var dialogue_text_path: NodePath = "DialogueText" 
@export_node_path("TextureRect") var portrait_path: NodePath = "Portrait"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = "AnimationPlayer"

# Node references (will be set in _ready)
var npc_label: Label
var dialogue_label: Label
var portrait: TextureRect
var animation_player: AnimationPlayer

func _ready():
	# Get nodes from paths
	npc_label = get_node_or_null(npc_name_path)
	dialogue_label = get_node_or_null(dialogue_text_path)
	portrait = get_node_or_null(portrait_path)
	animation_player = get_node_or_null(animation_player_path)
	
	# Error checking for required nodes
	if not npc_label or not dialogue_label:
		push_error("DialoguePanel: Required nodes not found. Make sure NPCName and DialogueText labels exist.")
		return
		
	# Connect to DialogueManager
	DialogueManager.setup_ui(
		self,               # Panel
		npc_label,          # NPC Name Label
		dialogue_label,     # Dialogue Text Label
		portrait,           # Portrait TextureRect
		animation_player    # Animation Player
	)
	
	# Hide panel initially
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # Make panel clickable
