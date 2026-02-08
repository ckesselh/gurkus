extends Control


func _ready() -> void:
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_01.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
