extends CharacterBody3D


const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.002
var normal_acceleration = 20.0
var friction = 10.0

# dash in a "thrusting" style
var dash_acceleration = 60.0
var dash_time = 0.2
var dash_timer = 0.0
var is_dashing = false
var dash_direction = Vector3.ZERO

# head bobbing variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
const GRAVITY = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle Dash.
	if is_dashing:
		# continue dashing for the DASH_TIME duration
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		if Input.is_action_just_pressed("dash") and direction != Vector3.ZERO:
			is_dashing = true
			dash_timer = dash_time
			dash_direction = direction
	
	# Regular acceleration 
	if direction != Vector3.ZERO:
		velocity += direction * normal_acceleration * delta
	else:
		# No input => apply friction to gradually stop horizontally
		var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
		horizontal_vel = horizontal_vel.move_toward(Vector3.ZERO, friction * delta)
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.z
		
		
	# Head Bobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	
