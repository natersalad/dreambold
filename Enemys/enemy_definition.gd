extends Resource
class_name EnemyDefinition

@export var enemy_scene: PackedScene
@export var enemy_name: String = "Unnamed"
@export var enemy_description: String = "A dangerous foe"
@export var enemy_icon: Texture2D
@export_range(1, 10) var min_count: int = 1
@export_range(1, 20) var max_count: int = 5
@export var spawn_timer_type: String = "quick" # "quick" or "slow"
@export var enemy_type: String = "ground" # "ground" or "air"
@export var base_count: int = 1
@export var gold_value: int = 50 # Gold awarded per kill
@export var difficulty_rating: int = 1 # Used for shop wager calculations
@export var speed: float = 4.0
@export var attack_range: float = 2.5
@export var base_health: int = 6
@export var attack_damage: int = 1
@export var attack_speed: float = 1.0
@export var attack_type: String = "melee" # "melee" or "ranged"
@export var attack_effect: String = "none" # "none", "fire", "ice", etc.

func get_min_count() -> int:
    return min_count

func get_max_count() -> int:
    return max_count
