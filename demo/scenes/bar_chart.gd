## Standalone BarChart3D demo.
extends Node3D

func _ready() -> void:
	_setup_env()

	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 4.0)
	add_child(frame)

	var chart := BarChart3D.new()
	chart.title   = "Monthly Sales"
	chart.x_label = "Month"
	chart.y_label = "Units"
	chart.data = {
		"labels":   ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
		"datasets": [
			{"name": "Product A", "values": [120.0,  95.0, 140.0, 180.0, 160.0, 210.0]},
			{"name": "Product B", "values": [ 80.0, 110.0,  90.0, 130.0, 100.0, 145.0]},
			{"name": "Product C", "values": [ 60.0,  70.0,  80.0,  75.0,  90.0,  95.0]},
		],
	}
	frame.add_child(chart)

	var cam := Camera3D.new()
	cam.position = Vector3(3.0, 2.0, 10.0)
	cam.look_at(Vector3(3.0, 2.0, 0.0))
	add_child(cam)


func _setup_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.9, 1.0)
	env.ambient_light_energy = 0.7
	var wenv := WorldEnvironment.new()
	wenv.environment = env
	add_child(wenv)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
	add_child(sun)
