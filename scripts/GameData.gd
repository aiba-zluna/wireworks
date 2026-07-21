extends Node

# 📢 Signals for UI updates
signal inventory_updated
signal hotbar_updated
signal active_item_changed

# 🎒 Inventory items
var inventory := {
	"slot1": {"name": "Wire Cutter", "description": "Cuts CAT5 cables.", "icon": preload("res://assets/tools/1. wire cutter.png")},
	"slot2": {"name": "CAT5 Wire Stripper", "description": "Removes outer insulation of CAT5 cables, exposing its inner wiring.", "icon": preload("res://assets/tools/2. cat5 wire stripper.png")},
	"slot3": {"name": "RJ45", "description": "CAT5 cable connector. \n The wiring order is:\n White Orange > Orange >\nWhite Green > Blue >\nWhite Blue > Green >\nWhite Brown > Brown", "icon": preload("res://assets/tools/3. rj45.png")},
	"slot4": {"name": "Crimping Tool", "description": "Locks RJ45 connectors in place.", "icon": preload("res://assets/tools/4. crimping tool.png")},
	"slot5": {"name": "RJ45 Coupler", "description": "Connects two Ethernet cables.", "icon": preload("res://assets/tools/5. rj45 coupler.png")}
}

# 🎮 Hotbar System
var hotbar: Array = []  # Items in the hotbar
var active_item: String = ""  # Currently selected item

var php: int = 0 #Gold system

# 📷 Progress Tracking
var last_completed_photo: int = 0  # Last photo progression

# 🗺️ Quest Tracking for Map Overview
var active_quests := {
	"rural": false,
	"sub_urban": false,
	"urban": false
}

# 🗣️ NPC Encounter Tracking 
var npc_encounter := {
	# 🌾 Rural Area
	"ruralhood1house1": {"npc1": false},
	"ruralhood1house2": {"npc1": false},
	"ruralhood1house3": {"npc1": false},
	"ruralhood2house1": {"npc1": false},
	"ruralhood2house2": {"npc1": false},
	"ruralhood2house3": {"npc1": false},
	"ruralbarnhouse1": {"npc1": false},
	"ruralbarnhouse2": {"npc1": false},
	"ruralbarnhouse3": {"npc1": false},

	# 🏡 Suburban Area
	"suburbanhood1house1": {"npc1": false},
	"suburbanhood1house2": {"npc1": false},
	"suburbanhood1house3": {"npc1": false},
	"suburbanhood2house1": {"npc1": false},
	"suburbanhood2house2": {"npc1": false},
	"suburbanhood2house3": {"npc1": false},
	"suburbanhood3house1": {"npc1": false},
	"suburbanhood3house2": {"npc1": false},
	"suburbanhood3house3": {"npc1": false},

	# 🏙️ Urban Area
	"urbanfloor1": {"npc1": false},
	"urbanfloor2": {"npc1": false},
	"urbanfloor3": {"npc1": false}
}

#region 🔥 Hotbar Methods

# ✅ Add an item to the hotbar (max 4 items)
func add_to_hotbar(slot_name: String):
	if slot_name in hotbar or hotbar.size() >= 4:
		return
	hotbar.append(slot_name)
	hotbar_updated.emit()

# ✅ Remove an item from the hotbar
func remove_from_hotbar(slot_name: String):
	if slot_name in hotbar:
		hotbar.erase(slot_name)
		if active_item == slot_name:
			active_item = ""
			active_item_changed.emit()
		hotbar_updated.emit()

# ✅ Set the active item (or deselect if already selected)
func set_active_item(slot_name: String):
	active_item = slot_name if active_item != slot_name else ""
	active_item_changed.emit()

#endregion

#region 🗺️ Map Overview Quest Icon Logic

# 🔄 Update active quest markers in the map overview
func update_active_quests():
	# Reset all quest area statuses
	active_quests["rural"] = false
	active_quests["sub_urban"] = false
	active_quests["urban"] = false

	# Fetch active quests from QuestManager
	for quest_name in QuestManager.quests.keys():
		if QuestManager.quests[quest_name] in ["available", "underway"]:
			if "rural" in quest_name:
				active_quests["rural"] = true
			elif "sub_urban" in quest_name:
				active_quests["sub_urban"] = true
			elif "urban" in quest_name:
				active_quests["urban"] = true

# ✅ Check if an area has an active quest
func has_active_quest_in(area: String) -> bool:
	return active_quests.get(area, false)

#endregion

#region 🗣️ NPC Encounter Methods

# ✅ Check if an NPC has been met in a specific location
func has_met_npc(location: String, npc_id: String) -> bool:
	return npc_encounter.get(location, {}).get(npc_id, false)

# ✅ Mark an NPC as "met"
func meet_npc(location: String, npc_id: String):
	if location in npc_encounter and npc_id in npc_encounter[location]:
		npc_encounter[location][npc_id] = true
	else:
		print("[GameData] ⚠️ NPC or location not found:", location, npc_id)

#endregion
