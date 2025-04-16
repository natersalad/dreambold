extends Node3D

# Simplified resource references - just need the weapon
@export var weapon_resource: WeaponResource
var current_weapon_resource: WeaponResource

# Bob and movement variables
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.008
@export var bob_rotation_amplitude: float = 0.008

# Shooting variables - these will be overridden by weapon_resource
@export var recoil_strength: float = 0.1
@export var recoil_recovery_speed: float = 10.0
@export var shoot_cooldown: float = 0.2

@export var shop_rotation_speed: float = 1.0

# Node references
@onready var blaster_mesh: MeshInstance3D = $BlasterMesh  
@onready var muzzle_point: Node3D = $MuzzlePoint
@onready var shoot_timer: Timer = Timer.new()
@onready var player_char = get_tree().get_first_node_in_group("PlayerCharacter")

# State variables
var bob_time: float = 0.0
var can_shoot: bool = true
var recoil_offset: Vector3 = Vector3.ZERO

# Starting position and rotation
var start_position: Vector3
var start_rotation: Vector3

func _ready() -> void:
	# Initialize with base weapon
	if not current_weapon_resource:
		current_weapon_resource = weapon_resource.duplicate()

	apply_current_weapon_stats()
	
	# Store the initial position and rotation
	start_position = position
	start_rotation = rotation
	
	# Setup shoot timer
	add_child(shoot_timer)
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Find player reference (only if not in shop mode)
	if not GameSettings.is_in_shop:
		call_deferred("find_player_character")

func _process(delta: float) -> void:	
	if GameSettings.is_in_shop:
		# Simple rotation for shop display
		rotate_z(shop_rotation_speed * delta)
	else:
		handle_bob(delta)
		handle_recoil(delta)
		handle_shooting()

func find_player_character() -> void:
	player_char = get_tree().get_first_node_in_group("PlayerCharacter")
	if not player_char:
		await get_tree().create_timer(0.1).timeout
		find_player_character()



func handle_bob(delta: float) -> void:
	if player_char.currentState != player_char.states.SLIDE and player_char.currentState != player_char.states.DASH:
		if player_char.velocity.length() > 0.1 and player_char.is_on_floor():
			bob_time += delta * player_char.velocity.length() * 0.5
			
			# Calculate weapon bob
			var bob_pos = Vector3.ZERO
			bob_pos.y = sin(bob_time * bob_frequency) * bob_amplitude
			bob_pos.x = cos(bob_time * bob_frequency / 2) * bob_amplitude
			
			# Calculate weapon rotation
			var bob_rot = Vector3.ZERO
			bob_rot.z = cos(bob_time * bob_frequency) * bob_rotation_amplitude
			bob_rot.x = sin(bob_time * bob_frequency / 2) * bob_rotation_amplitude
			
			# Apply smooth transition (including recoil)
			position = start_position + bob_pos + recoil_offset
			rotation = start_rotation + bob_rot
		else:
			# Return to starting position when not moving
			position = position.lerp(start_position + recoil_offset, delta * 5.0)
			rotation = rotation.lerp(start_rotation, delta * 5.0)

func handle_recoil(delta: float) -> void:
	# Gradually recover from recoil
	recoil_offset = recoil_offset.lerp(Vector3.ZERO, delta * recoil_recovery_speed)

func handle_shooting() -> void:
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func shoot() -> void:
	if not current_weapon_resource.projectile or not current_weapon_resource.projectile.projectile_scene:
		push_error("No projectile defined for this weapon.")
		return
	
	# Start cooldown
	can_shoot = false
	shoot_timer.start(shoot_cooldown)
	
	# Apply recoil
	recoil_offset = Vector3(
		0.0, # No horizontal recoil
		0.05, # Fixed upward recoil
		recoil_strength # Backward recoil
	)
	
	# Spawn projectile using the projectile from weapon_resource
	var projectile = current_weapon_resource.projectile.projectile_scene.instantiate()
	get_node("/root/Gameplay/World").add_child(projectile)
	projectile.global_transform = muzzle_point.global_transform
	
	# Apply base projectile resource properties to the instance
	if projectile.has_method("apply_resource"):
		projectile.apply_resource(current_weapon_resource.projectile)

	# TODO: Play sound effect
	# if shoot_sound:
	#     shoot_sound.play()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func change_texture(new_texture: Texture2D) -> void:
	# Get the material and update the albedo texture
	var mat = blaster_mesh.get_surface_override_material(0)
	if !mat:
		mat = blaster_mesh.get_active_material(0)
	
	if mat and mat is StandardMaterial3D:
		mat.albedo_texture = new_texture

# Update the apply_item function to permanently modify the weapon resource
func apply_item(item: ItemResource) -> WeaponResource:
	# get current state before applying
	var previous_weapon = current_weapon_resource.duplicate(true)

	apply_item_effects(current_weapon_resource, item)

	apply_current_weapon_stats()

	return previous_weapon

func apply_item_effects(weapon: WeaponResource, item: ItemResource) -> void:
	# Apply multipliers 
	weapon.fire_rate *= item.fire_rate_multiplier
	weapon.recoil_strength *= (1.0 - item.recoil_reduction) if item.has_method("get_recoil_reduction") else 1.0
	
	# Apply projectile modifications
	if weapon.projectile:
		# Multipliers
		weapon.projectile.damage *= item.damage_multiplier
		weapon.projectile.speed *= item.projectile_speed_multiplier
		
		# Additives
		weapon.projectile.damage += item.damage_additive
		weapon.projectile.speed += item.projectile_speed_additive
		
		# Special effects
		if item.adds_burn_effect:
			weapon.projectile.applies_burn = true
			weapon.projectile.burn_damage = max(weapon.projectile.burn_damage, item.burn_damage)
			weapon.projectile.burn_duration = max(weapon.projectile.burn_duration, item.burn_duration)
		
		if item.adds_freeze_effect:
			weapon.projectile.applies_freeze = true
			weapon.projectile.freeze_strength = max(weapon.projectile.freeze_strength, item.freeze_strength)
			weapon.projectile.freeze_duration = max(weapon.projectile.freeze_duration, item.freeze_duration)
		
		if item.adds_bounce:
			weapon.projectile.bounce_count = max(weapon.projectile.bounce_count, item.bounce_count)
		
		if item.adds_penetration:
			weapon.projectile.penetration_count = max(weapon.projectile.penetration_count, item.penetration_count)
		
	# Apply visual changes
	if item.weapon_texture_override:
		weapon.weapon_texture = item.weapon_texture_override
		change_texture(item.weapon_texture_override)

# Apply weapon stats from current weapon
func apply_current_weapon_stats() -> void:
	# Apply stats directly from current weapon
	shoot_cooldown = 1.0 / current_weapon_resource.fire_rate
	recoil_strength = current_weapon_resource.recoil_strength
	recoil_recovery_speed = current_weapon_resource.recoil_recovery_speed
	
	# Update texture if needed
	if current_weapon_resource.weapon_texture:
		change_texture(current_weapon_resource.weapon_texture)

# Helper function to check if this object has a given property
func has_property(prop_name: String) -> bool:
	for prop in get_property_list():
		if prop.name == prop_name:
			return true
	return false
