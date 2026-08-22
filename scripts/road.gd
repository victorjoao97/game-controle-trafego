class_name Road extends Node

enum ROAD_TYPE {
	STREET
}
enum CARDINAL_DIRECTION {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

var road_type: ROAD_TYPE
var road_id: String
var road_units: float
var next_roads: Array[Road]
var cardinal_direction: CARDINAL_DIRECTION

func get_direction() -> Vector2:
	match cardinal_direction:
		CARDINAL_DIRECTION.EAST:
			return Vector2.RIGHT
		CARDINAL_DIRECTION.WEST:
			return Vector2.LEFT
		CARDINAL_DIRECTION.NORTH:
			return Vector2.UP
		CARDINAL_DIRECTION.SOUTH:
			return Vector2.DOWN

	return Vector2.ZERO
