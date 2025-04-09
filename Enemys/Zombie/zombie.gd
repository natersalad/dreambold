extends CharacterBody3D

var state_machine
var speed: float = 4.0
var attack_range: float = 2.5
var enemy_definition: EnemyDefinition

@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")
@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var health = $HealthComponent

func _ready() -> void:
    look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
    state_machine = anim_tree.get("parameters/playback")
    snap_to_ground()
    
func _process(delta):
    velocity = Vector3.ZERO
    
    match state_machine.get_current_node():
        "Walk":
            # Navigation
            nav_agent.set_target_position(player.global_transform.origin)
            var next_nav_point = nav_agent.get_next_path_position()
            velocity = (next_nav_point - global_transform.origin).normalized() * speed
            rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0) # for smoother rotation
        "Attack1":
            anim_tree.set("parameters/conditions/attack", _target_in_range())
            look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
        
    anim_tree.set("parameters/conditions/attack", _target_in_range())
    anim_tree.set("parameters/conditions/walk", !_target_in_range())
    if state_machine.get_current_node() != "GetUp":
        move_and_slide()

func _target_in_range():
    return global_position.distance_to(player.global_position) < attack_range
    
func _hit_finished():
    if global_position.distance_to(player.global_position) < attack_range + 1.0:
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
    else:
        push_error("ERROR: No ground detected to spawn enemy!")

func _on_health_component_health_depleted() -> void:
    anim_tree.set("parameters/conditions/die", true)
    await get_tree().create_timer(4.0).timeout
    queue_free()

# Set the enemy definition and apply its properties
func set_enemy_definition(def: EnemyDefinition) -> void:
    enemy_definition = def
    if enemy_definition:
        speed = enemy_definition.speed
        attack_range = enemy_definition.attack_range
