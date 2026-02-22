extends CanvasLayer

## Pause menu overlay - only active in the world scene.
## Toggle with Escape key. Pauses the game tree.

const WORLD_SCENE := "res://world.tscn"

@onready var panel: Control = $Panel
@onready var resume_btn: TextureButton = $Panel/ResumeButton
@onready var quit_btn: TextureButton = $Panel/QuitButton

var is_paused: bool = false

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	resume_btn.pressed.connect(_on_resume)
	quit_btn.pressed.connect(_on_quit)

func _is_in_world() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == WORLD_SCENE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_in_world():
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	is_paused = not is_paused
	panel.visible = is_paused
	get_tree().paused = is_paused

func _on_resume() -> void:
	_toggle_pause()

func _on_quit() -> void:
	is_paused = false
	panel.visible = false
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/main_menu.tscn")
