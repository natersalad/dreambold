class_name WeaponResource
extends Resource

@export var weapon_name: String = "Default Blaster"
@export var description: String = "A basic blaster weapon"
@export var projectile: ProjectileResource
@export var fire_rate: float = 0.2
@export var recoil_strength: float = 0.1
@export var recoil_recovery_speed: float = 10.0
@export var weapon_texture: Texture2D

# Items equipped with this weapon
@export var equipped_items: Array[ItemResource] = []