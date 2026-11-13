extends Area2D

@export var next_scene : String = ""

var player_in_range: bool = false

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node2D):
	if body is Player:
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body is Player:
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interagir"):
		if next_scene != "":
			get_tree().call_deferred("change_scene_to_file", next_scene)
