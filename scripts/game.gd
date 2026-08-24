extends Node2D
@onready var tile_map: TileMapLayer = $Map
@onready var tile_map_terrain: TileMapLayer = $Terrain
@onready var markers: Node = %Markers
@onready var game_data_label: Label = %GameDataLabel
@onready var game_data_label_2: Label = %GameDataLabel2
@onready var canvas_layer: CanvasLayer = $CanvasLayer

@export var car_scene: PackedScene
@export var light_scene: PackedScene
@export var destination_tile: Array[Vector2i]
@export var max_cars := 20

var astar_grid: AStarGrid2D
var astar: AStar2D
var tween: Tween
var _markers: Array[Marker2D] = []
var congested_cars := 0:
	set (value):
		congested_cars = clampi(value, 0, created_cars)
var congestion_rate:
	get: return clampf(float(congested_cars) / created_cars, 0.0, 1.0)
var created_cars := 0:
	get: return created_cars
	set (value):
		_render_game_data()
		created_cars = value
var cars_per_tile: Dictionary[Vector2i, int]= {}
var roads: Dictionary[Vector2i, Dictionary] = {}
var intersections: Array[Vector2i] = []
var tile_ids: Dictionary[Vector2i, int] = {}
var next_id := 0
var lights: Array[Light] = []

enum TileTransform {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

func _ready() -> void:
	astar = AStar2D.new()
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.cell_size = tile_map.tile_set.tile_size
	astar_grid.update()
	
	var region = tile_map.get_used_rect()
	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			if tile_map.get_cell_source_id(Vector2i(x, y)) == -1:
				astar_grid.set_point_solid(Vector2i(x, y), true)
	
	for marker: Marker2D in markers.get_children():
		_markers.append(marker)
	
	for tile in tile_map.get_used_cells():
		roads[tile] = {
			"direction": Vector2i.RIGHT
		}
	for tile in roads:
		var neighbors := 0

		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if roads.has(tile + direction):
				neighbors += 1
		if neighbors >= 4:
			intersections.append(tile)
		var direction := get_road_direction(tile)
		roads[tile]["direction"] = direction
		var flip: int
		if direction == Vector2i.RIGHT:
			flip = TileTransform.ROTATE_0
		if direction == Vector2i.LEFT:
			flip = TileTransform.ROTATE_180
		if direction == Vector2i.DOWN:
			flip = TileTransform.ROTATE_90
		if direction == Vector2i.UP:
			flip = TileTransform.ROTATE_270
		if direction == Vector2i.ZERO:
			tile_map_terrain.set_cell(tile, 1, Vector2i(1, 0))
		else:
			tile_map_terrain.set_cell(tile, 1, Vector2i(0, 0), flip)
			

		tile_ids[tile] = next_id
		astar.add_point(next_id, tile_map.map_to_local(tile))
		next_id += 1
	
	for tile in roads:
		var direction: Vector2i = roads[tile]["direction"]

		if direction == Vector2i.ZERO:
			for _direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if roads.has(tile + _direction):
					astar.connect_points(
						tile_ids[tile],
						tile_ids[tile + _direction],
						false
					)
			continue

		var next_tile := tile + direction

		if not roads.has(next_tile):
			continue

		astar.connect_points(
			tile_ids[tile],
			tile_ids[next_tile],
			false
		)
	
	#for intersection in intersections:
		#var tile := roads[intersection]
		#var btn := Button.new()
		#btn.text = "Light"
		#btn.position = tile_map.map_to_local(intersection)
		#btn.position -= btn.size
		#canvas_layer.add_child(btn)
		#btn.pressed.connect(_on_lights_pressed.bind(intersection))

func _on_lights_pressed(tile: Vector2i) -> void:
	var new_light: Light = light_scene.instantiate()
	new_light.position = tile_map.map_to_local(tile)
	add_child(new_light)
	lights.append(new_light)
	if lights.size() == 1:
		new_light.sync()
		return
	for i in lights.size():
		var item := lights[i]
		item.timer.stop()
		item.timer.timeout.emit()
	lights[0].sync()
	for i in range(1, lights.size()):
		var item := lights[i]
		lights[0].timer.timeout.connect(item.sync)
		item.timer.timeout.connect(lights[0].sync)


func get_road_direction(tile: Vector2i) -> Vector2i:
	if tile == Vector2i(7, -1) or tile == Vector2i(8, -1):
		pass
	var left := roads.has(tile + Vector2i.LEFT)
	var right := roads.has(tile + Vector2i.RIGHT)
	var up := roads.has(tile + Vector2i.UP)
	var down := roads.has(tile + Vector2i.DOWN)

	if left and right and up and down:
		return Vector2i.ZERO

	if left and right:
		if down:
			return Vector2i.LEFT
		return Vector2i.RIGHT
	if left and !right:
		if down:
			return Vector2i.UP
		return Vector2i.DOWN
	if up and down:
		return Vector2i.DOWN
	if !up and !left:
		return Vector2i.DOWN
	if !up and right:
		return Vector2i.DOWN
	if down:
		return Vector2i.DOWN

	return Vector2i.ZERO

func _physics_process(_delta: float) -> void:
	congested_cars = 0
	cars_per_tile = {}
	for car in get_tree().get_nodes_in_group("cars"):
		if car.is_congested:
			congested_cars += 1
			var tile := tile_map.local_to_map(
				tile_map.to_local(car.global_position)
			)
			cars_per_tile[tile] = cars_per_tile.get(tile, 0) + 1
	
	for overlay in get_tree().get_nodes_in_group("overlays"):
		overlay.queue_free()

	for key in cars_per_tile:
		for x in range(-1, 2):
			for y in range(-1, 2):
				var tile_pos := key + Vector2i(x, y)
				var overlay := ColorRect.new()
				overlay.size = tile_map.tile_set.tile_size
				overlay.color = Color(1, 0, 0, 0.35)
				overlay.position = tile_map.map_to_local(tile_pos) - tile_map.tile_set.tile_size / 2.0
				overlay.add_to_group("overlays")
				add_child(overlay)

func _get_path(destination: Vector2i) -> PackedVector2Array:
	var start: Vector2 = _markers.pick_random().global_position
	var tilemap_point := tile_map.local_to_map(start)
	if destination.distance_to(tilemap_point) <= 2:
		return []
	if !tile_ids[tilemap_point] or !tile_ids[destination]:
		return []
	return astar.get_point_path(tile_ids[tilemap_point], tile_ids[destination])
	#return astar_grid.get_point_path(tilemap_point, destination)

func _create_car() -> void:
	var points := _get_path(destination_tile.pick_random())
	if points.size() == 0:
		return
	
	var spawn_position := points[0]

	for car in get_tree().get_nodes_in_group("cars"):
		if car.global_position.distance_to(spawn_position) < tile_map.tile_set.tile_size.x * 2:
			return
	
	var line = Line2D.new()
	line.points = points
	line.width = 1
	line.default_color = Color(randf(), randf(), randf())
	line.hide()
	add_child(line)

	var new_car: Car = car_scene.instantiate()
	new_car.add_to_group("cars")
	new_car.position = points[0]
	new_car.paths = points
	new_car.tileset_size = tile_map.tile_set.tile_size
	new_car.tree_exiting.connect(_on_car_removed.bind(line))
	created_cars += 1
	add_child(new_car)

func _on_spawner_timer_timeout() -> void:
	if created_cars > max_cars:
		%SpawnerTimer.stop()
		return
	for i in range(2):
		_create_car()

func _on_car_removed(line: Line2D) -> void:
	created_cars -= 1
	line.queue_free()

func _render_game_data() -> void:
	game_data_label.text = "Cars: %d\nCongested: %d\nRate: %d%%" % [
		created_cars, congested_cars, clampi(congestion_rate * 100, 0, 100),
	]
	var copy := cars_per_tile.keys().duplicate()
	copy.sort_custom(func(a, b): return cars_per_tile[a] > cars_per_tile[b])
	game_data_label_2.text = "Cars by tiles: %s" % [
		", ".join(copy.map(func (c): return "%s = %d" % [c, cars_per_tile[c]]))
	]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			prints("Left mouse button clicked at:", event.position, tile_map.local_to_map(event.position))
			_on_lights_pressed(tile_map.local_to_map(event.position))
