extends Control

@onready var logo: TextureRect = $Logo

var _logo_base_y: float
var _time: float = 0.0
const BOB_AMPLITUDE: float = 8.0
const BOB_SPEED: float = 2.0
const ROTATION_AMPLITUDE: float = 0.02
const ROTATION_SPEED: float = 1.5

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	_logo_base_y = logo.position.y
	logo.pivot_offset = logo.size * 0.5
	logo.position += logo.pivot_offset * (logo.scale - Vector2.ONE)
	_logo_base_y = logo.position.y

func _process(delta: float) -> void:
	_time += delta
	logo.position.y = _logo_base_y + sin(_time * BOB_SPEED) * BOB_AMPLITUDE
	logo.rotation = sin(_time * ROTATION_SPEED) * ROTATION_AMPLITUDE

func _on_start_pressed() -> void:
	SceneTransition.change_scene("res://world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
