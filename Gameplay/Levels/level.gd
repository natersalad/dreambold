class_name Level extends Node3D

@export var data:LevelDataHandoff

@onready var spawns = $Map/Spawns
@onready var navigation_region = $Map/NavigationRegion3D/Enemys
@onready var player = get_tree().get_first_node_in_group("PlayerCharacter")

var zombie = load("res://Enemys/Zombie/zombie.tscn")
var instance

func _ready() -> void:
	player.disable()
	# This block is here to allow us to test current scene without needing the SceneManager to call these :) 
	if data == null: 
		start_scene()

## When a class implements this, SceneManager.on_content_finished_loading will invoke it
## to receive this data and pass it to the next scene
func get_data():
	return data
	
## 1) emitted at the beginning of SceneManager.on_content_finished_loading
## When a class implements this, SceneManager.on_content_finished_loading will invoke it
## to insert data received from the previous scene into this one	
func receive_data(_data):
	# implementing class should do some basic checks to make sure it only acts on data it's prepared to accept
	# if previous scene sends data this scene doesn't need, simple logic as follows ensures no crash occurs
	# act only on the data you want to receive and process :) 
	if _data is LevelDataHandoff:
		data = _data
		# process data here if need be, for this we just need to receive it but only if it's of the correct data type
	else:
		# SceneManager is designed to allow data mismatches like this occur, because you wno't always know
		# which scene precedes or follows another. For example, this sample project passes data between
		# levels but not between a level and the start screen, or vice versa. But it's possible Start screen might
		# look for data from a different scene. So both incoming and outgoing scenes might implement get/receive_data
		# but you may not always want to process that data. This is way more explanation than you need for something
		# that's pretty much designed to work this way and fail silently when not in use :D
		push_warning("Level %s is receiving data it cannot process" % name)

## emitted at the very end of SceneManager.on_content_finished_loading, after the transition has completed
## 3) Here I'm using it to return control to the user because everything is ready to go
func start_scene() -> void:
	player.enable()
	
	
## used for selecting a random spawn for the enemies
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)


func _on_zombie_spawner_time_timeout() -> void:
	var spawn_point = _get_random_child(spawns).global_position
	instance = zombie.instantiate()
	instance.position = spawn_point
	navigation_region.add_child(instance)
