extends Control

var arrastando = false
var preview: TextureRect

func _on_control_gui_input(event: InputEvent) -> void:
	if (!preview):
		preview = $TextureRect.duplicate()
	preview.position = $TextureRect.position + event.position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				self.add_child(preview)
				arrastando = true
			else:
				var novo: Node2D = preload("res://scenes/Semaforo.tscn").instantiate()
				$"../../../Caminho".add_child(novo)
				novo.global_position = get_global_mouse_position()
				self.remove_child(preview)
				preview = null
				arrastando = false
