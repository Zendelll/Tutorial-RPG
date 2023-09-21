extends AnimatedSprite2D

@export var animation_name = "default"

func _ready():
	self.animation_finished.connect(_hide_self)
	_hide_self()
	

func play_animation():
	visible = true
	frame = 0
	play(animation_name)

func _hide_self():
	visible = false
