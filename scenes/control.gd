extends Control

var soltou = false
var preview: TextureRect

func _on_control_gui_input(event: InputEvent) -> void:
	if (soltou):
		return
	if (!preview):
		preview = $TextureRect.duplicate()
	preview.position = $TextureRect.position + event.position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				self.add_child(preview)
			else:
				var novo: Node2D = preload("res://scenes/Semaforo.tscn").instantiate()
				$"../../../Caminho".add_child(novo)
				novo.global_position = get_global_mouse_position()
				novo.global_position.y = novo.global_position.y + 70
				novo.scale = Vector2(2, 2)
				self.remove_child(preview)
				preview = null
				soltou = true
				$Iniciar.visible = true
				$Limpar.visible = true
