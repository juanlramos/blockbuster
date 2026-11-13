extends Area2D

@export_multiline var texto_da_fala: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("change_talk"):
		body.change_talk(texto_da_fala)
