extends PointLight2D
var ativo = true

func _on_timer_timeout() -> void:
	if (ativo):
		color = Color(0.0, 0.57, 0.197, 1.0)
	else:
		color = Color(0.859, 0.145, 0.0)
	ativo = !ativo
