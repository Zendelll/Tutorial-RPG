extends Area2D

var player = null
@export var player_name = "Player"

signal player_found
signal player_lost

func _on_body_entered(body):
	if player_name in body.name:
		emit_signal("player_found")
		player = body


func _on_body_exited(body):
	if player_name in body.name:
		emit_signal("player_lost")
		player = null
