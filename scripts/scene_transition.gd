extends CanvasLayer

## Scene transition manager - autoload singleton.
## Call SceneTransition.change_scene("res://path.tscn") from anywhere.

@onready var color_rect: ColorRect = $ColorRect
var _shader_mat: ShaderMaterial

const TRANSITION_DURATION: float = 0.6

func _ready() -> void:
	layer = 128
	var shader := load("res://shaders/scene_transition.gdshader") as Shader
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("progress", 0.0)
	color_rect.material = _shader_mat
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene(target_scene: String, duration: float = TRANSITION_DURATION) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = false
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration)
	await tween.finished
	_set_progress(1.0)
	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_set_progress(1.0)
	var tween_in := create_tween()
	tween_in.tween_method(_set_progress, 1.0, 0.0, duration)
	await tween_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene_cut(target_scene: String, duration: float = TRANSITION_DURATION) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = false
	color_rect.material = null
	color_rect.color = Color(0, 0, 0, 1)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	color_rect.material = _shader_mat
	_set_progress(0.0)
	color_rect.color = Color(1, 1, 1, 1)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_progress(value: float) -> void:
	_shader_mat.set_shader_parameter("progress", value)
