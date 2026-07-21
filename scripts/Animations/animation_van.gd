extends AnimatedSprite2D

@export var max_animation_speed: float = 10.0
var current_speed: float = 0
var slowing_down: bool = false

func start_animation():
	visible = true  # Ensure it's visible
	stop()  # Reset animation
	current_speed = max_animation_speed
	set_speed_scale(1.0)  
	play("van")  

func _process(_delta):
	if slowing_down:
		current_speed = lerp(current_speed, 0.0, 0.02)  
		set_speed_scale(current_speed / max_animation_speed)  

		if current_speed < 1.0:
			current_speed = 0.0  
			set_speed_scale(0)
			slowing_down = false  

func slow_down(new_speed):
	slowing_down = true
	current_speed = min(current_speed, new_speed)  # Prevent speed jumps
