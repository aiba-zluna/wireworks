extends Node

signal hotbar_updated

func _ready():
	print("[UIManager] Initialized")
	GameData.hotbar_updated.connect(_on_hotbar_updated)

func _on_hotbar_updated():
	hotbar_updated.emit()

func add_to_hotbar(slot_name):
	GameData.add_to_hotbar(slot_name)

func remove_from_hotbar(slot_name):
	GameData.remove_from_hotbar(slot_name)

func get_inventory():
	return GameData.inventory
