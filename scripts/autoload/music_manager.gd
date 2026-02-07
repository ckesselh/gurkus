extends Node

var _tracks: Array[AudioStream] = [
	preload("res://assets/audio/gurkus_song_01.mp3"),
	preload("res://assets/audio/gurkus_song_02.mp3"),
]

var _player: AudioStreamPlayer
var _shuffled: Array[AudioStream] = []
var _current_index := 0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.finished.connect(_on_track_finished)
	add_child(_player)
	_shuffle_and_play()


func _shuffle_and_play() -> void:
	_shuffled = _tracks.duplicate()
	_shuffled.shuffle()
	_current_index = 0
	_play_current()


func _play_current() -> void:
	_player.stream = _shuffled[_current_index]
	_player.play()


func _on_track_finished() -> void:
	_current_index += 1
	if _current_index >= _shuffled.size():
		_shuffle_and_play()
	else:
		_play_current()
