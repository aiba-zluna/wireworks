extends Node

var FOLDER_PATH := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("WireWorks/SaveFiles")
var SAVE_PATH := FOLDER_PATH.path_join("WWsavefile.json")

func save_game():
	var save_data = {
		"inventory": getinventory_data(),
		"hotbar": GameData.hotbar,
		"active_item": GameData.active_item,
		"npc_encounter": GameData.npc_encounter,
		"last_completed_photo": GameData.last_completed_photo,
		"quests": QuestManager.quests,
		"reputation": QuestManager.reputation,
		"exp": QuestManager.exp,
		"php": GameData.php
	}

	# Create folder path if it doesn't exist
	if not DirAccess.dir_exists_absolute(FOLDER_PATH):
		DirAccess.make_dir_recursive_absolute(FOLDER_PATH)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] Game saved to ", SAVE_PATH)

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found at ", SAVE_PATH)
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_data = file.get_as_text()
	file.close()

	var save_data = JSON.parse_string(json_data)
	if save_data:
		restoreinventory(save_data["inventory"])
		GameData.hotbar = save_data["hotbar"]
		GameData.active_item = save_data["active_item"]
		GameData.npc_encounter = save_data["npc_encounter"]
		GameData.last_completed_photo = save_data["last_completed_photo"]
		QuestManager.quests = save_data["quests"]
		QuestManager.reputation = save_data["reputation"]
		QuestManager.exp = save_data["exp"]
		GameData.php = save_data["php"]

		GameData.inventory_updated.emit()
		GameData.hotbar_updated.emit()
		GameData.active_item_changed.emit()

		print("[SaveManager] Game loaded successfully!")
		return true
	else:
		print("[SaveManager] Failed to parse save file.")
		return false

#region 🔹 Helper Methods

func getinventory_data():
	var data = {}
	for slot in GameData.inventory.keys():
		data[slot] = {
			"name": GameData.inventory[slot].name,
			"description": GameData.inventory[slot].description
		}
	return data

func restoreinventory(inventory_data):
	for slot in inventory_data.keys():
		if slot in GameData.inventory:
			GameData.inventory[slot].name = inventory_data[slot].name
			GameData.inventory[slot].description = inventory_data[slot].description

#endregion
