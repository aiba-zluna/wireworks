extends Area2D

@export var action_type: String = "open_menu"  # Define what the area does
@export var highlight_node: NodePath = "HighlightPolygon2D"  # Default to your Polygon2D

var highlight: Polygon2D  # Holds the highlight node

func _ready():
	# Ensure we can detect mouse interactions
	connect("input_event", _on_area_clicked)
	connect("mouse_entered", _on_hover_start)
	connect("mouse_exited", _on_hover_end)

	# Get the highlight node if assigned
	highlight = get_node_or_null(highlight_node)
	if highlight:
		highlight.modulate.a = 0.0  # Start fully transparent

func _on_area_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("[Click] Area2D Clicked:", name)
		_perform_action()

func _on_hover_start():
	print("[Hover] Mouse entered:", name)
	if highlight:
		highlight.modulate = Color(1, 1, 1, 0.25)  # Apply transparency

func _on_hover_end():
	print("[Hover] Mouse exited:", name)
	if highlight:
		highlight.modulate.a = 0.0  # Hide highlight

# Perform an action based on type
func _perform_action():
	match action_type:
		"open_menu":
			_open_ui_menu()
		"change_scene":
			_change_scene("res://scenes/new_scene.tscn")
		_:
			print("⚠️ No action defined for:", action_type)

# Opens the UI Menu scene
func _open_ui_menu():
	var ui_menu = load("res://scenes/User Interface/UI_Menu.tscn").instantiate()
	get_tree().current_scene.add_child(ui_menu)
	print("[UI] UI Menu Opened")

# Changes the scene
func _change_scene(scene_path: String):
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		print("[Scene] Changing to:", scene_path)
	else:
		print("❌ Error: Invalid scene path:", scene_path)
