extends Node2D
@onready var car: CharacterBody2D = $Car

@export var pixels_reference := 20.0
@export var road_width := 30.0

func _ready() -> void:
	var graph := StreetGraph.new()

	var last_point := Vector2(50, 100)

	for road in graph.roads:
		last_point = create_road(road, last_point)

		for child_road in road.next_roads:
			last_point = create_road(child_road, last_point)


func create_road(road: Road, start: Vector2) -> Vector2:
	var direction := road.get_direction()
	var end := start + direction * road.road_units * pixels_reference

	var line := Line2D.new()
	line.width = road_width
	line.default_color = Color(randf(), randf(), randf())
	line.add_point(start)
	line.add_point(end)

	add_child(line)

	return end
