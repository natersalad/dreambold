class_name HurtboxComponent
extends Area3D

@export var health_component: HealthComponent
@export var damage_multiplier: float = 1.0
 
signal body_part_hit(damage: int)

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Bullet") and can_accept_bullet_collision():
		hit(body)

func hit(bullet) -> void:
	print("Hit detected with bullet: ", bullet.name)
	var bullet_damage: int = int(bullet.get_damage() * damage_multiplier)
	emit_signal("body_part_hit", bullet_damage)
	print("Damage dealt: ", bullet_damage)
	if health_component:
		health_component.damage(bullet_damage)
		print("Health after damage: ", health_component.get_current_health())
	else:
		push_warning("No health component assigned to hurtbox component.")

func can_accept_bullet_collision() -> bool:
	return health_component.get_current_health() > 0 or health_component.is_invulnerable
