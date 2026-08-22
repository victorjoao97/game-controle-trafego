class_name StreetGraph extends Node

### A traffic control game with real maps
var roads: Array[Road] = []

func _init() -> void:
	var streetA := Road.new()
	streetA.road_units = 10
	streetA.road_id = "A"
	streetA.cardinal_direction = Road.CARDINAL_DIRECTION.EAST
	
	var streetB := Road.new()
	streetB.road_units = 20
	streetB.road_id = "B"
	streetB.cardinal_direction = Road.CARDINAL_DIRECTION.SOUTH
	
	var streetC := Road.new()
	streetC.road_units = 5
	streetC.road_id = "C"
	streetC.cardinal_direction = Road.CARDINAL_DIRECTION.EAST
	
	streetA.next_roads = [streetB, streetC]
	
	roads = [streetA]
