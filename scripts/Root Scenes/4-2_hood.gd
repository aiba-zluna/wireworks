extends Node2D

@export var back_scene: String = "res://scenes/4.0 map_rural.tscn"

# 📌 Dictionary mapping houses to their quest indicator nodes (NodePath for Inspector usage)
@export var house_quests: Dictionary = {
	"ruralhood2house1": {"available": NodePath(), "underway": NodePath()},
	"ruralhood2house2": {"available": NodePath(), "underway": NodePath()},
	"ruralhood2house3": {"available": NodePath(), "underway": NodePath()}
}

# 📌 House buttons (linked in the inspector)
@export var house_buttons: Dictionary = {
	"ruralhood2house1": "btnHood2House1",
	"ruralhood2house2": "btnHood2House2",
	"ruralhood2house3": "btnHood2House3"
}

# 📌 House highlights (linked in the inspector)
@export var house_highlights: Dictionary = {
	"ruralhood2house1": "Highlight_Polygon_Hood2_House1",
	"ruralhood2house2": "Highlight_Polygon_Hood2_House2",
	"ruralhood2house3": "Highlight_Polygon_Hood2_House3"
}

# 📌 House scene paths
@export var house_scenes: Dictionary = {
	"ruralhood2house1": "res://scenes/4.2.1 house.tscn",
	"ruralhood2house2": "res://scenes/4.2.2 house.tscn",
	"ruralhood2house3": "res://scenes/4.2.3 house.tscn"
}

func _ready():
	_setup_interactivity()
	_update_quest_indicators()
	QuestManager.quest_updated.connect(_update_quest_indicators)  # Auto-update when quest changes

# 📌 Setup house interactions and back navigation
func _setup_interactivity():
	for house in house_buttons.keys():
		_setup_house_interaction(house)

	# Back button
	var back_button = get_node_or_null("btn_back_to_rural_map")
	if back_button:
		back_button.input_event.connect(func(_viewport, event, _shape_idx):
			if event is InputEventMouseButton and event.pressed:
				get_tree().change_scene_to_file(back_scene)
		)

# 📌 Setup individual house interaction
func _setup_house_interaction(house: String):
	var area2d = get_node_or_null(house_buttons[house])
	var highlight = get_node_or_null(house_highlights[house])
	
	if area2d and area2d is Area2D:
		if highlight:
			highlight.color.a = 0.0  # Start fully transparent

			# Mouse hover effect (only if house is enterable)
			area2d.mouse_entered.connect(func(): 
				if _can_enter_house(house):
					highlight.color = Color(1, 1, 1, 0.25)
			)
			area2d.mouse_exited.connect(func(): highlight.color.a = 0.0)

			# Clicking transitions to the next scene ONLY IF entry is allowed
			area2d.input_event.connect(func(_viewport, event, _shape_idx):
				if event is InputEventMouseButton and event.pressed:
					if _can_enter_house(house):
						get_tree().change_scene_to_file(house_scenes[house])
					else:
						print("🚫 Access Denied: You can't enter this house right now.")
			)

# 📌 Updates quest indicators for each house
func _update_quest_indicators():
	for house in house_quests.keys():
		var indicators = house_quests[house]
		
		var available_icon = get_node_or_null(indicators["available"])
		var underway_icon = get_node_or_null(indicators["underway"])

		# Hide all icons by default
		if available_icon: available_icon.visible = false
		if underway_icon: underway_icon.visible = false

		# Check if the quest exists in QuestManager
		if not QuestManager.quests.has(house):
			print("⚠️ Quest not found for:", house)
			continue  # Skip houses without quests

		# Get the quest status
		var status = QuestManager.quests[house]["status"]

		match status:
			"available":
				if available_icon: available_icon.visible = true
			"underway":
				if underway_icon: underway_icon.visible = true

	# Hide all "available" icons if any quest is underway
	_hide_all_available_icons_if_underway_exists()

	# Disable house entry if needed
	_restrict_house_entry_if_needed()

	print("🏠 Quest indicators updated!")

# 📌 Hides all "available" icons if any quest is underway
func _hide_all_available_icons_if_underway_exists():
	var underway_exists = false

	# Check if any quest is underway
	for house in house_quests.keys():
		if QuestManager.quests.has(house) and QuestManager.quests[house]["status"] == "underway":
			underway_exists = true
			break

	# If a quest is underway, hide all "available" icons
	if underway_exists:
		for house in house_quests.keys():
			var available_icon = get_node_or_null(house_quests[house]["available"])
			if available_icon:
				available_icon.visible = false

		print("🚫 Quest underway! Hiding all available quest icons.")

# 📌 Disables house entry if a quest is unavailable, temporarily unavailable, or another quest is in progress
func _restrict_house_entry_if_needed():
	var active_quest = null

	# Find if a quest is already underway
	for house in house_quests.keys():
		if QuestManager.quests.has(house) and QuestManager.quests[house]["status"] == "underway":
			active_quest = house
			break  # Stop checking after finding an active quest

	# Restrict access to houses based on quest status
	for house in house_buttons.keys():
		var area2d = get_node_or_null(house_buttons[house])

		if not QuestManager.quests.has(house):
			continue  # Skip houses without quests

		var status = QuestManager.quests[house]["status"]

		# If a quest is unavailable, temporarily unavailable, or another quest is in progress, disable entry
		if status in ["unavailable", "temporarily unavailable"] or (active_quest and house != active_quest):
			if area2d:
				area2d.set_deferred("monitorable", false)  # Disables click detection
				print("🚷 Entry blocked for:", house)

# 📌 Checks if the player can enter a house
func _can_enter_house(house: String) -> bool:
	if not QuestManager.quests.has(house):
		return false  # House has no quest, deny access

	var status = QuestManager.quests[house]["status"]

	# Deny entry if quest is unavailable, temporarily unavailable, or another quest is in progress
	if status in ["unavailable", "temporarily unavailable"]:
		return false

	# Check if another quest is already underway
	for other_house in house_quests.keys():
		if house != other_house and QuestManager.quests.has(other_house) and QuestManager.quests[other_house]["status"] == "underway":
			return false  # Block entry to other houses

	return true  # Allow entry if all checks pass

# 📌 Function to refresh quest indicators manually
func refresh_quests():
	_update_quest_indicators()
