extends Control

@onready var version_num: Label = $VersionNum
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	version_num.text = "v%s" % SceneManager.VERSION
	print(">>> You are playing DreamBold version: v%s" % SceneManager.VERSION)

func _process(_delta: float) -> void:
	input_manager()
	
func _on_start_button_pressed() -> void:
	SceneManager.swap_scenes("res://Gameplay/gameplay.tscn", get_tree().root,self, "wipe_to_right")

func _on_settings_button_pressed() -> void:
	print("Todo!")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	
func input_manager():
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func get_data(_data):
	pass

func recieve_data(_data):
	pass	
		
	
