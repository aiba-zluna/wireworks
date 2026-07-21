extends Control

# Nodes for wires
@export var wire1: Sprite2D
@export var wire2: Sprite2D

# Nodes for pins
@export var pin1: Node2D
@export var pin2: Node2D

# Glow nodes inside pins
@export var pin1_glow: Node2D
@export var pin2_glow: Node2D

# Glow properties
@export var glow_color: Color = Color(1, 1, 0, 0.5)  # Yellow semi-transparent glow
@export var min_scale: float = 0.8  # Minimum scale when pulsing
@export var max_scale: float = 1.2  # Maximum scale when pulsing
@export var pulse_speed: float = 2.0  # Speed of pulsation
@export var glow_size: float = 20.0  # Size of the glow effect

# Track if wires are connected
var wire1_connected := false
var wire2_connected := false

# Store initial positions
var wire1_initial_pos: Vector2
var wire2_initial_pos: Vector2

# Track if wires are currently being dragged
var dragging_wire1 := false
var dragging_wire2 := false

# Offset for drag from mouse position
var drag_offset: Vector2

# Glow animation time
var time: float = 0.0

# Add signal for completion
signal minigame_completed

func _ready():
	# Store initial positions
	wire1_initial_pos = wire1.position
	wire2_initial_pos = wire2.position
	
	# Initialize glow nodes
	_setup_glow_nodes()
	
	# Enable input processing
	set_process_input(true)
	
	print("[Coupler Minigame] Ready")

func _setup_glow_nodes():
	# Setup glow nodes with draw functionality
	if pin1_glow:
		pin1_glow.visible = false  # Start invisible
		
		# Override the _draw method
		pin1_glow.set_script(create_glow_script())
	else:
		print("[Coupler Minigame] WARNING: pin1_glow not assigned!")
		
	if pin2_glow:
		pin2_glow.visible = false  # Start invisible
		
		# Override the _draw method
		pin2_glow.set_script(create_glow_script())
	else:
		print("[Coupler Minigame] WARNING: pin2_glow not assigned!")

# Create a script for glow nodes dynamically
func create_glow_script():
	var script = GDScript.new()
	script.source_code = """
extends Node2D

# Glow properties
@export var glow_color: Color = Color(1, 1, 0, 0.5)  # Yellow semi-transparent glow
@export var glow_size: float = 20.0  # Size of the glow effect

func _draw():
	# Draw an inner solid circle
	draw_circle(Vector2.ZERO, glow_size * 0.4, glow_color)
	
	# Draw outer glow using multiple circles with decreasing opacity
	var num_layers = 5
	for i in range(num_layers):
		var size_factor = 0.4 + (0.6 * (i + 1) / num_layers)
		var alpha_factor = 1.0 - (i / float(num_layers))
		
		var outer_color = glow_color
		outer_color.a = glow_color.a * alpha_factor
		
		draw_circle(Vector2.ZERO, glow_size * size_factor, outer_color)
"""
	script.reload()
	return script

func _input(event):
	# Handle mouse button events
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_check_start_drag(event.position)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_drop()

func _check_start_drag(mouse_pos: Vector2):
	# Check if mouse is over wire1
	if _is_point_in_sprite(mouse_pos, wire1):
		dragging_wire1 = true
		drag_offset = wire1.global_position - mouse_pos
		print("[Coupler Minigame] Started dragging Wire 1")
	
	# Check if mouse is over wire2
	elif _is_point_in_sprite(mouse_pos, wire2):
		dragging_wire2 = true
		drag_offset = wire2.global_position - mouse_pos
		print("[Coupler Minigame] Started dragging Wire 2")

func _handle_drop():
	if dragging_wire1:
		dragging_wire1 = false
		_check_wire1_connection()
	
	if dragging_wire2:
		dragging_wire2 = false
		_check_wire2_connection()

func _is_point_in_sprite(point: Vector2, sprite: Sprite2D) -> bool:
	# Convert point to local coordinates
	var local_point = sprite.to_local(point)
	
	# Get sprite dimensions (assuming centered origin)
	var half_width = sprite.texture.get_width() * sprite.scale.x / 2
	var half_height = sprite.texture.get_height() * sprite.scale.y / 2
	
	# Check if point is within sprite bounds
	return local_point.x > -half_width and local_point.x < half_width and \
		   local_point.y > -half_height and local_point.y < half_height

func _process(delta):
	# Update time for glow animation
	time += delta * pulse_speed
	
	# Calculate scale using sin wave for pulsing effect
	var scale_factor = (min_scale + max_scale) / 2 + sin(time) * (max_scale - min_scale) / 2
	
	# Handle wire dragging and pin glowing
	if dragging_wire1:
		wire1.global_position = get_global_mouse_position() + drag_offset
		if pin1_glow:
			pin1_glow.visible = true
			pin1_glow.scale = Vector2(scale_factor, scale_factor)
			pin1_glow.queue_redraw()
	elif not wire1_connected and pin1_glow:
		pin1_glow.visible = false

	if dragging_wire2:
		wire2.global_position = get_global_mouse_position() + drag_offset
		if pin2_glow:
			pin2_glow.visible = true
			pin2_glow.scale = Vector2(scale_factor, scale_factor)
			pin2_glow.queue_redraw()
	elif not wire2_connected and pin2_glow:
		pin2_glow.visible = false
	
	# Update glow for connected wires
	if wire1_connected and pin1_glow:
		pin1_glow.visible = true
		pin1_glow.scale = Vector2(scale_factor, scale_factor)
		pin1_glow.queue_redraw()
		
	if wire2_connected and pin2_glow:
		pin2_glow.visible = true
		pin2_glow.scale = Vector2(scale_factor, scale_factor)
		pin2_glow.queue_redraw()
	
	# Check if both wires are connected
	if wire1_connected and wire2_connected:
		_complete_minigame()

func _check_wire1_connection():
	# Get the rightmost part of wire1 (you may need to adjust this calculation)
	var wire1_right_edge = wire1.global_position + Vector2(wire1.texture.get_width() * wire1.scale.x / 2, 0)
	
	# Simple distance check to pin1
	var distance_to_pin1 = wire1_right_edge.distance_to(pin1.global_position)
	
	if distance_to_pin1 < 30:  # Adjust threshold as needed
		# Snap to position
		wire1.global_position = pin1.global_position - Vector2(wire1.texture.get_width() * wire1.scale.x / 2, 0)
		wire1_connected = true
		if pin1_glow:
			pin1_glow.visible = true
		print("[Coupler Minigame] Wire 1 connected")
	else:
		# Return to initial position
		wire1.position = wire1_initial_pos
		wire1_connected = false

func _check_wire2_connection():
	# Get the leftmost part of wire2 (you may need to adjust this calculation)
	var wire2_left_edge = wire2.global_position - Vector2(wire2.texture.get_width() * wire2.scale.x / 2, 0)
	
	# Simple distance check to pin2
	var distance_to_pin2 = wire2_left_edge.distance_to(pin2.global_position)
	
	if distance_to_pin2 < 30:  # Adjust threshold as needed
		# Snap to position
		wire2.global_position = pin2.global_position + Vector2(wire2.texture.get_width() * wire2.scale.x / 2, 0)
		wire2_connected = true
		if pin2_glow:
			pin2_glow.visible = true
		print("[Coupler Minigame] Wire 2 connected")
	else:
		# Return to initial position
		wire2.position = wire2_initial_pos
		wire2_connected = false

func _complete_minigame():
	print("[Coupler Minigame] Completed!")
	
	# Wait a moment to show success state
	await get_tree().create_timer(0.5).timeout
	
	# Set the minigame to invisible and remove it from the process loop
	self.visible = false  # Hide the minigame
	set_process(false)    # Stop processing to prevent further loops
	
	# Emit the completion signal for the parent scene to handle
	minigame_completed.emit()
	
	print("[Coupler Minigame] Completed, moving to next step.")
