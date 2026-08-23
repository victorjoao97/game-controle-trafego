extends Node2D

@onready var paths: Node = $Paths
@onready var car_spawner: TrafficSpawner = $CarSpawner
@onready var start_button: Button = %StartButton
@onready var status_label: Label = %StatusLabel

@export var road_width := 96.0
@export var intersection_size := 64.0
@export var car_scene: PackedScene
@export var semaphore_scene: PackedScene
@export var car_spawn_gap := 24.0
@export var max_cars_stucked := 5

var graph: StreetGraph
var cars_stucked := 0
var game_started := false


func _ready() -> void:
	graph = StreetGraph.new()
	for road: Road in graph.roads.values():
		if road.is_visual_owner:
			_render_road(road)
			_create_road_navigation(road)
			_render_tools(road)

	for intersection: Intersection in graph.intersections.values():
		_render_intersection(intersection)
		_create_intersection_navigation(intersection)
		_create_intersection_semaphores(intersection)

	var phase1 := Phase.new()
	phase1.max_alive_cars = 5
	phase1.interval = 0.3
	phase1.phase_name = "phase_1"
	phase1.spawn_count = 50
	phase1.routes = [PackedStringArray(["A", "E"]), PackedStringArray(["B", "D"]), PackedStringArray(["C", "A"])]
	car_spawner.configure([
		phase1,
	])
	car_spawner.spawn_requested.connect(_on_car_spawner_spawn_requested)
	car_spawner.finished.connect(_on_traffic_finished)
	
	if game_started:
		start_game()



func get_route(from_street_id: String, to_street_id: String) -> Array[String]:
	return graph.get_road_route(from_street_id, to_street_id)


func get_route_destinations(route: Array[String]) -> PackedVector2Array:
	var destinations := PackedVector2Array()
	for road_id: String in route:
		var road: Road = graph.roads[road_id]
		destinations.append(road.points[-1])
	return destinations


func _on_car_spawner_spawn_requested(from_street_id: String, to_street_id: String) -> void:
	var route := get_route(from_street_id, to_street_id)
	if route.is_empty():
		push_warning("Não há rota de %s para %s." % [from_street_id, to_street_id])
		return

	var first_road: Road = graph.roads[route[0]]
	var spawn_direction := first_road.points[0].direction_to(first_road.points[1])
	var cars_on_same_entry := 0
	for other_car: TrafficCar in get_tree().get_nodes_in_group("cars"):
		if not other_car.road_route.is_empty() and other_car.road_route[0] == route[0]:
			cars_on_same_entry += 1

	var car: TrafficCar = car_scene.instantiate()
	car.add_to_group("cars")
	car.add_to_group("cars:%s" % [[from_street_id, to_street_id].hash()])
	car.global_position = first_road.points[0] + spawn_direction * car_spawn_gap * cars_on_same_entry
	add_child(car)
	car.route_finished.connect(car.queue_free)
	car.set_road_route(route, get_route_destinations(route))
	car.car_stucked.connect(_on_car_stucked)

func _render_road(road: Road) -> void:
	var line := Line2D.new()
	line.z_index = -1
	line.width = road_width
	line.default_color = Color("#30343b")
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.points = _get_road_area_points(road)
	paths.add_child(line)

func _render_tools(road: Road) -> void:
	# Identifica os pontos de origem/destino sem expor os antigos botões de
	# depuração. Cada rua física é desenhada apenas uma vez.
	var label := Label.new()
	label.text = road.street_id
	label.position = (road.points[0] + road.points[-1]) * 0.5 + Vector2(6, 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paths.add_child(label)


func _create_intersection_semaphores(intersection: Intersection) -> void:
	if intersection.connected_road_ids.size() <= 2:
		return

	for road_id: String in intersection.connected_road_ids:
		var road: Road = graph.roads[road_id]
		if road.to_intersection_id != intersection.id:
			continue

		var direction := road.points[-2].direction_to(road.points[-1])
		var semaphore: TrafficSemaphore = semaphore_scene.instantiate()
		semaphore.global_position = intersection.position - direction * (intersection_size * 0.5 + 10.0)
		# As vias horizontais começam livres e as verticais aguardam. Isso evita
		# que o mapa nasça inteiramente bloqueado e dá ao jogador uma fase clara.
		var horizontal: bool = abs(direction.x) > abs(direction.y)
		semaphore.configure(road.id, direction, horizontal)
		paths.add_child(semaphore)

func _render_intersection(intersection: Intersection) -> void:
	var crossing := Polygon2D.new()
	crossing.z_index = -1
	var half_size := intersection_size * 0.5
	var p := intersection.position
	crossing.polygon = PackedVector2Array([p + Vector2(-half_size, -half_size), p + Vector2(half_size, -half_size), p + Vector2(half_size, half_size), p + Vector2(-half_size, half_size)])
	crossing.color = Color("#30343b")
	paths.add_child(crossing)


func _create_road_navigation(road: Road) -> void:
	var polygon := NavigationPolygon.new()
	var half_width := road_width * 0.5
	var area_points := _get_road_area_points(road)
	var start := area_points[0]
	var end := area_points[area_points.size() - 1]
	var normal := (end - start).normalized().orthogonal() * half_width
	polygon.add_outline(PackedVector2Array([start + normal, end + normal, end - normal, start - normal]))
	polygon.make_polygons_from_outlines()
	var region := NavigationRegion2D.new()
	region.navigation_polygon = polygon
	paths.add_child(region)


func _get_road_area_points(road: Road) -> PackedVector2Array:
	# O grafo continua ligando ruas pelo centro da interseção. Para desenho e
	# navegação, porém, a rua avança até a borda externa do cruzamento.
	var area_points := road.points.duplicate()
	var half_intersection := intersection_size * 0.5

	var from_intersection: Intersection = graph.intersections[road.from_intersection_id]
	if from_intersection.connected_road_ids.size() > 2:
		var start_direction := area_points[0].direction_to(area_points[1])
		area_points[0] -= start_direction * half_intersection

	var to_intersection: Intersection = graph.intersections[road.to_intersection_id]
	if to_intersection.connected_road_ids.size() > 2:
		var end_direction := area_points[area_points.size() - 2].direction_to(area_points[area_points.size() - 1])
		area_points[area_points.size() - 1] += end_direction * half_intersection

	return area_points


func _create_intersection_navigation(intersection: Intersection) -> void:
	var polygon := NavigationPolygon.new()
	var half_size := intersection_size * 0.5
	var p := intersection.position
	polygon.add_outline(PackedVector2Array([p + Vector2(-half_size, -half_size), p + Vector2(half_size, -half_size), p + Vector2(half_size, half_size), p + Vector2(-half_size, half_size)]))
	polygon.make_polygons_from_outlines()
	var region := NavigationRegion2D.new()
	region.navigation_polygon = polygon
	paths.add_child(region)

func _on_car_stucked() -> void:
	cars_stucked += 1
	if cars_stucked >= max_cars_stucked:
		stop_game()
		status_label.text = "Congestionamento! Ajuste os semáforos e tente novamente."
		start_button.text = "Reiniciar"
		game_started = false

func start_game() -> void:
	cars_stucked = 0
	status_label.text = "Clique nos semáforos para alternar entre verde e vermelho."
	car_spawner.start()

func stop_game() -> void:
	car_spawner.stop()


func _on_traffic_finished() -> void:
	status_label.text = "Fluxo concluído! Você resolveu o mapa de tráfego."
	start_button.text = "Jogar novamente"
	game_started = false

func _on_start_button_pressed() -> void:
	game_started = !game_started
	if game_started:
		start_game()
		start_button.text = "Pausar"
	else:
		stop_game()
		start_button.text = "Jogar"
