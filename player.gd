extends CharacterBody2D

const SPEED = 500
const KNOCKBACK_FORCE = 300.0
const KNOCKBACK_DECAY = 0.1

@export var max_health: float = 100.0
@export var bullet_color: Color = Color.WHITE
@export_group("Spark Timings")
@export var red_duration: float = 1.0
@export var green_duration: float = 0.3
@export var jam_duration: float = 2.0
@export_group("Dash")
@export var dash_speed: float = 1500.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.8
@export var afterimage_count: int = 5
@export_group("Energy Drain")
@export var energy_drain_rate: float = 2.0  ## Health lost per second
@export_group("Camera")
@export var camera_base_zoom: float = 1.5  ## Default zoom level (higher = more zoomed in)
@export var camera_focus_range: float = 400.0  ## How close enemies must be to pull the camera
@export var camera_focus_release_range: float = 550.0  ## Enemies must be this far to release focus
@export var camera_focus_weight: float = 0.3  ## How much camera shifts toward enemies (0-1)
@export var camera_zoom_out_min: float = 1.0  ## Minimum zoom when enemies are near
@export var camera_lerp_speed: float = 3.0  ## How fast the camera transitions
@export var camera_return_speed: float = 1.0  ## How fast camera returns to player (slower = stickier)
@export_group("Hit Effects")
@export var shake_intensity: float = 8.0
@export var shake_duration: float = 0.25
@export var vignette_fade_duration: float = 0.4

var health: float
var knockback_velocity: Vector2 = Vector2.ZERO
var hp_bar: ProgressBar

# Dash state
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var afterimage_interval: float = 0.0
var afterimage_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var camera: Camera2D = $Camera2D
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound
@onready var dash_sound: AudioStreamPlayer2D = $DashSound

var _health_mat: ShaderMaterial
var _vignette_rect: ColorRect
var _vignette_mat: ShaderMaterial
var _shake_timer: float = 0.0
var _shake_strength: float = 0.0
var _is_dead: bool = false
var _hp_bar_tween: Tween = null
var _camera_target_offset: Vector2 = Vector2.ZERO
var _camera_target_zoom: float = 1.5
var _camera_focused: bool = false

func _ready() -> void:
	health = max_health
	# Player collision: layer 2 (Player), mask = walls (1) + enemies (8)
	collision_layer = 2
	collision_mask = 1 + 8
	# Create HP bar above the player
	hp_bar = ProgressBar.new()
	hp_bar.max_value = max_health
	hp_bar.value = health
	hp_bar.z_index = 2
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(60, 6)
	hp_bar.position = Vector2(-30, -140)
	hp_bar.modulate = Color.GREEN
	add_child(hp_bar)
	# Connect magnet area
	var magnet: Area2D = $MagnetArea
	magnet.area_entered.connect(_on_magnet_area_entered)
	# Setup health shader on sprite
	var shader := load("res://shaders/player_health.gdshader") as Shader
	_health_mat = ShaderMaterial.new()
	_health_mat.shader = shader
	sprite.material = _health_mat
	_update_health_shader()
	# Create hit vignette overlay on camera
	_setup_hit_vignette()
	# Show HP bar at game start then hide after 5 seconds
	hp_bar.modulate.a = 1.0
	_flash_hp_bar(5.0)
	# Set initial camera zoom
	camera.zoom = Vector2(camera_base_zoom, camera_base_zoom)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not is_dashing and dash_cooldown_timer <= 0:
			_start_dash()

# Movement
func _physics_process(delta: float) -> void:
	# Energy drain over time
	if not _is_dead:
		health -= energy_drain_rate * delta
		if hp_bar:
			hp_bar.value = health
		_update_health_shader()
		if health <= 0:
			_is_dead = true
			SceneTransition.change_scene_cut("res://scenes/death_scene.tscn", 0.8)
			return

	# Camera shake
	if _shake_timer > 0:
		_shake_timer -= delta
		var shake_amount: float = _shake_strength * (_shake_timer / shake_duration)
		var shake_offset := Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		camera.offset = _camera_target_offset + shake_offset
		if _shake_timer <= 0:
			camera.offset = _camera_target_offset
	else:
		camera.offset = camera.offset.lerp(_camera_target_offset, camera_lerp_speed * delta)

	# Dynamic camera focus on nearby enemies
	_update_camera_focus(delta)

	# Dash cooldown countdown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	if is_dashing:
		dash_timer -= delta
		afterimage_timer -= delta
		if afterimage_timer <= 0:
			_spawn_afterimage()
			afterimage_timer = afterimage_interval
		velocity = dash_direction * dash_speed
		move_and_slide()
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		return

	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized() * SPEED
		velocity = Vector2(input_vector.x, input_vector.y / 2) + knockback_velocity
	else:
		velocity = knockback_velocity

	# Decay knockback over time
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY)

	move_and_slide()

func _start_dash() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	dash_direction = (mouse_pos - global_position).normalized()
	is_dashing = true
	dash_sound.play(0.54)
	dash_timer = dash_duration
	afterimage_interval = dash_duration / afterimage_count
	afterimage_timer = 0.0
	knockback_velocity = Vector2.ZERO

func _spawn_afterimage() -> void:
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.region_enabled = sprite.region_enabled
	ghost.region_rect = sprite.region_rect
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.global_scale
	ghost.rotation = sprite.global_rotation
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.offset = sprite.offset
	ghost.modulate = Color(0.6, 0.6, 0.6, 0.6)
	ghost.top_level = true
	ghost.show_behind_parent = true
	get_tree().current_scene.add_child(ghost)
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ghost.queue_free)

# Called by the gun script when shooting
func apply_knockback(direction: Vector2) -> void:
	if is_dashing:
		return # Don't interrupt dash with knockback
	knockback_velocity = - direction * KNOCKBACK_FORCE

func collect_battery(amount: float) -> void:
	health = minf(health + amount, max_health)
	if hp_bar:
		hp_bar.value = health
	_update_health_shader()
	_flash_hp_bar(1.5)

# Magnet pickup
func _on_magnet_area_entered(area: Area2D) -> void:
	var battery: Node = area.get_parent()
	if battery.has_method("start_magnet"):
		battery.start_magnet(self)

func take_damage(amount: float, _direction: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	damage_sound.play(0.14)
	if hp_bar:
		hp_bar.value = health
	_update_health_shader()
	_hit_effect()
	_flash_hp_bar(1.5)
	if health <= 0 and not _is_dead:
		_is_dead = true
		SceneTransition.change_scene_cut("res://scenes/death_scene.tscn", 0.8)

func _update_health_shader() -> void:
	if _health_mat:
		var shader_health = clamp(health, 0, max_health)
		_health_mat.set_shader_parameter("health_ratio", shader_health / max_health)

func _setup_hit_vignette() -> void:
	var shader := load("res://shaders/hit_vignette.gdshader") as Shader
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = shader
	_vignette_mat.set_shader_parameter("intensity", 0.0)
	_vignette_rect = ColorRect.new()
	_vignette_rect.material = _vignette_mat
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cover entire viewport via CanvasLayer so it stays screen-fixed
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	_vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(_vignette_rect)
	add_child(canvas_layer)

func _hit_effect() -> void:
	# Camera shake
	_shake_timer = shake_duration
	_shake_strength = shake_intensity
	# Red vignette flash
	if _vignette_mat:
		_vignette_mat.set_shader_parameter("intensity", 1.0)
		var tween := create_tween()
		tween.tween_method(_set_vignette_intensity, 1.0, 0.0, vignette_fade_duration)

func _set_vignette_intensity(value: float) -> void:
	if _vignette_mat:
		_vignette_mat.set_shader_parameter("intensity", value)

func _flash_hp_bar(visible_duration: float = 1.5) -> void:
	if not hp_bar:
		return
	if _hp_bar_tween:
		_hp_bar_tween.kill()
	hp_bar.modulate.a = 1.0
	_hp_bar_tween = create_tween()
	_hp_bar_tween.tween_interval(visible_duration)
	_hp_bar_tween.tween_property(hp_bar, "modulate:a", 0.0, 0.5)

func _update_camera_focus(delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	# Use a larger range to release focus than to enter it (hysteresis)
	var active_range: float = camera_focus_release_range if _camera_focused else camera_focus_range
	var nearby_positions: Array[Vector2] = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < active_range:
			nearby_positions.append(enemy.global_position)

	if nearby_positions.is_empty():
		# No enemies nearby — slowly return to default (slightly above player)
		_camera_focused = false
		_camera_target_offset = Vector2(0, -60)
		_camera_target_zoom = camera_base_zoom
		# Use slower return speed
		camera.offset = camera.offset.lerp(_camera_target_offset, camera_return_speed * delta)
		camera.zoom = camera.zoom.lerp(Vector2(camera_base_zoom, camera_base_zoom), camera_return_speed * delta)
	else:
		_camera_focused = true
		# Average position of nearby enemies
		var avg_pos := Vector2.ZERO
		for pos in nearby_positions:
			avg_pos += pos
		avg_pos /= nearby_positions.size()
		# Offset camera toward the midpoint between player and enemies
		var midpoint: Vector2 = (avg_pos - global_position) * camera_focus_weight
		_camera_target_offset = midpoint
		# Zoom out based on distance to farthest nearby enemy
		var max_dist: float = 0.0
		for pos in nearby_positions:
			max_dist = maxf(max_dist, global_position.distance_to(pos))
		var zoom_factor: float = 1.0 - (max_dist / camera_focus_release_range)
		_camera_target_zoom = lerpf(camera_zoom_out_min, camera_base_zoom, zoom_factor)
		camera.zoom = camera.zoom.lerp(Vector2(_camera_target_zoom, _camera_target_zoom), camera_lerp_speed * delta)
