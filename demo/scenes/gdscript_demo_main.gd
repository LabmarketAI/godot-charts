extends Node3D

const AnalyticalFrame = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const ScatterRenderer = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const Guides = preload("res://addons/godot-charts/renderers/cartesian_guides_3d.gd")
const PlotFigureModel = preload("res://addons/godot-charts/core/plot_figure.gd")
const PlotViewModel = preload("res://addons/godot-charts/core/plot_view.gd")
const PlotLayerModel = preload("res://addons/godot-charts/core/plot_layer.gd")
const PlotTableModel = preload("res://addons/godot-charts/core/plot_table.gd")
const LinearScaleModel = preload("res://addons/godot-charts/core/linear_scale.gd")
const CategoricalScaleModel = preload("res://addons/godot-charts/core/categorical_scale.gd")
const PlotGuideModel = preload("res://addons/godot-charts/core/plot_guide.gd")

const HANDLE_LINEAR_SCENE := "res://addons/godot-charts/assets/visual/glb/control_handle_linear.glb"
const MOVE_SPEED := 2.8
const SPRINT_MULTIPLIER := 2.2
const MOUSE_SENSITIVITY := 0.0025
const LOOK_PITCH_LIMIT := 1.35

var _camera_rig: Node3D
var _camera: Camera3D
var _yaw := 0.0
var _pitch := -0.12
var _mouse_captured := false


func _ready() -> void:
	_build_world()
	_build_desktop_camera()
	_build_reference_floor()
	_build_chart_frame()
	_build_new_asset_station()
	_build_status_labels()


func _process(delta: float) -> void:
	_update_desktop_controls(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_mouse_captured(true)
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_set_mouse_captured(false)
	elif event is InputEventMouseMotion and _mouse_captured:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -LOOK_PITCH_LIMIT, LOOK_PITCH_LIMIT)
		_apply_camera_rotation()


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.04, 0.048)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.82)
	env.ambient_light_energy = 0.42
	environment.environment = env
	add_child(environment)

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_energy = 2.1
	key.rotation_degrees = Vector3(-46.0, 30.0, 0.0)
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "AssetFillLight"
	fill.light_energy = 0.85
	fill.omni_range = 5.0
	fill.position = Vector3(-1.8, 2.2, 1.8)
	add_child(fill)


func _build_desktop_camera() -> void:
	_camera_rig = Node3D.new()
	_camera_rig.name = "DesktopCameraRig"
	_camera_rig.position = Vector3(0.0, 1.55, 4.6)
	add_child(_camera_rig)

	_camera = Camera3D.new()
	_camera.name = "DesktopCamera"
	_camera.current = true
	_camera.fov = 68.0
	_camera.near = 0.03
	_camera_rig.add_child(_camera)
	_apply_camera_rotation()


func _build_reference_floor() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(7.0, 7.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.09, 0.105, 0.12)
	material.roughness = 0.86
	mesh.material = material

	var floor := MeshInstance3D.new()
	floor.name = "ReferenceFloor"
	floor.mesh = mesh
	add_child(floor)

	var grid := GridMap.new()
	grid.name = "ScaleReference"
	grid.visible = false
	add_child(grid)


func _build_chart_frame() -> void:
	var frame := AnalyticalFrame.new()
	frame.name = "FreshChartFrame"
	add_child(frame)

	var state := FrameState.new(
		"fresh-chart-frame",
		Transform3D(Basis.IDENTITY, Vector3(0.0, 1.35, -0.35)),
		Vector3(3.2, 2.0, 2.0),
		"Asset Lab Chart"
	)
	state.aspect_policy = "fit"
	frame.apply_frame_state(state)

	var scatter := ScatterRenderer.new()
	scatter.name = "FreshScatterRenderer"
	scatter.point_radius = 0.045
	var guides := Guides.new()
	guides.name = "FreshCartesianGuides"
	guides.target_tick_count = 4
	frame.bind_content(scatter)
	frame.bind_guide_renderer(guides)
	frame.apply_figure(_sample_figure())


func _build_new_asset_station() -> void:
	var station := get_node_or_null("NewAssetStation") as Node3D
	if station == null:
		station = Node3D.new()
		station.name = "NewAssetStation"
		add_child(station)
	station.position = Vector3(1.95, 0.88, 0.25)

	var installed := station.get_node_or_null("ControlHandleLinearInstalled")
	if installed != null:
		installed.set_meta("asset_source", "editor-installed")
	else:
		var handle_scene := load(HANDLE_LINEAR_SCENE)
		if handle_scene is PackedScene:
			var handle: Node = handle_scene.instantiate()
			handle.name = "ControlHandleLinearRuntime"
			handle.scale = Vector3.ONE * 2.2
			handle.set_meta("asset_source", "runtime-loaded")
			station.add_child(handle)
		else:
			station.add_child(_fallback_handle())

	_add_label(station, "control/handle_linear", Vector3(0.0, 0.22, 0.0), 0.0042)
	_add_label(station, "GLB asset", Vector3(0.0, 0.14, 0.0), 0.0034)


func _fallback_handle() -> Node3D:
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.08
	body_mesh.height = 0.16
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.14, 0.62, 0.86)
	material.roughness = 0.48
	body_mesh.material = material
	var body := MeshInstance3D.new()
	body.name = "FallbackHandleLinear"
	body.mesh = body_mesh
	return body


func _build_status_labels() -> void:
	_add_label(self, "WASD move  QE up/down  Shift sprint  Click mouse-look  Esc release", Vector3(0.0, 2.9, -1.35), 0.004)
	_add_label(self, "Fresh 4.7 GDScript scene with new chart assets", Vector3(0.0, 2.75, -1.35), 0.004)


func _add_label(parent: Node, text: String, position: Vector3, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.name = text.to_pascal_case().left(32)
	label.text = text
	label.position = position
	label.font_size = 32
	label.pixel_size = pixel_size
	label.modulate = Color(0.9, 0.93, 0.96)
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label


func _update_desktop_controls(delta: float) -> void:
	if _camera_rig == null:
		return
	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction -= _camera_rig.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += _camera_rig.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= _camera_rig.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += _camera_rig.basis.x
	if Input.is_key_pressed(KEY_E):
		direction += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		direction -= Vector3.UP
	if direction.length_squared() == 0.0:
		return
	var speed := MOVE_SPEED * (SPRINT_MULTIPLIER if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	_camera_rig.position += direction.normalized() * speed * delta


func _apply_camera_rotation() -> void:
	if _camera_rig == null or _camera == null:
		return
	_camera_rig.basis = Basis(Vector3.UP, _yaw)
	_camera.basis = Basis(Vector3.RIGHT, _pitch)


func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured = captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _sample_figure() -> RefCounted:
	var rows := PackedStringArray()
	var xs: Array[float] = []
	var ys: Array[float] = []
	var zs: Array[float] = []
	var groups: Array[String] = []
	for index: int in 32:
		rows.append("row-%02d" % index)
		var unit := float(index) / 31.0
		xs.append(unit * 10.0)
		ys.append(1.2 + sin(unit * TAU * 1.25) * 1.4 + unit * 4.8)
		zs.append(1.0 + cos(unit * TAU * 0.85) * 1.2 + unit * 5.6)
		groups.append(["A", "B", "C"][index % 3])

	var table := PlotTableModel.new("fresh-data", 1, rows, {
		"x": xs,
		"y": ys,
		"z": zs,
		"group": groups,
	})
	var layer := PlotLayerModel.new("points", "point", "fresh-data", {
		"x": "x",
		"y": "y",
		"z": "z",
		"color": "group",
	})
	var view := PlotViewModel.new("main", "cartesian_3d", [layer], {
		"x": LinearScaleModel.new(0.0, 10.0, 0.0, 1.0, true),
		"y": LinearScaleModel.new(0.0, 8.0, 0.0, 1.0, true),
		"z": LinearScaleModel.new(0.0, 8.0, 0.0, 1.0, true),
		"color": CategoricalScaleModel.new(PackedStringArray(["A", "B", "C"]), [
			"#2f80ed",
			"#27ae60",
			"#f2994a",
		]),
	}, [
		PlotGuideModel.new("x-axis", "axis", "x", "X"),
		PlotGuideModel.new("y-axis", "axis", "y", "Y"),
		PlotGuideModel.new("z-axis", "axis", "z", "Z"),
	])
	return PlotFigureModel.new(
		"fresh-asset-lab-figure",
		"fresh-asset-lab",
		1,
		"Asset Lab Scatter",
		[view],
		{"fresh-data": table},
		{"name": "demo"},
		{"source": "gdscript-only"},
	)
