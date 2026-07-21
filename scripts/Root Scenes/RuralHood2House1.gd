extends Node2D

@export var back_area: Area2D
@export var router_area: Area2D
@export var router_control: Control  # The invisible Control node
@export var back_to_room_area: Area2D  # The Area2D inside the router UI
@export var camera: Camera2D  # Reference to the scene's camera

const HOOD_SCENE = "res://scenes/4.2 hood.tscn"

func _ready():

	# Router UI is invisible by default
	router_control.visible = false
	
	# Connect signals
	back_area.input_event.connect(_on_back_pressed)
	router_area.input_event.connect(_on_router_pressed)
	back_to_room_area.input_event.connect(_on_back_to_room_pressed)
	
	# First-time encounter check - now using DialogueLoader
	if not GameData.has_met_npc("ruralhood2house1", "npc1"):
		# Start dialogue with villager
		await get_tree().create_timer(2).timeout
		DialogueLoader.start_dialogue_for_npc("ruralhood2house1", "npc1")

func _on_back_pressed(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file(HOOD_SCENE)

func _on_router_pressed(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		router_control.visible = true
		# First-time encounter check - now using DialogueLoader
		await get_tree().create_timer(1).timeout
		if QuestManager.is_available("cutting"):
			DialogueLoader.start_dialogue_for_npc("cutting", "mc")

func _on_back_to_room_pressed(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		router_control.visible = false
