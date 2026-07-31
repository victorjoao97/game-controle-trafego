extends Area2D
signal semaforo_on(area: Area2D)

var ligado = true

func _on_semaforo_area_entered(area: Area2D) -> void:
	print("passou")
	semaforo_on.emit(area)
