class_name PlayerUseAbilityComponent
extends Node

@export var use_ability_action_name_fire_spin = "ability_fire_spin"
@export var use_ability_action_name_fire_ball = "ability_fire_ball"
@export var use_ability_action_name_water_ball = "ability_water_ball"
@export var use_ability_action_name_rock_throw = "ability_rock_throw"
@export var use_ability_action_name_wind_tornado = "ability_wind_tornado"
@export var ability_fire_spin : Ability
@export var ability_fire_ball : Ability
@export var ability_water_ball : Ability
@export var ability_rock_throw: Ability
@export var ability_wind_tornado: Ability
@export var user : Node2D

@export var fire_spin_cooldown := 0.8
@export var fire_ball_cooldown := 0.6
@export var rock_throw_cooldown := 0.8
@export var water_ball_cooldown := 1
@export var wind_tornado_cooldown := 1.5

# --- MANA COSTS (New!) ---
# Easily change these numbers in the Inspector now
@export_group("Mana Costs")
@export var fire_spin_cost := 12
@export var fire_ball_cost := 5
@export var water_ball_cost := 8
@export var rock_throw_cost := 10
@export var wind_tornado_cost := 15


# --- NEW SIGNAL ADDED HERE ---
signal magic_used(attack_name: String)
signal mana_missing(attack_name: String) 
# --- INTERNAL STATE ---
var _can_fire_spin := true
var _can_fire_ball := true
var _can_water_ball := true
var _can_rock_throw := true
var _can_wind_tornado := true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(use_ability_action_name_fire_spin):
		_try_fire_spin()

	if event.is_action_pressed(use_ability_action_name_fire_ball):
		_try_fire_ball()
		
	if event.is_action_pressed(use_ability_action_name_water_ball):
		_try_water_ball()
		
	if event.is_action_pressed(use_ability_action_name_rock_throw):
		_try_rock_throw()
		
	if event.is_action_pressed(use_ability_action_name_wind_tornado):
		_try_wind_tornado()

# --- FIRE SPIN ---
func _try_fire_spin() -> void:
	if not _can_fire_spin: return
	if ability_fire_spin == null: return
	
	if not _has_mana(fire_spin_cost):
		emit_signal("mana_missing", "fire_spin")
		return

	_can_fire_spin = false
	ability_fire_spin.use(user)
	emit_signal("magic_used", "fire_spin")

	await get_tree().create_timer(fire_spin_cooldown).timeout
	_can_fire_spin = true

# --- FIRE BALL ---
func _try_fire_ball() -> void:
	if not _can_fire_ball: return
	if ability_fire_ball == null: return
	
	if not _has_mana(fire_ball_cost):
		emit_signal("mana_missing", "fire_ball")
		return

	_can_fire_ball = false
	ability_fire_ball.use(user)
	emit_signal("magic_used", "fire_ball")

	await get_tree().create_timer(fire_ball_cooldown).timeout
	_can_fire_ball = true

# --- WATER BALL ---
func _try_water_ball() -> void:
	if not _can_water_ball: return
	if ability_water_ball == null: return
	
	if not _has_mana(water_ball_cost):
		emit_signal("mana_missing", "water_ball")
		return

	_can_water_ball = false
	ability_water_ball.use(user)
	emit_signal("magic_used", "water_ball")

	await get_tree().create_timer(water_ball_cooldown).timeout
	_can_water_ball = true

# --- ROCK THROW ---
func _try_rock_throw() -> void:
	if not _can_rock_throw: return
	if ability_rock_throw == null: return
	
	if not _has_mana(rock_throw_cost):
		emit_signal("mana_missing", "rock_throw")
		return

	_can_rock_throw = false
	ability_rock_throw.use(user)
	emit_signal("magic_used", "rock_throw")

	await get_tree().create_timer(rock_throw_cooldown).timeout
	_can_rock_throw = true

# --- WIND TORNADO ---
func _try_wind_tornado() -> void:
	if not _can_wind_tornado: return
	if ability_wind_tornado == null: return
	
	if not _has_mana(wind_tornado_cost):
		emit_signal("mana_missing", "wind_tornado")
		return

	_can_wind_tornado = false
	ability_wind_tornado.use(user)
	emit_signal("magic_used", "wind_tornado")

	await get_tree().create_timer(wind_tornado_cooldown).timeout
	_can_wind_tornado = true

# --- HELPERS ---

func _has_mana(cost: int) -> bool:
	if user == null: return false
	# Assuming user has a 'Stats' component or similar with this method
	if not user.has_method("get_current_mana"): return true 
	return user.get_current_mana() >= cost


# --- UI CLICK HANDLER ---
func attempt_ability(ability_name: String) -> void:
	match ability_name:
		"fire_ball":
			_try_fire_ball()
		"fire_spin":
			_try_fire_spin()
		"water_ball":
			_try_water_ball()
		"rock_throw":
			_try_rock_throw()
		"wind_tornado":
			_try_wind_tornado()
		_:
			print("Player doesn't know how to use: ", ability_name)
