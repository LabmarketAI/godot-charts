## Standalone ScatterChart3D demo.
extends Node3D

func _ready() -> void:
	_setup_env()

	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 4.0)
	add_child(frame)

	var chart := ScatterChart3D.new()
	chart.title = "3-D Point Cloud"
	chart.data = {
		"datasets": [
			{
				"name": "Cluster A",
				"points": [
					Vector3(0.2, 1.3, 0.5), Vector3(0.8, 0.4, 1.1),
					Vector3(0.5, 0.9, 0.7), Vector3(1.0, 1.5, 0.3),
					Vector3(0.3, 1.1, 0.9), Vector3(0.7, 0.6, 1.3),
				],
			},
			{
				"name": "Cluster B",
				"points": [
					Vector3(2.0, 0.6, 0.3), Vector3(1.7, 1.2, 1.9),
					Vector3(1.4, 0.3, 1.5), Vector3(1.9, 1.8, 0.8),
					Vector3(2.2, 1.0, 1.2), Vector3(1.6, 0.7, 0.6),
				],
			},
			{
				"name": "Cluster C",
				"points": [
					Vector3(1.0, 2.5, 1.5), Vector3(1.2, 2.2, 1.8),
					Vector3(0.8, 2.8, 1.2), Vector3(1.4, 2.4, 1.0),
				],
			},
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
