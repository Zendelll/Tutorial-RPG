extends Node
class_name enemy_stats_component


@export_group("Move")
@export var move_speed = 60

@export_group("Battle")
@export var max_health : int = 1
@export var damage : int = 1
@export var knockback_resistance = 400

@onready var health = max_health
signal no_health

func take_damage(input_damage: int):
	health -= input_damage
	if health <= 0: emit_signal("no_health")
