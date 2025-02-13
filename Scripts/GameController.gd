extends Control

# Dictionary to store preloaded level scenes
var LEVELS = {}

func _init():
	# Get all level files from Scenes/Levels directory
	var dir = DirAccess.open("res://Scenes/Levels")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var level_name = file_name.get_basename().to_lower()
				var level_path = "res://Scenes/Levels/" + file_name
				LEVELS[level_name] = load(level_path)
			file_name = dir.get_next()
			
		dir.list_dir_end()

# Current level node reference
var current_level: Node = null

func _ready():
	# Optionally load the first level on startup
	load_level("level0")

func load_level(level_name: String):
	if not LEVELS.has(level_name):
		print("Level not found: " + level_name)
		return

	# Remove the current level if any
	if current_level:
		remove_child(current_level)
		current_level.queue_free()
		current_level = null

	# Instantiate and add the new level
	var new_level = LEVELS[level_name].instantiate()
	add_child(new_level)
	current_level = new_level

	print("Loaded level: " + level_name)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var curr_mode = DisplayServer.window_get_mode()
		if curr_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
	if event.is_action_pressed("quit"):
		get_tree().quit()
