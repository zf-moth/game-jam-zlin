extends Area2D

# Hitbox detects bullets (RigidBody2D) entering it
# Calls take_damage() on the parent node and destroys the bullet

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Check if it's a bullet with damage
	if body.has_method("setup") and "damage" in body:
		var parent_node: Node = get_parent()
		if parent_node.has_method("take_damage"):
			var bullet_dir : Vector2 = body.linear_velocity.normalized() if body is RigidBody2D else Vector2.ZERO
			if "knockback_velocity" in parent_node:
				parent_node.take_damage(body.damage, bullet_dir)
			else:
				parent_node.take_damage(body.damage)
		body.queue_free()
