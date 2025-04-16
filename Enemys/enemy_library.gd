class_name EnemyLibrary
extends Resource

# Collection of all available enemy types
@export var available_enemies: Array[EnemyDefinition] = []

# Get a random enemy definition from the library
func get_random_enemy() -> EnemyDefinition:
	if available_enemies.size() == 0:
		return null
	
	var rand_index = randi() % available_enemies.size()
	return available_enemies[rand_index].duplicate()
