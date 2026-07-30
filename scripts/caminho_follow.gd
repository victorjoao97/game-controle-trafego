extends PathFollow2D
@onready var carro: Area2D = $Carro/Area2D

@export var velocidade := 200
var parar_progresso = true
signal perdeu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	carro.area_entered.connect(_on_carro_bateu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (parar_progresso):
		return
	progress += velocidade * delta

func _on_carro_bateu(area: Area2D):
	print(area.get_groups())
	if (area.is_in_group("carros")):
		print("você perdeu")
		parar_progresso = true
		perdeu.emit()
		return
	if (area.is_in_group("semaforos")):
		parar_progresso = true
