@tool
class_name ScatterRenderer3D
extends Node3D

signal figure_rendered(figure_revision: int, changed_instances: int)
signal render_diagnostic(diagnostic: Dictionary)

@export var plot_size: Vector3 = Vector3(4.0, 3.0, 4.0)
@export_range(0.005, 0.25, 0.005) var point_radius: float = 0.04

var active_figure: RefCounted
var diagnostics: Array[Dictionary] = []

var _instance: MultiMeshInstance3D
var _multi_mesh: MultiMesh
var _point_mesh: SphereMesh
var _pick_records: Array[Dictionary] = []
var _primitive_to_instance: Dictionary = {}
var _base_colors: Array[Color] = []
var _selected_row_ids: PackedStringArray = []
var _clipped_rows := 0


func apply_figure(figure: RefCounted, figure_diff: RefCounted = null) -> bool:
	diagnostics.clear()
	var resolved := _resolve_point_layer(figure)
	if resolved.is_empty():
		return false
	_ensure_resources()

	var view: RefCounted = resolved["view"]
	var layer: RefCounted = resolved["layer"]
	var table: RefCounted = resolved["table"]
	var rows: Array[Dictionary] = _renderable_rows(figure, view, layer, table)
	_multi_mesh.instance_count = rows.size()
	_pick_records.clear()
	_primitive_to_instance.clear()
	_base_colors.clear()

	for instance_index: int in rows.size():
		var row: Dictionary = rows[instance_index]
		_multi_mesh.set_instance_transform(instance_index, Transform3D(Basis.IDENTITY, row["position"]))
		_multi_mesh.set_instance_color(instance_index, row["color"])
		_base_colors.append(row["color"])
		var record: Dictionary = row["pick"]
		_pick_records.append(record)
		_primitive_to_instance[record["primitive_id"]] = instance_index
	_apply_selection_colors()

	active_figure = figure
	figure_rendered.emit(figure.revision, rows.size())
	return true


func rendered_point_count() -> int:
	return 0 if _multi_mesh == null else _multi_mesh.instance_count


func render_node() -> MultiMeshInstance3D:
	return _instance


func render_resource() -> MultiMesh:
	return _multi_mesh


func resolve_pick(instance_index: int) -> Dictionary:
	if instance_index < 0 or instance_index >= _pick_records.size():
		return {}
	return _pick_records[instance_index].duplicate(true)


func resolve_primitive(primitive_id: String) -> Dictionary:
	if not _primitive_to_instance.has(primitive_id):
		return {}
	return resolve_pick(_primitive_to_instance[primitive_id])


func instance_index_for_primitive(primitive_id: String) -> int:
	return int(_primitive_to_instance.get(primitive_id, -1))


func primitive_id_for_row(row_id: String) -> String:
	for record: Dictionary in _pick_records:
		if record["row_id"] == row_id:
			return record["primitive_id"]
	return ""


func set_selected_rows(row_ids: PackedStringArray) -> void:
	_selected_row_ids = row_ids.duplicate()
	_apply_selection_colors()


func selected_row_ids() -> PackedStringArray:
	return _selected_row_ids.duplicate()


func lifecycle_snapshot() -> Dictionary:
	return {
		"render_node_instance_id": 0 if _instance == null else _instance.get_instance_id(),
		"multimesh_instance_id": 0 if _multi_mesh == null else _multi_mesh.get_instance_id(),
		"point_mesh_instance_id": 0 if _point_mesh == null else _point_mesh.get_instance_id(),
		"renderer_child_count": get_child_count(),
		"rendered_points": rendered_point_count(),
		"clipped_rows": _clipped_rows,
		"pick_records": _pick_records.size(),
	}


func is_row_selected(row_id: String) -> bool:
	return _selected_row_ids.has(row_id)


func _ensure_resources() -> void:
	if _instance != null:
		return
	_point_mesh = SphereMesh.new()
	_point_mesh.radius = point_radius
	_point_mesh.height = point_radius * 2.0
	_point_mesh.radial_segments = 8
	_point_mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_point_mesh.material = material

	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_colors = true
	_multi_mesh.mesh = _point_mesh
	_instance = MultiMeshInstance3D.new()
	_instance.name = "ScatterMarks"
	_instance.multimesh = _multi_mesh
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_instance)


func _resolve_point_layer(figure: RefCounted) -> Dictionary:
	for view: RefCounted in figure.views:
		for layer: RefCounted in view.layers:
			if layer.mark != "point":
				continue
			var table: RefCounted = figure.table(layer.data_id)
			if table == null:
				_report("missing-table", "Point layer table is unavailable.", "/views/%s/layers/%s/data_id" % [view.id, layer.id])
				return {}
			return {"view": view, "layer": layer, "table": table}
	_report("missing-point-layer", "Figure has no supported point layer.", "/views")
	return {}


func _renderable_rows(figure: RefCounted, view: RefCounted, layer: RefCounted, table: RefCounted) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	_clipped_rows = 0
	for row_id: String in table.row_ids:
		var x: Variant = _mapped_position(table, row_id, layer, view, "x")
		var y: Variant = _mapped_position(table, row_id, layer, view, "y")
		var z: Variant = _mapped_position(table, row_id, layer, view, "z")
		if x == null or y == null or z == null:
			_clipped_rows += 1
			continue
		var color := Color.WHITE
		if layer.mappings.has("color") and view.scales.has("color"):
			var color_value: Variant = table.value(row_id, layer.mappings["color"])
			var mapped_color: Variant = view.scales["color"].map(color_value)
			if mapped_color != null:
				color = Color.from_string(str(mapped_color), Color.WHITE)
		var primitive_id := "%s/%s/%s/%s" % [figure.plot_id, view.id, layer.id, row_id]
		rows.append({
			"position": Vector3(float(x) - 0.5, float(y) - 0.5, float(z) - 0.5) * plot_size,
			"color": color,
			"pick": {
				"primitive_id": primitive_id,
				"plot_id": figure.plot_id,
				"figure_id": figure.id,
				"view_id": view.id,
				"layer_id": layer.id,
				"dataset_id": table.id,
				"dataset_revision": table.revision,
				"row_id": row_id,
				"world_position": Vector3(float(x) - 0.5, float(y) - 0.5, float(z) - 0.5) * plot_size,
				"values": _row_values(table, row_id),
			},
		})
	return rows


func _mapped_position(table: RefCounted, row_id: String, layer: RefCounted, view: RefCounted, channel: String) -> Variant:
	if not layer.mappings.has(channel) or not view.scales.has(channel):
		return null
	var scale: RefCounted = view.scales[channel]
	var value: Variant = table.value(row_id, layer.mappings[channel])
	if scale.has_method("visible_contains") and not scale.visible_contains(value):
		return null
	return scale.map(value)


func _row_values(table: RefCounted, row_id: String) -> Dictionary:
	var values: Dictionary = {}
	for column_id: Variant in table.columns:
		values[column_id] = table.value(row_id, column_id)
	return values


func _apply_selection_colors() -> void:
	if _multi_mesh == null:
		return
	for instance_index: int in _pick_records.size():
		var color: Color = _base_colors[instance_index]
		if _selected_row_ids.has(_pick_records[instance_index]["row_id"]):
			color = color.lightened(0.4)
		_multi_mesh.set_instance_color(instance_index, color)


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	render_diagnostic.emit(diagnostic)
