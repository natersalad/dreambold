extends Area3D

@export var speed: float = 50.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0  # Bullet will disappear after 5 seconds

func _ready() -> void:
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	# Start lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Move forward
	position += transform.basis.z * speed * delta

func _on_body_entered(_body: Node3D) -> void:
	# Create explosion effect
	create_explosion()
	# Queue free the projectile immediately
	queue_free()

func create_explosion() -> void:
	# Create a temporary light flash
	var flash = OmniLight3D.new()
	get_tree().root.add_child(flash)
	flash.position = global_position
	flash.light_color = Color(1, 0.5, 0, 1)
	flash.light_energy = 3.0
	
	# Create tween for light fadeout
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)
