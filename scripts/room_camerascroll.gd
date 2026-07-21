extends Node2D

@export var camera: Camera2D  # Assign Camera2D in Inspector
@export var sprite: Sprite2D  # Assign your PNG Sprite2D here
@export var move_speed: float = 500.0  # Adjust as needed
@export var margin: float = 100.0  # Distance from screen edge before scrolling

var screen_size: Vector2
var min_x: float
var max_x: float

func _ready():
	screen_size = get_viewport_rect().size  # Get screen size

	if not sprite or not sprite.texture:
		print("Error: Sprite2D or texture not assigned!")
		return

	# Get actual PNG size (respects scaling)
	var texture_size = sprite.texture.get_size() * sprite.scale
	var texture_pos = sprite.global_position - texture_size / 2  # Centered

	# Define camera movement limits
	min_x = texture_pos.x + screen_size.x / 2  # Left boundary
	max_x = texture_pos.x + texture_size.x - screen_size.x / 2  # Right boundary

	# Ensure camera starts within the image boundaries
	camera.position.x = clamp(camera.position.x, min_x, max_x)

func _process(delta):
	if not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()

	# Define "left" and "right" scrolling zones
	var left_zone = margin
	var right_zone = screen_size.x - margin

	var move_direction = 0

	if mouse_pos.x < left_zone:
		move_direction = -1  # Move left
	elif mouse_pos.x > right_zone:
		move_direction = 1  # Move right

	# Move the camera, but clamp within the PNG size
	var new_x = clamp(camera.position.x + move_direction * move_speed * delta, min_x, max_x)
	camera.position.x = new_x
