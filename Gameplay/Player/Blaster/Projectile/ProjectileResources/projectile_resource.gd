class_name ProjectileResource
extends Resource

@export var projectile_scene: PackedScene
@export var damage: float = 10.0
@export var speed: float = 20.0
@export var lifetime: float = 5.0

# Status effect properties
@export var applies_burn: bool = false
@export var burn_damage: float = 0.0
@export var burn_duration: float = 0.0

@export var applies_freeze: bool = false
@export var freeze_strength: float = 0.0
@export var freeze_duration: float = 0.0

# Advanced projectile properties (for items to modify)
@export var bounce_count: int = 0
@export var penetration_count: int = 0