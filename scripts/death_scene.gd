extends Node2D

var _transitioning: bool = false
@onready var shatter_sound: AudioStreamPlayer = $ShatterSound
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim_sprite.frame_changed.connect(_on_frame_changed)

func _on_frame_changed() -> void:
	if anim_sprite.frame == 10:
		shatter_sound.play()

func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event is InputEventMouseButton and event.pressed:
		_transitioning = true
		SceneTransition.change_scene_cut("res://scenes/main_menu.tscn", 0.8)
