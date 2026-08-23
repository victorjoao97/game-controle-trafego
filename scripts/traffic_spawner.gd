class_name TrafficSpawner
extends Node

signal spawn_requested(from_street_id: String, to_street_id: String)
signal finished

@onready var timer: Timer = $Timer

var phases: Array[Phase] = []
var phase_index := 0
var spawned_in_phase := 0


func configure(p_phases: Array[Phase]) -> void:
	phases = p_phases

func start() -> void:
	stop()
	phase_index = 0
	spawned_in_phase = 0
	_start_current_phase()

func stop() -> void:
	for car in get_tree().get_nodes_in_group("cars"):
		car.queue_free.call_deferred()
	
	phase_index = 0
	spawned_in_phase = 0
	timer.stop()

func _start_current_phase() -> void:
	if phase_index >= phases.size():
		timer.stop()
		finished.emit()
		return
	var phase := phases[phase_index]
	timer.wait_time = phase.interval
	timer.start()

func _on_timer_timeout() -> void:
	var phase := phases[phase_index]
	var routes := phase.routes
	if routes.is_empty():
		_advance_phase()
		return

	for selected_route in routes:
		#var selected_route: PackedStringArray = routes.pick_random()
		if selected_route.size() != 2:
			push_error("Cada rota da fase deve conter origem e destino.")
			return

		if get_tree().get_nodes_in_group("cars:%s" % [Array(selected_route).hash()]).size() >= phase.max_alive_cars:
			continue

		spawn_requested.emit(selected_route[0], selected_route[1])
		spawned_in_phase += 1
		if spawned_in_phase >= phase.spawn_count:
			_advance_phase()

func _advance_phase() -> void:
	phase_index += 1
	spawned_in_phase = 0
	_start_current_phase()
