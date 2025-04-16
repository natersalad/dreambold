class_name ItemComponent
extends Control

signal item_selected(item: ItemResource)
signal item_deselected(item: ItemResource)
signal item_purchased(item: ItemResource)

# Static variable to track which component is currently selected
static var current_selected_component: ItemComponent = null

@export var item_resource: ItemResource:
	set(new_resource):
		item_resource = new_resource
		if is_inside_tree():
			load_item_data(new_resource)

# Node references based on your scene structure
@onready var color_rect = $ColorRect
@onready var item_texture = $ColorRect/ItemTexture
@onready var info_panel = $InfoPanel
@onready var info_container = $InfoPanel/InfoContainer
@onready var item_name_label = $InfoPanel/InfoContainer/ItemNameLabel
@onready var description_label = $InfoPanel/InfoContainer/DescriptionLabel
@onready var rarity_label = $InfoPanel/InfoContainer/RarityLabel
@onready var buy_button = $ColorRect/Button
@onready var animation_player = $AnimationPlayer
@onready var soldLabel = $ColorRect/SoldLabel

# State tracking
var is_hovered: bool = false
var is_selected: bool = false
var is_disabled: bool = false
var current_animation: String = ""
var last_click_time: float = 0.0
var click_debounce_time: float = 0.3

# Ensure animations complete and don't get cut off
func _on_animation_finished(anim_name: String):


	# Clear current animation tracking
	if anim_name == current_animation:
		current_animation = ""

	# Enforce visibility state after animation completion
	update_info_panel_visibility()
	
	# If mouse exited while animation was playing and we're not selected
	if not is_hovered and not is_selected and anim_name == "hover":
		play_animation("unhover")
	
	# If mouse entered while animation was playing
	if is_hovered and anim_name == "unhover":
		play_animation("hover")

func _ready():
	# Load item data from resource
	if item_resource:
		load_item_data(item_resource)

	# Make sure mouse events work properly
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	item_texture.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow events to pass through to ColorRect
	
	# Connect signals
	connect_signals()
	
	# Ensure animations don't cut short
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Enable global input processing to detect clicks outside this component
	set_process_input(true)

	# Add debug print to check signals
	print("[ITEMCOMP] ItemComponent ready: ", item_resource.item_name if item_resource else "No resource")

func connect_signals():
	# Connect hover signals to ColorRect instead of item_texture
	color_rect.mouse_entered.connect(_on_mouse_entered)
	color_rect.mouse_exited.connect(_on_mouse_exited)
	
	# Connect click signals to ColorRect instead of item_texture
	color_rect.gui_input.connect(_on_texture_gui_input)
	buy_button.pressed.connect(_on_buy_button_pressed)

func load_item_data(item: ItemResource):
	if not item:
		push_error("[ITEMCOMP] No ItemResource provided")
		return
		
	# Apply item data to UI
	item_texture.texture = item.icon
	item_name_label.text = item.item_name
	description_label.text = item.description
	
	# Set rarity text and color
	var rarity_text = ""
	var rarity_color = Color.WHITE
	
	match item.rarity:
		ItemResource.Rarity.COMMON:
			rarity_text = "COMMON"
			rarity_color = Color(0.7, 0.7, 0.7)  # White/Gray
		ItemResource.Rarity.UNCOMMON:
			rarity_text = "UNCOMMON"
			rarity_color = Color(0.0, 0.8, 0.0)  # Green
		ItemResource.Rarity.RARE:
			rarity_text = "RARE"
			rarity_color = Color(0.0, 0.5, 1.0)  # Blue
		ItemResource.Rarity.EPIC:
			rarity_text = "EPIC"
			rarity_color = Color(0.6, 0.0, 0.8)  # Purple
		ItemResource.Rarity.LEGENDARY:
			rarity_text = "LEGENDARY"
			rarity_color = Color(1.0, 0.5, 0.0)  # Orange
	
	# Apply colors to labels
	item_name_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.text = rarity_text
	rarity_label.add_theme_color_override("font_color", rarity_color)
	
	# Update buy button with cost
	buy_button.text = "BUY (%d)" % item.cost
	buy_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	buy_button.add_theme_color_override("font_hover_color", Color(0.3, 1.0, 0.3))

func play_animation(anim_name: String) -> void:
	if animation_player.is_playing():
		await animation_player.animation_finished
	
	# Only play if not already playing this animation
	current_animation = anim_name
	animation_player.play(anim_name)

func _on_mouse_entered():

	is_hovered = true
	if not is_selected and not is_disabled:
		play_animation("hover")
	update_info_panel_visibility()

func _on_mouse_exited():
	is_hovered = false

	# Only play unhover if not selected
	if not is_selected and not is_disabled:
		play_animation("unhover")
		
	# Update panel visibility
	update_info_panel_visibility()

# Function to update panel visibility based on hover AND selection state
func update_info_panel_visibility():
	info_panel.visible = is_hovered or current_animation == "click"

func _on_texture_gui_input(event):

	if is_disabled:
		get_viewport().set_input_as_handled()
		return

	if current_animation in ["click", "unclick"]:
		if event is InputEventMouseButton and event.pressed:
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_click_time < click_debounce_time:
				get_viewport().set_input_as_handled()
				return
			
			last_click_time = current_time

			if is_selected:
				deselect()
			else:
				# Deselect any previously selected component
				if current_selected_component != null and current_selected_component != self:
					current_selected_component.deselect()
				
				# Select this component
				is_selected = true
				current_selected_component = self
				play_animation("click")
				item_selected.emit(item_resource)
				get_viewport().set_input_as_handled()

func deselect():
	play_animation("unclick")
	is_selected = false
	update_info_panel_visibility()
	item_deselected.emit(item_resource)


# New function to disable the item after purchase
func disable_after_purchase() -> void:
	# Ensure the animation is finished before proceeding
	if animation_player.is_playing():
		await animation_player.animation_finished
	
	# Set the disabled state
	is_disabled = true
	
	# Grey out the item visually
	color_rect.modulate = Color(0.5, 0.5, 0.5, 1.0)
	item_texture.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	# Show the sold label
	soldLabel.visible = true
	
	# Deselect if currently selected
	if is_selected:
		is_selected = false
		if current_selected_component == self:
			current_selected_component = null
		update_info_panel_visibility()
	
	# Disable hover and selection effects
	if current_animation != "":
		animation_player.stop()
		current_animation = ""
	
	# Play the unclick animation if needed
	if is_selected:
		play_animation("unclick")

func purchase_succeeded() -> void:
	play_animation("unclick")
	disable_after_purchase()

func purchase_failed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _on_buy_button_pressed():
	item_purchased.emit(item_resource)
	
