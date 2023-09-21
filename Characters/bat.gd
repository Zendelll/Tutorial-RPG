extends CharacterBody2D

@export var knockback_force = 150
@export var knockback_resistance = 200
var knockback = Vector2.ZERO
var death : bool = false

@onready var stats = $Stats
@onready var death_effect = $Enemy_death
@onready var hit_effect = $Hit_effect
@onready var sprite = $Bat_sprite

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_resistance * delta)
	velocity = knockback
	move_and_slide()

func _on_hurtbox_area_entered(area):
	if "Hitbox" in area.name:
		knockback = area.get_parent().mouse_vector * knockback_force
		stats.take_damage(area.get_parent().get_node("Stats").damage)
		hit_effect.play_animation()

func _on_stats_no_health():
	sprite.visible = false
	hit_effect._hide_self()
	knockback = Vector2.ZERO
	death_effect.play_animation()

func _on_enemy_death_animation_finished():
	queue_free()
