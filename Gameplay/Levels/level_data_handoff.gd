extends Resource
class_name LevelDataHandoff

@export var gold_earned: int = 0
@export var gold_available: int = 0
@export var enemy_definitions: Array[EnemyDefinition] = []
@export var round_number: int = 1
@export var base_weapon: WeaponResource  # Store the base weapon stats
@export var collected_items: Array[ItemResource] = [] # Store the list of items
@export var current_weapon: WeaponResource  # Store the current weapon stats
