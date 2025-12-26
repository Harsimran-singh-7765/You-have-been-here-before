class_name AbilitySlot
extends MarginContainer

# --- CONFIG ---
@export var icon_texture: Texture2D

# --- NODES ---
@onready var icon_rect: ColorRect = $IconRect
@onready var mana_label: Label = $ManaLabel
@onready var button: Button = $Button 

# --- SIGNALS ---
signal slot_clicked 

# --- VARS ---
var cooldown_value: float = 100.0
var is_locked: bool = false
var tween: Tween

func _ready() -> void:
	# 1. Setup Shader
	if icon_rect.material:
		icon_rect.material = icon_rect.material.duplicate()
		if icon_texture:
			icon_rect.material.set_shader_parameter("custom_texture", icon_texture)
	
	# 2. Setup Button Signals
	if button:
		button.pressed.connect(_on_button_pressed)
		# --- NEW: HOVER SIGNALS ---
		button.mouse_entered.connect(_on_hover_enter)
		button.mouse_exited.connect(_on_hover_exit)
	
	# 3. Setup Label
	if mana_label: mana_label.visible = false
	
	# 4. Reset
	cooldown_value = 100.0
	icon_rect.modulate = Color.WHITE
	_update_shader()

func _process(_delta: float) -> void:
	_update_shader()

func _update_shader() -> void:
	if icon_rect.material:
		icon_rect.material.set_shader_parameter("cooldown_progress", int(cooldown_value))

# --- BUTTON CLICK LOGIC ---
func _on_button_pressed() -> void:
	if is_locked: return
	emit_signal("slot_clicked")

# --- NEW: HOVER LOGIC ---
func _on_hover_enter() -> void:
	# Don't change color if locked or flashing "No Mana"
	if is_locked or mana_label.visible: return
	
	# Turn slightly Grey (0.7) to show it's clickable
	var t = create_tween()
	t.tween_property(icon_rect, "modulate", Color(0.7, 0.7, 0.7), 0.1)

func _on_hover_exit() -> void:
	# Don't change color if locked or flashing "No Mana"
	if is_locked or mana_label.visible: return
	
	# Return to Normal White
	var t = create_tween()
	t.tween_property(icon_rect, "modulate", Color.WHITE, 0.1)

# --- ANIMATION LOGIC ---
func activate(time: float) -> void:
	if is_locked: return
	
	mana_label.visible = false
	icon_rect.modulate = Color.WHITE 
	
	cooldown_value = 0.0
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "cooldown_value", 100.0, time).from(0.0)

func show_no_mana() -> void:
	# Snap to Black/Locked visual immediately
	cooldown_value = 0.0 
	icon_rect.modulate = Color(0.2, 0.2, 0.2) 
	
	if mana_label:
		mana_label.visible = true
		mana_label.text = "NO MANA"
	
	var t = create_tween()
	t.tween_interval(0.5)
	t.tween_callback(revert_mana_warning)

func revert_mana_warning() -> void:
	mana_label.visible = false
	
	if not is_locked:
		cooldown_value = 100.0
		
		# SMART CHECK: If mouse is still hovering, stay Grey, otherwise go White
		if button and button.is_hovered():
			icon_rect.modulate = Color(0.7, 0.7, 0.7)
		else:
			icon_rect.modulate = Color.WHITE

func lock() -> void:
	is_locked = true
	cooldown_value = 0.0
	icon_rect.modulate = Color(0.2, 0.2, 0.2)
	if button: 
		button.disabled = true
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func unlock() -> void:
	is_locked = false
	cooldown_value = 100.0
	icon_rect.modulate = Color.WHITE
	if button: 
		button.disabled = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
