extends Node

# Debug print for LevelDataHandoff
func print_level_data(data: LevelDataHandoff, title: String = "LEVEL DATA") -> String:
	var text = "\n===== %s =====\n" % title
	text += "Round: %d\n" % data.round_number
	text += "Gold Earned: %d\n" % data.gold_earned
	text += "Gold Available: %d\n" % data.gold_available
	
	# Print enemy definitions summary
	text += "Enemy Definitions: %d total\n" % data.enemy_definitions.size()
	for i in range(data.enemy_definitions.size()):
		var enemy = data.enemy_definitions[i]
		text += "  - Enemy %d: %s (%s)\n" % [i, enemy.enemy_name, enemy.enemy_type]
	
	# Print collected items
	text += "\nCollected Items: %d total\n" % data.collected_items.size()
	for i in range(data.collected_items.size()):
		var item = data.collected_items[i]
		text += "  - [%d] %s\n" % [i, item.item_name]
	
	# Print weapon info
	text += "\nBase Weapon: "
	if data.base_weapon:
		text += data.base_weapon.weapon_name + "\n"
	else:
		text += "None\n"
	
	print(text)
	return text

# Debug print for WeaponResource
func print_weapon_resource(weapon: WeaponResource, title: String = "WEAPON RESOURCE", return_string: bool = true) -> String:
	var indent = "  "
	var text = ""
	
	if return_string:
		text += "\n===== %s =====\n" % title
	
	text += "%sName: %s\n" % [indent, weapon.weapon_name]
	text += "%sDescription: %s\n" % [indent, weapon.description]
	text += "%sFire Rate: %.2f\n" % [indent, weapon.fire_rate]
	text += "%sRecoil Strength: %.2f\n" % [indent, weapon.recoil_strength]
	text += "%sRecoil Recovery: %.2f\n" % [indent, weapon.recoil_recovery_speed]
	text += "%sTexture: %s\n" % [indent, "Set" if weapon.weapon_texture else "None"]
	
	# Equipped items
	text += "%sEquipped Items: %d\n" % [indent, weapon.equipped_items.size()]
	for i in range(weapon.equipped_items.size()):
		var item = weapon.equipped_items[i]
		text += "%s  - [%d] %s\n" % [indent, i, item.item_name]
	
	# Projectile info
	text += "%sProjectile:\n" % indent
	if weapon.projectile:
		text += print_projectile_resource(weapon.projectile, "", false, indent + "  ")
	else:
		text += "%s  None\n" % indent
	
	if return_string:
		return text
	else:
		print(text)
	return text

# Debug print for ProjectileResource
func print_projectile_resource(proj: ProjectileResource, title: String = "PROJECTILE RESOURCE", 
							  return_string: bool = true, indent: String = "  ") -> String:
	var text = ""
	
	if return_string:
		text += "\n===== %s =====\n" % title
	
	text += "%sDamage: %.1f\n" % [indent, proj.damage]
	text += "%sSpeed: %.1f\n" % [indent, proj.speed]
	text += "%sLifetime: %.1f sec\n" % [indent, proj.lifetime]
	
	# Special effects
	var has_effects = false
	
	if proj.applies_burn:
		has_effects = true
		text += "%sBurn Effect: %.1f damage for %.1f sec\n" % [indent, proj.burn_damage, proj.burn_duration]
	
	if proj.applies_freeze:
		has_effects = true
		text += "%sFreeze Effect: %.1f strength for %.1f sec\n" % [indent, proj.freeze_strength, proj.freeze_duration]
	
	if proj.bounce_count > 0:
		has_effects = true
		text += "%sBounce Count: %d\n" % [indent, proj.bounce_count]
	
	if proj.penetration_count > 0:
		has_effects = true
		text += "%sPenetration Count: %d\n" % [indent, proj.penetration_count]
	
	if !has_effects:
		text += "%sNo special effects\n" % indent
	
	if return_string:
		return text
	else:
		print(text)
	return text

# Debug print for ItemResource
func print_item_resource(item: ItemResource, title: String = "ITEM", 
						return_string: bool = true, indent: String = "  ") -> String:
	var text = ""
	
	if return_string:
		text += "\n===== %s =====\n" % title
	
	# Basic properties
	text += "%sName: %s\n" % [indent, item.item_name]
	text += "%sDescription: %s\n" % [indent, item.description]
	text += "%sRarity: %s\n" % [indent, _get_rarity_name(item.rarity)]
	text += "%sCost: %d gold\n" % [indent, item.cost]
	
	# Stat multipliers
	text += "\n%sStat Multipliers:\n" % indent
	text += "%s  Damage: %.2fx\n" % [indent, item.damage_multiplier]
	text += "%s  Fire Rate: %.2fx\n" % [indent, item.fire_rate_multiplier]
	text += "%s  Projectile Speed: %.2fx\n" % [indent, item.projectile_speed_multiplier]
	
	# Additives
	if item.damage_additive != 0 or item.fire_rate_additive != 0 or item.projectile_speed_additive != 0:
		text += "\n%sAdditives:\n" % indent
		if item.damage_additive != 0:
			text += "%s  Damage: +%.1f\n" % [indent, item.damage_additive]
		if item.fire_rate_additive != 0:
			text += "%s  Fire Rate: +%.1f\n" % [indent, item.fire_rate_additive]
		if item.projectile_speed_additive != 0:
			text += "%s  Projectile Speed: +%.1f\n" % [indent, item.projectile_speed_additive]
	
	# Special effects
	text += "\n%sSpecial Effects:\n" % indent
	var has_effects = false
	
	if item.adds_burn_effect:
		has_effects = true
		text += "%s  Burn: %.1f damage for %.1f sec\n" % [indent, item.burn_damage, item.burn_duration]
	
	if item.adds_freeze_effect:
		has_effects = true
		text += "%s  Freeze: %.1f strength for %.1f sec\n" % [indent, item.freeze_strength, item.freeze_duration]
	
	if item.adds_bounce:
		has_effects = true
		text += "%s  Bounces: %d times\n" % [indent, item.bounce_count]
	
	if item.adds_penetration:
		has_effects = true
		text += "%s  Penetrates: %d enemies\n" % [indent, item.penetration_count]
	
	if !has_effects:
		text += "%s  None\n" % indent
	
	# Visual changes
	text += "\n%sVisual Changes: %s\n" % [indent, "Yes" if item.weapon_texture_override else "No"]
	
	if return_string:
		return text
	else:
		print(text)
	return text

# Print current game state (useful for checkpoints)
func print_game_state(level_data: LevelDataHandoff, current_weapon : WeaponResource) -> void:
	print("\n=====================================")
	print("         CURRENT GAME STATE          ")
	print("=====================================")
	
	print("\nCurrent Round: %d" % level_data.round_number)
	print("Gold Available: %d" % level_data.gold_available)
	print("Items Collected: %d" % level_data.collected_items.size())
	
	# Display base weapon info
	if level_data.base_weapon:
		print("\nBase Weapon: %s" % level_data.base_weapon.weapon_name)
		
		# Display collected items
		if level_data.collected_items.size() > 0:
			print("\nItems:")
			for i in range(level_data.collected_items.size()):
				var item = level_data.collected_items[i]
				print("  - %s (%s)" % [item.item_name, _get_rarity_name(item.rarity)])
		
		# Create a temporary item manager to calculate correct stats
		var modified_weapon = current_weapon
		
		print("\nCurrent Weapon Stats:")
		print("  - Damage: %.1f" % modified_weapon.projectile.damage)
		print("  - Speed: %.1f" % modified_weapon.projectile.speed) 
		print("  - Fire Rate: %.2f" % modified_weapon.fire_rate)
		
		# Show special effects
		var proj = modified_weapon.projectile
		if proj.applies_burn or proj.applies_freeze or proj.bounce_count > 0 or proj.penetration_count > 0:
			print("\nSpecial Effects:")
			if proj.applies_burn:
				print("  - Burn effect: %.1f damage for %.1f sec" % [proj.burn_damage, proj.burn_duration])
			if proj.applies_freeze:
				print("  - Freeze effect: %.1f strength for %.1f sec" % [proj.freeze_strength, proj.freeze_duration])
			if proj.bounce_count > 0:
				print("  - Bounces: %d times" % proj.bounce_count)
			if proj.penetration_count > 0:
				print("  - Penetrates: %d enemies" % proj.penetration_count)
	
	print("=====================================\n")

# Debug print scene transitions
func print_scene_transition(from_scene: String, to_scene: String) -> void:
	print("\n--> SCENE TRANSITION: %s → %s\n" % [from_scene, to_scene])

# Helper function to get rarity name
func _get_rarity_name(rarity_value: int) -> String:
	match rarity_value:
		ItemResource.Rarity.COMMON:
			return "COMMON"
		ItemResource.Rarity.UNCOMMON:
			return "UNCOMMON"
		ItemResource.Rarity.RARE:
			return "RARE"
		ItemResource.Rarity.EPIC:
			return "EPIC"
		ItemResource.Rarity.LEGENDARY:
			return "LEGENDARY"
	return "UNKNOWN"
