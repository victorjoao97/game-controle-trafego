class_name StreetGraph
extends RefCounted

## Cada rua física gera duas arestas: ida e volta. O sufixo do ID informa
## o sentido, por exemplo: A:forward e A:reverse.
var roads: Dictionary = {}
var street_directions: Dictionary = {}
var intersections: Dictionary = {}
var outgoing_roads_by_intersection: Dictionary = {}
var intersection_id_by_position: Dictionary = {}


func _init() -> void:
	#       B
	#       |
	# A ---- X
	#       |
	#       C ---- D ---- E
	add_bidirectional_road("A", PackedVector2Array([Vector2(100, 250), Vector2(430, 250)]))
	add_bidirectional_road("B", PackedVector2Array([Vector2(430, 250), Vector2(430, 100)]))
	add_bidirectional_road("C", PackedVector2Array([Vector2(430, 250), Vector2(430, 450)]))
	add_bidirectional_road("D", PackedVector2Array([Vector2(430, 450), Vector2(760, 450)]))
	add_bidirectional_road("E", PackedVector2Array([Vector2(430, 250), Vector2(760, 250)]))


func add_bidirectional_road(street_id: String, points: PackedVector2Array) -> void:
	if points.size() < 2:
		push_error("A rua '%s' precisa de pelo menos dois pontos." % street_id)
		return

	var forward_id := "%s:forward" % street_id
	var reverse_id := "%s:reverse" % street_id
	_add_directed_road(forward_id, street_id, points, true)

	var reverse_points := points.duplicate()
	reverse_points.reverse()
	_add_directed_road(reverse_id, street_id, reverse_points, false)
	street_directions[street_id] = PackedStringArray([forward_id, reverse_id])


func add_one_way_road(street_id: String, points: PackedVector2Array) -> void:
	if points.size() < 2:
		push_error("A rua '%s' precisa de pelo menos dois pontos." % street_id)
		return
	var forward_id := "%s:forward" % street_id
	_add_directed_road(forward_id, street_id, points, true)
	street_directions[street_id] = PackedStringArray([forward_id])


func _add_directed_road(id: String, street_id: String, points: PackedVector2Array, is_visual_owner: bool) -> void:
	var from := _get_or_create_intersection(points[0])
	var to := _get_or_create_intersection(points[-1])
	var road_points := points.duplicate()
	road_points[0] = from.position
	road_points[-1] = to.position
	var road := Road.new(id, street_id, from.id, to.id, road_points, is_visual_owner)
	roads[id] = road
	outgoing_roads_by_intersection[from.id].append(id)
	from.connected_road_ids.append(id)
	to.connected_road_ids.append(id)


func get_road_route(from_street_or_direction_id: String, to_street_or_direction_id: String) -> Array[String]:
	var from_candidates := _get_direction_candidates(from_street_or_direction_id)
	var to_candidates := _get_direction_candidates(to_street_or_direction_id)
	var best_route: Array[String] = []

	for from_id: String in from_candidates:
		for to_id: String in to_candidates:
			var candidate := _find_directed_route(from_id, to_id)
			if not candidate.is_empty() and (best_route.is_empty() or candidate.size() < best_route.size()):
				best_route = candidate
	return best_route


func _get_direction_candidates(street_or_direction_id: String) -> PackedStringArray:
	if street_directions.has(street_or_direction_id):
		return street_directions[street_or_direction_id]
	if roads.has(street_or_direction_id):
		return PackedStringArray([street_or_direction_id])
	return PackedStringArray()


func _find_directed_route(from_road_id: String, to_road_id: String) -> Array[String]:
	var queue: Array[String] = [from_road_id]
	var previous: Dictionary = {from_road_id: ""}
	while not queue.is_empty():
		var current_id: String = queue.pop_front()
		if current_id == to_road_id:
			break
		var current: Road = roads[current_id]
		for next_id: String in outgoing_roads_by_intersection[current.to_intersection_id]:
			if not previous.has(next_id):
				previous[next_id] = current_id
				queue.append(next_id)

	if not previous.has(to_road_id):
		return []

	var route: Array[String] = []
	var road_id := to_road_id
	while road_id != "":
		route.push_front(road_id)
		road_id = previous[road_id]
	return route


func _get_or_create_intersection(position: Vector2) -> Intersection:
	var position_key := _position_key(position)
	if intersection_id_by_position.has(position_key):
		return intersections[intersection_id_by_position[position_key]]

	var id := "I_%d" % intersections.size()
	var intersection := Intersection.new(id, position)
	intersections[id] = intersection
	intersection_id_by_position[position_key] = id
	outgoing_roads_by_intersection[id] = []
	return intersection


func _position_key(position: Vector2) -> String:
	return "%d:%d" % [roundi(position.x), roundi(position.y)]
