extends Control

@export var hotbar_bg: Sprite2D
@export var grid_container: GridContainer
@export var item_name_label: Label
@export var item_cursor: TextureRect  # 🔥 NEW: Cursor image

var active_slot: TextureRect = null  # Tracks the currently active slot

func _ready():
	print("[UIHotbar] Hotbar Ready")
	GameData.hotbar_updated.connect(update_hotbar_display)
	GameData.active_item_changed.connect(update_hotbar_display)
	update_hotbar_display()
	set_process_input(true)  # Enable mouse tracking

func update_hotbar_display():
	print("[UIHotbar] Updating hotbar...")

	# Clear previous textures and reset visuals
	for slot in grid_container.get_children():
		slot.texture = null
		slot.self_modulate = Color.WHITE  # Reset color
		slot.scale = Vector2(1, 1)  # Reset size
		if slot.is_connected("gui_input", _on_hotbar_interaction):
			slot.disconnect("gui_input", _on_hotbar_interaction)

	# Add items from hotbar
	for i in range(min(GameData.hotbar.size(), grid_container.get_child_count())):
		var slot_name = GameData.hotbar[i]
		var slot = grid_container.get_child(i)
		var item_data = GameData.inventory.get(slot_name, null)

		if item_data:
			slot.texture = item_data["icon"]
			slot.connect("gui_input", _on_hotbar_interaction.bind(slot, slot_name))

			# Highlight & enlarge active item
			if GameData.active_item == slot_name:
				slot.self_modulate = Color(1.2, 1.2, 1.2)  # Brighten slot
				slot.scale = Vector2(1.2, 1.2)  # Increase size
			else:
				slot.self_modulate = Color.WHITE  # Normal color
				slot.scale = Vector2(1, 1)  # Default size

	# 🔥 Update cursor display
	_update_cursor()

# 📌 Handles left-click (select active item) and right-click (remove item if UI_Menu exists)
func _on_hotbar_interaction(event, slot, slot_name):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Right-click: Remove item if UI_Menu is present
			if is_instance_valid(get_tree().get_current_scene().find_child("UI_Menu", true, false)):
				print("[UIHotbar] Removing item from hotbar:", slot_name)
				GameData.remove_from_hotbar(slot_name)
			else:
				print("[UIHotbar] Cannot remove items – UI_Menu is not in this scene!")
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Left-click: Select item as active
			GameData.set_active_item(slot_name)
			_update_cursor()  # 🔥 Update cursor on selection

# 🔥 Mouse Follower: Keeps cursor aligned with mouse
func _input(event):
	if event is InputEventMouseMotion:
		if item_cursor.visible:
			item_cursor.global_position = get_global_mouse_position() - (item_cursor.size / 2)

# 🔥 Updates the cursor image when selecting an item
func _update_cursor():
	if not is_instance_valid(item_cursor):
		print("[UIHotbar] ERROR: item_cursor is not assigned!")
		return
	
	var active_item = GameData.active_item
	
	if active_item != "":
		var item_data = GameData.inventory.get(active_item, null)
		if item_data:
			item_cursor.texture = item_data["icon"]
			item_cursor.visible = true
		else:
			item_cursor.visible = false
	else:
		item_cursor.visible = false

# ✅ Shows item name on hover
func _on_slot_hovered(item_name):
	item_name_label.text = item_name
	item_name_label.visible = true

# ❌ Hides name when mouse exits slot
func _on_slot_unhovered():
	item_name_label.visible = false
