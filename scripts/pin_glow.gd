extends Node2D

# Pin Glow Node - Add to your pin marker in the scene

@export_group("Glow Settings")
@export var glow_color: Color = Color(1, 1, 0.5, 0.8)  # Yellow/gold glow by default
@export var base_size: float = 20.0  # Base size of the glow
@export var max_size: float = 30.0  # Maximum size when pulsing
@export var pulse_speed: float = 2.0  # How fast the glow pulses
@export var enabled: bool = false  # Is the glow currently visible?

# Internal variables for animation
var current_size: float = 0.0
var t: float = 0.0  # Time accumulator for pulsing

func _ready():
	# Initialize with no glow unless enabled in Inspector
	if not enabled:
		modulate.a = 0.0
	else:
		modulate.a = 1.0

func _process(delta):
	# Only process if enabled
	if enabled:
		# Animate the pulsing effect
		t += delta * pulse_speed
		current_size = base_size + (max_size - base_size) * 0.5 * (1.0 + sin(t * PI))
		
		# Apply scale and update visibility
		modulate.a = 1.0
	else:
		# Fade out if not enabled
		modulate.a = move_toward(modulate.a, 0.0, delta * 4.0)
	
	# Always update drawing
	queue_redraw()

func _draw():
	# Draw the circular glow
	if modulate.a > 0.01:
		# Create colors with different alpha values
		var outer_glow_color = Color(
			glow_color.r * 0.8,  # Darkened red component
			glow_color.g * 0.8,  # Darkened green component
			glow_color.b * 0.8,  # Darkened blue component
			0.3                  # Lower alpha
		)
		
		var middle_glow_color = Color(
			glow_color.r,
			glow_color.g,
			glow_color.b,
			0.6
		)
		
		var inner_glow_color = Color(
			min(glow_color.r * 1.2, 1.0),  # Lightened red component
			min(glow_color.g * 1.2, 1.0),  # Lightened green component
			min(glow_color.b * 1.2, 1.0),  # Lightened blue component
			0.9                            # Higher alpha
		)
		
		# Outer glow
		draw_circle(Vector2.ZERO, current_size, outer_glow_color)
		
		# Middle glow
		draw_circle(Vector2.ZERO, current_size * 0.7, middle_glow_color)
		
		# Inner glow
		draw_circle(Vector2.ZERO, current_size * 0.4, inner_glow_color)

# Public functions to enable/disable the glow
func show_glow():
	enabled = true

func hide_glow():
	enabled = false

# For immediate on/off without fade
func set_glow(state: bool):
	enabled = state
	modulate.a = 1.0 if state else 0.0
