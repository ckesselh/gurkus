extends CharacterBody2D

# Movement
const SPEED_MAX := 250.0
const ACCEL_FLOOR := 1200.0
const ACCEL_AIR := 600.0
const FRICTION_FLOOR := 800.0
const FRICTION_AIR := 200.0

# Jump — scales with horizontal speed
const JUMP_BASE := -300.0
const JUMP_MOMENTUM_BONUS := -120.0
const GRAVITY := 900.0
const GRAVITY_FALL := 1400.0
const JUMP_SLOWFALL := -3.0

# Coyote time & jump buffer
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12

const FIREBALL_COOLDOWN := 15.0
const SHOOT_ANIM_FPS := 20.0
const SHOOT_FRAME_COUNT := 30
const SHOOT_SPAWN_FRAME := 15

const ANIM_FPS := 10.0

const FireballScene := preload("res://scenes/player/fireball.tscn")

var _anim_frame := 0
var _anim_timer := 0.0
var _cooldown_remaining := 0.0
var _is_shooting := false
var _shoot_frame := 0
var _shoot_timer := 0.0
var _fireball_spawned := false
var _facing_right := true
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false
var _is_jumping := false

@onready var walk_sprite: Sprite2D = $WalkSprite
@onready var shoot_sprite: Sprite2D = $ShootSprite
@onready var cooldown_bar: ColorRect = $CooldownUI/Bar
@onready var cooldown_bg: ColorRect = $CooldownUI/Background


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	# Coyote time: allow jumping briefly after leaving a ledge
	if on_floor:
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta

	# Jump buffer: remember jump press for a short window
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta

	# Gravity — heavier when falling for snappier feel
	if not on_floor:
		var grav := GRAVITY if velocity.y < 0 and Input.is_action_pressed("jump") else GRAVITY_FALL
		velocity.y += grav * delta

	# Slowfall while holding jump and ascending
	if Input.is_action_pressed("jump") and velocity.y < 0:
		velocity.y += JUMP_SLOWFALL

	# Jump — stronger with more horizontal speed
	var can_jump := _coyote_timer > 0 and _jump_buffer_timer > 0
	if can_jump:
		var speed_ratio := absf(velocity.x) / SPEED_MAX
		velocity.y = JUMP_BASE + JUMP_MOMENTUM_BONUS * speed_ratio
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_is_jumping = true

	if on_floor and velocity.y >= 0:
		_is_jumping = false

	# Horizontal movement with acceleration
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		var accel := ACCEL_FLOOR if on_floor else ACCEL_AIR
		velocity.x = move_toward(velocity.x, direction * SPEED_MAX, accel * delta)
	else:
		var friction := FRICTION_FLOOR if on_floor else FRICTION_AIR
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	_was_on_floor = on_floor
	move_and_slide()

	# Shooting
	if Input.is_action_just_pressed("shoot") and _cooldown_remaining <= 0 and not _is_shooting:
		_start_shooting()

	if _is_shooting:
		_update_shoot_animation(delta)
	else:
		_update_animation(direction, delta)

	# Cooldown
	if _cooldown_remaining > 0:
		_cooldown_remaining -= delta
		if _cooldown_remaining < 0:
			_cooldown_remaining = 0
	_update_cooldown_ui()


func _update_animation(direction: float, delta: float) -> void:
	if direction > 0:
		walk_sprite.flip_h = false
		_facing_right = true
	elif direction < 0:
		walk_sprite.flip_h = true
		_facing_right = false

	if direction != 0:
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 6
		walk_sprite.frame = _anim_frame
	else:
		_anim_frame = 0
		_anim_timer = 0.0
		walk_sprite.frame = 0


func _start_shooting() -> void:
	_is_shooting = true
	_shoot_frame = 0
	_shoot_timer = 0.0
	_fireball_spawned = false
	walk_sprite.visible = false
	shoot_sprite.visible = true
	shoot_sprite.flip_h = not _facing_right
	shoot_sprite.frame = 0


func _update_shoot_animation(delta: float) -> void:
	_shoot_timer += delta
	if _shoot_timer >= 1.0 / SHOOT_ANIM_FPS:
		_shoot_timer = 0.0
		_shoot_frame += 1

		if _shoot_frame >= SHOOT_FRAME_COUNT:
			_end_shooting()
			return

		shoot_sprite.frame = _shoot_frame

	if _shoot_frame >= SHOOT_SPAWN_FRAME and not _fireball_spawned:
		_spawn_fireball()
		_fireball_spawned = true


func _end_shooting() -> void:
	_is_shooting = false
	shoot_sprite.visible = false
	walk_sprite.visible = true
	_cooldown_remaining = FIREBALL_COOLDOWN


func _spawn_fireball() -> void:
	var fireball := FireballScene.instantiate()
	var offset_x := 30.0 if _facing_right else -30.0
	fireball.global_position = global_position + Vector2(offset_x, -10)
	fireball.direction = 1.0 if _facing_right else -1.0
	get_parent().add_child(fireball)


func _update_cooldown_ui() -> void:
	if _cooldown_remaining > 0:
		var ratio := _cooldown_remaining / FIREBALL_COOLDOWN
		cooldown_bar.size.x = 80.0 * (1.0 - ratio)
		cooldown_bar.color = Color(0.5, 0.5, 0.5, 0.6)
	else:
		cooldown_bar.size.x = 80.0
		cooldown_bar.color = Color(1.0, 0.5, 0.0, 0.9)
