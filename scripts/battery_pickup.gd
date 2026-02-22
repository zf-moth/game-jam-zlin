extends Node2D

# Battery pickup, dropped by enemies on death.
# Floats toward the player when in magnet range.
# Recharges the player on contact.

@export var heal_amount: float = 20.0
@export var magnet_speed: float = 400.0
@export var max_magnet_speed: float = 800.0
@export var acceleration: float = 1200.0
@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 3.0

var _player: Node2D = null
var _being_sucked: bool = false
var _current_speed: float = 0.0
var _base_y: float = 0.0
var _bob_time: float = 0.0

func _ready() -> void:
	_base_y = global_position.y
	_bob_time = randf() * TAU
	var tween := create_tween()
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _physics_process(delta: float) -> void:
	_bob_time += delta * bob_speed
	if not _being_sucked:
		global_position.y = _base_y + sin(_bob_time) * bob_amplitude
	
	if _being_sucked and _player:
		_current_speed = minf(_current_speed + acceleration * delta, max_magnet_speed)
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		global_position += dir * _current_speed * delta
		var dist: float = global_position.distance_to(_player.global_position)
		if dist < 20.0:
			_collect()

func start_magnet(player: Node2D) -> void:
	if _being_sucked:
		return
	_player = player
	_being_sucked = true
	_current_speed = magnet_speed

func _collect() -> void:
	if _player and _player.has_method("collect_battery"):
		_player.collect_battery(heal_amount)
	queue_free()
