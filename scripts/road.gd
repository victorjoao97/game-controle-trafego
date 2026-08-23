class_name Road
extends RefCounted

## Segmento dirigido entre dois cruzamentos. Seus pontos são a fonte única
## para o desenho e para a área de navegação.
var id: String
var street_id: String
var from_intersection_id: String
var to_intersection_id: String
var points: PackedVector2Array
var is_visual_owner := true


func _init(
		p_id: String = "",
		p_street_id: String = "",
		p_from: String = "",
		p_to: String = "",
		p_points: PackedVector2Array = PackedVector2Array(),
		p_is_visual_owner: bool = true
	) -> void:
	id = p_id
	street_id = p_street_id
	from_intersection_id = p_from
	to_intersection_id = p_to
	points = p_points
	is_visual_owner = p_is_visual_owner
