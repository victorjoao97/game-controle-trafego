class_name TrafficCar
extends CharacterBody2D

signal route_finished
signal car_stucked

@export var speed := 100.0
@export var arrival_distance := 8.0
@export var minimum_follow_distance := 18.0
@export var follow_look_ahead := 72.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = %StuckTimer
@onready var forward_detector: RayCast2D = $ForwardDetector

var road_route: Array[String] = []
var route_destinations := PackedVector2Array()
var destination_index := 0
var has_finished_route := false
var last_position := Vector2.ZERO
var is_waiting_for_traffic := false
var is_waiting_for_signal := false


func _ready() -> void:
	# A layer 1 continua ativa para o RayCast detectar carros. O corpo só
	# colide fisicamente com objetos da layer 2 (obstáculos/semafóros).
	#collision_mask = 2
	forward_detector.target_position = Vector2(follow_look_ahead, 0)


func set_road_route(p_road_route: Array[String], p_destinations: PackedVector2Array) -> void:
	road_route = p_road_route
	route_destinations = p_destinations
	destination_index = 0
	has_finished_route = false
	_set_next_destination()
	modulate = _route_color(p_road_route)


func _physics_process(_delta: float) -> void:
	if route_destinations.is_empty() or destination_index >= route_destinations.size():
		_finish_route()
		queue_free.call_deferred()
		return

	var current_destination := route_destinations[destination_index]
	if global_position.distance_to(current_destination) <= arrival_distance:
		destination_index += 1
		if destination_index >= route_destinations.size():
			_finish_route()
		else:
			_set_next_destination()
		return

	var next_position := current_destination
	if not navigation_agent.is_navigation_finished():
		var navigation_next_position := navigation_agent.get_next_path_position()
		if navigation_next_position.distance_to(global_position) > 1.0:
			next_position = navigation_next_position

	var direction := global_position.direction_to(next_position)
	var target_speed := _get_follow_speed(speed)
	velocity = direction * target_speed
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	move_and_slide()
	is_waiting_for_signal = false
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		if collision.get_collider() is TrafficSemaphore:
			is_waiting_for_signal = true
			velocity = Vector2.ZERO
			break
	_update_stuck_timer()


func get_current_road_id() -> String:
	if destination_index >= road_route.size():
		return ""
	return road_route[destination_index]


func _get_follow_speed(desired_speed: float) -> float:
	is_waiting_for_traffic = false
	if not forward_detector.is_colliding():
		return desired_speed

	var car_ahead := forward_detector.get_collider() as TrafficCar
	if car_ahead == null or car_ahead.get_current_road_id() != get_current_road_id():
		return desired_speed

	is_waiting_for_traffic = true
	var distance_to_car := global_position.distance_to(car_ahead.global_position)
	if distance_to_car <= minimum_follow_distance:
		return 0.0

	var available_space := follow_look_ahead - minimum_follow_distance
	return desired_speed * clamp((distance_to_car - minimum_follow_distance) / available_space, 0.0, 1.0)


func _set_next_destination() -> void:
	if destination_index >= route_destinations.size():
		velocity = Vector2.ZERO
		return
	navigation_agent.target_position = route_destinations[destination_index]


func _finish_route() -> void:
	velocity = Vector2.ZERO
	if has_finished_route:
		return
	has_finished_route = true
	route_finished.emit()


func _update_stuck_timer() -> void:
	if is_waiting_for_traffic or is_waiting_for_signal:
		timer.stop()
		last_position = global_position
		return
	if last_position.distance_to(global_position) > 20.0:
		last_position = global_position
		timer.stop()
	elif timer.is_stopped():
		timer.start()


func _route_color(route: Array[String]) -> Color:
	var route_name : String = route.reduce(func(accum: String, road_id: String) -> String: return accum + road_id, "")
	var hue := float(route_name.hash() & 0xFFFF) / 65535.0
	return Color.from_hsv(hue, 0.7, 0.9)


func _on_stuck_timer_timeout() -> void:
	car_stucked.emit()
