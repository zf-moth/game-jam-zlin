extends CharacterBody2D

# Enemy controller - follows the player, attacks when in range, and drops a battery on death.

@export var speed: float = 100.0
@export var attack_range: float = 300.0
@export var detection_range: float = 500.0
@export var health: float = 100.0
@export var bullet_scene: PackedScene
@export var battery_scene: PackedScene = preload("res://scenes/battery.tscn")
@export var bullet_color: Color = Color(1.0, 0.3, 0.3)
@export var knockback_force: float = 200.0
@export var knockback_decay: float = 0.1
@export var show_healthbar: bool = false

const PLAYER_HITBOX_OFFSET: Vector2 = Vector2(1, -72)

@onready var sprite: AnimatedSprite2D = $EnemySprite
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var front_left: Node2D = $FrontLeftPoint
@onready var front_right: Node2D = $FrontRightPoint
@onready var back_left: Node2D = $BackLeftPoint
@onready var back_right: Node2D = $BackRightPoint
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound

var player: Node2D
var is_attacking: bool = false
var has_fired_this_attack: bool = false
var is_dying: bool = false
var hp_bar: ProgressBar
var max_health: float
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	player = get_parent().get_node("Player")
	sprite.frame_changed.connect(_on_frame_changed)
	max_health = health
	collision_layer = 8
	collision_mask = 1 + 2
	if show_healthbar:
		hp_bar = ProgressBar.new()
		hp_bar.max_value = max_health
		hp_bar.value = health
		hp_bar.show_percentage = false
		hp_bar.z_index = 2
		hp_bar.custom_minimum_size = Vector2(60, 6)
		hp_bar.position = Vector2(-30, -130)
		hp_bar.modulate = Color.RED
		add_child(hp_bar)
	explosion.hide()
	explosion.animation_finished.connect(_on_explosion_finished)

func _physics_process(delta: float) -> void:
	if player == null or is_dying:
		return

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay)
		move_and_slide()
		return
	knockback_velocity = Vector2.ZERO

	var target_pos: Vector2 = player.global_position + PLAYER_HITBOX_OFFSET
	var direction: Vector2 = (target_pos - global_position).normalized()
	var distance: float = global_position.distance_to(target_pos)
	var facing_front: bool = direction.y > 0

	if direction.x > 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	if is_attacking:
		return

	if distance <= attack_range:
		velocity = Vector2.ZERO
		is_attacking = true
		has_fired_this_attack = false
		if facing_front:
			sprite.play("attack_front")
		else:
			sprite.play("attack_back")
	elif distance <= detection_range:
		if facing_front:
			if sprite.animation != "idle_front":
				sprite.play("idle_front")
		else:
			if sprite.animation != "idle_back":
				sprite.play("idle_back")
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if facing_front:
			if sprite.animation != "idle_front":
				sprite.play("idle_front")
		else:
			if sprite.animation != "idle_back":
				sprite.play("idle_back")

func _on_frame_changed() -> void:
	if not is_attacking:
		return
	if sprite.frame == 7 and not has_fired_this_attack:
		_fire_bullet()
		has_fired_this_attack = true
	if sprite.frame >= sprite.sprite_frames.get_frame_count(sprite.animation) - 1:
		is_attacking = false

func _fire_bullet() -> void:
	if bullet_scene == null or player == null:
		return

	var spawn_point: Node2D
	var anim: String = sprite.animation
	var flipped: bool = sprite.flip_h

	if anim == "attack_front":
		if flipped:
			spawn_point = front_right
		else:
			spawn_point = front_left
	else:
		if flipped:
			spawn_point = back_right
		else:
			spawn_point = back_left

	var bullet: Node = bullet_scene.instantiate()
	bullet.collision_layer = 16
	bullet.collision_mask = 1
	bullet.modulate = bullet_color
	get_parent().add_child(bullet)
	bullet.global_position = spawn_point.global_position

	var target_pos: Vector2 = player.global_position + PLAYER_HITBOX_OFFSET
	var aim_dir: Vector2 = (target_pos - spawn_point.global_position).normalized()
	bullet.setup(aim_dir, 500)

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if is_dying:
		return
	health -= amount
	damage_sound.play(0.23)
	if hp_bar:
		hp_bar.value = health
	if direction != Vector2.ZERO:
		knockback_velocity = direction * knockback_force
	_flash_red()
	if health <= 0:
		_die()

func _flash_red() -> void:
	sprite.modulate = Color(1, 0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _die() -> void:
	is_dying = true
	_drop_battery()
	sprite.hide()
	if hp_bar:
		hp_bar.hide()
	$Collision.set_deferred("disabled", true)
	$Hitbox/HitboxShape.set_deferred("disabled", true)
	explosion.show()
	explosion.play("default")

func _on_explosion_finished() -> void:
	queue_free()

func _drop_battery() -> void:
	if battery_scene == null:
		return
	var battery: Node2D = battery_scene.instantiate()
	battery.global_position = global_position
	get_parent().call_deferred("add_child", battery)
