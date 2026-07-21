extends Panel

@onready var label = $Label
@onready var anim_player = $AnimationPlayer

var dialogues = [
	" Fresh out of tech-voc, and here I am, diving straight into the job.",
	" No orientation, no warm-up—just me, my tools, and the road ahead.",
	" They say the city is where all the action is, where the best jobs pay the best money.",
	" But let’s be real… those gigs are a nightmare.",
	" Offices stacked like server racks", 
	" tangled cables running like spaghetti in the ceilings",
	" and clients who think turning it off and on again is 'too much work.'",
	" Nah. I need to start somewhere I can actually breathe.",

	" [SFX: The van rattles a bit as I leave the city behind.]",
	" Suburbs up next. Cleaner streets, bigger houses,",
	" people who only call a tech when their Wi-Fi dies in the middle of a streaming binge.",
	" A little less pressure, but still plenty of work.",
	" Home networks, small businesses—just enough to keep me on my toes.",
	" Not bad, but still not where I want to be.",

	" Rural’s the goal. Open roads, fresh air,",
	" and jobs where the biggest problem is a busted cat5 line",
	" or a street vendor who just wants their piso wifi connection to work.",
	" Less stress, more hands-on work.",
	" Besides, these are the places that actually need people like me.",
	" No corporate IT teams, no endless help desk tickets.",
	" Just me, a problem, and a solution.",

	" [SFX: I tighten my grip on the wheel.]",
	" This is it. My first real job as a network tech.",
	" Let’s see what the world throws at me."
]

var index = 0
var can_progress = true

func _ready():
	label.text = ""
	show_next_line()  # Start the dialogue

func show_next_line():
	if index < dialogues.size():
		can_progress = false  # Prevent skipping
		label.text = dialogues[index]
		anim_player.play("fade_in")  # Play fade-in animation
		await anim_player.animation_finished  # Wait for animation
		await get_tree().create_timer(1.5).timeout  # Wait before fade-out
		anim_player.play("fade_out")  # Play fade-out animation
		await anim_player.animation_finished  # Wait for fade-out to finish
		
		index += 1
		if index < dialogues.size():  # Ensure there are still lines to show
			show_next_line()  # Immediately show the next line
		else:
			queue_free()  # Remove dialogue box when done

func _input(event):
	if event.is_action_pressed("ui_accept") and can_progress:
		show_next_line()
