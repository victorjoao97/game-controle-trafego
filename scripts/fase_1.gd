extends Node2D
signal perdeu
signal ganhou
@onready var santana_caminho: PathFollow2D = $Santana/SantanaCaminho
@onready var santa_isabel_caminho: PathFollow2D = $SantaIsabel/SantaIsabelCaminho

func _process(delta: float) -> void:
	if (santana_caminho.progress_ratio == 1 and santa_isabel_caminho.progress_ratio == 1):
		ganhou.emit()
		return

func _on_santana_caminho_perdeu() -> void:
	perdeu.emit()

func _on_iniciar_pressed() -> void:
	for caminho in get_tree().get_nodes_in_group("caminhos"):
		caminho.parar_progresso = false
	$CanvasLayer/Control/Iniciar.text = "Parar"
	$CanvasLayer/Control/Limpar.visible = false

func _on_limpar_pressed() -> void:
	var semaforos = get_children().filter(func(c): return c.name == "Semaforo")
	if (semaforos.is_empty()):
		return
	for semaforo in semaforos:
		semaforo.queue_free()
	if (!semaforos.is_empty()):
		$CanvasLayer/Control.soltou = false
