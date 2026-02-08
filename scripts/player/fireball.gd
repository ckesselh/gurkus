extends Area2D

const SPEED := 400.0
const LIFETIME := 3.0

var direction := 1.0
var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += SPEED * direction * delta
	_age += delta
	if _age >= LIFETIME:
		call_deferred("queue_free")


func _draw() -> void:
	# Outer glow
	draw_circle(Vector2.ZERO, 12, Color(1.0, 0.4, 0.0, 0.3))
	# Core
	draw_circle(Vector2.ZERO, 8, Color(1.0, 0.6, 0.0, 0.9))
	# Hot center
	draw_circle(Vector2.ZERO, 4, Color(1.0, 1.0, 0.5, 1.0))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("die"):
		body.die()
	call_deferred("queue_free")
