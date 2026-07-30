extends Node2D
signal perdeu

func _on_santana_caminho_perdeu() -> void:
	perdeu.emit()

func _on_iniciar_pressed() -> void:
	for caminho in get_tree().get_nodes_in_group("caminhos"):
		caminho.parar_progresso = false
	$CanvasLayer/Control/Iniciar.text = "Parar"
