extends Control

signal minigame_completed  # Signal to notify parent when minigame is finished

@export var left_input: NodePath  # Assign the left cut area in the Inspector
@export var right_input: NodePath  # Assign the right cut area in the Inspector
@export var progress_bar: NodePath  # Assign the shared progress bar in the Inspector
@export var left_dotted_line: NodePath  # Assign the left dotted line Sprite2D
@export var right_dotted_line: NodePath  # Assign the right dotted line Sprite2D

@onready var left_cut = get_node(left_input) if left_input else null
@onready var right_cut = get_node(right_input) if right_input else null
@onready var progress_bar_node = get_node(progress_bar) if progress_bar else null
@onready var left_line = get_node(left_dotted_line) if left_dotted_line else null
@onready var right_line = get_node(right_dotted_line) if right_dotted_line else null

var left_cut_done := false
var right_cut_done := false
var is_dragging_left := false
var is_dragging_right := false
var current_progress_left := 0.0
var current_progress_right := 0.0
var last_mouse_position_left := Vector2.ZERO
var last_mouse_position_right := Vector2.ZERO
var active_area := ""  # Track which area is currently being used
var game_completed := false  # Flag to prevent multiple completions

const DECAY_RATE := 5.0  # Points lost per second when not dragging

func _ready():
	print("[Cutter Minigame] READY - Waiting for user interaction...")

	# Ensure the player has the correct item equipped
	if not _has_required_item():
		print("[Cutter Minigame] Incorrect tool equipped. The game is still visible for testing.")
	else:
		print("[Cutter Minigame] Correct tool equipped! Proceed with cutting.")

	# Initialize progress bar to 0
	if progress_bar_node:
		progress_bar_node.value = 0

	# Check if input areas and progress bar are assigned
	if left_cut and right_cut and progress_bar_node:
		# Connect the input events
		left_cut.input_event.connect(_on_area_input.bind("left"))
		right_cut.input_event.connect(_on_area_input.bind("right"))
		
		# Connect hover signals
		left_cut.mouse_entered.connect(_on_mouse_entered.bind("left"))
		left_cut.mouse_exited.connect(_on_mouse_exited.bind("left"))
		right_cut.mouse_entered.connect(_on_mouse_entered.bind("right"))
		right_cut.mouse_exited.connect(_on_mouse_exited.bind("right"))
	else:
		printerr("[Cutter Minigame] Error: Input areas or progress bar not assigned in Inspector!")

func _process(delta):
	# Only allow progress if the correct tool (wire cutter) is equipped
	if not _has_required_item():
		# Show some indication that the player needs to equip the wire cutter
		if progress_bar_node and progress_bar_node.value > 0:
			progress_bar_node.value = 0
		return
		
	if is_dragging_left and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Get mouse movement
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta_y = current_mouse_pos.y - last_mouse_position_left.y
		
		if abs(delta_y) > 0:
			# Update progress based on vertical movement (10 points per unit)
			current_progress_left = clamp(current_progress_left + delta_y * 0.1, 0, 100)
			_update_progress_bar()
			print("[DEBUG] LEFT Progress: ", current_progress_left)
			
		last_mouse_position_left = current_mouse_pos
		
		# Check if the left cut area is complete
		if current_progress_left >= 100.0 and not left_cut_done:
			left_cut_done = true
			left_cut.modulate = Color(1, 1, 1, 0.3)  # Fade effect when cut
			
			# Hide the left dotted line
			if left_line:
				left_line.visible = false
	
	elif is_dragging_right and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Get mouse movement
		var current_mouse_pos = get_viewport().get_mouse_position()
		var delta_y = current_mouse_pos.y - last_mouse_position_right.y
		
		if abs(delta_y) > 0:
			# Update progress based on vertical movement (10 points per unit)
			current_progress_right = clamp(current_progress_right + delta_y * 0.1, 0, 100)
			_update_progress_bar()
			print("[DEBUG] RIGHT Progress: ", current_progress_right)
			
		last_mouse_position_right = current_mouse_pos
		
		# Check if the right cut area is complete
		if current_progress_right >= 100.0 and not right_cut_done:
			right_cut_done = true
			right_cut.modulate = Color(1, 1, 1, 0.3)  # Fade effect when cut
			
			# Hide the right dotted line
			if right_line:
				right_line.visible = false
	
	# Decay progress when not dragging
	elif not is_dragging_left and current_progress_left > 0:
		current_progress_left = max(0, current_progress_left - DECAY_RATE * delta)
		_update_progress_bar()
		
	elif not is_dragging_right and current_progress_right > 0:
		current_progress_right = max(0, current_progress_right - DECAY_RATE * delta)
		_update_progress_bar()
	
	# Check if both sides are cut and the game hasn't been completed yet
	if left_cut_done and right_cut_done and not game_completed:
		print("[Cutter Minigame] You Win!")
		game_completed = true
		_finish_cutting()

func _has_required_item() -> bool:
	# Check if the active item is "Wire Cutter" (slot1)
	return GameData.active_item == "slot1"

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
	# Reset dragging state when exiting
	if side == "left":
		is_dragging_left = false
	elif side == "right":
		is_dragging_right = false

func _on_area_input(_viewport, event, _shape_idx, side):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[DEBUG] Mouse PRESSED on " + side + " area")
			if side == "left":
				is_dragging_left = true
				last_mouse_position_left = event.position
				active_area = "left"
			elif side == "right":
				is_dragging_right = true
				last_mouse_position_right = event.position
				active_area = "right"
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[DEBUG] Mouse RELEASED on " + side + " area")
			if side == "left":
				is_dragging_left = false
			elif side == "right":
				is_dragging_right = false

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

func _finish_cutting():
	await get_tree().create_timer(0.5).timeout  # Small delay for effect
	print("[Cutter Minigame] Completed, moving to next step.")
	
	# Set the minigame to invisible and remove it from the process loop
	self.visible = false  # Hide the minigame
	set_process(false)    # Stop processing to prevent further loops
	
	# Emit the completion signal for the parent scene to handle
	minigame_completed.emit()
