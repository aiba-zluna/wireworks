extends ParallaxBackground

@export var speed: float = 100
@export var stop_position: float = -3130
@export var van: AnimatedSprite2D  # Assign Van in the Inspector
@export var fade_layer: CanvasLayer  # Assign the FadeLayer in Inspector

var slowing_down: bool = false
var animation_started: bool = false

func _ready():
	await get_tree().create_timer(4.0).timeout  # Wait 4 seconds before animation starts
	animation_started = true

	if van:
		van.start_animation()  # Call function in van.gd
	else:
		print("Van node not assigned!")

func _process(delta):
	if animation_started and scroll_offset.x > stop_position:
		check_slowdown()

		if slowing_down:
			speed = lerp(speed, 0.0, 0.02)
			if speed < 1.0:
				speed = 0.0
				slowing_down = false
				await get_tree().create_timer(5.0).timeout  # Wait 3 seconds after stopping
				start_fade()

		scroll_offset.x -= speed * delta  # Move background

		if van and slowing_down:
			van.slow_down(speed)

func check_slowdown():
	if not slowing_down and scroll_offset.x < stop_position + 400:
		slowing_down = true

func start_fade():
	if fade_layer:
		fade_layer.fade_to_black_and_change_scene("res://scenes/3. map_overview.tscn")
	else:
		print("FadeLayer not assigned!")
