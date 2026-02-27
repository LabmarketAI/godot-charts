## Standalone LineChart3D demo.
extends Node3D

func _ready() -> void:
	_setup_env()

	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 4.0)
	add_child(frame)

	var chart := LineChart3D.new()
	chart.title   = "Stock Prices"
	chart.x_label = "Week"
	chart.y_label = "USD"
	chart.data = {
		"labels": ["Wk1", "Wk2", "Wk3", "Wk4", "Wk5", "Wk6"],
		"datasets": [
			{"name": "ACME",  "values": [142.0, 138.0, 155.0, 149.0, 162.0, 171.0]},
			{"name": "Globex","values": [ 98.0, 105.0, 101.0, 112.0, 108.0, 120.0]},
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
