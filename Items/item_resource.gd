class_name ItemResource
extends Resource

enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
}

# Basic properties
@export var item_name: String = "Default Item"
@export var description: String = "A basic item"
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var cost: int = 50

# Stat modifiers (multipliers)
@export_group("Stat Modifiers (Multipliers)")
@export var damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var projectile_speed_multiplier: float = 1.0

# Stat modifiers (additive)
@export_group("Stat Modifiers (Additive)")
@export var damage_additive: float = 0.0
@export var fire_rate_additive: float = 0.0
@export var projectile_speed_additive: float = 0.0

# Visual changes
@export_group("Visual Changes")
@export var weapon_texture_override: Texture2D  # If set, replaces the weapon's texture

# Special effects
@export_group("Special Effects")
@export var adds_burn_effect: bool = false
@export var burn_damage: float = 0.0
@export var burn_duration: float = 0.0

@export var adds_freeze_effect: bool = false
@export var freeze_strength: float = 0.0
@export var freeze_duration: float = 0.0

@export var adds_bounce: bool = false
@export var bounce_count: int = 0

@export var adds_penetration: bool = false
@export var penetration_count: int = 0