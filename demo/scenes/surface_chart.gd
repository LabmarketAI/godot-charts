## Standalone SurfaceChart3D demo — two modes shown sequentially.
## Press Space to toggle between callable and grid-data modes.
extends Node3D

var _chart: SurfaceChart3D
var _mode := 0


func _ready() -> void:
	_setup_env()

	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 4.0)
	add_child(frame)

	_chart = SurfaceChart3D.new()
	_chart.grid_cols = 28
	_chart.grid_rows = 28
	frame.add_child(_chart)
	_apply_mode()

	var cam := Camera3D.new()
	cam.position = Vector3(3.0, 2.0, 10.0)
	cam.look_at(Vector3(3.0, 2.0, 0.0))
	add_child(cam)

	var hint := Label3D.new()
	hint.text = "Press [Space] to switch surface mode"
	hint.font_size = 18
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.position = Vector3(3.0, -0.6, 0.0)
	add_child(hint)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		_mode = (_mode + 1) % 2
		_apply_mode()


func _apply_mode() -> void:
	match _mode:
		0:
			_chart.title = "sin(x)·cos(z)  [callable]"
			_chart.surface_function = func(x: float, z: float) -> float:
				return sin(x * TAU) * cos(z * TAU) * 0.5 + 0.5
		1:
			_chart.title = "Grid data"
			_chart.surface_function = Callable()  # clear callable
			_chart.grid_data = [
				[0.0, 0.2, 0.5, 0.8, 1.0],
				[0.1, 0.4, 0.9, 0.6, 0.7],
				[0.3, 0.7, 1.5, 0.8, 0.4],
				[0.5, 0.9, 0.8, 0.5, 0.2],
				[0.2, 0.4, 0.3, 0.1, 0.0],
			]


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
