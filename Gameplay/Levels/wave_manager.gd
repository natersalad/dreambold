class_name WaveManager
extends Node

signal wave_completed(total_gold_earned)
signal enemy_spawned(enemy_instance)
signal enemy_killed(enemy_def)

# Configuration
@export var quick_spawn_interval: float = 1.0
@export var slow_spawn_interval: float = 4.0

# Wave state
var enemy_definitions: Array[EnemyDefinition] = []
var total_enemies_to_spawn: int = 0
var total_enemies_spawned: int = 0
var total_enemies_killed: int = 0
var gold_earned: int = 0
var wave_in_progress: bool = false

# Internal tracking
var _remaining_counts: Dictionary = {}
var _quick_timer: Timer
var _slow_timer: Timer

func _ready() -> void:
	_setup_timers()
	start_wave(3)

func _setup_timers() -> void:
	_quick_timer = Timer.new()
	_quick_timer.wait_time = quick_spawn_interval
	_quick_timer.connect("timeout", Callable(self, "_on_quick_timer_timeout"))
	add_child(_quick_timer)
	
	_slow_timer = Timer.new()
	_slow_timer.wait_time = slow_spawn_interval
	_slow_timer.connect("timeout", Callable(self, "_on_slow_timer_timeout"))
	add_child(_slow_timer)
	

func initialize(enemy_defs: Array[EnemyDefinition]) -> void:
	print("[WAVE MANAGER] Initializing with ", enemy_defs.size(), " enemy definitions.")
	enemy_definitions = enemy_defs.duplicate()
	_setup_enemy_counts()
	total_enemies_to_spawn = _calculate_total_enemies()
	total_enemies_spawned = 0
	total_enemies_killed = 0
	gold_earned = 0
	wave_in_progress = false
	print("[WAVE MANAGER] Total enemies to spawn: ", total_enemies_to_spawn)
	for enemy in enemy_definitions:
		print("Enemy definition: " + enemy.enemy_name + 
					 ", Count: " + str(enemy.base_count) + 
					 ", Type: " + enemy.enemy_type +
					 ", Timer: " + enemy.spawn_timer_type)
					 
func start_wave(delay: float = 3.0) -> void:
	print("[WAVE MANAGER] Starting wave with delay: ", delay)
	wave_in_progress = true
	if delay > 0:
		print("[WAVE MANAGER] Creating direct timer with delay: ", delay)
		get_tree().create_timer(delay).timeout.connect(_start_wave_timers, CONNECT_ONE_SHOT)
	else:
		_start_wave_timers()

func _start_wave_timers() -> void:
	print("[WAVE MANAGER] Starting wave timers")
	_quick_timer.start()
	_slow_timer.start()

func stop_wave() -> void:
	wave_in_progress = false
	_quick_timer.stop()
	_slow_timer.stop()

func _setup_enemy_counts() -> void:
	_remaining_counts.clear()
	print("[WAVE MANAGER] Setting up enemy counts")
	for i in enemy_definitions.size():
		var enemy = enemy_definitions[i]
		# Use index as a key instead of resource_path
		_remaining_counts[i] = enemy.base_count
		print("[WAVE MANAGER] Enemy " + enemy.enemy_name + " count set to " + str(enemy.base_count))

func _calculate_total_enemies() -> int:
	var total = 0
	for enemy in enemy_definitions:
		total += enemy.base_count
	return total

func _on_quick_timer_timeout() -> void:
	print("[WAVE MANAGER] Quick timer timeout")
	var enemy_def = _get_random_enemy("quick")
	if enemy_def != null:
		print("[WAVE MANAGER] Spawning quick enemy: ", enemy_def.enemy_name)
		_spawn_enemy(enemy_def)
	
	if _are_all_enemies_spawned():
		print("[WAVE MANAGER] All enemies spawned, stopping quick timer")
		_quick_timer.stop()

func _on_slow_timer_timeout() -> void:
	print("[WAVE MANAGER] Slow timer timeout")
	var enemy_def = _get_random_enemy("slow")
	if enemy_def != null:
		print("[WAVE MANAGER] Spawning slow enemy: ", enemy_def.enemy_name)
		_spawn_enemy(enemy_def)
	
	if _are_all_enemies_spawned():
		print("[WAVE MANAGER] All enemies spawned, stopping slow timer")
		_slow_timer.stop()

func _get_random_enemy(spawn_type: String) -> EnemyDefinition:
	print("[WAVE MANAGER] Getting random enemy of type: ", spawn_type)
	var available_enemies = []
	
	for i in enemy_definitions.size():
		var enemy = enemy_definitions[i]
		if enemy.spawn_timer_type == spawn_type and _remaining_counts.has(i) and _remaining_counts[i] > 0:
			available_enemies.append({"enemy": enemy, "index": i})
			print("[WAVE MANAGER] Found available enemy: " + enemy.enemy_name)
	
	if available_enemies.size() > 0:
		var selected = available_enemies[randi() % available_enemies.size()]
		print("[WAVE MANAGER] Selected " + selected.enemy.enemy_name + " to spawn")
		return selected.enemy
	
	return null

func _spawn_enemy(enemy_def: EnemyDefinition) -> void:
	# Find the index of this enemy definition
	var index = enemy_definitions.find(enemy_def)
	if index != -1:
		_remaining_counts[index] -= 1
	
	total_enemies_spawned += 1
	emit_signal("enemy_spawned", enemy_def)
	print("[WAVE MANAGER] Spawned: ", enemy_def.enemy_name)

func on_enemy_killed(enemy_instance) -> void:
	# Find which definition this enemy belongs to
	var enemy_def = _find_enemy_definition(enemy_instance)
	if enemy_def:
		total_enemies_killed += 1
		gold_earned += enemy_def.gold_value
		emit_signal("enemy_killed", enemy_def)
		
		# Check if wave is complete
		if total_enemies_killed >= total_enemies_to_spawn:
			wave_in_progress = false
			emit_signal("wave_completed", gold_earned)
			
		# Debug
		print("[WAVE MANAGER] Killed: ", enemy_def.enemy_name, " (", total_enemies_killed, "/", total_enemies_to_spawn, ")")

func _find_enemy_definition(enemy_instance) -> EnemyDefinition:
	# This is a bit of a hack - you might want to store the definition directly on the enemy
	var scene_path = enemy_instance.scene_file_path
	
	for enemy_def in enemy_definitions:
		if enemy_def.enemy_scene and enemy_def.enemy_scene.resource_path == scene_path:
			return enemy_def
	
	return null

func _are_all_enemies_spawned() -> bool:
	return total_enemies_spawned >= total_enemies_to_spawn
