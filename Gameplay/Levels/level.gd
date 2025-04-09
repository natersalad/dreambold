class_name Level extends Node3D

@export var data: LevelDataHandoff
@export var enemy_definitions: Array[EnemyDefinition] = []

@onready var ground_spawns = $Map/Spawns/GroundSpawns
@onready var air_spawns = $Map/Spawns/AirSpawns
@onready var navigation_region = $Map/NavigationRegion3D/Enemys
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var wave_manager = $WaveManager
@onready var ui_gold_label = $UI/GoldLabel
@onready var ui_enemies_left = $UI/EnemiesLeftLabel

var instance
var level_gold: int = 0

var last_ground_spawn_index: int = -1
var last_air_spawn_index: int = -1

func _ready() -> void:
	print("[LEVEL] Level _ready() called - starting initialization")
	print("[LEVEL] Enemy definitions count: ", enemy_definitions.size())
	# Setup wave manager
	wave_manager.initialize(enemy_definitions)
	wave_manager.connect("enemy_spawned", Callable(self, "_on_enemy_spawned"))
	wave_manager.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
	print("[LEVEL] Wave manager initialized and signals connected")
	
	# This block is here to allow us to test current scene without needing the SceneManager
	if data == null: 
		start_scene()

func start_scene() -> void:
	print("[LEVEL] Level start_scene() called - beginning wave")
	wave_manager.start_wave(1.0)  # 1 second delay before enemies start spawning
	update_ui()

func _on_enemy_spawned(enemy_def: EnemyDefinition) -> void:
	print("[LEVEL] Enemy spawn requested: " + enemy_def.enemy_name + " (Type: " + enemy_def.enemy_type + ")")
	if enemy_def.enemy_type == "ground":
		spawn_ground_enemy(enemy_def)
	else:  # air
		spawn_air_enemy(enemy_def)
	update_ui()

func _on_enemy_killed(enemy_def: EnemyDefinition) -> void:
	level_gold += enemy_def.gold_value
	update_ui()

func _on_wave_completed(gold_earned: int) -> void:
	print("[LEVEL] Wave completed! Gold earned: ", gold_earned)
	
	# Show completion UI
	$UI/WaveCompletePanel.visible = true
	$UI/WaveCompletePanel/GoldEarnedLabel.text = "Gold Earned: " + str(gold_earned)
	
	# Prepare data for next scene
	if data == null:
		data = LevelDataHandoff.new()
	data.gold_earned = gold_earned
	data.enemy_definitions = enemy_definitions
	
	# Wait a few seconds then go to shop
	var transition_timer = get_tree().create_timer(3.0)
	transition_timer.timeout.connect(func():
		# Use the SceneManager autoload to change scenes with a more robust approach
		SceneManager.swap_scenes(
		"res://Menus/Shop/shop.tscn",  # scene to load
		get_tree().root.get_node_or_null("Gameplay").get_node_or_null("HUD").get_node_or_null("CanvasLayer"),  # Find HUD node from root
		self,  # unload current scene
		"fade_to_black"  # transition type
		)
	)

func update_ui() -> void:
	if ui_gold_label:
		ui_gold_label.text = "Gold: " + str(level_gold)
	if ui_enemies_left:
		var remaining = wave_manager.total_enemies_to_spawn - wave_manager.total_enemies_killed
		ui_enemies_left.text = "Enemies: " + str(remaining)

func spawn_ground_enemy(enemy_def: EnemyDefinition) -> void:
	print("[LEVEL] Attempting to spawn ground enemy: " + enemy_def.enemy_name)
	
	if !enemy_def.enemy_scene:
		push_error(("[LEVEL] ERROR: No enemy scene assigned to definition: " + enemy_def.enemy_name))
		return

	var spawn_data = _get_different_random_child(ground_spawns, last_ground_spawn_index)
	var spawn_point = spawn_data.node.global_position
	last_ground_spawn_index = spawn_data.index

	instance = enemy_def.enemy_scene.instantiate()
	instance.position = spawn_point
	
	# Pass the enemy definition to the enemy
	if instance.has_method("set_enemy_definition"):
		instance.set_enemy_definition(enemy_def)
		print("[LEVEL] Enemy def passed to instance")
	else:
		push_error("[LEVEL] ERROR: Enemy instance does not have set_enemy_definition method")
	
	# Connect death signal
	if instance.has_node("HealthComponent"):
		instance.get_node("HealthComponent").connect("health_depleted", 
			Callable(self, "_on_enemy_health_depleted").bind(instance))
		print("[LEVEL] HealthComponent signal connected")
	else:
		push_error("[LEVEL] ERROR: Enemy instance '%s' does not have HealthComponent node" % enemy_def.enemy_name)
	navigation_region.add_child(instance)
	print("[LEVEL] Ground enemy spawned: " + enemy_def.enemy_name)

func spawn_air_enemy(enemy_def: EnemyDefinition) -> void:
	print("[LEVEL] Attempting to spawn air enemy: " + enemy_def.enemy_name)
	
	if !enemy_def.enemy_scene:
		push_error(("[LEVEL] ERROR: No enemy scene assigned to definition: " + enemy_def.enemy_name))
		return

	var spawn_data = _get_different_random_child(air_spawns, last_air_spawn_index)
	var spawn_point = spawn_data.node.global_position
	last_air_spawn_index = spawn_data.index

	instance = enemy_def.enemy_scene.instantiate()
	instance.position = spawn_point
	
	# Pass the enemy definition to the enemy
	if instance.has_method("set_enemy_definition"):
		instance.set_enemy_definition(enemy_def)
	
	# Connect death signal
	if instance.has_node("HealthComponent"):
		instance.get_node("HealthComponent").connect("health_depleted", 
			Callable(self, "_on_enemy_health_depleted").bind(instance))
	navigation_region.add_child(instance)

func _on_enemy_health_depleted(enemy_instance) -> void:
	wave_manager.on_enemy_killed(enemy_instance)

## used for selecting a random spawn for the enemies
func _get_different_random_child(parent_node, last_index: int):
	var child_count = parent_node.get_child_count()

	if child_count <= 1:
		return {"node": parent_node.get_child(0) if child_count > 0 else null, "index": 0}

	var random_id = randi() % child_count
	while random_id == last_index:
		random_id = randi() % child_count
	
	return {"node": parent_node.get_child(random_id), "index": random_id}

# for backwards compatibility
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func get_data():
	return data
	
func receive_data(_data):
	if _data is LevelDataHandoff:
		data = _data
		
		# If data has enemy definitions, update our wave
		if data.enemy_definitions.size() > 0:
			enemy_definitions = data.enemy_definitions
	else:
		push_warning("[LEVEL] Level %s is receiving data it cannot process" % name)
