class_name TrafficSemaphore
extends StaticBody2D

## Semáforo clicável colocado antes da entrada de um cruzamento.
## Vermelho bloqueia os carros; verde mantém o controle clicável, sem colisão.

signal state_changed(is_green: bool)

@export var is_green := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var road_id := ""
var travel_direction := Vector2.RIGHT


func _ready() -> void:
	input_pickable = true
	_apply_state()


func configure(p_road_id: String, p_direction: Vector2, p_is_green: bool) -> void:
	road_id = p_road_id
	travel_direction = p_direction.normalized()
	is_green = p_is_green
	rotation = travel_direction.angle()
	_apply_state()
	queue_redraw()


func toggle() -> void:
	is_green = not is_green
	_apply_state()
	state_changed.emit(is_green)


func _apply_state() -> void:
	if not is_instance_valid(collision_shape):
		return
	# O carro usa a máscara 2. No vermelho a barreira fica nessa camada; no
	# verde ela muda para outra camada para continuar clicável sem colidir.
	collision_layer = 4 if is_green else 2
	collision_mask = 0
	queue_redraw()


func _draw() -> void:
	# O corpo é desenhado orientado no sentido do carro. A faixa bloqueia a via
	# transversalmente e a lâmpada fica ao lado dela.
	draw_line(Vector2(0, -34), Vector2(0, 34), Color("#161a20"), 5.0)
	draw_circle(Vector2(-12, -18), 10.0, Color("#1b2028"))
	draw_circle(Vector2(-12, -18), 6.0, Color("#34d399") if is_green else Color("#ef4444"))


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle()
