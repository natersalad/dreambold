extends Control

# Define constant paths for levels
const LEVEL_0_PATH: String = "res://Scenes/Level0.tscn"

# Preload the scenes
const LEVEL_0 = preload(LEVEL_0_PATH)

# Dictionary for level lookups
const LEVELS = {
	"level_0": LEVEL_0
}

# Current level node reference
var current_level: Node = null

func _ready():
	# Optionally load the first level on startup
	load_level("level_0")

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
