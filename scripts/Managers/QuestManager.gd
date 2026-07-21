extends Node

# 📢 Signals
signal quest_updated  # Triggers when quest statuses change
signal reputation_updated  # Triggers when reputation changes

# 🏆 Reputation System
enum Reputation { NOVICE, EXPERIENCED, VETERAN }
var reputation: int = Reputation.NOVICE  # Default: Novice
var exp: int = 0  # Player's experience points

# 📜 Quest Data Structure
var quests := {
	#tutorials (one time events)
	"overview": {"status": "available"},
	"menu": {"status": "available"},
	"cutting": {"status": "available"},
	"stripping": {"status": "available"},
	"rj45": {"status": "available"},
	"crimping": {"status": "available"},
	"coupler": {"status": "available"},
	
	"ruralhood1house1": {"location": "ruralhood1house1", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralhood1house2": {"location": "ruralhood1house2", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralhood1house3": {"location": "ruralhood1house3", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralhood2house1": {"location": "ruralhood2house1", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralhood2house2": {"location": "ruralhood2house2", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralhood2house3": {"location": "ruralhood2house3", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralbarnhouse1": {"location": "ruralbarnhouse1", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralbarnhouse2": {"location": "ruralbarnhouse2", "status": "available", "EXP reward": 1, "PHP reward": 1},
	"ruralbarnhouse3": {"location": "ruralbarnhouse3", "status": "available", "EXP reward": 1, "PHP reward": 1},

	"suburbanhood1house1": {"location": "suburbanhood1house1", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood1house2": {"location": "suburbanhood1house2", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood1house3": {"location": "suburbanhood1house3", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood2house1": {"location": "suburbanhood2house1", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood2house2": {"location": "suburbanhood2house2", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood2house3": {"location": "suburbanhood2house3", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood3house1": {"location": "suburbanhood3house1", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood3house2": {"location": "suburbanhood3house2", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},
	"suburbanhood3house3": {"location": "suburbanhood3house3", "status": "unavailable", "EXP reward": 2, "PHP reward": 1},

	"urbanfloor1": {"location": "urbanfloor1", "status": "unavailable", "EXP reward": 7, "PHP reward": 1},
	"urbanfloor2": {"location": "urbanfloor2", "status": "unavailable", "EXP reward": 7, "PHP reward": 1},
	"urbanfloor3": {"location": "urbanfloor3", "status": "unavailable", "EXP reward": 7, "PHP reward": 1}
}

#region 🔥 Quest Methods

func _ready():
	update_quests()  # 🔄 Ensure quests are updated on game start
	print("[QuestManager] Initialized")



# ✅ Start a Quest
func start_quest(quest_name: String):
	if quests.has(quest_name) and quests[quest_name]["status"] == "available":
		quests[quest_name]["status"] = "underway"
		
		# Make other available quests temporarily unavailable
		for q in quests.keys():
			if quests[q]["status"] == "available":
				quests[q]["status"] = "temp_unavailable"

		update_quests()

func is_available(quest_name: String) -> bool:
	if quests.has(quest_name):
		var quest = quests[quest_name]
		if quest is Dictionary and quest.has("status"):
			return quest["status"] == "available"
	return false

# ✅ Complete a Quest
func complete_quest(quest_name: String):
	if quests.has(quest_name) and quests[quest_name]["status"] == "underway":
		exp += quests[quest_name]["EXP reward"]
		quests[quest_name]["status"] = "finished"

		# Restore temp_unavailable quests
		for q in quests.keys():
			if quests[q]["status"] == "temp_unavailable":
				quests[q]["status"] = "available"

		update_quests()

# ✅ Manually Update Quest Status (🔧 Fix for your issue)
func update_quest_status(quest_name: String, new_status: String):
	if quests.has(quest_name):
		quests[quest_name]["status"] = new_status
		update_quests()

# ✅ Check if an area has an active quest
func has_active_quest_in(area: String) -> bool:
	for quest in quests.values():
		if quest is Dictionary and quest.has("status"):
			if quest["location"].begins_with(area) and quest["status"] in ["available", "underway"]:
				return true
	return false

#endregion

#region 🏆 Reputation System

# 🔄 Update Reputation & Unlock Quests
func update_quests():
	_update_reputation()
	_update_quest_availability()
	quest_updated.emit()

# 🔄 Update Reputation Based on EXP
func _update_reputation():
	if exp >= 35:
		reputation = Reputation.VETERAN
	elif exp >= 18:
		reputation = Reputation.EXPERIENCED
	else:
		reputation = Reputation.NOVICE

	reputation_updated.emit()

# ✅ Unlock Quests Based on Reputation
func _update_quest_availability():
	for quest_name in quests.keys():
		var quest = quests[quest_name]
		if quest is Dictionary and quest.has("status") and quest["status"] == "unavailable":
			if reputation == Reputation.EXPERIENCED and "suburban" in quest["location"]:
				quest["status"] = "available"
			elif reputation == Reputation.VETERAN and "urban" in quest["location"]:
				quest["status"] = "available"

#endregion

#region 🚪 Level Access Control

# ✅ Check if Player Can Enter a Level
func can_enter_level(location: String) -> bool:
	if not quests.has(location):
		return false  # Location doesn't exist
	
	var quest = quests[location]
	if quest is Dictionary and quest.has("status"):
		return quest["status"] not in ["finished", "unavailable", "temp_unavailable"]
	
	return false

#endregion
