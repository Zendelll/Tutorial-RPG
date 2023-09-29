extends Area2D
class_name hitbox_component

signal hurtbox_found(area: Area2D)

func _on_area_entered(area):
	if "hurtbox" in area.name.to_lower():
		emit_signal("hurtbox_found", area)
