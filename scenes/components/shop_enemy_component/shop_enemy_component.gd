class_name ShopEnemyComponent
extends Control

signal enemy_selected(component: ShopEnemyComponent)

@export var enemy_definition: EnemyDefinition:
	set(new_def):
		enemy_definition = new_def
		if is_inside_tree():
			update_display()

var enemy_count: int = 1

@onready var icon = $EnemyIcon
@onready var count_label = $CountLabel

func _ready():
	update_display()
	$Button.pressed.connect(_on_button_pressed)

func update_display():
	if not enemy_definition:
		return
		
	# Set icon
	if enemy_definition.enemy_icon:
		icon.texture = enemy_definition.enemy_icon

	# Update count display
	count_label.text = "x" + str(enemy_count)

func set_enemy_count(count: int):
	enemy_count = count
	if is_inside_tree():
		update_display()

func _on_button_pressed():
	enemy_selected.emit(self)
