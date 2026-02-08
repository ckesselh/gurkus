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

# Health
const MAX_HP := 3
const INVINCIBILITY_TIME := 1.5
const KNOCKBACK_HORIZONTAL := 200.0
const KNOCKBACK_VERTICAL := -200.0
const BLINK_SPEED := 10.0

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
var _hp := MAX_HP
var _invincible_timer := 0.0

@onready var walk_sprite: Sprite2D = $WalkSprite
@onready var idle_sprite: Sprite2D = $IdleSprite
@onready var shoot_sprite: Sprite2D = $ShootSprite
@onready var cooldown_bar: ColorRect = $CooldownUI/Bar
@onready var cooldown_bg: ColorRect = $CooldownUI/Background
@onready var heart_label: Label = $CooldownUI/Hearts


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

	_check_enemy_collisions()

	# Invincibility
	if _invincible_timer > 0:
		_invincible_timer -= delta
		modulate.a = 0.3 + 0.7 * absf(sin(_invincible_timer * BLINK_SPEED))
		if _invincible_timer <= 0:
			_invincible_timer = 0
			modulate.a = 1.0

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
	_update_heart_ui()


func _update_animation(direction: float, delta: float) -> void:
	if direction > 0:
		_facing_right = true
	elif direction < 0:
		_facing_right = false

	var flip := not _facing_right
	walk_sprite.flip_h = flip
	idle_sprite.flip_h = flip

	if direction != 0:
		idle_sprite.visible = false
		walk_sprite.visible = true
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 6
		walk_sprite.frame = _anim_frame
	else:
		walk_sprite.visible = false
		idle_sprite.visible = true
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 6
		idle_sprite.frame = _anim_frame


func _start_shooting() -> void:
	_is_shooting = true
	_shoot_frame = 0
	_shoot_timer = 0.0
	_fireball_spawned = false
	walk_sprite.visible = false
	idle_sprite.visible = false
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
	idle_sprite.visible = true
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


func _update_heart_ui() -> void:
	heart_label.text = ""
	for i in MAX_HP:
		if i < MAX_HP - _hp:
			heart_label.text += "♡ "
		else:
			heart_label.text += "♥ "


func _check_enemy_collisions() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if not collider is CharacterBody2D:
			continue
		if collider.is_in_group("tornadoes"):
			collider._check_player_collision()
		elif collider.is_in_group("enemies"):
			if collision.get_normal().y < -0.5:
				_stomp(collider)
			else:
				_take_damage(collider)


func _stomp(enemy: CharacterBody2D) -> void:
	enemy.die()
	velocity.y = JUMP_BASE


func enemy_touched(enemy: CharacterBody2D) -> void:
	if not enemy.is_queued_for_deletion():
		_take_damage(enemy)


func tornado_touched(launch_velocity: float) -> void:
	velocity.y = launch_velocity


func _take_damage(enemy: CharacterBody2D) -> void:
	if _invincible_timer > 0 or enemy.is_queued_for_deletion():
		return
	_hp -= 1
	if _hp <= 0:
		get_tree().call_deferred("reload_current_scene")
		return
	_invincible_timer = INVINCIBILITY_TIME
	var away: float = signf(global_position.x - enemy.global_position.x)
	if away == 0:
		away = 1.0
	velocity.x = away * KNOCKBACK_HORIZONTAL
	velocity.y = KNOCKBACK_VERTICAL
