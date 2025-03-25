extends MeshInstance3D

# Bob and movement variables
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.008
@export var bob_rotation_amplitude: float = 0.008

# Shooting variables
@export var recoil_strength: float = 0.1
@export var recoil_recovery_speed: float = 10.0
@export var shoot_cooldown: float = 0.2
@export var projectile_scene: PackedScene

# Temp Blaster Texures
@export var original_texture = load("res://temp/img/blaster_texture_2.png")
@export var ai_texture = load("res://temp/img/blaster_texture_1.png")

# Node references
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
	change_texture(2)

	# Store the initial position and rotation
	start_position = position
	start_rotation = rotation
	
	# Setup shoot timer
	add_child(shoot_timer)
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Configure muzzle flash light

func _process(delta: float) -> void:
	handle_bob(delta)
	handle_recoil(delta)
	handle_shooting()

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
	# Start cooldown
	can_shoot = false
	shoot_timer.start(shoot_cooldown)
	
	# Apply recoil
	recoil_offset = Vector3(
		0.0, # No horizontal recoil
		0.05, # Fixed upward recoil
		recoil_strength # Backward recoil
	)
	# Spawn projectile
	var projectile = projectile_scene.instantiate()
	# Add projectile to the World node instead of the root
	get_node("/root/Gameplay/World").add_child(projectile)
	projectile.global_transform = muzzle_point.global_transform
	
	# Optional: Add initial impulse in the shooting direction
	if projectile is RigidBody3D:
		projectile.apply_central_impulse(-muzzle_point.global_transform.basis.z * 20.0)
	
	# TODO: Play sound effect
	# if shoot_sound:
	#     shoot_sound.play()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true


# Texture Changing code, this is for testing purposes right now
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("texture1"):
		change_texture(1)
	elif event.is_action_pressed("texture2"):
		change_texture(2)

func change_texture(index: int) -> void:
	var new_texture: Texture2D

	if index == 1:
		new_texture = original_texture
		print("Loaded texture: blaster_texture_1.png")
	elif index == 2:
		new_texture = ai_texture
		print("Loaded texture: blaster_texture_2.png")
	else:
		push_error("Invalid texture index: ", index)
		return

	# Get the material and update the albedo texture
	var mat = get_surface_override_material(0)
	if !mat:
		mat = get_active_material(0)
	
	if mat and mat is StandardMaterial3D:
		mat.albedo_texture = new_texture
		print("Weapon texture changed to blaster_texture_%s" % str(index))
	else:
		print("Could not find StandardMaterial3D on BlasterMesh")
