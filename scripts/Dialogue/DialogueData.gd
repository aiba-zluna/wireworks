extends Resource
class_name DialogueData

# Dialogue resource for storing NPC conversations
# Create instances of this resource to define dialogues

@export var dialogue_id: String = ""
@export var npc_name: String = ""
@export var portrait_path: String = ""
@export_multiline var dialogue_lines: Array[String] = []
@export var next_dialogue_id: String = ""
@export var trigger_quest: String = ""
@export var quest_status_on_complete: String = ""

func get_portrait() -> Texture2D:
	if portrait_path.is_empty():
		return null
	
	return load(portrait_path) as Texture2D
