extends RigidBody2D

# Bullet with damage

var damage: float = 25.0
var size_multiplier: float = 1.0
const LIFETIME: float = 3.0

func _ready() -> void:
	gravity_scale = 0
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(_on_timeout)
	if has_node("ShootSound"):
		$ShootSound.play(1.0)

func setup(direction: Vector2, speed: float) -> void:
	linear_velocity = direction * speed
	rotation = direction.angle()
	if size_multiplier != 1.0:
		for child in get_children():
			child.scale *= size_multiplier

func _on_timeout() -> void:
	queue_free()

func _on_body_entered(_body: Node) -> void:
	queue_free()
