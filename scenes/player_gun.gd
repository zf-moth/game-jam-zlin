extends Node2D

# Gun controller with Spark color mechanic
# Yellow = ready (normal shot), Green = power window (2x shot), Red = cooldown (jam if fired)
# Cycle: Yellow → fire → Red → Green → Yellow

@onready var player: CharacterBody2D = get_parent()
@onready var bullet_spawner: Node2D = $BulletSpawner
@onready var spark: Sprite2D = get_parent().get_node("Spark")
@onready var gun_sprite: Sprite2D = $Sprite2D
@onready var sparky_jam: AnimatedSprite2D = $Sparky

enum SparkState {YELLOW, RED, GREEN, JAMMED}
var spark_state: SparkState = SparkState.YELLOW
var spark_timer: float = 0.0


const NORMAL_DAMAGE: float = 25.0
const NORMAL_SPEED: float = 800.0
const POWER_DAMAGE: float = 50.0
const POWER_SPEED: float = 800.0
const POWER_SCALE: float = 2.0

func _ready() -> void:
	spark.self_modulate = Color.YELLOW
	sparky_jam.hide()

func _physics_process(delta: float) -> void:
	# Rotate gun toward mouse
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).normalized()
	if direction.x < 0:
		scale.y = -0.1
	else:
		scale.y = 0.1
	rotation = direction.angle()

	# Spark timer state machine
	if spark_state == SparkState.RED:
		spark_timer -= delta
		if spark_timer <= 0:
			_set_spark_state(SparkState.GREEN)
	elif spark_state == SparkState.GREEN:
		spark_timer -= delta
		if spark_timer <= 0:
			_set_spark_state(SparkState.YELLOW)
	elif spark_state == SparkState.JAMMED:
		spark_timer -= delta
		if spark_timer <= 0:
			_set_spark_state(SparkState.YELLOW)
			# Restore gun color
			sparky_jam.hide()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	match spark_state:
		SparkState.YELLOW:
			_fire_bullet(NORMAL_DAMAGE, NORMAL_SPEED, 1.0)
			_set_spark_state(SparkState.RED)
		SparkState.GREEN:
			_fire_bullet(POWER_DAMAGE, POWER_SPEED, POWER_SCALE)
			_set_spark_state(SparkState.RED)
		SparkState.RED:
			# Gun jams!
			_set_spark_state(SparkState.JAMMED)
			sparky_jam.show()
		SparkState.JAMMED:
			# Can't shoot while jammed
			pass

func _fire_bullet(damage: float, speed: float, bullet_scale: float) -> void:
	var bullet_scene = preload("res://laser_bullet.tscn")
	var bullet_instance = bullet_scene.instantiate()
	# Player bullet: layer 3 (val 4), mask = walls only (1)
	bullet_instance.collision_layer = 4
	bullet_instance.collision_mask = 1
	bullet_instance.damage = damage
	bullet_instance.size_multiplier = bullet_scale
	bullet_instance.modulate = player.bullet_color
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = bullet_spawner.global_position
	var direction: Vector2 = Vector2(cos(rotation), sin(rotation))
	bullet_instance.setup(direction, speed)
	# Apply knockback to player
	player.apply_knockback(direction)

func _set_spark_state(new_state: SparkState) -> void:
	spark_state = new_state
	match new_state:
		SparkState.YELLOW:
			spark.self_modulate = Color.YELLOW
			spark_timer = 0.0
		SparkState.RED:
			spark.self_modulate = Color.RED
			spark_timer = player.red_duration
		SparkState.GREEN:
			spark.self_modulate = Color.GREEN
			spark_timer = player.green_duration
		SparkState.JAMMED:
			spark.self_modulate = Color.RED
			spark_timer = player.jam_duration
