extends Node

# DialogueLoader - Autoload script for managing dialogue data
# Add this as an autoload in Project Settings

# Dictionary of all dialogues by location/NPC combination
var dialogues: Dictionary = {}

func _ready():
	# Load all dialogue resources on startup
	load_all_dialogues()

# Preload all dialogue resources from a directory
func load_all_dialogues():
	var dir_path = "res://assets/dialogues/"
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		printerr("[DialogueLoader] ERROR: Could not open dialogue directory: " + dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path = dir_path + file_name
			var dialogue_resource = load(resource_path) as DialogueData
			
			if dialogue_resource:
				#print("[DialogueLoader] Loaded: " + dialogue_resource.dialogue_id)
				dialogues[dialogue_resource.dialogue_id] = dialogue_resource
			else:
				printerr("[DialogueLoader] ERROR: Not a valid DialogueData resource: " + resource_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("[DialogueLoader] Loaded " + str(dialogues.size()) + " dialogue resources")

# Get a dialogue resource by ID
func get_dialogue(dialogue_id: String) -> DialogueData:
	if dialogues.has(dialogue_id):
		return dialogues[dialogue_id]
	
	printerr("[DialogueLoader] ERROR: Dialogue not found: " + dialogue_id)
	return null

# Get dialogue based on location and NPC
func get_dialogue_for_npc(location: String, npc_id: String) -> DialogueData:
	var combined_id = location + "_" + npc_id
	
	# Try exact match first
	if dialogues.has(combined_id):
		return dialogues[combined_id]
	
	# Try partial match (dialogue IDs that start with the location_npc pattern)
	for id in dialogues.keys():
		if id.begins_with(combined_id):
			return dialogues[id]
	
	# No dialogue found
	printerr("[DialogueLoader] WARNING: No dialogue found for location: " + location + ", NPC: " + npc_id)
	return null

# Get all dialogues for a specific location
func get_dialogues_for_location(location: String) -> Array[DialogueData]:
	var result: Array[DialogueData] = []
	
	for id in dialogues.keys():
		if id.begins_with(location):
			result.append(dialogues[id])
	
	return result

# Start a dialogue by ID
func start_dialogue(dialogue_id: String, location: String = "", npc_id: String = ""):
	var dialogue = get_dialogue(dialogue_id)
	
	if dialogue:
		# Use provided location/NPC or extract from dialogue_id if not provided
		var actual_location = location
		var actual_npc = npc_id
		
		if actual_location.is_empty() or actual_npc.is_empty():
			var parts = dialogue_id.split("_", false, 1)
			if parts.size() >= 2:
				actual_location = parts[0] if actual_location.is_empty() else actual_location
				actual_npc = parts[1] if actual_npc.is_empty() else actual_npc
		
		# Start the dialogue
		DialogueManager.start_dialogue_from_resource(actual_location, actual_npc, dialogue)
	else:
		printerr("[DialogueLoader] ERROR: Cannot start dialogue, ID not found: " + dialogue_id)

# Start a dialogue for a specific NPC at a location
func start_dialogue_for_npc(location: String, npc_id: String):
	var dialogue = get_dialogue_for_npc(location, npc_id)
	
	if dialogue:
		DialogueManager.start_dialogue_from_resource(location, npc_id, dialogue)
	else:
		printerr("[DialogueLoader] ERROR: No dialogue found for location: " + location + ", NPC: " + npc_id)
