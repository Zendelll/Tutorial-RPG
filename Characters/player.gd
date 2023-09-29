extends CharacterBody2D

enum state {
	MOVE,
	ROLL,
	ATTACK
}
enum {
	NONE,
	IDLE,
	WALK,
	ATTACK,
	ROLL
}

@export_group("Move")
@export var move_speed : float = 100

@export_group("Roll")
@export var roll_speed : float = 200
@export var roll_cooldown : float = 0.8
@export var max_roll_cooldown : float = 2
@export var max_roll_charges : int = 2

var current_state = state.MOVE
var current_action = IDLE
var last_animation = "idle_down"
var input_direction = Vector2.ZERO
var roll_ready = true
var roll_charges = max_roll_charges
var mouse_vector = Vector2.ZERO
var hearts_size_px = 15

@onready var animation_player = $AnimationPlayer
@onready var roll_timer = $RollTimer
@onready var invincible_timer = $InvincibleTimer
@onready var stats = $Stats
@onready var hit_effect = $Hit_effect
@onready var hurtbox_collider = $Hurtbox/CollisionShape2D
@onready var full_hearts_ui = $Player_UI/Health_UI/Full_Hearts
@onready var roll_bar = $Player_UI/Roll_UI/Roll_Bar

func _process(_delta):
	full_hearts_ui.size.x = stats.health * hearts_size_px
	roll_bar.value = roll_charges
	
func _physics_process(_delta):
	if Input.is_action_just_pressed("roll") and input_direction != Vector2.ZERO and roll_ready:
		current_state = state.ROLL
	elif Input.is_action_just_pressed("attack") and current_state == state.MOVE:
		current_state = state.ATTACK
	if current_state == state.ROLL:
		roll_state()
	elif current_state == state.ATTACK and current_action != ATTACK:
		attack_state()
	elif current_state == state.MOVE:
		move_state()

func move_state():
	input_direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	play_move_animation(input_direction)
	velocity = input_direction * move_speed
	move_and_slide()

func attack_state():
	current_action = ATTACK
	if not "attack" in last_animation:
		mouse_vector = (get_global_mouse_position() - position).normalized()
		var animation_direction = get_direction(mouse_vector)
		animation_player.play("attack_" + animation_direction)
		#last_animation = "attack_" + animation_direction

func roll_state():
	if roll_ready and current_action != ROLL:
		current_action = ROLL
		roll_charges -= 1
		roll_timer.start(max_roll_cooldown)
		if roll_charges <= 0:
			roll_ready = false
			roll_timer.start(roll_cooldown)
		velocity = input_direction * roll_speed
		hurtbox_collider.disabled = true
		animation_player.play("roll_" + last_animation.split("_")[1])
		last_animation = "roll_" + last_animation.split("_")[1]
	move_and_slide()

func play_move_animation(move_input: Vector2):
	var new_animation = last_animation
	if (move_input == Vector2.ZERO):
		current_action = IDLE
		animation_player.play("idle_" + last_animation.split("_")[1])
		last_animation = "idle_" + last_animation.split("_")[1]
	else:
		current_action = WALK
		if (move_input.x < -0.1):
			new_animation = "walk_left"
		elif (move_input.x > 0.1):
			new_animation = "walk_right"
		elif (move_input.y < -0.1):
			new_animation = "walk_up"
		elif (move_input.y > 0.1):
			new_animation = "walk_down"
		animation_player.play(new_animation)
		last_animation = new_animation

func get_direction(input_vector: Vector2):
	input_vector = input_vector.normalized()
	var animation_direction = "down"
	if (input_vector.x < -0.5):
		animation_direction = "left"
	elif (input_vector.x > 0.5):
		animation_direction = "right"
	elif (input_vector.y < -0.5):
		animation_direction = "up"
	elif (input_vector.y > 0.5):
		animation_direction = "down"
	return animation_direction

func _on_animation_player_animation_finished(anim_name):
	if anim_name.split("_")[0] == "attack" or anim_name.split("_")[0] == "roll":
		current_state = state.MOVE
		current_action = NONE
		if anim_name.split("_")[0] == "roll":
			hurtbox_collider.disabled = false

func _on_roll_timer_timeout():
	roll_ready = true
	roll_charges = max_roll_charges

func _on_hurtbox_area_entered(area):
	if "Hitbox" in area.name:
		var enemy = area.get_parent()
		stats.take_damage(enemy.get_node("Stats").damage)
		invincible_timer.start(stats.invincibility_time)
		hurtbox_collider.set_deferred("disabled", true)
		hit_effect.play_animation()

func _on_invincible_timer_timeout():
	if current_action != ROLL:
		hurtbox_collider.disabled = false

func _on_stats_no_health():
	pass
