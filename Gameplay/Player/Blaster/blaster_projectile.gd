extends Node3D

@export var speed: float = 100.0
@export var damage: float = 1.0
@export var lifetime: float = 5.0 

@onready var ray = $RayCast3D
@onready var mesh = $Area3D
@onready var particles = $GPUParticles3D

func _ready() -> void:
	# Start lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	

func _physics_process(delta: float) -> void:
	# Move forward
	position += transform.basis.z * speed * delta
	if ray.is_colliding():
		mesh.visible = false
		particles.emitting = true
		ray.enabled = false
		if ray.get_collider().is_in_group("enemy"):
			ray.get_collider().hit(self)
		await get_tree().create_timer(1.0).timeout
		queue_free()

func get_damage() -> float:
	return damage
		
	
