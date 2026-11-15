extends Control

@onready var player_health = get_node("../../Player/Health")
@onready var health_label = $PopCorn/Label

func _ready():
	if player_health:

		player_health.health_changed.connect(_on_health_changed)
		
		health_label.text = "x " + str(player_health.health)

func _on_health_changed(new_health: int):
	health_label.text = "x " + str(new_health)
