extends Node2D

@export var fade_layer: CanvasLayer  # Assign the FadeLayer in Inspector
@export var backR: String = "res://scenes/4.0 map_rural.tscn"
@export var backOV: String = "res://scenes/3. map_overview.tscn"  # Scene to load

# 📌 Dictionary mapping hoods to their quest indicators (NodePath for Inspector usage)
@export var hood_quests: Dictionary = {
	"ruralhood1": {"available": NodePath(), "underway": NodePath()},
	"ruralhood2": {"available": NodePath(), "underway": NodePath()},
	"ruralbarns": {"available": NodePath(), "underway": NodePath()}
}

func _ready():
	call_deferred("_setup_scene")  
	call_deferred("_update_quest_indicators")  
	QuestManager.quest_updated.connect(_update_quest_indicators)  

#region 🎯 Scene-Specific Setup
func _setup_scene():
	var scene_name = get_tree().current_scene.name

	match scene_name:
		"Map Rural":
			_setup_rural_map()
		_:
			print("⚠️ Warning: Unknown scene -", scene_name)
#endregion

#region 🏡 Scene 4.0 - Rural Map
func _setup_rural_map():
	_setup_area("btn Hood 1", "Highlight_Polygon_Hood1", "res://scenes/4.1 hood.tscn")
	_setup_area("btn Hood 2", "Highlight_Polygon_Hood2", "res://scenes/4.2 hood.tscn")
	_setup_area("btn Barns", "Highlight_Polygon_Barns", "res://scenes/4.3 barns.tscn")
	_setup_navigation("btn_back_to_overview_map", backOV)
#endregion

#region ✨ Utility Functions for Navigation & Highlights
func _setup_area(area_name: String, highlight_name: String, scene_path: String):
	var area = get_node_or_null(area_name)
	if area and area is Area2D:
		var highlight = area.get_node_or_null(highlight_name)
		if highlight:
			highlight.color.a = 0.0  

			area.mouse_entered.connect(func(): highlight.color.a = 0.25)
			area.mouse_exited.connect(func(): highlight.color.a = 0.0)

		area.input_event.connect(func(_viewport, event, _shape_idx):
			if event is InputEventMouseButton and event.pressed:
				_change_scene(scene_path)
		)
	else:
		print("❌ Error: Area2D not found -", area_name)

func _setup_navigation(area_name: String, target_scene: String):
	var area = get_node_or_null(area_name)
	if area and area is Area2D:
		area.input_event.connect(func(_viewport, event, _shape_idx):
			if event is InputEventMouseButton and event.pressed:
				_change_scene(target_scene)
		)
	else:
		print("❌ Error: Area2D not found -", area_name)
#endregion

#region 🚀 Scene Transition
func _change_scene(scene_path: String):
	if ResourceLoader.exists(scene_path):
		if fade_layer:
			fade_layer.fade_out_and_change_scene(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		print("❌ Error: Scene path invalid -", scene_path)
#endregion

#region 🔥 Quest Icon Updates
func _update_quest_indicators():
	# Hide all quest indicators initially
	for hood in hood_quests.keys():
		var available_icon = get_node_or_null(hood_quests[hood]["available"])
		var underway_icon = get_node_or_null(hood_quests[hood]["underway"])

		if available_icon: available_icon.visible = false
		if underway_icon: underway_icon.visible = false

	# Track quest states per hood
	var hood_status := {
		"ruralhood1": {"available": false, "underway": false},
		"ruralhood2": {"available": false, "underway": false},
		"ruralbarns": {"available": false, "underway": false}
	}

	var has_underway_quest := false  # Flag for active quest

	for house in QuestManager.quests.keys():
		var quest_data = QuestManager.quests.get(house, null)
		if quest_data == null or not quest_data.has("status"):
			continue  

		var quest_status = quest_data["status"]
		var hood_key = ""

		if house.begins_with("ruralhood1"):
			hood_key = "ruralhood1"
		elif house.begins_with("ruralhood2"):
			hood_key = "ruralhood2"
		elif house.begins_with("ruralbarn"):
			hood_key = "ruralbarns"

		if hood_key:
			if quest_status == "underway":
				hood_status[hood_key]["underway"] = true
				has_underway_quest = true  # Flag that an "underway" quest exists
			elif quest_status == "available":
				hood_status[hood_key]["available"] = true

	# Show the "underway" icon if a quest is in progress
	if has_underway_quest:
		for hood in hood_status.keys():
			var underway_icon = get_node_or_null(hood_quests[hood]["underway"])
			if hood_status[hood]["underway"] and underway_icon:
				underway_icon.visible = true

	else:
		# Show "available" icons only if no quest is underway
		for hood in hood_status.keys():
			var available_icon = get_node_or_null(hood_quests[hood]["available"])
			if hood_status[hood]["available"] and available_icon:
				available_icon.visible = true
#endregion
