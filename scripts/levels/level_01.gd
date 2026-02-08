extends Node2D


func _ready() -> void:
	$DeathZone.body_entered.connect(_on_death_zone_entered)
	$GoalZone.body_entered.connect(_on_goal_zone_entered)


func _on_death_zone_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().call_deferred("reload_current_scene")


func _on_goal_zone_entered(body: Node2D) -> void:
	if body.name == "Player":
		_show_victory()


func _show_victory() -> void:
	get_tree().paused = true

	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

	var label := Label.new()
	label.text = "Sieg!!!"
	label.add_theme_font_size_override("font_size", 80)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.scale = Vector2(0.1, 0.1)
	label.pivot_offset = Vector2(640, 360)
	label.modulate.a = 0.0
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(label)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween.set_parallel(true)
	var scale_tween := tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)
	scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_property(overlay, "color:a", 0.4, 0.5)

	tween.chain().tween_interval(1.5)
	tween.chain().tween_callback(_go_to_menu)


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
