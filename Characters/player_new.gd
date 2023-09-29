extends CharacterBody2D
class_name player
"""
input_direction - считается всегда в начале кадра в физике, потом используется при надобности
mouse_direction - аналогично считается в каждом кадре

current_state - текущий стейт                      - Говорят о том, что за действие идет
is_action_started - стартовали ли анимацию         - Решаем, может ли нужное его прервать
queue_state - стейт, который по инпуну следующий   - И какое в данный момент в очереди

last_animation - анимация, которая стартовала в прошлый раз. По ней можем понять направление

### knockback скорее для противников, либо добавлю, если персонажа нужно будет отбрасывать
Движение и отбрасывание считаем в начале кадра, суммируя все векторы, в конце функции выполняем
knockback отнимаем в начале кадра и устанавливаем в качестве ускорения в этом кадре
Движение прибавляем в момент инпута по надобности

Логика кадра:
	1. Обнуляем ускорение (если только не делаем рывок)
	2. Считываем инпуты
	3. По инпутам добавляем действие в очередь
	4. Если можем, производим действие из очереди (если прошлое закончилось или можем прервать) 
		Иначе пропускаем
	5. Применяем движение в кадре, если ускорение не равно Vector2.ZERO

"""

#Misc
@onready var stats = $Stats

#Direction
var input_direction = Vector2.ZERO
var mouse_vector = Vector2.ZERO

#State-action
enum { NONE, IDLE, WALK, ATTACK, ROLL }
var current_state = NONE
var queue_state = NONE
var is_action_started = false

#Animation
var last_animation = "idle_down"
var finished_animation = ""
@onready var animation_player = $AnimationPlayer
@onready var hit_effect = $Hit_effect

#Roll
var roll_ready = true
@onready var roll_timer = $RollTimer
@onready var invincible_timer = $InvincibleTimer
@onready var hurtbox_collider = $Hurtbox/CollisionShape2D

#Sound
@onready var hit_sound = $Hit_sound

func _physics_process(_delta):
	if current_state != ROLL:
		velocity = Vector2.ZERO
		
	if finished_animation != "":
		finished_animation_logic()
		
	read_inputs()
	change_state()
	if velocity != Vector2.ZERO:
		move_and_slide()

#input func for move, mouse and all button inputs
func read_inputs():
	input_direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	mouse_vector = position.direction_to(get_global_mouse_position())
	
	if Input.is_action_just_pressed("roll"):
		queue_state = ROLL
	elif Input.is_action_just_pressed("attack"):
		queue_state = ATTACK

func change_state():
	if queue_state == ROLL:
		if input_direction != Vector2.ZERO and roll_ready and current_state != ROLL:
			roll_state()
		else:
			queue_state = NONE
	elif queue_state == ATTACK:
		if not is_action_started:
			attack_state()
		else:
			queue_state = NONE
	elif (queue_state == WALK or queue_state == NONE) and not is_action_started:
		move_state()

func move_state():
	play_move_animation(input_direction)
	velocity += input_direction * stats.move_speed

func attack_state():
	if not is_action_started:
		queue_state = NONE
		current_state = ATTACK
		is_action_started = true
		var animation_direction = get_animation_direction(mouse_vector, 0.5)
		animation_player.play("attack_" + animation_direction)

func roll_state():
	if current_state != ROLL:
		queue_state = NONE
		current_state = ROLL
		is_action_started = true
		
		velocity += input_direction * stats.roll_speed
		roll_timer.start(stats.roll_cooldown)
		hurtbox_collider.disabled = true
		stats.change_roll_charges(-1)
		if stats.roll_charges <= 0:
			roll_ready = false
		
		last_animation = "roll_" + get_animation_direction(input_direction, 0.1)
		animation_player.play(last_animation)

func play_move_animation(move_input: Vector2):
	if move_input == Vector2.ZERO:
		current_state = IDLE
		last_animation = "idle_" + last_animation.split("_")[1]
	else:
		current_state = WALK
		last_animation = "walk_" + get_animation_direction(move_input, 0.1)
	animation_player.play(last_animation)

func get_animation_direction(input_vector: Vector2, offset: float):
	var animation_direction = "down"
	if (input_vector.x < -offset):
		animation_direction = "left"
	elif (input_vector.x > offset):
		animation_direction = "right"
	elif (input_vector.y < -offset):
		animation_direction = "up"
	elif (input_vector.y > offset):
		animation_direction = "down"
	return animation_direction

func _on_animation_player_animation_finished(anim_name):
	finished_animation = anim_name

func finished_animation_logic():
	if "attack" in finished_animation  or "roll" in finished_animation:
		current_state = NONE
		is_action_started = false
		if "roll" in finished_animation:
			hurtbox_collider.disabled = false
		finished_animation = ""

func _on_roll_timer_timeout():
	if stats.roll_charges < stats.max_roll_charges:
		roll_ready = true
		stats.change_roll_charges(1)
		roll_timer.start(stats.roll_cooldown)

func _on_invincible_timer_timeout():
	if current_state != ROLL:
		hurtbox_collider.disabled = false

func _on_stats_no_health():
	pass

func _on_hurtbox_got_hit(damage, _knockback_vector):
	stats.take_damage(damage)
	invincible_timer.start(stats.invincibility_time)
	hurtbox_collider.set_deferred("disabled", true)
	hit_effect.play_animation()
	hit_sound.play()

func _on_sword_hitbox_hurtbox_found(area):
	area.take_damage(stats.damage, mouse_vector)
