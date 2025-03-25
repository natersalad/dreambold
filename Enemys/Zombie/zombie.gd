extends CharacterBody3D

var state_machine
@export var health = 6

const SPEED = 4.0
const ATTACK_RANGE = 2.5

@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var mesh = $Armature/Skeleton3D/Zombie

var original_emission_color : Color

func _ready() -> void:
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	state_machine = anim_tree.get("parameters/playback")
	snap_to_ground()

	if not mesh.material_override:
		var active_mat = mesh.get_active_material(0) as StandardMaterial3D
		if active_mat:
			var dup_mat = active_mat.duplicate() as StandardMaterial3D
			mesh.material_override = dup_mat
			original_emission_color = dup_mat.emission
		else:
			original_emission_color = Color.BLACK
	else:
		original_emission_color = (mesh.material_override as StandardMaterial3D).emission
	
func _process(delta):
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Walk":
			# Navigation
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0) # for smoother rotation
		"Attack1":
			anim_tree.set("parameters/conditions/attack", _target_in_range())
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/walk", !_target_in_range())
	if state_machine.get_current_node() != "GetUp":
		move_and_slide()

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
	
func snap_to_ground():
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = global_transform.origin + Vector3.UP * 5.0
	query.to = global_transform.origin + Vector3.DOWN * 5.0
	query.exclude = [self]
	var ray_result = space_state.intersect_ray(query)
	if ray_result:
		global_transform.origin.y = ray_result.position.y
		print("Zombie snapped to ground at y =", ray_result.position.y)
	else:
		print("No ground detected!")

func flash_red() -> void:
	# Get the current material override.
	var mat = mesh.material_override as StandardMaterial3D
	if not mat:
		print("No material override found!")
		return

	# Enable emission (if not already enabled).
	mat.emission_enabled = true

	# Set the material to red
	mat.emission = Color(1, 0, 0)
	mat.emission_energy = 1.0

	# Wait for a short duration of the flash effect.
	await get_tree().create_timer(0.1).timeout

	# Restore the original emission values.
	mat.emission = original_emission_color
	mat.emission_energy = 0
	


func _on_area_3d_body_part_hit(dam: Variant) -> void:
	flash_red()
	health -= dam
	if health <= 0:
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(4.0).timeout
		queue_free()
