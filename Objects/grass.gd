extends Node2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox_collider = $Hurtbox/CollisionShape2D
var disable = false

func _ready():
	animated_sprite.frame = 0

func _process(_delta):
	if disable: hurtbox_collider.disabled = true

func _on_animated_sprite_2d_animation_finished():
	queue_free()

func _on_hurtbox_got_hit(_damage, _knockback_vector):
	disable = true
	animated_sprite.play("Destroy")
