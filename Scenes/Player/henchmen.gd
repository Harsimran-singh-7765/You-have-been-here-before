extends CharacterBody2D

const DEBUG_AI := false

# -----------------------
# CONFIG
# -----------------------
const SPEED := 70.0
const JUMP_VELOCITY := -320.0
const JUMP_COOLDOWN_TIME := 0.6

const ATTACK_RANGE := 40.0
const ATTACK_DAMAGE := 10        # Damage wapas 10 kar diya (Henchman level)
const ATTACK_TICK_RATE := 1    # Har 0.5 sec mein damage dega agar player range mein raha
const ATTACK_COOLDOWN := 1    # Attack khatam hone ke baad 0.5 sec wait
const ATTACK_HITBOX_FRAME := 0.3 # Animation ke 0.3 sec baad damage shuru hoga

const MAX_HEALTH := 50

# CRITICAL for Wave Handler
signal died

# -----------------------
# STATE
# -----------------------
enum State { IDLE, CHASE, ATTACK, ATTACK_RECOVERY, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D = null
var health: int = MAX_HEALTH

var jump_cooldown: bool = false

# --- COMBAT VARS (New Logic) ---
var attack_can_hit: bool = false
var damage_tick_timer: float = 0.0 
var recovery_timer: float = 0.0

# -----------------------
# NODES
# -----------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_check: RayCast2D = $GroundCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var attack_area: Area2D = $attack_area
@onready var health_bar = $health_bar

# -----------------------
func _ready():
	sprite.play("idle")
	attack_area.monitoring = false
	
	health_bar.max_value = MAX_HEALTH
	health_bar.value = MAX_HEALTH
	health_bar.visible = false
	
	if DEBUG_AI: print("[ENEMY] Henchman ready")

func enemy():
	pass

# -----------------------
func _physics_process(delta: float) -> void:
	if state == State.DEAD: return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match state:
		State.IDLE: 
			_idle_state()
		State.CHASE: 
			_chase_state()
		State.ATTACK: 
			_attack_state(delta)          # <-- DELTA PASS KIYA
		State.ATTACK_RECOVERY: 
			_attack_recovery_state(delta) # <-- DELTA PASS KIYA
	
	move_and_slide()

# -----------------------
# STATES
# -----------------------
func _idle_state():
	velocity.x = 0
	sprite.play("idle")
	if player: state = State.CHASE

func _chase_state():
	if player == null:
		state = State.IDLE
		return
	
	var dx: float = player.global_position.x - global_position.x
	var dist_x: float = abs(dx)
	var dir: float = sign(dx)
	
	sprite.flip_h = dir < 0
	
	# ATTACK TRIGGER
	# Range mein aate hi attack shuru karo
	if dist_x <= ATTACK_RANGE:
		_start_attack()
		return
	
	# Movement
	velocity.x = dir * SPEED
	if sprite.animation != "run": sprite.play("run")
	
	# Jump Logic
	ground_check.target_position = Vector2(20.0 * dir, 30.0)
	wall_check.target_position = Vector2(20.0 * dir, 0.0)
	
	if is_on_floor() and not jump_cooldown:
		if not ground_check.is_colliding() or wall_check.is_colliding():
			_do_jump(dir)

# -----------------------
# NEW COMBAT LOGIC (Continuous Tick)
# -----------------------
func _start_attack():
	state = State.ATTACK
	velocity.x = 0
	sprite.play("attack")
	
	if DEBUG_AI: print("[ENEMY] Attack Start")
	
	# Delay ke baad Hitbox ON karo
	get_tree().create_timer(ATTACK_HITBOX_FRAME).timeout.connect(func():
		if state == State.ATTACK:
			attack_can_hit = true
			attack_area.monitoring = true
			damage_tick_timer = 0.0 # Turant damage dene ke liye ready
			if DEBUG_AI: print("[ENEMY] Hitbox Active")
	)
	
	# Animation khatam hone ka wait karo
	await sprite.animation_finished
	
	# Agar abhi bhi zinda hai aur attack state mein hai
	if state == State.ATTACK:
		_end_attack()

func _attack_state(delta: float):
	velocity.x = 0 # Attack karte waqt move nahi karega
	
	# Logic: Agar hitbox active hai, toh tick rate ke hisaab se damage do
	if attack_can_hit:
		damage_tick_timer -= delta
		
		if damage_tick_timer <= 0:
			# Check karo kon kon area mein hai
			var bodies = attack_area.get_overlapping_bodies()
			for body in bodies:
				if body == player and body.has_method("take_damage"):
					if DEBUG_AI: print("[ENEMY] Dealt ", ATTACK_DAMAGE, " damage")
					body.take_damage(ATTACK_DAMAGE)
					damage_tick_timer = ATTACK_TICK_RATE # Timer reset (0.5s wait)
					break 
	
	# Cancel: Agar player bohot door chala gaya
	if player:
		var dist = abs(player.global_position.x - global_position.x)
		if dist > ATTACK_RANGE * 1.5:
			_end_attack()
			state = State.CHASE

func _end_attack():
	attack_can_hit = false
	attack_area.monitoring = false
	recovery_timer = ATTACK_COOLDOWN
	state = State.ATTACK_RECOVERY

func _attack_recovery_state(delta: float):
	velocity.x = 0
	sprite.play("idle")
	
	recovery_timer -= delta
	
	if recovery_timer <= 0:
		if player and _get_distance_to_player() <= ATTACK_RANGE:
			_start_attack() # Turant attack karo agar paas hai
		elif player:
			state = State.CHASE
		else:
			state = State.IDLE

# -----------------------
# HELPERS
# -----------------------
func _get_distance_to_player() -> float:
	if player == null: return INF
	return abs(player.global_position.x - global_position.x)

func _do_jump(dir: float):
	jump_cooldown = true
	velocity.y = JUMP_VELOCITY
	velocity.x = dir * SPEED
	sprite.play("jump")
	
	await get_tree().create_timer(JUMP_COOLDOWN_TIME).timeout
	jump_cooldown = false

# -----------------------
# DETECTION
# -----------------------
func _on_detection_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body
		if state == State.IDLE: state = State.CHASE

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		if state != State.ATTACK and state != State.ATTACK_RECOVERY:
			state = State.IDLE

# -----------------------
# DAMAGE & DEATH
# -----------------------
func take_damage(amount: int):
	if state == State.DEAD: return
	
	health -= amount
	health = clamp(health, 0, MAX_HEALTH)
	
	health_bar.value = health
	health_bar.visible = true
	
	# Hit Animation (Optional: Agar attack nahi kar raha toh flinch kare)
	if state != State.ATTACK:
		# sprite.play("hit") # Uncomment if hit anim exists
		pass
	
	if health <= 0:
		die()

func die():
	state = State.DEAD
	velocity = Vector2.ZERO
	health_bar.visible = false
	
	# Disable collisions
	$CollisionShape2D.set_deferred("disabled", true)
	attack_area.set_deferred("monitoring", false)
	
	emit_signal("died")
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	
	queue_free()
