class_name Car extends StaticBody2D
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var sprite: Sprite2D = $Sprite2D

@export var max_speed := 50.0
@export var min_speed := 0.0
@export var safe_distance := 40.0
@export var detection_distance := 100.0

var paths: PackedVector2Array
var tileset_size: Vector2i
var speed := 50.0
var path_index := 0
var direction: Vector2
var is_congested := false
var can_detect_cars := false

func _ready() -> void:
	rotation = 0
	speed = max_speed
	await get_tree().create_timer(0.5).timeout
	can_detect_cars = true

func _physics_process(delta: float) -> void:
	if path_index >= paths.size():
		queue_free.call_deferred()
		return
	
	var target := paths[path_index]
	direction = global_position.direction_to(target)
	
	var target_speed := max_speed
	if can_detect_cars and ray_cast.is_colliding():
		var distance := global_position.distance_to(
			ray_cast.get_collision_point()
		)

		var factor := clampf(
			(distance - safe_distance) /
			(detection_distance - safe_distance),
			0.0,
			1.0
		)

		target_speed = lerpf(min_speed, max_speed, factor)

	match direction:
		Vector2.LEFT:
			sprite.flip_v = true
			rotation = direction.angle()
		_:
			sprite.flip_v = false
			rotation = direction.angle()

	if target_speed == min_speed:
		target_speed -= 1
		rotation = move_toward(rotation, -1, delta)

	position = position.move_toward(target, target_speed * delta)
	is_congested = target_speed < max_speed * 0.5
	#is_congested = ray_cast.is_colliding()

	if position == target:
		path_index += 1
