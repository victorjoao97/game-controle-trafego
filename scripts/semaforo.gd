extends Area2D
signal semaforo_on(area: Area2D)
signal semaforo_off()

var ligado = true

func _on_semaforo_area_entered(area: Area2D) -> void:
	print("passou")
	semaforo_on.emit(area)

func _on_timer_timeout() -> void:
	ligado != ligado
	monitorable = ligado
	semaforo_off.emit()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_parent().queue_free()
