## Standalone HistogramChart3D demo.
extends Node3D

func _ready() -> void:
	_setup_env()

	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 4.0)
	add_child(frame)

	var chart := HistogramChart3D.new()
	chart.title   = "Height Distribution (cm)"
	chart.x_label = "Height"
	chart.y_label = "Count"
	# Approximately normal distribution around 170 cm
	chart.raw_data = [
		152.0, 155.0, 157.0, 158.0, 160.0, 161.0, 162.0, 163.0,
		163.0, 164.0, 165.0, 165.0, 166.0, 167.0, 167.0, 168.0,
		168.0, 169.0, 169.0, 170.0, 170.0, 170.0, 171.0, 171.0,
		172.0, 172.0, 173.0, 173.0, 174.0, 175.0, 176.0, 177.0,
		178.0, 180.0, 182.0, 185.0, 188.0,
	]
	chart.n_bins = 10
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
