extends Control

func _ready() -> void:
	# Delay scene swap by 0.1 seconds to avoid race conditions
	await get_tree().create_timer(1).timeout
	SceneManager.swap_scenes("res://Gameplay/gameplay.tscn", get_tree().root, self, "fade_to_black")
