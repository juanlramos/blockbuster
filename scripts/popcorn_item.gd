extends Area2D

@export var value: int = 1

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.get_node("Health").health_collected()
		get_parent().queue_free()
		
