class_name HealthComponent
extends Node

# signals

signal max_health_changed(max_health: int)
signal health_changed(current_health: int)
signal health_depleted
signal invulnerable_changed(is_invulnerable: bool)
signal shield_changed(current_shield: int)
signal shield_depleted

# exported variables for health
@export var max_health: int = 6
@export var health_regen_per_second: int = 0
@export var health_regen_delay: float = 2.0
@export var health_regen_enabled: bool = false

# exported variables for shield
@export var has_shield: bool = false
@export var max_shield: int = 4
@export var shield_regen_per_second: int = 0
@export var shield_cooldown: float = 3.0

# exported variables for invulnerability
@export var is_invulnerable: bool = false
@export var invulnerability_duration: float = 0.0

# exported variables for mesh (used for flashing when hit)
@export var hit_flash_mesh: MeshInstance3D = null
var original_emission_color: Color = Color.BLACK

# internal timers
var health_regen_timer: Timer = null
var shield_regen_timer: Timer = null
var shield_cooldown_timer: Timer = null
var invulnerability_timer: Timer = null

# runtime values
var current_health: int 
var current_shield: int

func _ready() -> void:
	max_health = max(max_health, 1) # ensure max health is at least 1
	max_shield = max(max_shield, 0) # ensure max shield is at least 0

	current_health = max_health
	current_shield = max_shield

	# setup health regen if enabled
	if health_regen_per_second > 0:
		_init_health_regen_timer()
	# setup shield regen if enabled
	if shield_regen_per_second > 0 and current_shield > 0 and has_shield:
		_init_shield_regen_timer()

	# setup mesh to flash
	if not hit_flash_mesh.material_override:
		var active_mat = hit_flash_mesh.get_active_material(0) as StandardMaterial3D
		if active_mat:
			var dup_mat = active_mat.duplicate() as StandardMaterial3D
			hit_flash_mesh.material_override = dup_mat
			original_emission_color = dup_mat.emission
		else:
			original_emission_color = Color.BLACK
	else:
		original_emission_color = (hit_flash_mesh.material_override as StandardMaterial3D).emission

func damage(amount: int) -> void:
	# if invulnerable, ignore damage
	if is_invulnerable:
		emit_signal("health_changed", current_health)
		return

	amount = abs(amount)

	# if there is no sheild
	if current_shield <= 0 or not has_shield:
		current_health = max(0, current_health - amount)
		emit_signal("health_changed", current_health)
		flash_mesh(Color(1.0, 0.0, 0.0)) # flash red

		# if health is depleted -> emit signal -> stop all timers and start invulnerability
		if current_health <= 0:
			emit_signal("health_depleted")
			_stop_all_timers()
			enable_invulnerability(true, 10.0) # put 10 cuz they would prob despawn by then
	
	# apply damage to shield first
	if current_shield > 0 and has_shield:
		var shield_damage: int = min(current_shield, amount)
		current_shield -= shield_damage
		amount -= shield_damage
		emit_signal("shield_changed", current_shield)
		flash_mesh(Color(0.0, 0.0, 1.0)) # flash blue
	
	# if the shield is broken -> emit signal -> stop shield regen and start cooldown
	if current_shield <= 0 and has_shield:
		emit_signal("shield_depleted")
		flash_mesh(Color(1.0, 1.0, 0.0)) # flash yellow
		if shield_regen_timer:
			shield_regen_timer.stop()
		_start_shield_cooldown()
	
func heal_health(amount: int) -> void:
	amount = abs(amount)
	if current_health > 0:
		current_health = min(max_health, current_health + amount)
		emit_signal("health_changed", current_health)

func heal_shield(amount: int) -> void:
	amount = abs(amount)
	if current_shield > 0 and has_shield:
		current_shield = min(max_shield, current_shield + amount)
		emit_signal("shield_changed", current_shield)

# flashing mesh methods

func flash_mesh(color: Color) -> void:
	# Get the current material override.
	var mat = hit_flash_mesh.material_override as StandardMaterial3D
	if not mat:
		push_warning("No material override found!")
		return

	# Enable emission (if not already enabled).
	mat.emission_enabled = true

	# Set the material to red
	mat.emission = color
	mat.emission_energy = 1.0

	# Wait for a short duration of the flash effect.
	await get_tree().create_timer(0.1).timeout

	# Restore the original emission values.
	mat.emission = original_emission_color
	mat.emission_energy = 0
	

# health regeneration timer methods

func _init_health_regen_timer() -> void:
	health_regen_timer = Timer.new()
	health_regen_timer.wait_time = 1.0 # 1 second
	health_regen_timer.autostart = true
	health_regen_timer.one_shot = false
	add_child(health_regen_timer)
	health_regen_timer.connect("timeout", Callable(self, "_on_health_regen_timeout"))

# might have an issue with this when taking damage it might still try to regen all the time idk...
func _on_health_regen_timeout() -> void:
	if current_health < max_health:
		heal_health(health_regen_per_second)
	else:
		health_regen_timer.stop()

# shield regeneration timer methods - only starts after cooldown if shield gets popped

func _init_shield_regen_timer() -> void:
	shield_regen_timer = Timer.new()
	shield_regen_timer.wait_time = 1.0 # 1 second
	shield_regen_timer.autostart = true
	shield_regen_timer.one_shot = false
	add_child(shield_regen_timer)
	shield_regen_timer.connect("timeout", Callable(self, "_on_shield_regen_timeout"))

func _on_shield_regen_timeout() -> void:
	if current_shield < max_shield:
		heal_shield(shield_regen_per_second)
		emit_signal("shield_changed", current_shield)
	else:
		shield_regen_timer.stop()

func _start_shield_cooldown() -> void:
	# start a cooldown timer before re-enabling shield regen
	if shield_cooldown > 0.0:
		if shield_cooldown_timer:
			shield_cooldown_timer.stop()
		else:
			shield_cooldown_timer = Timer.new()
			shield_cooldown_timer.one_shot = true
			add_child(shield_cooldown_timer)
			shield_cooldown_timer.connect("timeout", Callable(self, "_on_shield_cooldown_timeout"))
		shield_cooldown_timer.wait_time = shield_cooldown
		shield_cooldown_timer.start()
	else:
		# if no cooldown, start shield regen immediately
		_init_shield_regen_timer()

# invulnerability methods

func enable_invulnerability(enable: bool, duration: float = 0.0) -> void:
	is_invulnerable = enable
	emit_signal("invulnerable_changed", is_invulnerable)
	if enable and duration >= 0.0:
		if invulnerability_timer:
			invulnerability_timer.stop()
		else:
			invulnerability_timer = Timer.new()
			invulnerability_timer.one_shot = true
			add_child(invulnerability_timer)
			invulnerability_timer.connect("timeout", Callable(self, "_on_invulnerability_timeout"))
		invulnerability_timer.wait_time = duration
		invulnerability_timer.start()
	elif not enable and invulnerability_timer:
		invulnerability_timer.stop()
		
func _on_invulnerability_timeout() -> void:
	is_invulnerable = false
	emit_signal("invulnerable_changed", is_invulnerable)

func _stop_all_timers() -> void:
	if health_regen_timer:
		health_regen_timer.stop()
	if shield_regen_timer:
		shield_regen_timer.stop()
	if shield_cooldown_timer:
		shield_cooldown_timer.stop()
	if invulnerability_timer:
		invulnerability_timer.stop()

func get_health_percent() -> float:
	return current_health / float(max_health)

func get_shield_percent() -> float:
	if not has_shield:
		return 0.0
	return current_shield / float(max_shield)

func get_current_health() -> int:
	return current_health

func get_current_shield() -> int:
	return current_shield
