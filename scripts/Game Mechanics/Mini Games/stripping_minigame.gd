extends Control

signal minigame_completed  # Signal to notify parent when minigame is finished

@export var left_input: NodePath  # Assign the left area in the Inspector
@export var right_input: NodePath  # Assign the right area in the Inspector
@export var progress_bar: NodePath  # Assign the shared progress bar in the Inspector
@export var left_cut: NodePath  # Assign the LeftCut Sprite2D
@export var right_cut: NodePath  # Assign the RightCut Sprite2D
@export var left_stripped: NodePath  # Assign the leftstripped Sprite2D
@export var right_stripped: NodePath  # Assign the rightstripped Sprite2D

@onready var left_area = get_node(left_input) if left_input else null
@onready var right_area = get_node(right_input) if right_input else null
@onready var progress_bar_node = get_node(progress_bar) if progress_bar else null
@onready var left_cut_node = get_node(left_cut) if left_cut else null
@onready var right_cut_node = get_node(right_cut) if right_cut else null
@onready var left_stripped_node = get_node(left_stripped) if left_stripped else null
@onready var right_stripped_node = get_node(right_stripped) if right_stripped else null

var left_stripped_done := false
var right_stripped_done := false
var is_stripping_left := false
var is_stripping_right := false
var current_progress_left := 0.0
var current_progress_right := 0.0
var active_area := ""  # Track which area is currently being used
var game_completed := false  # Flag to prevent multiple completions

# Rotation tracking variables
var left_center := Vector2.ZERO
var right_center := Vector2.ZERO
var last_left_angle := 0.0
var last_right_angle := 0.0

const DECAY_RATE := 5.0  # Points lost per second when not rotating

func _ready():
	print("[Stripper Minigame] READY - Waiting for user interaction...")

	# Connect to the active_item_changed signal
	if not GameData.is_connected("active_item_changed", _on_active_item_changed):
		GameData.active_item_changed.connect(_on_active_item_changed)

	# Check current tool status
	var has_correct_tool = _has_required_item()
	print("[Stripper Minigame] Current tool: " + GameData.active_item)
	print("[Stripper Minigame] Has correct tool (Wire Stripper/slot2): " + str(has_correct_tool))
	
	if not has_correct_tool:
		print("[Stripper Minigame] Incorrect tool equipped. Waiting for Wire Stripper...")
	else:
		print("[Stripper Minigame] Correct tool equipped! Proceed with stripping.")

	# Initialize progress bar to 0
	if progress_bar_node:
		progress_bar_node.value = 0

	# Show original cut wires and hide the stripped visuals initially
	if left_cut_node:
		left_cut_node.visible = true
	if right_cut_node:
		right_cut_node.visible = true
	if left_stripped_node:
		left_stripped_node.visible = false
	if right_stripped_node:
		right_stripped_node.visible = false

	# Check if input areas and progress bar are assigned
	if left_area and right_area and progress_bar_node:
		# Calculate centers of areas for rotation tracking
		if left_area.get_child(0) is CollisionShape2D:
			left_center = left_area.global_position + left_area.get_child(0).position
		else:
			left_center = left_area.global_position
			
		if right_area.get_child(0) is CollisionShape2D:
			right_center = right_area.global_position + right_area.get_child(0).position
		else:
			right_center = right_area.global_position
			
		print("[DEBUG] Left center position: ", left_center)
		print("[DEBUG] Right center position: ", right_center)
		
		# Connect the input events
		left_area.input_event.connect(_on_area_input.bind("left"))
		right_area.input_event.connect(_on_area_input.bind("right"))
		
		# Connect hover signals
		left_area.mouse_entered.connect(_on_mouse_entered.bind("left"))
		left_area.mouse_exited.connect(_on_mouse_exited.bind("left"))
		right_area.mouse_entered.connect(_on_mouse_entered.bind("right"))
		right_area.mouse_exited.connect(_on_mouse_exited.bind("right"))
		
		# Workaround: Reset area nodes to fix input detection
		call_deferred("_reset_area_nodes")
		
		# Print the tool status at start
		print("[DEBUG] Initial tool status: " + GameData.active_item)
		print("[DEBUG] Has correct tool: " + str(_has_required_item()))
	else:
		printerr("[Stripper Minigame] Error: Input areas or progress bar not assigned in Inspector!")

func _process(delta):
	# Only allow progress if the correct tool (wire stripper) is equipped
	if not _has_required_item():
		# Show some indication that the player needs to equip the wire stripper
		if progress_bar_node and progress_bar_node.value > 0:
			progress_bar_node.value = 0
		return
	
	# Track mouse position for continuous rotation if we're still holding the mouse button
	if is_stripping_left and not left_stripped_done and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_viewport().get_mouse_position()
		_handle_rotation(mouse_pos, "left")
	elif is_stripping_right and not right_stripped_done and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_viewport().get_mouse_position()
		_handle_rotation(mouse_pos, "right")
		
	# Decay progress when not actively stripping
	if not is_stripping_left and current_progress_left > 0:
		current_progress_left = max(0, current_progress_left - DECAY_RATE * delta)
		_update_progress_bar()
		
	elif not is_stripping_right and current_progress_right > 0:
		current_progress_right = max(0, current_progress_right - DECAY_RATE * delta)
		_update_progress_bar()
	
	# Check if both sides are stripped and the game hasn't been completed yet
	if left_stripped_done and right_stripped_done and not game_completed:
		print("[Stripper Minigame] You Win!")
		game_completed = true
		_finish_stripping()

func _has_required_item() -> bool:
	# Check if the active item is "Wire Stripper" (slot2)
	return GameData.active_item == "slot2"
	
# Handle active item changes
func _on_active_item_changed():
	print("[Stripper Minigame] Tool changed to: " + GameData.active_item)
	print("[Stripper Minigame] Has correct tool: " + str(_has_required_item()))
	
	# Reset area nodes when tool changes to ensure input detection works
	call_deferred("_reset_area_nodes")

# WORKAROUND: Reset area nodes to fix circular drag detection
func _reset_area_nodes():
	if left_area and right_area:
		print("[DEBUG] Applying area node visibility workaround")
		
		# Store original visibility
		var left_visible = left_area.visible
		var right_visible = right_area.visible
		
		# Hide and then show to reset
		left_area.visible = false
		right_area.visible = false
		await get_tree().create_timer(0.05).timeout
		left_area.visible = left_visible
		right_area.visible = right_visible
		
		print("[DEBUG] Area nodes reset completed")

func _on_mouse_entered(side):
	print("[DEBUG] Mouse ENTERED " + side + " area")
	
	# Reset progress if switching between areas
	if active_area != "" and active_area != side:
		if side == "left":
			current_progress_left = 0.0
		else:
			current_progress_right = 0.0
		_update_progress_bar()
	
	active_area = side

func _on_mouse_exited(side):
	print("[DEBUG] Mouse EXITED " + side + " area")
	
	# We don't reset stripping state here anymore
	# This allows the player to make larger circular movements
	# that might temporarily go outside the area
	
	# Just track which side we exited if needed
	print("[DEBUG] Note: Circular motion tracking will continue until mouse button is released")

func _on_area_input(_viewport, event, _shape_idx, side):
	# Don't process if the area is already completed
	if (side == "left" and left_stripped_done) or (side == "right" and right_stripped_done):
		return
		
	# First check if the correct tool is equipped
	if event is InputEventMouseButton and event.pressed:
		var has_correct_tool = _has_required_item()
		print("[DEBUG] Tool check on click - Current tool: " + GameData.active_item)
		print("[DEBUG] Has correct tool (Wire Stripper/slot2): " + str(has_correct_tool))
		
		if not has_correct_tool:
			print("[Stripper Minigame] Cannot strip wire: Wire Stripper not equipped")
			return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[DEBUG] Mouse PRESSED on " + side + " area")
			if side == "left":
				is_stripping_left = true
				last_left_angle = _get_angle_to_center(event.position, left_center)
				active_area = "left"
				print("[DEBUG] Started tracking LEFT rotation")
			elif side == "right":
				is_stripping_right = true
				last_right_angle = _get_angle_to_center(event.position, right_center)
				active_area = "right"
				print("[DEBUG] Started tracking RIGHT rotation")
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[DEBUG] Mouse RELEASED on " + side + " area")
			if side == "left":
				is_stripping_left = false
			elif side == "right":
				is_stripping_right = false
	
	# Initial rotation handling for mouse motion events
	# Note: Continuous motion is now handled in _process for more reliable tracking
	if event is InputEventMouseMotion and _has_required_item():
		if side == "left" and is_stripping_left and not left_stripped_done:
			# Just update the angle for initial movement
			last_left_angle = _get_angle_to_center(event.position, left_center)
		elif side == "right" and is_stripping_right and not right_stripped_done:
			# Just update the angle for initial movement
			last_right_angle = _get_angle_to_center(event.position, right_center)

# Calculate angle between mouse position and center point
func _get_angle_to_center(mouse_pos: Vector2, center: Vector2) -> float:
	return atan2(mouse_pos.y - center.y, mouse_pos.x - center.x)

# Handle rotation detection
func _handle_rotation(mouse_pos: Vector2, side: String):
	# First check if the correct tool is equipped
	if not _has_required_item():
		print("[DEBUG] Rotation attempted with wrong tool: " + GameData.active_item)
		return
	
	var center = left_center if side == "left" else right_center
	var current_angle = _get_angle_to_center(mouse_pos, center)
	var last_angle = last_left_angle if side == "left" else last_right_angle
	
	# Calculate angle difference (handles wrapping around +/- PI)
	var angle_diff = current_angle - last_angle
	if angle_diff > PI:
		angle_diff -= 2 * PI
	elif angle_diff < -PI:
		angle_diff += 2 * PI
		
	# Update the last known angle
	if side == "left":
		last_left_angle = current_angle
	else:
		last_right_angle = current_angle
	
	# Accumulate rotation (using absolute value to count both directions)
	var rotation_value = abs(angle_diff) * 15.0  # Increased scaling factor for more responsive rotation
	
	if rotation_value > 0.01:  # Small threshold to avoid minor movements
		if side == "left":
			current_progress_left = clamp(current_progress_left + rotation_value, 0, 100)
			print("[DEBUG] LEFT Progress: ", current_progress_left)
			
			# Check if the left area is complete
			if current_progress_left >= 100.0 and not left_stripped_done:
				left_stripped_done = true
				if left_cut_node:
					left_cut_node.visible = false  # Hide original wire
				if left_stripped_node:
					left_stripped_node.visible = true  # Show stripped visual
				left_area.visible = false  # Hide the area to prevent further interaction
				print("[DEBUG] LEFT side stripping complete!")
				
				# Reset progress bar when switching to the other side
				current_progress_left = 0.0
				_update_progress_bar()
		else:
			current_progress_right = clamp(current_progress_right + rotation_value, 0, 100)
			print("[DEBUG] RIGHT Progress: ", current_progress_right)
			
			# Check if the right area is complete
			if current_progress_right >= 100.0 and not right_stripped_done:
				right_stripped_done = true
				if right_cut_node:
					right_cut_node.visible = false  # Hide original wire
				if right_stripped_node:
					right_stripped_node.visible = true  # Show stripped visual
				right_area.visible = false  # Hide the area to prevent further interaction
				print("[DEBUG] RIGHT side stripping complete!")
				
				# Reset progress bar
				current_progress_right = 0.0
				_update_progress_bar()
		
		# Update progress bar
		_update_progress_bar()

func _update_progress_bar():
	# Update the progress bar to show current progress
	if progress_bar_node:
		var display_progress = 0
		
		# If we're working on the left side, show left progress
		if active_area == "left":
			display_progress = current_progress_left
		# If we're working on the right side, show right progress
		elif active_area == "right":
			display_progress = current_progress_right
		
		progress_bar_node.value = display_progress

func _finish_stripping():
	await get_tree().create_timer(0.5).timeout  # Small delay for effect
	print("[Stripper Minigame] Completed, moving to next step.")
	
	# Set the minigame to invisible and remove it from the process loop
	self.visible = false  # Hide the minigame
	set_process(false)    # Stop processing to prevent further loops
	
	# Clean up signal connections
	if GameData.is_connected("active_item_changed", _on_active_item_changed):
		GameData.active_item_changed.disconnect(_on_active_item_changed)
	
	# Emit the completion signal for the parent scene to handle
	minigame_completed.emit()
