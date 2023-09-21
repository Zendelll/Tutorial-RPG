extends Node

@export var max_health : int = 1
@export var damage : int = 1

@onready var health = max_health

signal no_health

func take_damage(input_damage: int):
	health -= input_damage
	if health <= 0: emit_signal("no_health")
