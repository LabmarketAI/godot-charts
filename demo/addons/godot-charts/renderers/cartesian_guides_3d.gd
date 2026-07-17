class_name CartesianGuides3D
extends Node3D

signal guides_rendered(figure_revision: int, tick_count: int)
signal guide_diagnostic(diagnostic: Dictionary)

const Ticks = preload("res://addons/godot-charts/core/linear_ticks.gd")

@export_range(2, 12, 1) var target_tick_count: int = 5
@export var axis_color := Color(0.72, 0.76, 0.82, 0.9)
@export var grid_color := Color(0.42, 0.47, 0.55, 0.22)
@export var label_color := Color(0.88, 0.9, 0.94, 1.0)

var diagnostics: Array[Dictionary] = []

var _axis_instance: MeshInstance3D
var _axis_mesh: ImmediateMesh
var _axis_material: StandardMaterial3D
var _grid_instance: MeshInstance3D
var _grid_mesh: ImmediateMesh
var _grid_material: StandardMaterial3D
var _tick_labels: Array[Label3D] = []
var _axis_labels: Array[Label3D] = []
var _landmark_labels: Array[Label3D] = []
var _title_label: Label3D
var _chrome_root: Node3D
var _active_tick_labels: int = 0


func bind_chrome_root(chrome_root: Node3D) -> void:
	_ensure_resources()
	_chrome_root = chrome_root
	if _title_label.get_parent() != chrome_root:
		_title_label.reparent(chrome_root, false)


func apply_figure(figure: RefCounted, plot_size: Vector3) -> bool:
	diagnostics.clear()
	var view := _cartesian_view(figure)
	if view == null:
		_report("missing-cartesian-view", "Figure has no supported Cartesian 3D view.", "/views")
		return false
	for channel: String in ["x", "y", "z"]:
		if not view.scales.has(channel):
			_report("missing-guide-scale", "Cartesian guide scale is unavailable.", "/views/%s/scales/%s" % [view.id, channel])
			return false
		if not view.scales[channel].has_method("map"):
			_report("unsupported-guide-scale", "Cartesian guide scale is not mappable.", "/views/%s/scales/%s" % [view.id, channel])
			return false
	_ensure_resources()
	var ticks_by_channel: Dictionary = {}
	for channel: String in ["x", "y", "z"]:
		var scale: RefCounted = view.scales[channel]
		ticks_by_channel[channel] = Ticks.generate(scale.domain_min, scale.domain_max, target_tick_count)
	_build_lines(view, plot_size, ticks_by_channel)
	_build_labels(figure, view, plot_size, ticks_by_channel)
	guides_rendered.emit(figure.revision, _active_tick_labels)
	return true


func lifecycle_snapshot() -> Dictionary:
	_ensure_resources()
	return {
		"axis_node": _axis_instance.get_instance_id(),
		"axis_mesh": _axis_mesh.get_instance_id(),
		"grid_node": _grid_instance.get_instance_id(),
		"grid_mesh": _grid_mesh.get_instance_id(),
		"axis_surfaces": _axis_mesh.get_surface_count(),
		"grid_surfaces": _grid_mesh.get_surface_count(),
		"title_label": _title_label.get_instance_id(),
		"tick_label_pool": _tick_labels.size(),
		"axis_label_pool": _axis_labels.size(),
		"landmark_label_pool": _landmark_labels.size(),
		"active_tick_labels": _active_tick_labels,
		"guide_child_count": get_child_count(),
	}


func title_text() -> String:
	return "" if _title_label == null else _title_label.text


func visible_tick_texts() -> PackedStringArray:
	var values := PackedStringArray()
	for label: Label3D in _tick_labels:
		if label.visible:
			values.append(label.text)
	return values


func _ready() -> void:
	_ensure_resources()


func _ensure_resources() -> void:
	if _axis_instance != null:
		return
	_axis_material = _line_material(axis_color)
	_grid_material = _line_material(grid_color)
	_axis_mesh = ImmediateMesh.new()
	_axis_instance = MeshInstance3D.new()
	_axis_instance.name = "Axes"
	_axis_instance.mesh = _axis_mesh
	_axis_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_axis_instance)
	_grid_mesh = ImmediateMesh.new()
	_grid_instance = MeshInstance3D.new()
	_grid_instance.name = "Grid"
	_grid_instance.mesh = _grid_mesh
	_grid_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_grid_instance)
	_title_label = _new_label("FigureTitle")
	add_child(_title_label)


func _build_lines(view: RefCounted, size: Vector3, ticks_by_channel: Dictionary) -> void:
	var low := size * -0.5
	var high := size * 0.5
	var axis_points: Array[Vector3] = [
		low, Vector3(high.x, low.y, low.z),
		low, Vector3(low.x, high.y, low.z),
		low, Vector3(low.x, low.y, high.z),
	]
	var grid_points: Array[Vector3] = []
	var tick_length := maxf(size.length() * 0.012, 0.035)
	for channel: String in ["x", "y", "z"]:
		var scale: RefCounted = view.scales[channel]
		for tick: float in ticks_by_channel[channel]:
			var unit: float = float(scale.map(tick))
			match channel:
				"x":
					var x := lerpf(low.x, high.x, unit)
					grid_points.append_array([Vector3(x, low.y, low.z), Vector3(x, high.y, low.z), Vector3(x, low.y, low.z), Vector3(x, low.y, high.z)])
					axis_points.append_array([Vector3(x, low.y, low.z), Vector3(x, low.y - tick_length, low.z)])
				"y":
					var y := lerpf(low.y, high.y, unit)
					grid_points.append_array([Vector3(low.x, y, low.z), Vector3(high.x, y, low.z), Vector3(low.x, y, low.z), Vector3(low.x, y, high.z)])
					axis_points.append_array([Vector3(low.x, y, low.z), Vector3(low.x - tick_length, y, low.z)])
				"z":
					var z := lerpf(low.z, high.z, unit)
					grid_points.append_array([Vector3(low.x, low.y, z), Vector3(high.x, low.y, z), Vector3(low.x, low.y, z), Vector3(low.x, high.y, z)])
					axis_points.append_array([Vector3(low.x, low.y, z), Vector3(low.x - tick_length, low.y, z)])
	_write_lines(_axis_mesh, _axis_material, axis_points)
	_write_lines(_grid_mesh, _grid_material, grid_points)


func _build_labels(figure: RefCounted, view: RefCounted, size: Vector3, ticks_by_channel: Dictionary) -> void:
	var low := size * -0.5
	var high := size * 0.5
	var label_offset := maxf(size.length() * 0.025, 0.08)
	var label_index := 0
	for channel: String in ["x", "y", "z"]:
		var scale: RefCounted = view.scales[channel]
		var ticks: Array = ticks_by_channel[channel]
		var step: float = absf(float(ticks[1]) - float(ticks[0])) if ticks.size() > 1 else scale.domain_max - scale.domain_min
		for tick: float in ticks:
			var label := _pooled_label(_tick_labels, label_index, "Tick")
			label.text = Ticks.format(tick, step)
			var unit: float = float(scale.map(tick))
			match channel:
				"x": label.position = Vector3(lerpf(low.x, high.x, unit), low.y - label_offset, low.z)
				"y": label.position = Vector3(low.x - label_offset, lerpf(low.y, high.y, unit), low.z)
				"z": label.position = Vector3(low.x - label_offset, low.y, lerpf(low.z, high.z, unit))
			label.visible = true
			label_index += 1
	_active_tick_labels = label_index
	_hide_pool_after(_tick_labels, label_index)

	var titles := {"x": "X", "y": "Y", "z": "Z"}
	for guide: RefCounted in view.guides:
		if guide.type == "axis" and guide.channel in titles:
			titles[guide.channel] = guide.title
	var axis_positions := [
		Vector3(0.0, low.y - label_offset * 2.1, low.z),
		Vector3(low.x - label_offset * 2.1, 0.0, low.z),
		Vector3(low.x - label_offset * 2.1, low.y, 0.0),
	]
	for index: int in 3:
		var axis_label := _pooled_label(_axis_labels, index, "AxisTitle")
		axis_label.text = titles[["x", "y", "z"][index]]
		axis_label.position = axis_positions[index]
		axis_label.visible = true

	for index: int in 4:
		var landmark := _pooled_label(_landmark_labels, index, "Orientation")
		landmark.text = ["X+", "Y+", "Z+", "O · RESET"][index]
		landmark.position = [Vector3(high.x, low.y, low.z), Vector3(low.x, high.y, low.z), Vector3(low.x, low.y, high.z), low + Vector3(label_offset, label_offset, label_offset)][index]
		landmark.visible = true
	_title_label.text = figure.title
	_title_label.position = Vector3(0.0, high.y + label_offset * 2.0, low.z)
	_title_label.visible = not figure.title.is_empty()


func _cartesian_view(figure: RefCounted) -> RefCounted:
	for view: RefCounted in figure.views:
		if view.coordinate_system == "cartesian_3d":
			return view
	return null


func _pooled_label(pool: Array[Label3D], index: int, prefix: String) -> Label3D:
	while pool.size() <= index:
		var label := _new_label(prefix + str(pool.size()))
		pool.append(label)
		add_child(label)
	return pool[index]


func _hide_pool_after(pool: Array[Label3D], count: int) -> void:
	for index: int in range(count, pool.size()):
		pool[index].visible = false


func _new_label(label_name: String) -> Label3D:
	var label := Label3D.new()
	label.name = label_name
	label.font_size = 32
	label.pixel_size = 0.003
	label.outline_size = 6
	label.modulate = label_color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	return label


func _line_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.vertex_color_use_as_albedo = false
	return material


func _write_lines(mesh: ImmediateMesh, material: Material, points: Array[Vector3]) -> void:
	mesh.clear_surfaces()
	if points.is_empty():
		return
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for point: Vector3 in points:
		mesh.surface_add_vertex(point)
	mesh.surface_end()


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	guide_diagnostic.emit(diagnostic.duplicate(true))
