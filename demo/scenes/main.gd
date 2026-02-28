## Godot Charts — full demo.
##
## Arranges all chart types in a 3-column grid so you can inspect every chart
## at once.  Press [1]–[7] to jump the camera to a specific chart.
##
## Layout (top view):
##   col 0        col 1        col 2
##   BarChart3D   LineChart3D  ScatterChart3D     (row 0, top)
##   SurfaceChart HistogramChart GraphNet2D       (row 1, middle)
##   GraphNet3D   —            —                 (row 2, bottom)
extends Node3D

const FRAME_W := 5.0
const FRAME_H := 4.0
const COL_STEP := 6.0   # horizontal spacing between frame centres
const ROW_STEP := 5.0   # vertical spacing between frame centres

var _camera: Camera3D
var _frame_centres: Array[Vector3] = []


func _ready() -> void:
	_setup_lighting()
	_build_demos()
	_setup_camera()
	_show_hint()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var k := event.keycode
	if k >= KEY_1 and k <= KEY_7:
		var idx := k - KEY_1
		if idx < _frame_centres.size():
			_fly_to(_frame_centres[idx])


# ---------------------------------------------------------------------------
# Demos
# ---------------------------------------------------------------------------

func _build_demos() -> void:
	_demo_bar_chart(_col_row(0, 0))
	_demo_line_chart(_col_row(1, 0))
	_demo_scatter_chart(_col_row(2, 0))
	_demo_surface_chart(_col_row(0, 1))
	_demo_histogram(_col_row(1, 1))
	_demo_graph_2d(_col_row(2, 1))
	_demo_graph_3d(_col_row(0, 2))


func _demo_bar_chart(pos: Vector3) -> void:
	var frame := _make_frame("Bar Chart", pos)
	var chart := BarChart3D.new()
	chart.title   = "Monthly Sales"
	chart.x_label = "Month"
	chart.y_label = "Units"
	chart.data = {
		"labels":   ["Jan", "Feb", "Mar", "Apr"],
		"datasets": [
			{"name": "Product A", "values": [120.0,  95.0, 140.0, 180.0]},
			{"name": "Product B", "values": [ 80.0, 110.0,  90.0, 130.0]},
		],
	}
	frame.add_child(chart)


func _demo_line_chart(pos: Vector3) -> void:
	var frame := _make_frame("Line Chart", pos)
	var chart := LineChart3D.new()
	chart.title   = "Quarterly Revenue"
	chart.x_label = "Quarter"
	chart.y_label = "USD (M)"
	chart.data = {
		"labels":   ["Q1", "Q2", "Q3", "Q4"],
		"datasets": [
			{"name": "Revenue",  "values": [1.2, 3.5, 2.8, 4.2]},
			{"name": "Expenses", "values": [0.9, 1.4, 2.1, 1.9]},
		],
	}
	frame.add_child(chart)


func _demo_scatter_chart(pos: Vector3) -> void:
	var frame := _make_frame("Scatter Plot", pos)
	var chart := ScatterChart3D.new()
	chart.title = "3-D Point Cloud"
	chart.data = {
		"datasets": [
			{
				"name": "Group A",
				"points": [
					Vector3(0.2, 1.3, 0.5), Vector3(0.8, 0.4, 1.1),
					Vector3(0.5, 0.9, 0.7), Vector3(1.0, 1.5, 0.3),
				],
			},
			{
				"name": "Group B",
				"points": [
					Vector3(2.0, 0.6, 0.3), Vector3(1.7, 1.2, 1.9),
					Vector3(1.4, 0.3, 1.5), Vector3(1.9, 1.8, 0.8),
				],
			},
		],
	}
	frame.add_child(chart)


func _demo_surface_chart(pos: Vector3) -> void:
	var frame := _make_frame("Surface Chart", pos)
	var chart := SurfaceChart3D.new()
	chart.title = "sin(x)·cos(z)"
	chart.surface_function = func(x: float, z: float) -> float:
		return sin(x * TAU) * cos(z * TAU) * 0.5 + 0.5
	chart.grid_cols = 24
	chart.grid_rows = 24
	frame.add_child(chart)


func _demo_histogram(pos: Vector3) -> void:
	var frame := _make_frame("Histogram", pos)
	var chart := HistogramChart3D.new()
	chart.title = "Sample Distribution"
	chart.x_label = "Value"
	chart.y_label = "Count"
	# Simulated normal-ish data around 50
	chart.raw_data = [
		28.0, 33.0, 35.0, 38.0, 40.0, 42.0, 43.0, 44.0, 45.0, 46.0,
		47.0, 48.0, 49.0, 50.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0,
		56.0, 57.0, 58.0, 60.0, 62.0, 65.0, 68.0, 72.0,
	]
	chart.n_bins = 8
	frame.add_child(chart)


func _demo_graph_2d(pos: Vector3) -> void:
	var frame := _make_frame("Graph Network 2D", pos)
	var chart := GraphNetworkChart2D.new()
	chart.title = "Social Graph"
	chart.layout_mode = 1  # CIRCULAR
	chart.data = {
		"nodes": [
			{"id": "alice",   "label": "Alice"},
			{"id": "bob",     "label": "Bob"},
			{"id": "carol",   "label": "Carol"},
			{"id": "dave",    "label": "Dave"},
			{"id": "eve",     "label": "Eve"},
		],
		"edges": [
			{"source": "alice", "target": "bob"},
			{"source": "alice", "target": "carol"},
			{"source": "bob",   "target": "dave"},
			{"source": "carol", "target": "dave"},
			{"source": "dave",  "target": "eve"},
			{"source": "eve",   "target": "alice"},
		],
	}
	frame.add_child(chart)


func _demo_graph_3d(pos: Vector3) -> void:
	var frame := _make_frame("Graph Network 3D", pos)
	var chart := GraphNetworkChart3D.new()
	chart.title = "3-D Network"
	chart.layout_mode = 1  # CIRCULAR (Fibonacci sphere)
	chart.data = {
		"nodes": [
			{"id": "hub",  "label": "Hub"},
			{"id": "n1",   "label": "N1"},
			{"id": "n2",   "label": "N2"},
			{"id": "n3",   "label": "N3"},
			{"id": "n4",   "label": "N4"},
			{"id": "n5",   "label": "N5"},
			{"id": "n6",   "label": "N6"},
		],
		"edges": [
			{"source": "hub", "target": "n1"},
			{"source": "hub", "target": "n2"},
			{"source": "hub", "target": "n3"},
			{"source": "hub", "target": "n4"},
			{"source": "hub", "target": "n5"},
			{"source": "hub", "target": "n6"},
			{"source": "n1",  "target": "n2"},
			{"source": "n3",  "target": "n4"},
		],
	}
	frame.add_child(chart)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _col_row(col: int, row: int) -> Vector3:
	var pos := Vector3(col * COL_STEP, -row * ROW_STEP, 0.0)
	_frame_centres.append(pos)
	return pos


func _make_frame(label: String, pos: Vector3) -> ChartFrame3D:
	var frame := ChartFrame3D.new()
	frame.size = Vector2(FRAME_W, FRAME_H)
	frame.position = pos
	add_child(frame)
	# Small label above the frame (plain Label3D so it works without @tool)
	var lbl := Label3D.new()
	lbl.text = "[%d] %s" % [_frame_centres.size(), label]
	lbl.font_size = 24
	lbl.position = Vector3(FRAME_W * 0.5, FRAME_H + 0.3, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	frame.add_child(lbl)
	return frame


func _setup_camera() -> void:
	_camera = Camera3D.new()
	# Position to see the full 3-column, 3-row grid
	_camera.position = Vector3(COL_STEP, -ROW_STEP, 22.0)
	_camera.look_at(Vector3(COL_STEP, -ROW_STEP, 0.0))
	add_child(_camera)


func _setup_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.9)
	env.ambient_light_energy = 0.6

	var wenv := WorldEnvironment.new()
	wenv.environment = env
	add_child(wenv)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	sun.light_energy = 1.2
	add_child(sun)


func _fly_to(target: Vector3) -> void:
	# Instant snap — replace with a Tween for a smooth fly-to if desired
	_camera.position = target + Vector3(FRAME_W * 0.5, FRAME_H * 0.5, 12.0)
	_camera.look_at(target + Vector3(FRAME_W * 0.5, FRAME_H * 0.5, 0.0))


func _show_hint() -> void:
	print("Godot Charts Demo — press [1]-[7] to fly to each chart")
