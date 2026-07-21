extends CanvasLayer

@export var fade_time: float = 1.0  # Duration of fade

func _ready():
	# Ensure all UI elements start fully visible
	for child in get_children():
		if child is CanvasItem:
			child.modulate.a = 1.0

func fade_out_and_change_scene(target_scene: String):
	var tween = create_tween()

	if not tween:
		print("Failed to create tween!")
		return

	tween.set_parallel(true)  # Run all fade animations at the same time
	var has_tweens = false  # Track if any tweens were created

	# Apply fade effect to all UI elements inside FadeLayer
	for child in get_children():
		if child is CanvasItem:
			tween.tween_property(child, "modulate:a", 0.0, fade_time)
			has_tweens = true

	if not has_tweens:
		print("Warning: No CanvasItem elements to fade!")
		return

	await tween.finished  # Wait for fade to complete
	get_tree().change_scene_to_file(target_scene)  # Change scene

	# Reset transparency for next use
	for child in get_children():
		if child is CanvasItem:
			child.modulate.a = 1.0
