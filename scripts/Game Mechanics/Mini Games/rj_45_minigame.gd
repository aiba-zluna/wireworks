extends Control

# Add the signal for minigame completion
signal minigame_completed

# 📌 Inspector-assigned nodes
@export var rj45_connector: Control  # Area where RJ45 pins are located
@export var wires_container: Control  # Container for the source wires

# 📌 Pin references
@export var pin_positions: Array[Marker2D]  # Markers for pin positions in RJ45
@export var correct_order: Array[String] = ["WhiteOrange", "Orange", "WhiteGreen", "Blue", 
										 "WhiteBlue", "Green", "WhiteBrown", "Brown"]  # T568B standard

# 📌 Runtime variables
var wires = []  # All wire TextureRects
var wire_original_positions = {}  # Store original positions for each wire
var wire_sizes = {}  # Store sizes of each wire for centering
var selected_wire = null  # Currently selected wire
var selected_wire_name = ""  # Name of the selected wire
var placed_wire_names = []  # Names of placed wires (in order they were placed)
var pin_filled = []  # Array tracking which pins are filled (true/false)
var pin_highlight_tweens = {}  # Store tweens for pin highlights
var pin_visual_nodes = {}  # Store references to visual nodes for each pin marker
var initialized = false  # Flag to track if initial setup has been done

# Highlighting colors
@export var normal_pin_color: Color = Color(0.7, 0.7, 0.7, 0.5)  # Default pin color
@export var pulse_color_start: Color = Color(0.3, 0.8, 1.0, 0.7)  # Blue-ish glow start
@export var pulse_color_end: Color = Color(0.5, 1.0, 1.0, 0.9)    # Brighter blue-ish glow end

# Debug mode
var debug_mode = true  # Set to true to enable debug messages

func _ready():
	print("[RJ45 Minigame] Ready called - Setting up...")
	
	# Run initial setup if not already done
	if not initialized:
		_do_initial_setup()
	
	# Important: Always reset the minigame when it becomes visible
	# This ensures proper state when reusing the minigame
	reset_minigame()
	
	# Connect to visibility changed signal to ensure reset when shown
	if not is_connected("visibility_changed", _on_visibility_changed):
		connect("visibility_changed", _on_visibility_changed)

# Called when visibility changes
func _on_visibility_changed():
	if visible:
		print("[RJ45 Minigame] Became visible - Resetting state...")
		reset_minigame()

# Function to do one-time initial setup
func _do_initial_setup():
	print("[RJ45 Minigame] Performing initial setup...")
	
	# Initialize pin tracking
	pin_filled.resize(pin_positions.size())
	for i in range(pin_filled.size()):
		pin_filled[i] = false
	
	# Set up visual pin markers
	_setup_pin_visuals()
	
	# Set up TextureRect wires
	_setup_texturerect_wires()
	
	# Mark as initialized
	initialized = true
	
	if debug_mode:
		print("[RJ45 Minigame] Initial setup complete:")
		print("  - Found", wires.size(), "wires")
		print("  - Correct order:", correct_order)
		print("  - Found", pin_positions.size(), "pin positions")

# Public function to reset the minigame for reuse
func reset_minigame():
	print("[RJ45 Minigame] Resetting minigame state...")
	
	# Clear pin tracking
	for i in range(pin_filled.size()):
		pin_filled[i] = false
	
	# Stop all pin highlights
	_stop_all_pin_highlights()
	
	# Reset the visibility of all visual nodes
	for pin_marker in pin_visual_nodes:
		var visual_node = pin_visual_nodes[pin_marker]
		if visual_node:
			visual_node.set_glow(false)
			visual_node.scale = Vector2(1, 1)
	
	# Move all wires back to original positions with animation
	for wire in wires:
		if wire and wire.name in wire_original_positions:
			var tween = create_tween()
			tween.tween_property(wire, "position", wire_original_positions[wire.name], 0.2)
			tween.parallel().tween_property(wire, "scale", Vector2(1, 1), 0.2)
			tween.parallel().tween_property(wire, "modulate", Color(1, 1, 1, 1), 0.2)
			tween.parallel().tween_property(wire, "rotation", 0, 0.2)
			
			# Ensure wires are visible
			wire.visible = true
	
	# Clear placed wires tracking
	placed_wire_names.clear()
	
	# Make sure no wire is selected
	selected_wire = null
	selected_wire_name = ""
	
	# Turn off process
	set_process(false)
	
	print("[RJ45 Minigame] Reset complete - Ready for use")

func _setup_pin_visuals():
	# Create visual elements for each pin marker
	for i in range(pin_positions.size()):
		var pin_marker = pin_positions[i]
		
		# Create a visual node for the pin
		var visual_node = _create_pin_visual_node(i)
		pin_marker.add_child(visual_node)
		
		# Store reference to visual node
		pin_visual_nodes[pin_marker] = visual_node
		
		if debug_mode:
			print("[RJ45 Minigame] Created visual for pin", i+1)

func _create_pin_visual_node(pin_index):
	# Create a visual node for the pin
	var visual = PinVisual.new()
	visual.name = "PinVisual"
	visual.radius = 10.0
	visual.normal_color = normal_pin_color
	visual.glow_color = pulse_color_start
	
	return visual

# Inner class for pin visual nodes
class PinVisual extends Node2D:
	var radius: float = 10.0
	var normal_color: Color = Color(0.7, 0.7, 0.7, 0.5)
	var glow_color: Color = Color(0.3, 0.8, 1.0, 0.7)
	var current_color: Color
	var is_glowing: bool = false
	
	func _ready():
		current_color = normal_color
	
	func _draw():
		draw_circle(Vector2.ZERO, radius, current_color)
	
	func set_glow(enabled: bool):
		is_glowing = enabled
		if enabled:
			current_color = glow_color
		else:
			current_color = normal_color
		queue_redraw()
		
	func set_color(color: Color):
		current_color = color
		queue_redraw()

func _setup_texturerect_wires():
	# Clear existing references to avoid duplicates
	wires.clear()
	wire_original_positions.clear()
	wire_sizes.clear()
	
	# Get all TextureRect children from wires_container
	for child in wires_container.get_children():
		if child is TextureRect:
			# Store the wire reference
			wires.append(child)
			
			# Store original position
			wire_original_positions[child.name] = child.position
			
			# Store wire size for centering calculations
			wire_sizes[child.name] = child.size
			
			# Make sure mouse filter is set to stop input
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			
			# Disconnect existing connections to avoid duplicates
			if child.is_connected("gui_input", _on_wire_input.bind(child)):
				child.disconnect("gui_input", _on_wire_input.bind(child))
			
			# Connect input event
			child.gui_input.connect(_on_wire_input.bind(child))
			
			if debug_mode:
				print("[RJ45 Minigame] Found TextureRect wire:", child.name)
				print("  - Original position:", child.position)
				print("  - Wire size:", child.size)

func _on_wire_input(event, wire):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("[RJ45 Minigame] Wire clicked:", wire.name)
			
			# Allow removing wires that have been placed
			var pin_index = _get_pin_index_for_wire(wire.name)
			if pin_index != -1:
				# Wire is placed in a pin, remove it
				print("[RJ45 Minigame] Removing wire", wire.name, "from pin", pin_index+1)
				_remove_wire_from_pin(wire, pin_index)
			
			# Select the wire for dragging
			_select_wire(wire)
		
		elif selected_wire == wire:
			# Mouse released while dragging a wire
			if debug_mode:
				print("[RJ45 Minigame] Mouse released while dragging wire:", wire.name)
			
			# Stop highlighting all pins
			_stop_all_pin_highlights()
			
			# Check if wire is over an RJ45 pin
			var placed_in_pin = false
			
			# Check each pin position
			for i in range(pin_positions.size()):
				if not pin_filled[i]: # Only check empty pins
					var pin_pos = pin_positions[i].global_position
					var mouse_pos = get_global_mouse_position()
					var distance = mouse_pos.distance_to(pin_pos)
					
					if debug_mode:
						print("[RJ45 Minigame] Checking pin", i+1, "- Distance:", distance)
					
					if distance < 30: # Snap distance
						print("[RJ45 Minigame] Wire", wire.name, "placed in pin", i+1)
						_place_wire_in_pin(wire, i)
						placed_in_pin = true
						break
			
			# Return wire to original position if not placed
			if not placed_in_pin:
				print("[RJ45 Minigame] Wire", wire.name, "returned to original position")
				_return_wire_to_original()
			
			# Clear selection
			selected_wire = null
			selected_wire_name = ""
			set_process(false)

func _select_wire(wire):
	# Set as selected wire
	selected_wire = wire
	selected_wire_name = wire.name
	
	# Move wire to top of draw order
	wire.get_parent().move_child(wire, wire.get_parent().get_child_count() - 1)
	
	# Enable _process to track mouse position
	set_process(true)
	
	print("[RJ45 Minigame] Selected wire:", wire.name)

# Function to get the pin index where a wire is placed
func _get_pin_index_for_wire(wire_name):
	for i in range(pin_filled.size()):
		if pin_filled[i] and i < placed_wire_names.size() and placed_wire_names[i] == wire_name:
			return i
	return -1

# Function to remove a wire from a pin
func _remove_wire_from_pin(wire, pin_index):
	# Mark the pin as empty
	pin_filled[pin_index] = false
	
	# Remove from placed wires
	placed_wire_names[pin_index] = ""
	
	# Update array to maintain correct length but with empty spot
	var new_placed_wires = []
	for i in range(placed_wire_names.size()):
		if i == pin_index:
			new_placed_wires.append("")
		else:
			new_placed_wires.append(placed_wire_names[i])
	placed_wire_names = new_placed_wires
	
	if debug_mode:
		print("[RJ45 Minigame] Removed wire", wire.name, "from pin", pin_index+1)
		print("[RJ45 Minigame] Updated placed wires:", placed_wire_names)

func _is_wire_placed(wire_name):
	return placed_wire_names.has(wire_name) and wire_name != ""

func _process(delta):
	if selected_wire:
		# Make wire follow mouse position
		var mouse_pos = get_global_mouse_position()
		var local_pos = wires_container.get_global_transform().affine_inverse() * mouse_pos
		selected_wire.position = local_pos
		
		# Highlight empty pins when dragging a wire
		_highlight_available_pins()

# 1. Highlight available pins when dragging a wire
func _highlight_available_pins():
	for i in range(pin_positions.size()):
		if not pin_filled[i]:
			var pin_marker = pin_positions[i]
			
			# Create or update the tween for this pin
			if not pin_marker in pin_highlight_tweens or pin_highlight_tweens[pin_marker] == null:
				_create_pin_highlight_tween(pin_marker)

# Stop highlighting pins
func _stop_all_pin_highlights():
	for pin_marker in pin_highlight_tweens:
		if pin_highlight_tweens[pin_marker] != null:
			pin_highlight_tweens[pin_marker].kill()
		
		# Reset visual node
		var visual_node = pin_visual_nodes.get(pin_marker)
		if visual_node:
			visual_node.set_glow(false)
			visual_node.scale = Vector2(1, 1)
	
	pin_highlight_tweens.clear()

# Create a pulsing highlight effect for a pin
func _create_pin_highlight_tween(pin_marker):
	# Get the visual node for this pin
	var visual_node = pin_visual_nodes.get(pin_marker)
	if not visual_node:
		return
		
	# Cancel any existing tween
	if pin_marker in pin_highlight_tweens and pin_highlight_tweens[pin_marker] != null:
		pin_highlight_tweens[pin_marker].kill()
	
	# Set the node to glow
	visual_node.set_glow(true)
	
	# Create a new pulsing tween
	var tween = create_tween()
	tween.set_loops() # Make it loop indefinitely
	
	# Pulse both color and scale for a nice effect
	tween.tween_property(visual_node, "scale", Vector2(1.2, 1.2), 0.5)
	tween.parallel().tween_method(Callable(visual_node, "set_color"), pulse_color_start, pulse_color_end, 0.5)
	
	tween.tween_property(visual_node, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_method(Callable(visual_node, "set_color"), pulse_color_end, pulse_color_start, 0.5)
	
	pin_highlight_tweens[pin_marker] = tween

func _place_wire_in_pin(wire, pin_index):
	# Mark the pin as filled
	pin_filled[pin_index] = true
	
	# Calculate global pin position and convert to wires_container local position
	var pin_global_pos = pin_positions[pin_index].global_position
	var pin_local_pos = wires_container.get_global_transform().affine_inverse() * pin_global_pos
	
	# Get the wire size for centering
	var wire_size = wire_sizes[wire.name]
	
	# Calculate position adjustment for centering (horizontally centered, vertically aligned with top)
	var centered_pos = pin_local_pos - Vector2(wire_size.x / 2, 0)
	
	if debug_mode:
		print("[RJ45 Minigame] Placing wire", wire.name, "at pin", pin_index+1)
		print("  - Pin global position:", pin_global_pos)
		print("  - Pin local position:", pin_local_pos)
		print("  - Centered position:", centered_pos)
	
	# Animate the wire to the centered pin position
	var tween = create_tween()
	tween.tween_property(wire, "position", centered_pos, 0.2)
	
	# 2. Move the wire to the back of the drawing order
	wire.get_parent().move_child(wire, 0)
	
	# Expand placed_wire_names array if needed
	while placed_wire_names.size() <= pin_index:
		placed_wire_names.append("")
	
	# Add to placed wires tracking
	placed_wire_names[pin_index] = wire.name
	
	if debug_mode:
		print("[RJ45 Minigame] Placed wires so far:", placed_wire_names)
	
	# Check if all pins are filled with actual wires (no empty strings)
	var all_filled = true
	for i in range(pin_positions.size()):
		if not pin_filled[i] or i >= placed_wire_names.size() or placed_wire_names[i] == "":
			all_filled = false
			break
	
	if all_filled:
		print("[RJ45 Minigame] All pins filled! Validating wiring...")
		# Wait a short moment before validating
		await get_tree().create_timer(0.3).timeout
		_validate_wiring()

func _return_wire_to_original():
	if selected_wire:
		# Animate the wire back to its original position
		var tween = create_tween()
		tween.tween_property(selected_wire, "position", wire_original_positions[selected_wire.name], 0.2)

func _validate_wiring():
	var is_correct = true
	
	# Add visual feedback - scanning animation
	_play_scanning_animation()
	
	# Compare the placed wire names with the correct order
	for i in range(placed_wire_names.size()):
		if i < correct_order.size() and placed_wire_names[i] != correct_order[i]:
			if debug_mode:
				print("[RJ45 Minigame] Incorrect wire at position", i+1)
				print("  - Expected:", correct_order[i], "Got:", placed_wire_names[i])
			is_correct = false
			break
	
	# After scanning animation, show result
	await get_tree().create_timer(1.5).timeout
	
	if is_correct:
		print("[RJ45 Minigame] Wiring is CORRECT!")
		_on_success()
	else:
		print("[RJ45 Minigame] Wiring is INCORRECT!")
		_on_failure()

func _play_scanning_animation():
	print("[RJ45 Minigame] Scanning wiring...")
	
	# Scan animation: highlight each pin in sequence
	for i in range(placed_wire_names.size()):
		var wire_name = placed_wire_names[i]
		if wire_name != "":
			var wire = _find_wire_by_name(wire_name)
			
			if wire:
				if debug_mode:
					print("[RJ45 Minigame] Scanning wire at pin", i+1, ":", wire_name)
				
				# Flash effect
				var tween = create_tween()
				tween.tween_property(wire, "modulate", Color(1.5, 1.5, 1.5), 0.1)
				tween.tween_property(wire, "modulate", Color(1, 1, 1), 0.1)
		
		await get_tree().create_timer(0.15).timeout

func _find_wire_by_name(wire_name):
	for wire in wires:
		if wire.name == wire_name:
			return wire
	return null

func _on_success():
	print("[RJ45 Minigame] Success! Animation playing...")
	
	# Success animation - flash all wires green
	for wire in wires:
		var tween = create_tween()
		tween.tween_property(wire, "modulate", Color(0.5, 1.5, 0.5), 0.2)
		tween.tween_property(wire, "modulate", Color(1, 1, 1), 0.2)
	
	# Finish the minigame
	await get_tree().create_timer(1.0).timeout
	_finish_minigame(true)

func _on_failure():
	print("[RJ45 Minigame] Failure! Animation playing...")
	
	# Failure animation - shake the connector
	var shake_tween = create_tween()
	shake_tween.tween_property(rj45_connector, "position", rj45_connector.position + Vector2(5, 0), 0.1)
	shake_tween.tween_property(rj45_connector, "position", rj45_connector.position - Vector2(5, 0), 0.1)
	shake_tween.tween_property(rj45_connector, "position", rj45_connector.position, 0.1)
	
	# Highlight incorrect wires in red
	for i in range(placed_wire_names.size()):
		if i < correct_order.size() and placed_wire_names[i] != correct_order[i] and placed_wire_names[i] != "":
			var wire = _find_wire_by_name(placed_wire_names[i])
			if wire:
				print("[RJ45 Minigame] Highlighting incorrect wire:", wire.name)
				var tween = create_tween()
				tween.tween_property(wire, "modulate", Color(1.5, 0.5, 0.5), 0.2)
				tween.tween_property(wire, "modulate", Color(1, 1, 1), 0.2)
	
	# Reset after a delay
	await get_tree().create_timer(1.5).timeout
	print("[RJ45 Minigame] Resetting game after failure...")
	
	# Reset the game state
	reset_minigame()

func _finish_minigame(success):
	if success:
		print("[RJ45 Minigame] Game complete! Emitting completion signal...")
		# Hide this minigame
		self.visible = false
		
		# Emit the completion signal
		minigame_completed.emit()
