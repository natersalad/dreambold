extends Resource
class_name EnemyDefinition

@export var enemy_scene: PackedScene
@export var enemy_name: String = "Unnamed"
@export var enemy_description: String = "A dangerous foe"
@export var icon: Texture
@export var spawn_timer_type: String = "quick" # "quick" or "slow"
@export var enemy_type: String = "ground" # "ground" or "air"
@export var base_count: int = 0
@export var gold_value: int = 50 # Gold awarded per kill
@export var difficulty_rating: int = 1 # Used for shop wager calculations
@export var max_wager_count: int = 20 # Maximum number that can be wagered
@export var speed: float = 4.0
@export var attack_range: float = 2.5