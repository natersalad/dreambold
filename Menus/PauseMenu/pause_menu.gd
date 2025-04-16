extends Control

func _ready() -> void:
	visible = false
	$AnimationPlayer.play("RESET")

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	visible = false
	if not GameSettings.is_in_shop:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func pause():
	visible = true
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	SceneManager.swap_scenes("res://Menus/RestartScene/restart.tscn", get_tree().root, $"../../..", "fade_to_black")


func _on_settings_pressed() -> void:
	pass # TODO


func _on_menu_pressed() -> void:
	resume()
	SceneManager.swap_scenes("res://Menus/MainMenu/menu.tscn", get_tree().root, $"../../..", "wipe_to_right")


func _on_quit_pressed() -> void:
	get_tree().quit()
