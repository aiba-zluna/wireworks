extends Node2D  

@export var fade_layer: FadeLayer  # Assign FadeLayer in Inspector

# Quest Icons
@export var quest_icon_rural: Node2D  
@export var quest_icon_sub_urban: Node2D  
@export var quest_icon_urban: Node2D  

# Buttons & Highlights
@export var btn_rural_map: Area2D  
@export var highlight_rural: Polygon2D  

@export var btn_sub_urban_map: Area2D  
@export var highlight_sub_urban: Polygon2D  

@export var btn_urban_map: Area2D  
@export var highlight_urban: Polygon2D  

@export var btn_shop_map: Area2D  
@export var highlight_shop: Polygon2D  

@export var btn_academy_map: Area2D  
@export var highlight_academy: Polygon2D  
@onready var dialogue_scene = preload("res://scenes/User Interface/UI_dialogues.tscn")

func _ready():
	# Debugging output for QuestManager status
	_setup_button(btn_rural_map, highlight_rural, "res://scenes/4.0 map_rural.tscn")
	_setup_button(btn_sub_urban_map, highlight_sub_urban, "res://scenes/5.0 map_suburban.tscn")
	_setup_button(btn_urban_map, highlight_urban, "res://scenes/6.0 map_urban.tscn")
	_setup_button(btn_shop_map, highlight_shop, "res://scenes/shop.tscn")
	_setup_button(btn_academy_map, highlight_academy, "res://scenes/academy.tscn")

	QuestManager.quest_updated.connect(update_quest_icons)  # Ensure quest updates reflect in UI
	update_quest_icons()
			# First-time encounter check - now using DialogueLoader
			
	if QuestManager.is_available("overview"):
		await get_tree().create_timer(1).timeout
		DialogueLoader.start_dialogue_for_npc("overview", "mc")



#region 🟢 Generic Button Setup
func _setup_button(area: Area2D, highlight: Polygon2D, scene_path: String):
	if not area:
		return  # Skip if Area2D is not assigned

	area.set_meta("target_scene", scene_path)
	area.connect("mouse_entered", func(): _on_mouse_entered(highlight))
	area.connect("mouse_exited", func(): _on_mouse_exited(highlight))
	area.connect("input_event", func(_viewport, event, _shape_idx): _on_input_event(area, event))

	if highlight:
		highlight.color.a = 0.0  # Fully transparent initially

func _on_mouse_entered(highlight: Polygon2D):
	if highlight:
		highlight.color = Color(1, 1, 1, 0.25)  # Whitish, slightly transparent highlight

func _on_mouse_exited(highlight: Polygon2D):
	if highlight:
		highlight.color.a = 0.0  # Fully transparent when not hovered

func _on_input_event(area: Area2D, event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if area.has_meta("target_scene"):
			var target_scene = area.get_meta("target_scene")
			if fade_layer:
				fade_layer.fade_out_and_change_scene(target_scene)
			else:
				get_tree().change_scene_to_file(target_scene)
#endregion

#region 🏆 Quest System
func update_quest_icons():
	# Reset all quest icons
	if quest_icon_rural:
		quest_icon_rural.visible = false
	if quest_icon_sub_urban:
		quest_icon_sub_urban.visible = false
	if quest_icon_urban:
		quest_icon_urban.visible = false

	# Ensure QuestManager has quests
#	if not QuestManager.has("quests") or QuestManager.quests.is_empty():
#		print("⚠️ Warning: QuestManager.quests is missing or empty!")
#		return  # Exit function to prevent errors

	# Loop through quests and enable relevant icons
	for house in QuestManager.quests.keys():
		var quest_data = QuestManager.quests.get(house, null)
		if quest_data == null or not quest_data.has("status"):
			continue  # Skip invalid entries

		var quest_status = quest_data["status"]

		# Rural quest detection
		if house.begins_with("rural") and quest_status in ["available", "underway"]:
			if quest_icon_rural:
				quest_icon_rural.visible = true

		# Suburban quest detection
		elif house.begins_with("suburban") and quest_status in ["available", "underway"]:
			if quest_icon_sub_urban:
				quest_icon_sub_urban.visible = true

		# Urban quest detection
		elif house.begins_with("urban") and quest_status in ["available", "underway"]:
			if quest_icon_urban:
				quest_icon_urban.visible = true
#endregion
