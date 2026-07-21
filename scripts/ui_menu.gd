extends Control

@export var grid_container: GridContainer
@export var item_info_panel: Panel
@export var item_name_label: Label
@export var item_description_label: Label
@export var item_icon_texture: TextureRect


@onready var van_background = $"Van bg"
@onready var notes_background = $"Notes bg"
@onready var options_background = $"Options bg"

@onready var btn_van = $"btn Van"
@onready var btn_notes = $"btn Notes"
@onready var btn_options = $"btn Options"
@onready var dialogue_scene = preload("res://scenes/User Interface/UI_dialogues.tscn")

func _ready():
	print("[UI_Menu] Menu Ready")
	update_inventory_display()
		# Ensure only Van Background is visible at start
	show_background(van_background)
	update_inventory_display()

	# Connect buttons to switch backgrounds
	btn_van.connect("pressed", _on_btn_van_pressed)
	btn_notes.connect("pressed", _on_btn_notes_pressed)
	btn_options.connect("pressed", _on_btn_options_pressed)
	# First-time encounter check - now using DialogueLoader
	if QuestManager.is_available("menu"):
		await get_tree().create_timer(1).timeout
		DialogueLoader.start_dialogue_for_npc("menu", "mc")
		
#region UI Menu Backgrounds
func show_background(background_to_show):
	# Hide all backgrounds first
	van_background.visible = false
	notes_background.visible = false
	options_background.visible = false

	# Show the selected background
	background_to_show.visible = true

func _on_btn_van_pressed():
	show_background(van_background)

func _on_btn_notes_pressed():
	show_background(notes_background)

func _on_btn_options_pressed():
	show_background(options_background)
	
#endregion

#region Inventory management
func update_inventory_display():
	print("[UI_Menu] Updating inventory...")

	# Clear all previous items
	for slot in grid_container.get_children():
		slot.texture = null
		if slot.is_connected("gui_input", _on_item_interaction):
			slot.disconnect("gui_input", _on_item_interaction)
		if slot.is_connected("mouse_entered", _on_item_hovered):
			slot.disconnect("mouse_entered", _on_item_hovered)
		if slot.is_connected("mouse_exited", _on_item_unhovered):
			slot.disconnect("mouse_exited", _on_item_unhovered)

	# Fill inventory slots
	var inventory_keys = GameData.inventory.keys()
	for i in range(min(inventory_keys.size(), grid_container.get_child_count())):
		var slot_name = inventory_keys[i]
		var slot = grid_container.get_child(i)
		var item_data = GameData.inventory[slot_name]

		if item_data:
			slot.texture = item_data["icon"]
			slot.connect("gui_input", _on_item_interaction.bind(slot_name, item_data))
			slot.connect("mouse_entered", _on_item_hovered.bind(slot))
			slot.connect("mouse_exited", _on_item_unhovered.bind(slot))

# 📌 Clicking item updates the info panel
func _on_item_interaction(event, slot_name, item_data):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		item_icon_texture.texture = item_data["icon"]
		item_name_label.text = item_data["name"]
		item_description_label.text = item_data["description"]
		item_info_panel.visible = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		GameData.add_to_hotbar(slot_name)

# 🎨 Hover effect: Slightly enlarges & tints the icon
func _on_item_hovered(slot):
	slot.scale = Vector2(1.1, 1.1)  # Slightly increase size
	slot.modulate = Color(1.2, 1.2, 1.2, 1)  # Light tint

# 🆗 Reset effect when unhovered
func _on_item_unhovered(slot):
	slot.scale = Vector2(1, 1)  # Restore original size
	slot.modulate = Color(1, 1, 1, 1)  # Reset color
#endregion

#region Options
func _on_btn_main_menu_pressed() -> void:
		get_tree().change_scene_to_file("res://scenes/1. menu.tscn")  # Fallback if FadeLayer isn't found

func _on_btn_exit_pressed() -> void:
	get_tree().quit()
#endregion

func _on_btn_close_inventory_pressed() -> void:
	self.visible = false


func _on_btn_save_pressed() -> void:
	SaveManager.save_game()
	print("[Menu] Game saved successfully!")
