extends Node

func _ready():
	var screen_size = DisplayServer.window_get_size()
	DisplayServer.window_set_size(screen_size)
