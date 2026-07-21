extends Panel  # Dialogue_Rural is a Panel

@onready var dialogue_label = $Dialogue  # Dialogue text label
@onready var npc_label = $NPC  # NPC name label
@onready var villager1 = $Villager1  # First sprite
@onready var villager2 = $Villager2  # Second sprite

var npc_name = "Villager"  
var dialogue_lines = [
	"Hi! Are you the network technician that we requested?",
	"Great! There was a rat infestation in our village which destroyed our cables....",
	"I was hoping if you could help us restore our wifi."
]

var current_line = 0
var current_text = ""
var words = []
var word_index = 0
var is_typing = false

func _ready():
	npc_label.text = npc_name  
	dialogue_label.text = ""  
	villager1.visible = true  # Show first sprite initially
	villager2.visible = false  # Hide second sprite
	mouse_filter = Control.MOUSE_FILTER_STOP  # Ensures clicks are detected
	show_next_line()

func show_next_line():
	if current_line < dialogue_lines.size():
		current_text = dialogue_lines[current_line]
		words = current_text.split(" ")
		word_index = 0
		dialogue_label.text = ""
		is_typing = true
		current_line += 1
		switch_frame()
		type_next_word()
	else:
		self.visible = false  # Hide the panel after the last dialogue
		GameData.meet_npc("ruralhood2house1", "npc1")  # Mark NPC as encountered
		QuestManager.update_quest_status("ruralhood2house1", "underway") 


func switch_frame():
	# Toggle between Villager1 and Villager2
	if current_line % 2 == 0:
		villager1.visible = true
		villager2.visible = false
	else:
		villager1.visible = false
		villager2.visible = true

func type_next_word():
	if word_index < words.size():
		dialogue_label.text += words[word_index] + " "
		word_index += 1
		await get_tree().create_timer(0.15).timeout  
		type_next_word()
	else:
		is_typing = false  

# 📌 Detect clicks anywhere on the panel
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and not is_typing:
		show_next_line()
