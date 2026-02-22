extends Node2D

@export var animation_tree: AnimationTree
@onready var player: CharacterBody2D = get_owner()

func _physics_process(_delta: float) -> void:
	var velocity: Vector2 = player.velocity
	# Direction is based on mouse position relative to player
	var mouse_dir: Vector2 = player.get_global_mouse_position() - player.global_position
	var blend_position: Vector2 = _snap_to_isometric(mouse_dir)

	if velocity.length() < 10.0:
		animation_tree.set("parameters/conditions/idle", true)
		animation_tree.set("parameters/conditions/walk", false)
		animation_tree.set("parameters/Idle/blend_position", blend_position)
	else:
		animation_tree.set("parameters/conditions/idle", false)
		animation_tree.set("parameters/conditions/walk", true)
		animation_tree.set("parameters/Walk/blend_position", blend_position)

# Snap direction to the nearest isometric diagonal.
# Only 4 valid directions: top-right, top-left, bottom-right, bottom-left.
func _snap_to_isometric(dir: Vector2) -> Vector2:
	var dir_x: float
	var dir_y: float

	if dir.x >= 0:
		dir_x = 1.0
	else:
		dir_x = -1.0

	if dir.y >= 0:
		dir_y = 1.0
	else:
		dir_y = -1.0

	return Vector2(dir_x, dir_y).normalized()
