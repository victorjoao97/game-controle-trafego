class_name Light extends StaticBody2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer

var enable := true

func _on_timer_timeout() -> void:
	enable = false
	collision_shape_2d.disabled = enable

func sync() -> void:
	enable = true
	collision_shape_2d.disabled = enable
	#var connections := timer.get_signal_connection_list("timeout")
	#for connection in connections:
		#timer.timeout.disconnect(connection.callable)
	timer.start()
