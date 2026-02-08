extends CharacterBody2D

const SPEED := 80.0
const GRAVITY := 900.0
const ANIM_FPS := 8.0

var _direction := -1.0
var _anim_frame := 0
var _anim_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var floor_detector: RayCast2D = $FloorDetector


func _ready() -> void:
	add_to_group("enemies")
	_update_direction()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = _direction * SPEED
	move_and_slide()

	_check_player_collision()

	if is_on_wall() or (is_on_floor() and not floor_detector.is_colliding()):
		_direction *= -1.0
		_update_direction()

	_animate(delta)


func _update_direction() -> void:
	sprite.flip_h = _direction < 0
	floor_detector.target_position = Vector2(_direction * 20.0, 30.0)


func _animate(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % 6
	sprite.frame = _anim_frame


func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider.has_method("enemy_touched"):
			collider.enemy_touched(self)


func die() -> void:
	queue_free()
