extends CharacterBody2D

"""
В начале кадра ставим приближаем knockback и ставим это ускорением
Если оно 0, то фактически просто обнулили ускорение
knockback - это любое ускорение, которое не должно обнуляться
stats.knockback_resistance - насколько быстро противник будет бороться с этим ускорением

Стейты:
	NONE      - В прошлом кадре закончили действие, в этом пока не начали
	IDLE      - Стоим на месте
	WANDER    - Ходим-бродим-патрулируем
	CHASE     - Увидели игрока, идем за ним
	TELEGRAPH - Показываем начало атаки, если это необходимо, но не атакуем
	ATTACK    - Атакуем, например рывком вперед
	DEATH     - Умираем

is_action_started - начали действие в текущем стейте (если его нужно начать 1 раз)
queue_state - стейт, который будет следующим
vector_length_for_attack - расстояние, на котором начинаем атаку или телеграф

По текущему стейту и стейту в очереди опеределяем, какую логику включаем в кадре
Все ускорение должно прибавляться к текущему ускорению, чтобы в итоге все посчиталось верно

После отработки соответствующей логики возвращаемся в основную функцию
И делаем move_and_slide() один раз
"""

enum { NONE, IDLE, WANDER, CHASE, TELEGRAPH, ATTACK, DEATH }

@export_group("Knockback")
@export var knockback_force = 200
@export var knockback_attack_force = 250

@export_group("Attack")
@export var vector_length_for_attack = 25

#Stats
@onready var stats = $Stats

#Move
var direction = Vector2.ZERO
var knockback = Vector2.ZERO
var target_position = Vector2.ZERO

#State
var state = IDLE
var is_action_started = false
var queue_state = IDLE
@onready var detection_zone = $Player_detection_zone

#Animation
@onready var death_effect = $Enemy_death
@onready var hit_effect = $Hit_effect
@onready var sprite = $Bat_sprite

#Sound
@onready var death_sound = $Death_sound
@onready var hit_sound = $Hit_sound

#Potentionally useless
var death : bool = false

func _process(_delta):
		sprite.flip_h = direction.x < 0

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, stats.knockback_resistance * delta)
	velocity = knockback
	move_and_slide()
	
	if state == IDLE:
		velocity = Vector2.ZERO
	elif state == WANDER:
		pass
	elif state == CHASE:
		var player_vector = detection_zone.player.global_position - global_position
		direction = player_vector.normalized()
		velocity = direction * stats.move_speed
		if player_vector.length() < vector_length_for_attack and knockback == Vector2.ZERO:
			knockback = direction * knockback_attack_force
			velocity = knockback
	move_and_slide()

func _on_stats_no_health():
	state = IDLE
	get_node("Hurtbox").queue_free()
	get_node("Hitbox").queue_free()
	sprite.visible = false
	hit_effect._hide_self()
	knockback = Vector2.ZERO
	death_effect.play_animation()
	death_sound.play()

func _on_enemy_death_animation_finished():
	queue_free()

func _on_player_detection_zone_player_found():
	state = CHASE

func _on_player_detection_zone_player_lost():
	state = IDLE

func _on_hurtbox_got_hit(damage, knockback_vector):
	knockback = knockback_vector * knockback_force
	stats.take_damage(damage)
	hit_effect.play_animation()
	hit_sound.play()


func _on_hitbox_hurtbox_found(area):
	area.take_damage(stats.damage, Vector2.ZERO)
