extends Node3D

# Base properties - these will be overridden by the resource
var speed: float = 100.0
var damage: float = 1.0
var lifetime: float = 5.0

# Status effect properties
var applies_burn: bool = false
var burn_damage: float = 0.0
var burn_duration: float = 0.0

var applies_freeze: bool = false
var freeze_strength: float = 0.0
var freeze_duration: float = 0.0

# Advanced properties
var bounce_count: int = 0
var bounces_remaining: int = 0
var penetration_count: int = 0
var penetrations_remaining: int = 0

# Store hit targets to avoid hitting the same enemy multiple times with penetration
var hit_targets: Array = []

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
	
	# Check collision
	if ray.is_colliding():
		var collider = ray.get_collider()
		
		# Handle enemy hit
		if collider.is_in_group("enemy") and not hit_targets.has(collider):
			hit_targets.append(collider)
			collider.hit(self)
			
			# Apply status effects
			apply_status_effects(collider)
			
			# Handle penetration
			if penetrations_remaining > 0:
				penetrations_remaining -= 1
				# Continue moving, don't destroy projectile
				return
		
		# Handle bounce
		elif bounces_remaining > 0 and not collider.is_in_group("enemy"):
			bounces_remaining -= 1
			
			# Calculate reflection direction
			var normal = ray.get_collision_normal()
			var reflection = transform.basis.z.reflect(normal)
			
			# Set new direction
			look_at(global_position + reflection, Vector3.UP)
			
			# Small visual effect for bounce
			var bounce_particles = particles.duplicate()
			add_child(bounce_particles)
			bounce_particles.global_position = ray.get_collision_point()
			bounce_particles.emitting = true
			bounce_particles.one_shot = true
			
			# Remove after effect completes
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func(): bounce_particles.queue_free())
			
			return
			
		# Destroy projectile
		mesh.visible = false
		particles.emitting = true
		ray.enabled = false
		
		await get_tree().create_timer(1.0).timeout
		queue_free()

# Apply a ProjectileResource to this projectile
func apply_resource(resource: ProjectileResource) -> void:
	if not resource:
		push_error("Null ProjectileResource passed to projectile")
		return
		
	# Basic properties
	speed = resource.speed
	damage = resource.damage
	lifetime = resource.lifetime
	
	# Status effects
	applies_burn = resource.applies_burn
	burn_damage = resource.burn_damage
	burn_duration = resource.burn_duration
	
	applies_freeze = resource.applies_freeze
	freeze_strength = resource.freeze_strength
	freeze_duration = resource.freeze_duration
	
	# Advanced properties
	bounce_count = resource.bounce_count
	bounces_remaining = resource.bounce_count
	penetration_count = resource.penetration_count
	penetrations_remaining = resource.penetration_count
	
	print("[PROJECTILE] Applied resource - Speed: ", speed, " Damage: ", damage)

# Apply status effects to the target
func apply_status_effects(target) -> void:
	# Apply burn effect
	if applies_burn and target.has_method("apply_burn"):
		target.apply_burn(burn_damage, burn_duration)
	
	# Apply freeze effect
	if applies_freeze and target.has_method("apply_freeze"):
		target.apply_freeze(freeze_strength, freeze_duration)

func get_damage() -> float:
	return damage
