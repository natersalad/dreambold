extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_pressed() -> void:
	SceneManager.swap_scenes("res://Gameplay/gameplay.tscn", get_tree().root,self, "fade_to_white")
