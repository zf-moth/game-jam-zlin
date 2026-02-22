extends Control

## Splash screen — shows Godot logo, then team logo, then transitions to main menu.

@onready var bg: ColorRect = $Background
@onready var godot_logo: TextureRect = $GodotLogo
@onready var team_logo: TextureRect = $TeamLogo
@onready var black_overlay: ColorRect = $BlackOverlay

const DARK_GREY := Color(0.058, 0.058, 0.058, 1.0)
const GREY := Color(0.467, 0.467, 0.467)  # #777777

func _ready() -> void:
	bg.color = DARK_GREY
	godot_logo.modulate.a = 0.0
	team_logo.modulate.a = 0.0
	black_overlay.color = Color(0, 0, 0, 1)

	await _run_sequence()

func _run_sequence() -> void:
	var t: Tween

	t = create_tween()
	t.set_parallel(true)
	t.tween_property(black_overlay, "color:a", 0.0, 1.0)
	t.tween_property(godot_logo, "modulate:a", 1.0, 1.0)
	await t.finished

	await get_tree().create_timer(2.0).timeout

	t = create_tween()
	t.set_parallel(true)
	t.tween_property(godot_logo, "modulate:a", 0.0, 0.8)
	t.tween_property(team_logo, "modulate:a", 1.0, 0.8).set_delay(0.4)
	t.tween_property(bg, "color", GREY, 1.2)
	await t.finished

	await get_tree().create_timer(2.0).timeout

	t = create_tween()
	t.tween_property(black_overlay, "color:a", 1.0, 0.8)
	await t.finished

	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
