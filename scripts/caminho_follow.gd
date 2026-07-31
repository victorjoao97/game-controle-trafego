extends PathFollow2D
@onready var carro: Area2D = $Carro/Area2D
var semaforo: Timer

@export var velocidade := 200
var parar_progresso = true
var amount = 0
var bateu = false
signal perdeu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	carro.area_entered.connect(_on_carro_bateu)
	get_parent().get_parent().child_entered_tree.connect(_on_entered_tree)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (parar_progresso):
		if (bateu):
			amount += velocidade * delta
			if (amount < 100):
				carro.rotation_degrees = carro.rotation + delta * velocidade * 10
				progress += velocidade / 4 * delta
				return
		return
	progress += velocidade * delta

func _on_carro_bateu(area: Area2D):
	if (area.is_in_group("carros")):
		print("você perdeu")
		parar_progresso = true
		bateu = true
		perdeu.emit()
		return
	if (area.is_in_group("semaforos")):
		semaforo.timeout.connect(_on_timer_timeout)
		semaforo.start()
		parar_progresso = true

func _on_timer_timeout():
	parar_progresso = false
	semaforo.stop()

func _on_entered_tree(node: Node):
	if (node.name == "Semaforo"):
		semaforo = node.find_child("Timer")
	
