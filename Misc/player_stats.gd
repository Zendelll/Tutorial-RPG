extends Node
class_name player_stats_component

@export_group("Battle")
@export var hitbox: hitbox_component
@export var max_health : int = 3
@onready var health = max_health
@export var damage : int = 1
@export var invincibility_time = 0.5

@export_group("Move")
@export var move_speed : float = 100

@export_group("Roll")
@export var roll_speed : float = 200
@export var roll_cooldown : float = 0.8
@export var max_roll_cooldown : float = 2
@export var max_roll_charges : int = 2
var roll_charges : int = max_roll_charges

@onready var hp_ui = self.get_parent().get_node("Player_camera2D").get_node("HP")
@onready var roll_ui = self.get_parent().get_node("Player_camera2D").get_node("Roll")

signal no_health
signal health_changed

func _ready():
	hp_ui.max_value = max_health
	hp_ui.value = health
	roll_ui.max_value = max_roll_charges
	roll_ui.value = roll_charges

func take_damage(input_damage: int):
	if health > 0:
		health -= input_damage
		hp_ui.value = health
		print(hp_ui.value)
		if health <= 0: emit_signal("no_health")

func change_roll_charges(change: int):
	roll_charges += change
	roll_ui.value = roll_charges
