extends Node2D
@onready var perdeuControl: Control = $CanvasLayer/Perdeu
@onready var ganhou: Control = $CanvasLayer/Ganhou

func _on_caminho_perdeu() -> void:
	perdeuControl.visible = true

func _on_tentar_novamente_pressed() -> void:
	get_tree().reload_current_scene()

func _on_caminho_ganhou() -> void:
	ganhou.visible = true
