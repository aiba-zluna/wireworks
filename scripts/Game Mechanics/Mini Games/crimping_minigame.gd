extends Control

# Signal emitted when minigame is completed
signal minigame_completed

#region Inspector Properties
# Game Configuration - Easily adjustable in Inspector
@export_group("Difficulty Settings")
@export var needle_speed: float = 500.0  # Pixels per second
@export var target_area_size: float = 50.0  # Width of the highlighted area
@export var points_required: int = 3
@export var snap_distance: float = 100.0  # How close wire needs to be to slot

@export_group("Wire Settings")
@export var wire_texture: TextureRect
@export var wire_initial_position: Vector2
@export var pin_marker: Node  # Visual guide showing the connection point

@export_group("Tool Views")
@export var tool_front_view: TextureRect
@export var tool_side_view: TextureRect

@export_group("QTE Components")
@export var qte_bar: ColorRect  # The bar container
@export var qte_needle: ColorRect  # The moving needle
@export var qte_target_area: ColorRect  # The highlighted area
@export var progress_indicator: Label  # Shows current progress (e.g., "1/3")
@export var crimp_button: Button  # The button to start crimping
#endregion

#region Game State Variables
var is_dragging_wire: bool = false
var is_wire_placed: bool = false
var is_qte_active: bool = false
var current_points: int = 0
var needle_direction: int = 1  # 1 = right, -1 = left
var drag_offset: Vector2 = Vector2.ZERO  # Where the wire was clicked
var initialized: bool = false  # Track if the game has been initialized
#endregion

func _ready():
	print("[Crimping Minigame] Ready called")
	
	# Do initial setup if not already done
	if not initialized:
		_setup_initial_state()
	
	# Always reset the minigame when it becomes visible
	reset_minigame()
	
	# Connect to visibility changed signal to ensure reset when shown
	if not is_connected("visibility_changed", _on_visibility_changed):
		connect("visibility_changed", _on_visibility_changed)

# Called when visibility changes
func _on_visibility_changed():
	if visible:
		print("[Crimping Minigame] Became visible - Resetting state...")
		reset_minigame()

func _setup_initial_state():
	print("[Crimping Minigame] Performing initial setup...")
	
	# Connect signals
	_connect_signals()
	
	# Mark as initialized
	initialized = true
	
	print("[Crimping Minigame] Initial setup complete")

func _process(delta):
	# Handle wire dragging
	if is_dragging_wire and wire_texture:
		wire_texture.global_position = get_global_mouse_position() - drag_offset
	
	# Process QTE needle movement
	if is_qte_active and qte_needle and qte_bar:
		_move_needle(delta)
		
	# Debug drawing
	queue_redraw()
	
func _draw():
	# Draw the snap radius as a visual aid in development (only when dragging)
	if pin_marker and pin_marker.visible and is_dragging_wire:
		var circle_pos = pin_marker.global_position - global_position  # Convert to local coordinates
		draw_circle(circle_pos, snap_distance, Color(1, 1, 0, 0.1))  # Very faint yellow

# Public function to reset the minigame for reuse
func reset_minigame():
	print("[Crimping Minigame] Resetting minigame...")
	
	# Reset game state variables
	is_dragging_wire = false
	is_wire_placed = false
	is_qte_active = false
	current_points = 0
	needle_direction = 1
	
	# Reset wire position
	if wire_texture:
		wire_texture.position = wire_initial_position
		# Hide wire PinGlow
		if wire_texture.has_node("PinGlow"):
			wire_texture.get_node("PinGlow").hide_glow()
	
	# Reset views
	if tool_front_view and tool_side_view:
		tool_front_view.visible = true
		tool_side_view.visible = false
	
	# Hide QTE elements
	_set_qte_elements_visibility(false)
	
	# Hide pin marker and glow
	if pin_marker:
		pin_marker.visible = false
		if pin_marker.has_node("PinGlow"):
			pin_marker.get_node("PinGlow").hide_glow()
	
	# Reset progress indicator
	if progress_indicator:
		progress_indicator.text = "0/" + str(points_required)
		progress_indicator.visible = false
	
	print("[Crimping Minigame] Reset complete and ready for use")

func _connect_signals():
	# Wire input - disconnect first to avoid duplicates
	if wire_texture:
		if wire_texture.is_connected("gui_input", _on_wire_input):
			wire_texture.disconnect("gui_input", _on_wire_input)
		wire_texture.gui_input.connect(_on_wire_input)
		
	# Crimp button pressed - disconnect first to avoid duplicates
	if crimp_button:
		if crimp_button.is_connected("pressed", _on_crimp_button_pressed):
			crimp_button.disconnect("pressed", _on_crimp_button_pressed)
		crimp_button.pressed.connect(_on_crimp_button_pressed)

#region Wire Handling
func _on_wire_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("[DEBUG] Wire pressed - Starting drag")
				# Remember where in the wire the player clicked
				drag_offset = event.position
				
				# Start dragging wire
				is_dragging_wire = true
				
				# Switch to side view
				_switch_tool_view(false)
				
				# Show pin marker while dragging
				if pin_marker:
					pin_marker.visible = true
					print("[DEBUG] Pin marker path: ", pin_marker.get_path())
					# Enable pin glow when dragging
					if pin_marker.has_node("PinGlow"):
						print("[DEBUG] Found pin marker PinGlow node, showing glow")
						pin_marker.get_node("PinGlow").show_glow()
				
				# Enable wire glow when dragging starts
				if wire_texture and wire_texture.has_node("PinGlow"):
					print("[DEBUG] Found wire PinGlow node, showing glow")
					wire_texture.get_node("PinGlow").show_glow()
			else:
				print("[DEBUG] Wire released - Ending drag")
				# Stop dragging
				is_dragging_wire = false
				
				# Get the right edge center point of the wire
				var wire_right_edge = _get_wire_right_edge()
				
				# Check if the right edge of the wire is close to the pin marker
				if pin_marker and wire_right_edge.distance_to(pin_marker.global_position) <= snap_distance:
					_place_wire_in_slot()
				else:
					_reset_wire()
				
				# Hide pin marker when not dragging (unless wire is placed)
				if pin_marker and not is_wire_placed:
					pin_marker.visible = false
				
				# Always hide the pin marker glow when releasing
				if pin_marker and pin_marker.has_node("PinGlow"):
					print("[DEBUG] Hiding pin marker PinGlow")
					pin_marker.get_node("PinGlow").hide_glow()
				
				# Hide wire glow when dragging ends (unless wire is placed)
				if wire_texture and wire_texture.has_node("PinGlow"):
					if not is_wire_placed:
						print("[DEBUG] Hiding wire PinGlow")
						wire_texture.get_node("PinGlow").hide_glow()
					
				# Print debug info
				print("[Crimping Minigame] Wire placement:")
				print("  - Wire right edge: ", wire_right_edge)
				if pin_marker:
					print("  - Pin position: ", pin_marker.global_position)
					print("  - Distance: ", wire_right_edge.distance_to(pin_marker.global_position))
				print("  - Snap distance: ", snap_distance)

# Get the position of the right edge center of the wire
func _get_wire_right_edge() -> Vector2:
	if wire_texture:
		var right_edge = wire_texture.global_position
		right_edge.x += wire_texture.size.x  # Right edge
		right_edge.y += wire_texture.size.y / 2  # Vertical center
		return right_edge
	return Vector2.ZERO

func _place_wire_in_slot():
	if pin_marker and wire_texture:
		# Calculate position so the right edge of the wire aligns with the pin marker
		var new_position = pin_marker.global_position
		new_position.x -= wire_texture.size.x  # Move left by the wire's width
		new_position.y -= wire_texture.size.y / 2  # Center vertically
		
		# Snap wire to correct position
		wire_texture.global_position = new_position
		is_wire_placed = true
		
		# Keep showing side view
		_switch_tool_view(false)
		
		# Show QTE elements and crimp button
		_set_qte_elements_visibility(true)
		
		print("[Crimping Minigame] Wire placed successfully!")

func _reset_wire():
	if wire_texture:
		# Return wire to initial position
		wire_texture.position = wire_initial_position
		is_wire_placed = false
		
		# Switch back to front view
		_switch_tool_view(true)
		
		print("[Crimping Minigame] Wire reset to initial position")

func _switch_tool_view(show_front: bool):
	if tool_front_view and tool_side_view:
		tool_front_view.visible = show_front
		tool_side_view.visible = !show_front
#endregion

#region QTE Handling
func _set_qte_elements_visibility(visible: bool):
	if qte_bar:
		qte_bar.visible = visible
	
	if qte_needle:
		qte_needle.visible = visible
	
	if qte_target_area:
		qte_target_area.visible = visible
	
	if progress_indicator:
		progress_indicator.visible = visible
		
	if crimp_button:
		crimp_button.visible = visible

func _on_crimp_button_pressed():
	# Start the QTE when the crimp button is pressed
	if is_wire_placed and not is_qte_active:
		print("[Crimping Minigame] Crimp button pressed - starting QTE")
		_initialize_qte_positions()
		is_qte_active = true

func _initialize_qte_positions():
	# Position the needle at the start of the bar
	if qte_needle:
		qte_needle.position.x = 0
	
	# Position the target area
	_place_target_area_randomly()

# Method to handle clicks anywhere on the screen to stop the needle
func _input(event):
	if event is InputEventMouseButton and event.pressed and is_qte_active:
		# Check if needle hit the target
		var did_hit = _check_needle_hit_target()
		
		if did_hit:
			current_points += 1
			print("[Crimping Minigame] Hit target! Current points:", current_points, "/", points_required)
			
			# Update progress indicator
			if progress_indicator:
				progress_indicator.text = str(current_points) + "/" + str(points_required)
			
			if current_points >= points_required:
				print("[Crimping Minigame] All points collected! Completing minigame.")
				_complete_minigame()
			else:
				# Set new target area for next round
				_place_target_area_randomly()
				
				# Reset needle and keep QTE active
				if qte_needle:
					qte_needle.position.x = 0
					needle_direction = 1
		else:
			print("[Crimping Minigame] Missed target! Resetting needle.")
			# On miss, reset the needle
			if qte_needle:
				qte_needle.position.x = 0
				needle_direction = 1

func _check_needle_hit_target() -> bool:
	if qte_needle and qte_target_area:
		var needle_pos = qte_needle.position.x
		var target_min = qte_target_area.position.x
		var target_max = target_min + qte_target_area.size.x
		
		return needle_pos >= target_min and needle_pos <= target_max
	return false

func _move_needle(delta):
	if qte_needle and qte_bar:
		var bar_width = qte_bar.size.x - qte_needle.size.x
		
		# Move needle based on direction and speed
		qte_needle.position.x += needle_direction * needle_speed * delta
		
		# Bounce when hitting edges
		if qte_needle.position.x <= 0:
			qte_needle.position.x = 0
			needle_direction = 1
		elif qte_needle.position.x >= bar_width:
			qte_needle.position.x = bar_width
			needle_direction = -1

func _place_target_area_randomly():
	if qte_target_area and qte_bar:
		# Resize target area based on setting
		qte_target_area.size.x = target_area_size
		
		# Random position within bar
		var max_pos = qte_bar.size.x - qte_target_area.size.x
		qte_target_area.position.x = randf_range(0, max_pos)
#endregion

func _complete_minigame():
	# Hide all QTE elements
	_set_qte_elements_visibility(false)
	
	# Reset QTE state
	is_qte_active = false
	
	# Signal that minigame is completed
	print("[Crimping Minigame] Emitting completion signal")
	minigame_completed.emit()
