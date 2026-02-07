extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -350.0
const GRAVITY := 800.0

const FIREBALL_COOLDOWN := 15.0
const SHOOT_ANIM_FPS := 20.0
const SHOOT_FRAME_COUNT := 30
const SHOOT_SPAWN_FRAME := 15

const FireballScene := preload("res://scenes/player/fireball.tscn")

@onready var walk_sprite: Sprite2D = $WalkSprite
@onready var shoot_sprite: Sprite2D = $ShootSprite
@onready var cooldown_bar: ColorRect = $CooldownUI/Bar
@onready var cooldown_bg: ColorRect = $CooldownUI/Background

var _anim_frame := 0
var _anim_timer := 0.0
const ANIM_FPS := 10.0

var _cooldown_remaining := 0.0
var _is_shooting := false
var _shoot_frame := 0
var _shoot_timer := 0.0
var _fireball_spawned := false
var _facing_right := true


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

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
		cooldown_bg.visible = true
		cooldown_bar.visible = true
		var ratio := _cooldown_remaining / FIREBALL_COOLDOWN
		cooldown_bar.size.x = 80.0 * (1.0 - ratio)
	else:
		cooldown_bg.visible = false
		cooldown_bar.visible = false
