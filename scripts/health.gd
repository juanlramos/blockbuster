extends Node2D
class_name Health

@export var max_health := 3

var health : int

signal health_changed(health)

func _ready():
	health = max_health
	emit_signal("health_changed", health)

func lose_health():
	health -= 1
	emit_signal("health_changed", health)
	if health <= 0:
		print("Jogador morreu")

func health_collected():
	health += 1
	emit_signal("health_changed", health)
