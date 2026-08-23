class_name Intersection
extends RefCounted

var id: String
var position: Vector2
var connected_road_ids: Array[String] = []


func _init(p_id: String = "", p_position: Vector2 = Vector2.ZERO) -> void:
	id = p_id
	position = p_position
