## Graph network demo — shows GraphNetworkChart2D and GraphNetworkChart3D side by side.
## Press [Tab] to cycle through layout modes (Preset → Circular → Spring).
extends Node3D

var _chart2d: GraphNetworkChart2D
var _chart3d: GraphNetworkChart3D
var _layout := 1  # start at CIRCULAR


func _ready() -> void:
	_setup_env()
	_build_2d()
	_build_3d()
	_setup_camera()

	var hint := Label3D.new()
	hint.text = "Press [Tab] to cycle layout modes"
	hint.font_size = 18
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.position = Vector3(7.0, -0.8, 0.0)
	add_child(hint)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		_layout = (_layout + 1) % 3
		_chart2d.layout_mode = _layout
		_chart3d.layout_mode = _layout


var _GRAPH_DATA := {
	"nodes": [
		{"id": "alice",  "label": "Alice",  "type": "person"},
		{"id": "bob",    "label": "Bob",    "type": "person"},
		{"id": "carol",  "label": "Carol",  "type": "person"},
		{"id": "dave",   "label": "Dave",   "type": "person"},
		{"id": "server", "label": "Server", "type": "machine"},
		{"id": "db",     "label": "DB",     "type": "machine"},
	],
	"edges": [
		{"source": "alice",  "target": "bob",    "label": "friend"},
		{"source": "alice",  "target": "carol",  "label": "friend"},
		{"source": "bob",    "target": "server", "label": "connects"},
		{"source": "carol",  "target": "server", "label": "connects"},
		{"source": "dave",   "target": "server", "label": "connects"},
		{"source": "server", "target": "db",     "label": "reads"},
	],
}


func _build_2d() -> void:
	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 5.0)
	frame.position = Vector3(0.0, 0.0, 0.0)
	add_child(frame)

	_chart2d = GraphNetworkChart2D.new()
	_chart2d.title = "Graph Network 2D"
	_chart2d.layout_mode = _layout
	_chart2d.data = _GRAPH_DATA
	frame.add_child(_chart2d)


func _build_3d() -> void:
	var frame := ChartFrame3D.new()
	frame.size = Vector2(6.0, 5.0)
	frame.position = Vector3(7.0, 0.0, 0.0)
	add_child(frame)

	_chart3d = GraphNetworkChart3D.new()
	_chart3d.title = "Graph Network 3D"
	_chart3d.layout_mode = _layout
	_chart3d.data = _GRAPH_DATA
	frame.add_child(_chart3d)


func _setup_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(6.5, 2.5, 14.0)
	cam.look_at(Vector3(6.5, 2.5, 0.0))
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
