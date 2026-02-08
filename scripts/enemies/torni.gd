extends CharacterBody2D

const SPEED := 160.0
const DIRECTION_CHANGE_TIME := 0.5
const ANIM_FPS := 10.0
const LAUNCH_VELOCITY := -2600.0
const MAX_HEIGHT_ABOVE_SPAWN := 80.0
const PLAYER_BIAS_CHANCE := 0.6

var _anim_frame := 0
var _anim_timer := 0.0
var _direction_timer := 0.0
var _move_dir := Vector2.ZERO
var _spawn_y := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("tornadoes")
	_spawn_y = global_position.y
	_pick_direction()


func _physics_process(delta: float) -> void:
	_direction_timer -= delta
	if _direction_timer <= 0:
		_pick_direction()

	velocity = _move_dir * SPEED

	# Stay near ground level
	if global_position.y < _spawn_y - MAX_HEIGHT_ABOVE_SPAWN:
		_move_dir.y = absf(_move_dir.y)
		velocity.y = absf(velocity.y)
	elif global_position.y > _spawn_y + 10.0:
		_move_dir.y = -absf(_move_dir.y)
		velocity.y = -absf(velocity.y)

	move_and_slide()

	if is_on_wall():
		_move_dir.x *= -1.0

	_check_player_collision()
	_animate(delta)


func _pick_direction() -> void:
	var player: Node2D = get_tree().current_scene.get_node_or_null("Player")
	var angle := randf_range(-0.5, 0.5)
	var base_dir := 1.0 if randf() > 0.5 else -1.0

	if player and randf() < PLAYER_BIAS_CHANCE:
		var dir_x := player.global_position.x - global_position.x
		base_dir = signf(dir_x)
		if base_dir == 0:
			base_dir = 1.0

	_move_dir = Vector2(base_dir * cos(angle), sin(angle))
	_direction_timer = DIRECTION_CHANGE_TIME + randf() * 0.4


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider.has_method("tornado_touched"):
			collider.tornado_touched(LAUNCH_VELOCITY)


func die() -> void:
	call_deferred("queue_free")


func _animate(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % 6
	sprite.frame = _anim_frame
