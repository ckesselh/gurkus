extends Node2D


func _ready() -> void:
	$DeathZone.body_entered.connect(_on_death_zone_entered)
	$GoalZone.body_entered.connect(_on_goal_zone_entered)


func _on_death_zone_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().reload_current_scene()


func _on_goal_zone_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
