extends Control

const MAX_ENEMY_COMPONENTS = 12

# References to nodes
@onready var blaster = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/SubViewportContainer/SubViewport/Blaster
@onready var stats_display = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/RichTextLabel
@onready var item_container = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/ItemContainer
@onready var currency_label = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/CurrencyLabel
@onready var enemey_grid = $BorderColor/MarginContainer/CenterColor/HBoxContainer/RightEnemys/VBoxContainer/EnemyGrid
@onready var raise_prize_button = $BorderColor/MarginContainer/CenterColor/HBoxContainer/RightEnemys/VBoxContainer/ButtonContainer/RaisePrizeButton
@onready var round_label = $BorderColor/MarginContainer/CenterColor/HBoxContainer/RightEnemys/VBoxContainer/TitleLabel
@onready var total_prize_label = $BorderColor/MarginContainer/CenterColor/HBoxContainer/RightEnemys/VBoxContainer/TotalPrizeText


# Resource for testing/default
@export var available_items: Array[ItemResource] = []
@export var enemy_library: EnemyLibrary

# Currency tracking
var current_gold: int = 0
var selected_item: ItemResource = null
var enemy_components: Array[ShopEnemyComponent] = []
var selected_enemy_component: ShopEnemyComponent = null
var current_enemy_defs: Array[EnemyDefinition] = []

# Level data handoff reference
var level_data: LevelDataHandoff

func _ready():
	GameSettings.enter_shop()

	# Update the currency label
	update_shop_currency()

	# Update the round label
	update_round_label()

	# Set up the blaster for shop mode
	setup_blaster()
	
	# Display projectile stats
	update_stats_display()
	
	# Setup item components
	setup_items()

	setup_enemy_grid()

	# Connect fight button
	var fight_button = $BorderColor/MarginContainer/CenterColor/HBoxContainer/RightEnemys/VBoxContainer/ButtonContainer/FightButton
	fight_button.pressed.connect(_on_exit_button_pressed)

	raise_prize_button.pressed.connect(_on_raise_prize_button_pressed)

func update_shop_currency():
	# Update the currency label with the current gold amount
	if currency_label != null:
		currency_label.text = "GOLD: %d" % current_gold

func update_round_label():
	# Update the round label with the current round number
	if round_label != null:
		round_label.text = "ROUND No. %d" % level_data.round_number

func setup_blaster():
	# initialize the blaster with the level data if available
	if level_data:
		if level_data.current_weapon:
			blaster.weapon_resource = level_data.base_weapon.duplicate()
			blaster.current_weapon_resource = level_data.current_weapon.duplicate()
		else:
			blaster.weapon_resource = level_data.base_weapon.duplicate()
			blaster.current_weapon_resource = level_data.base_weapon.duplicate()
		
		for item in level_data.collected_items:
			blaster.apply_item_effects(blaster.current_weapon_resource, item)

		# apply the final stats
		blaster.apply_current_weapon_stats()
		

	# Make the blaster's material unshaded
	var mesh = blaster.get_node("BlasterMesh")
	if mesh:
		var blaster_material = mesh.get_surface_override_material(0)
		if not blaster_material:
			blaster_material = mesh.get_active_material(0)
		
		if blaster_material and blaster_material is StandardMaterial3D:
			blaster_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED

# Helper function to format stat display with changes
func format_stat_change(stat_name: String, current_value: float, modified_value: float, preview_item: bool, decimal_precision: int = 1) -> String:
	var text = stat_name + ": " + str(current_value)
	
	if preview_item:
		var diff = modified_value - current_value
		var color = "green" if diff > 0 else "red"
		text += " [color=%s]%s%s[/color] ► %.*f\n" % [
			color,
			"+" if diff > 0 else "",
			str(diff),
			decimal_precision,
			modified_value
		]
	else:
		text += "\n"
	
	return text

func setup_items():
	# Get references to existing item components
	var component1 = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/ItemContainer/ItemComponent
	var component2 = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/ItemContainer/ItemComponent2
	var component3 = $BorderColor/MarginContainer/CenterColor/HBoxContainer/LeftShop/ItemContainer/ItemComponent3
	
	# Array of components for easier iteration
	var components = [component1, component2, component3]
	
	# Assign resources to each component
	for i in range(min(components.size(), available_items.size())):
		# Set the item resource
		components[i].item_resource = available_items[i]
		
		# Connect signals (first disconnect to prevent duplicates)
		if components[i].is_connected("item_selected", _on_item_selected):
			components[i].disconnect("item_selected", _on_item_selected)
		if components[i].is_connected("item_deselected", _on_item_deselected):
			components[i].disconnect("item_deselected", _on_item_deselected)
		if components[i].is_connected("item_purchased", _on_item_purchased):
			components[i].disconnect("item_purchased", _on_item_purchased)
			
		# Connect new 
		components[i].item_deselected.connect(_on_item_deselected)
		components[i].item_selected.connect(_on_item_selected)
		components[i].item_purchased.connect(func(item): _on_item_purchased(item, components[i]))
		
		# Make sure it's visible
		components[i].visible = true
	
	# Hide any unused components
	for i in range(available_items.size(), components.size()):
		components[i].visible = false

func _on_item_deselected(item: ItemResource):
	if selected_item == item:
		selected_item = null
		update_stats_display()


func _on_item_selected(item: ItemResource):
	if selected_item == item:
		selected_item = null
		update_stats_display()
	else:
		selected_item = item
		update_stats_display(item)

func _on_item_purchased(item: ItemResource, sender_component: ItemComponent):
	# Check if player has enough gold
	if current_gold >= item.cost:
		# save original weapon stats for comparision
		var original_weapon : WeaponResource = blaster.apply_item(item)

		# Subtract the cost from current_gold
		current_gold -= item.cost
		
		# Update the currency display
		update_shop_currency()
		
		# Update level data for persistence
		if level_data:
			level_data.gold_available = current_gold
			level_data.collected_items.append(item)

		show_item_purchased_message(item, original_weapon)

		# Update stats to reflect the new item
		update_stats_display()

		sender_component.purchase_succeeded()

		print("[SHOP] Purchased item: ", item.item_name, " for ", item.cost, " gold.")
		#DebugUtils.print_weapon_resource(blaster.weapon_resource)
		#DebugUtils.print_level_data(level_data, "LEVEL DATA AFTER PURCHASE")
		#DebugUtils.print_game_state(level_data)
	else:
		# Player doesn't have enough gold
		print("[SHOP] Not enough gold to purchase ", item.item_name)
		sender_component.purchase_failed()
		show_insufficient_funds_message()
	
# Fix the incomplete show_item function that's causing an error
func show_item_purchased_message(item: ItemResource, original_weapon: WeaponResource):
	var message = RichTextLabel.new()
	message.bbcode_enabled = true
	
	# Get weapon/projectile resources
	var new_projectile = blaster.current_weapon_resource.projectile
	var old_projectile = original_weapon.projectile
	
	# Format the message with item name and changes
	var text = "[center][b]Item Purchased![/b]\n"
	text += "[color=%s]%s[/color][/center]\n\n" % [get_rarity_color_from_enum(item.rarity), item.item_name]
	
	# Show stat changes
	text += "[b]Stat Changes:[/b]\n"
	
	# Damage comparison
	var old_damage = old_projectile.damage
	var new_damage = new_projectile.damage
	text += "Damage: %.1f → %.1f %s\n" % [
		old_damage, 
		new_damage,
		get_change_indicator(new_damage - old_damage)
	]
	
	# Speed comparison
	var old_speed = old_projectile.speed
	var new_speed = new_projectile.speed
	text += "Speed: %.1f → %.1f %s\n" % [
		old_speed, 
		new_speed,
		get_change_indicator(new_speed - old_speed)
	]
	
	# Fire rate comparison
	var old_fire_rate = original_weapon.fire_rate
	var new_fire_rate = blaster.weapon_resource.fire_rate
	text += "Fire Rate: %.2f → %.2f %s\n" % [
		old_fire_rate, 
		new_fire_rate,
		get_change_indicator(new_fire_rate - old_fire_rate)
	]
	
	# Special effects added
	var new_effects = []
	if item.adds_burn_effect and !old_projectile.applies_burn:
		new_effects.append("[color=orange]• Burn effect[/color]")
	if item.adds_freeze_effect and !old_projectile.applies_freeze:
		new_effects.append("[color=cyan]• Freeze effect[/color]")
	if item.adds_bounce and old_projectile.bounce_count == 0:
		new_effects.append("• Bounce")
	if item.adds_penetration and old_projectile.penetration_count == 0:
		new_effects.append("• Penetration")
	
	if new_effects.size() > 0:
		text += "\n[b]New Effects Added:[/b]\n"
		for effect in new_effects:
			text += effect + "\n"
	
	# Configure and display message
	message.text = text
	message.size = Vector2(300, 200)
	var viewport_size = get_viewport_rect().size
	message.position = (viewport_size / 2) - (message.size / 2)  # Center on screen
	add_child(message)
	
	# Fade out after delay
	var tween = create_tween()
	tween.tween_interval(4.0)  # Show for 2 seconds
	tween.tween_property(message, "modulate", Color(1,1,1,0), 1.0)
	tween.tween_callback(message.queue_free)

# Helper function to get change indicators
func get_change_indicator(change: float) -> String:
	if change > 0:
		return "[color=green](+%.2f)[/color]" % change
	elif change < 0:
		return "[color=red](%.2f)[/color]" % change
	else:
		return ""

func update_stats_display(preview_item: ItemResource = null):
	var projectile_resource = blaster.current_weapon_resource.projectile
	
	if not projectile_resource:
		stats_display.text = "No projectile data available"
		return
	
	var stats_text = "[b][color=white]%s[/color][/b]\n" % [
		blaster.weapon_resource.weapon_name if blaster.weapon_resource else "Unknown Weapon"
	]
	
	# Show equipped items count
	var equipped_items_count = level_data.collected_items.size() if level_data else 0
	stats_text += "[color=yellow]Equipped Items: %d[/color]\n" % equipped_items_count
	
	stats_text += "\n[b]Current Stats:[/b]\n"
	
	# Current stats
	var current_damage = projectile_resource.damage
	var current_speed = projectile_resource.speed
	var current_fire_rate = blaster.weapon_resource.fire_rate
	
	# Display current stats (these are already with all items applied)
	stats_text += "Damage: %.1f\n" % current_damage
	stats_text += "Speed: %.1f\n" % current_speed
	stats_text += "Fire Rate: %.2f\n" % current_fire_rate
	
	# Add special effects section
	if projectile_resource.applies_burn or projectile_resource.applies_freeze or projectile_resource.bounce_count > 0 or projectile_resource.penetration_count > 0:
		
		stats_text += "\n[b]Current Effects:[/b]\n"
		
		if projectile_resource.applies_burn:
			stats_text += "• [color=orange]Burn:[/color] %.1f damage for %.1f sec\n" % [
				projectile_resource.burn_damage, 
				projectile_resource.burn_duration
			]
			
		if projectile_resource.applies_freeze:
			stats_text += "• [color=cyan]Freeze:[/color] %.1f strength for %.1f sec\n" % [
				projectile_resource.freeze_strength,
				projectile_resource.freeze_duration
			]
			
		if projectile_resource.bounce_count > 0:
			stats_text += "• Bounces: %d times\n" % projectile_resource.bounce_count
			
		if projectile_resource.penetration_count > 0:
			stats_text += "• Penetrates: %d enemies\n" % projectile_resource.penetration_count
	
	# If an item is selected, show its preview effects
	if preview_item:
		stats_text += "\n[b][color=yellow]If Purchased:[/color][/b]\n"
		
		# Calculate modified stats for preview
		var modified_damage = current_damage * preview_item.damage_multiplier + preview_item.damage_additive
		var modified_speed = current_speed * preview_item.projectile_speed_multiplier + preview_item.projectile_speed_additive
		var modified_fire_rate = current_fire_rate * preview_item.fire_rate_multiplier + preview_item.fire_rate_additive
		
		# Display stat changes
		stats_text += format_stat_change("Damage", current_damage, modified_damage, true)
		stats_text += format_stat_change("Speed", current_speed, modified_speed, true)
		stats_text += format_stat_change("Fire Rate", current_fire_rate, modified_fire_rate, true, 2)
		
		# New effects that would be added
		var new_effects = []
		
		if preview_item.adds_burn_effect and not projectile_resource.applies_burn:
			new_effects.append("[color=orange]• Burn:[/color] %.1f damage for %.1f sec" % [
				preview_item.burn_damage, 
				preview_item.burn_duration
			])
		
		if preview_item.adds_freeze_effect and not projectile_resource.applies_freeze:
			new_effects.append("[color=cyan]• Freeze:[/color] %.1f strength for %.1f sec" % [
				preview_item.freeze_strength,
				preview_item.freeze_duration
			])
			
		if preview_item.adds_bounce and projectile_resource.bounce_count == 0:
			new_effects.append("• Bounces: %d times" % preview_item.bounce_count)
			
		if preview_item.adds_penetration and projectile_resource.penetration_count == 0:
			new_effects.append("• Penetrates: %d enemies" % preview_item.penetration_count)
		
		if new_effects.size() > 0:
			stats_text += "\n[b][color=green]New Effects:[/color][/b]\n"
			for effect in new_effects:
				stats_text += effect + "\n"
		
		# Preview item cost
		stats_text += "\n[b]Selected Item:[/b] %s\n" % preview_item.item_name
		stats_text += "[b]Cost:[/b] [color=%s]%d Gold[/color]" % [
			"green" if current_gold >= preview_item.cost else "red",
			preview_item.cost
		]		

	stats_display.text = stats_text

func show_insufficient_funds_message():
	var message = Label.new()
	message.text = "Insufficient funds!"
	message.add_theme_color_override("font_color", Color(1, 0, 0))
	message.position = Vector2(0, 0)  
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(message)
	
	# Create a fade-out animation
	var tween = create_tween()
	tween.tween_property(message, "modulate", Color(1,1,1,0), 1.5)
	tween.tween_callback(message.queue_free)

func display_item_info(item: ItemResource):
	var item_info = ""
	
	# Item name with rarity color
	var rarity_color = get_rarity_color_from_enum(item.rarity)
	item_info += "[b][color=%s]%s[/color][/b]\n" % [rarity_color, item.item_name]
	
	# Description
	item_info += "%s\n\n" % item.description
	
	# Stat modifications
	item_info += "[b]Stat Modifiers:[/b]\n"
	
	if item.damage_multiplier != 1.0:
		var color = "green" if item.damage_multiplier > 1.0 else "red"
		item_info += "[color=%s]Damage: %d%%[/color]\n" % [color, item.damage_multiplier * 100]
	
	if item.fire_rate_multiplier != 1.0:
		var color = "green" if item.fire_rate_multiplier > 1.0 else "red"
		item_info += "[color=%s]Fire Rate: %d%%[/color]\n" % [color, item.fire_rate_multiplier * 100]
	
	if item.projectile_speed_multiplier != 1.0:
		var color = "green" if item.projectile_speed_multiplier > 1.0 else "red"
		item_info += "[color=%s]Projectile Speed: %d%%[/color]\n" % [color, item.projectile_speed_multiplier * 100]
	
	# Special effects
	var has_effects = false
	if item.adds_burn_effect or item.adds_freeze_effect or item.adds_bounce or item.adds_penetration:
		has_effects = true
		item_info += "\n[b]Special Effects:[/b]\n"
		
		if item.adds_burn_effect:
			item_info += "[color=orange]• Adds Burn: %s damage for %s sec[/color]\n" % [
				str(item.burn_damage), 
				str(item.burn_duration)
			]
			
		if item.adds_freeze_effect:
			item_info += "[color=cyan]• Adds Freeze: %s strength for %s sec[/color]\n" % [
				str(item.freeze_strength),
				str(item.freeze_duration)
			]
			
		if item.adds_bounce:
			item_info += "• Bounces: %d times\n" % item.bounce_count
			
		if item.adds_penetration:
			item_info += "• Penetrates: %d enemies\n" % item.penetration_count
	
	# Add cost information
	item_info += "\n[b]Cost:[/b] [color=%s]%d Gold[/color]" % [
		"green" if current_gold >= item.cost else "red",
		item.cost
	]
	
	# Update the RichTextLabel
	stats_display.text = item_info

# update the total prize
func update_total_prize():
	var total_prize = 0
	for component in enemy_components:
		total_prize += component.enemy_definition.gold_value * component.enemy_count
	
	if total_prize_label:
		total_prize_label.bbcode_enabled = true
		total_prize_label.text = "[center]Total Prize: [color=yellow]" + str(total_prize) + " Gold[/color][/center]"

# enemy wagering code
func setup_enemy_grid():
	# clear exisiting components
	for component in enemy_components:
		component.queue_free()
	enemy_components.clear()
	current_enemy_defs.clear()

	var num_enemies = randi_range(1, 4)

	for i in range(num_enemies):
		add_random_enemy_to_grid()

	update_raise_prize_button_state()
	update_total_prize()

func add_random_enemy_to_grid():
	# get random enemy from available enemies
	if not enemy_library or enemy_library.available_enemies.size() == 0:
		push_error("[SHOP] No enemies available in the library.")
		return
	
	var enemy_def = enemy_library.get_random_enemy()

	var min_count = enemy_def.min_count if enemy_def.has_method("get_min_count") else 1
	var max_count = enemy_def.max_count if enemy_def.has_method("get_max_count") else 5
	var count = randi_range(min_count, max_count)

	# create component
	var enemy_component = preload("res://scenes/components/shop_enemy_component/ShopEnemyComponent.tscn").instantiate()
	enemy_component.enemy_definition = enemy_def
	enemy_component.set_enemy_count(count)

	# connect signal
	enemy_component.enemy_selected.connect(_on_enemy_selected)
	
	# add to grid and array
	enemey_grid.add_child(enemy_component)
	enemy_components.append(enemy_component)

func _on_enemy_selected(component: ShopEnemyComponent):
	# handle enemy selection (show details)
	if selected_enemy_component == component:
		selected_enemy_component = null
		#clear selection display
	else:
		selected_enemy_component = component
		display_enemy_info(component.enemy_definition, component.enemy_count)

func display_enemy_info(def: EnemyDefinition, count: int):
	# Display info about the enemy in stats_display
	var info_text = "[b]%s[/b] (x%d)\n" % [def.enemy_name, count]
	info_text += "[i]%s[/i]\n\n" % def.enemy_description
	
	info_text += "[b]Base Stats:[/b]\n"
	info_text += "Type: %s\n" % def.enemy_type
	info_text += "Health: %.1f\n" % def.base_health
	info_text += "Speed: %.1f\n" % def.speed
	info_text += "Difficulty: %d★\n\n" % def.difficulty_rating
	
	info_text += "[b]Combat:[/b]\n" 
	info_text += "Attack Type: %s\n" % def.attack_type.capitalize()
	info_text += "Damage: %d\n" % def.attack_damage
	info_text += "Attack Speed: %.1f\n" % def.attack_speed
	info_text += "Attack Range: %.1f\n" % def.attack_range
	
	if def.attack_effect != "none":
		info_text += "Effect: %s\n" % def.attack_effect.capitalize()
	
	info_text += "\n[b]Reward:[/b]\n"
	info_text += "Gold Value: %d each\n" % def.gold_value
	info_text += "Total Gold: [color=yellow]%d[/color]" % (def.gold_value * count)

	stats_display.text = info_text
	
func _on_raise_prize_button_pressed():
	if enemy_components.size() >= MAX_ENEMY_COMPONENTS:
		show_max_enemies_reached_message()
		return
	
	var max_to_add = MAX_ENEMY_COMPONENTS - enemy_components.size()
	var additional_enemies = min(randi_range(1, 4), max_to_add)

	for i in range(additional_enemies):
		add_random_enemy_to_grid()

	update_raise_prize_button_state()
	update_total_prize()

func update_raise_prize_button_state():
	# disable button if at or over limit
	var limit_reached : bool = enemy_components.size() >= MAX_ENEMY_COMPONENTS
	if limit_reached:
		show_max_enemies_reached_message()

	raise_prize_button.disabled = limit_reached

	if raise_prize_button.disabled:
		raise_prize_button.modulate = Color(0.5, 0.5, 0.5)  # Grey out the button
	else:
		raise_prize_button.modulate = Color(1, 1, 1)  # Reset to normal color

func show_max_enemies_reached_message():
	var message = Label.new()
	message.text = "Very bold of you... Maximum enemies reached!"
	message.add_theme_color_override("font_color", Color(1, 0.5, 0))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add to scene before setting position so size is calculated
	add_child(message)
	
	# Get viewport size and calculate center position
	var viewport_size = get_viewport_rect().size
	
	# Force the label to update its size
	message.size = Vector2.ZERO
	await get_tree().process_frame
	
	# Center the label on screen
	message.global_position = Vector2(
		viewport_size.x / 2 - message.size.x / 2,
		viewport_size.y / 2 - message.size.y / 2
	)
	
	# Create a fade-out animation
	var tween = create_tween()
	tween.tween_property(message, "modulate", Color(1,1,1,0), 4)
	tween.tween_callback(message.queue_free)


# Helper function to get color from rarity enum
func get_rarity_color_from_enum(rarity_value: int) -> String:
	match rarity_value:
		0: # COMMON
			return "white"
		1: # UNCOMMON
			return "green"
		2: # RARE
			return "blue"
		3: # EPIC
			return "purple"
		4: # LEGENDARY
			return "orange"
	return "white"

# Called when the exit button is pressed
func _on_exit_button_pressed():		
	if level_data:
		level_data.current_weapon = blaster.current_weapon_resource.duplicate()

		# create a new array for the next level's enemy defs
		var next_level_enemies : Array[EnemyDefinition] = []

		# add all selected enemies to the array based on their counts
		for component in enemy_components:
			var enemy_def = component.enemy_definition
			var count = component.enemy_count

			# add this enemey
			var enemy_for_level = enemy_def.duplicate()
			enemy_for_level.base_count = count

			next_level_enemies.append(enemy_for_level)
		
		level_data.enemy_definitions = next_level_enemies

		
	SceneManager.swap_scenes(
		"res://Gameplay/Levels/Level1.tscn",  # scene to load
		get_tree().root.get_node_or_null("Gameplay").get_node_or_null("World"),  # Find HUD node from root
		get_tree().root.get_node_or_null("Gameplay").get_node_or_null("Shop"),  # unload current scene
		"fade_to_white"  # transition type
	)

# Get data to pass to next scene
func get_data():
	return level_data
	
func receive_data(data):
	print("[SHOP] Received data from Level: ", data)
	#DebugUtils.print_level_data(data)
	if data is LevelDataHandoff:
		level_data = data
		current_gold = level_data.gold_available
	else:
		push_error("[SHOP] ERROR: Received data is not of type LevelDataHandoff")
