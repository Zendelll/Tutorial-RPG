extends Area2D
class_name hurtbox_component

signal got_hit(damage: int, knockback_vector: Vector2)

func take_damage(damage: int, knockback_vector = Vector2.ZERO):
	emit_signal("got_hit", damage, knockback_vector.normalized())
