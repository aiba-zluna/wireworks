extends Control
@onready var dialogue_scene = preload("res://scenes/User Interface/UI_dialogues.tscn")
@export var pulse_target: RichTextLabel
@export var pulse_speed: float = 2.0
@export var pulse_scale: float = 1.1

#region Buttons

func _on_new_game_pressed() -> void:
	# Always create a new save file, overwriting any existing one
	print("[Menu] Starting a new game...")
	
	# Reset GameData values
	GameData.hotbar = []
	GameData.active_item = ""
	GameData.last_completed_photo = 0
	GameData.php = 0
	
	# Reset quest progress in QuestManager
	QuestManager.exp = 0
	QuestManager.reputation = QuestManager.Reputation.NOVICE
	
	# Reset all quests to their initial states
	for quest_name in QuestManager.quests.keys():
		# Check if quest is a tutorial and skip resetting its status
		if quest_name in ["overview", "menu", "cutting", "stripping", "rj45", "crimping", "coupler"]:
			continue  # Skip resetting this quest's status

		# For all other quests, reset them based on their location
		if quest_name.begins_with("rural"):
			QuestManager.quests[quest_name]["status"] = "available"
		else:
			QuestManager.quests[quest_name]["status"] = "unavailable"

	
	# Call SaveManager to handle saving the game state
	SaveManager.save_game()

	# Navigate to cutscene
	var fade_layer = get_tree().current_scene.get_node("FadeLayer")
	if fade_layer:
		fade_layer.fade_out_and_change_scene("res://scenes/2. cutscene.tscn")

func _on_load_game_pressed() -> void:
	# Call SaveManager to load the game
	if SaveManager.load_game():
		var fade_layer = get_tree().current_scene.get_node("FadeLayer")
		if fade_layer:
			fade_layer.fade_out_and_change_scene("res://scenes/3. map_overview.tscn")  # Load scene
	else:
		print("[Menu] No save file found!")

func _on_options_pressed() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	get_tree().quit()

#endregion

var _pulse_time := 0.0

func _process(delta: float) -> void:
	if pulse_target:
		_pulse_time += delta * pulse_speed
		var scale_factor = 1.0 + (sin(_pulse_time) * 0.5 * (pulse_scale - 1.0))
		pulse_target.scale = Vector2(scale_factor, scale_factor)
