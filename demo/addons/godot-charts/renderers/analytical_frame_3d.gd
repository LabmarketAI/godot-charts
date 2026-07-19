@tool
class_name AnalyticalFrame3D
extends Node3D

signal frame_state_applied(frame_id: String)
signal frame_diagnostic(diagnostic: Dictionary)

const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")

var active_state: RefCounted
var diagnostics: Array[Dictionary] = []

var _content_root: Node3D
var _guide_root: Node3D
var _chrome_root: Node3D
var _handle_root: Node3D
var _bounds_instance: MeshInstance3D
var _bounds_mesh: BoxMesh
var _bounds_material: StandardMaterial3D
var _content_renderer: Node3D
var _guide_renderer: Node3D
var _table_view: Control
var _content_base_size := Vector3.ONE
var _title: String = ""
var _source_status: String = "ready"
var _theme_ref: String = "theme-neutral"
var _locked: bool = false
var _interaction_mode: String = "content"
var _frame_selected: bool = false
var _capture_active: bool = false


func apply_frame_state(state: RefCounted) -> bool:
	diagnostics.clear()
	if state == null or not state.has_method("validate") or not state.has_method("to_dictionary"):
		_report("invalid-frame-state", "Frame presentation requires a valid frame-state contract.", "/frame")
		return false
	var validation: Array = state.validate()
	if not validation.is_empty():
		for diagnostic: Dictionary in validation:
			diagnostics.append(diagnostic.duplicate(true))
			frame_diagnostic.emit(diagnostic.duplicate(true))
		return false

	_ensure_structure()
	var next_state: RefCounted = FrameState.from_dictionary(state.to_dictionary())
	transform = next_state.transform
	visible = next_state.visible
	_title = next_state.title
	_source_status = next_state.source_status
	_theme_ref = next_state.theme_ref
	_locked = next_state.locked
	_bounds_mesh.size = next_state.bounds
	_layout_domain_handles(next_state.bounds)
	_update_interaction_presentation()
	_chrome_root.set_meta("title", _title)
	_chrome_root.set_meta("source_status", _source_status)
	_chrome_root.set_meta("theme_ref", _theme_ref)
	_apply_content_bounds(next_state.bounds, next_state.aspect_policy)
	active_state = next_state
	frame_state_applied.emit(next_state.id)
	return true


func bind_content(renderer: Node3D, table_view: Control = null) -> bool:
	if renderer == null or not renderer.has_method("apply_figure"):
		_report("invalid-content-renderer", "Frame content renderer must implement apply_figure.", "/frame/content")
		return false
	if table_view != null and not table_view.has_method("display_window"):
		_report("invalid-table-view", "Frame table port must implement display_window.", "/frame/table")
		return false
	_ensure_structure()
	if _content_renderer != null and _content_renderer != renderer:
		_report("content-already-bound", "Frame already owns a different content renderer.", "/frame/content")
		return false
	_content_renderer = renderer
	_table_view = table_view
	if renderer.get_parent() != _content_root:
		if renderer.get_parent() == null:
			_content_root.add_child(renderer)
		else:
			renderer.reparent(_content_root, false)
	if _has_property(renderer, "plot_size"):
		_content_base_size = renderer.plot_size
	if active_state != null:
		_apply_content_bounds(active_state.bounds, active_state.aspect_policy)
	return true


func bind_guide_renderer(renderer: Node3D) -> bool:
	if renderer == null or not renderer.has_method("apply_figure"):
		_report("invalid-guide-renderer", "Frame guide renderer must implement apply_figure.", "/frame/guides")
		return false
	_ensure_structure()
	if _guide_renderer != null and _guide_renderer != renderer:
		_report("guides-already-bound", "Frame already owns a different guide renderer.", "/frame/guides")
		return false
	_guide_renderer = renderer
	if renderer.get_parent() != _guide_root:
		if renderer.get_parent() == null:
			_guide_root.add_child(renderer)
		else:
			renderer.reparent(_guide_root, false)
	if renderer.has_method("bind_chrome_root"):
		renderer.bind_chrome_root(_chrome_root)
	return true


func apply_figure(figure: RefCounted, figure_diff: RefCounted = null) -> bool:
	diagnostics.clear()
	if _content_renderer == null:
		_report("missing-content-renderer", "Frame has no bound content renderer.", "/frame/content")
		return false
	if not _content_renderer.apply_figure(figure, figure_diff):
		_append_component_diagnostics(_content_renderer)
		return false
	if _guide_renderer != null:
		var plot_size: Vector3 = _content_renderer.plot_size if _has_property(_content_renderer, "plot_size") else active_state.bounds
		if not _guide_renderer.apply_figure(figure, plot_size):
			_append_component_diagnostics(_guide_renderer)
			return false
	return true


func set_selected_rows(row_ids: PackedStringArray) -> void:
	if _content_renderer != null and _content_renderer.has_method("set_selected_rows"):
		_content_renderer.set_selected_rows(row_ids)


func selected_row_ids() -> PackedStringArray:
	return PackedStringArray() if _content_renderer == null else _content_renderer.selected_row_ids()


func resolve_primitive(primitive_id: String) -> Dictionary:
	return {} if _content_renderer == null else _content_renderer.resolve_primitive(primitive_id)


func resolve_pick(instance_index: int) -> Dictionary:
	return {} if _content_renderer == null else _content_renderer.resolve_pick(instance_index)


func primitive_id_for_row(row_id: String) -> String:
	return "" if _content_renderer == null else _content_renderer.primitive_id_for_row(row_id)


func is_row_selected(row_id: String) -> bool:
	return false if _content_renderer == null else _content_renderer.is_row_selected(row_id)


func rendered_point_count() -> int:
	return 0 if _content_renderer == null else _content_renderer.rendered_point_count()


func content_renderer() -> Node3D:
	return _content_renderer


func table_view() -> Control:
	return _table_view


func guide_renderer() -> Node3D:
	return _guide_renderer


func content_root() -> Node3D:
	_ensure_structure()
	return _content_root


func guide_root() -> Node3D:
	_ensure_structure()
	return _guide_root


func chrome_root() -> Node3D:
	_ensure_structure()
	return _chrome_root


func handle_root() -> Node3D:
	_ensure_structure()
	return _handle_root


func resolve_domain_handle(target: Node) -> Dictionary:
	_ensure_structure()
	var node := target
	while node != null and node != self:
		var interaction_role := str(node.get_meta("interaction_role", ""))
		if interaction_role == "axis_domain_handle" or interaction_role == "axis_domain_scrubber" or node.has_meta("axis_channel"):
			return {
				"channel": str(node.get_meta("axis_channel", node.get_meta("domain_channel", ""))),
				"edge": str(node.get_meta("axis_edge", node.get_meta("domain_edge", ""))),
				"part": str(node.get_meta("axis_part", node.get_meta("axis_edge", node.get_meta("domain_edge", "")))),
				"asset_source": str(node.get_meta("asset_source", "")),
				"node": node,
			}
		node = node.get_parent()
	return {}


func bounds_node() -> MeshInstance3D:
	_ensure_structure()
	return _bounds_instance


func chrome_snapshot() -> Dictionary:
	return {"title": _title, "source_status": _source_status, "theme_ref": _theme_ref, "locked": _locked}


func apply_interaction_state(next_mode: String, next_selected: bool, capture: Dictionary = {}) -> void:
	_ensure_structure()
	_interaction_mode = next_mode
	_frame_selected = next_selected
	_capture_active = bool(capture.get("active", false))
	_update_interaction_presentation()


func interaction_snapshot() -> Dictionary:
	return {"mode": _interaction_mode, "selected": _frame_selected, "capturing": _capture_active, "handles_visible": false if _handle_root == null else _handle_root.visible}


func lifecycle_snapshot() -> Dictionary:
	_ensure_structure()
	var content: Dictionary = {} if _content_renderer == null else _content_renderer.lifecycle_snapshot()
	var guides: Dictionary = {} if _guide_renderer == null else _guide_renderer.lifecycle_snapshot()
	var snapshot := {
		"frame_node": get_instance_id(),
		"content_root": _content_root.get_instance_id(),
		"guide_root": _guide_root.get_instance_id(),
		"chrome_root": _chrome_root.get_instance_id(),
		"handle_root": _handle_root.get_instance_id(),
		"bounds_node": _bounds_instance.get_instance_id(),
		"bounds_mesh": _bounds_mesh.get_instance_id(),
		"child_count": get_child_count(),
		"content_child_count": _content_root.get_child_count(),
		"content": content,
		"guides": guides,
		"rendered_points": int(content.get("rendered_points", 0)),
		"renderer_child_count": int(content.get("renderer_child_count", 0)),
	}
	for key: String in ["render_node_instance_id", "multimesh_instance_id", "point_mesh_instance_id", "pick_records"]:
		if content.has(key):
			snapshot[key] = content[key]
	return snapshot


func _ready() -> void:
	_ensure_structure()


func _ensure_structure() -> void:
	if _content_root != null:
		return
	_content_root = _ensure_child_node3d("ContentRoot")
	_guide_root = _ensure_child_node3d("GuideRoot")
	_chrome_root = _ensure_child_node3d("ChromeRoot")
	_handle_root = _ensure_child_node3d("HandleRoot")
	_bounds_instance = get_node_or_null("FrameBounds") as MeshInstance3D
	if _bounds_instance == null:
		_bounds_instance = MeshInstance3D.new()
		_bounds_instance.name = "FrameBounds"
		add_child(_bounds_instance)
	_bounds_mesh = _bounds_instance.mesh as BoxMesh
	if _bounds_mesh == null:
		_bounds_mesh = BoxMesh.new()
		_bounds_mesh.size = Vector3(4.0, 3.0, 1.0)
		_bounds_instance.mesh = _bounds_mesh
	_bounds_material = _bounds_mesh.material as StandardMaterial3D
	if _bounds_material == null:
		_bounds_material = StandardMaterial3D.new()
		_bounds_mesh.material = _bounds_material
	_bounds_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bounds_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bounds_material.albedo_color = Color(0.16, 0.19, 0.24, 0.035)
	_bounds_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_bounds_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ensure_child_node3d(node_name: String) -> Node3D:
	var existing := get_node_or_null(node_name) as Node3D
	if existing != null:
		return existing
	var child := Node3D.new()
	child.name = node_name
	add_child(child)
	return child


func _apply_content_bounds(bounds: Vector3, aspect_policy: String) -> void:
	if _content_renderer == null or not _has_property(_content_renderer, "plot_size"):
		return
	match aspect_policy:
		"preserve":
			var ratios := bounds / _content_base_size
			_content_renderer.plot_size = _content_base_size * minf(ratios.x, minf(ratios.y, ratios.z))
		"fit":
			_content_renderer.plot_size = bounds
		"free":
			_content_renderer.plot_size = _content_base_size


func _update_interaction_presentation() -> void:
	if _bounds_material == null or _handle_root == null:
		return
	_handle_root.visible = not _locked and _interaction_mode == "frame" and _frame_selected
	if _capture_active:
		_bounds_material.albedo_color = Color(1.0, 0.55, 0.16, 0.12)
	elif _interaction_mode == "frame" and _frame_selected:
		_bounds_material.albedo_color = Color(0.15, 0.78, 1.0, 0.09)
	elif _interaction_mode == "navigate":
		_bounds_material.albedo_color = Color(0.55, 0.42, 0.9, 0.06)
	else:
		_bounds_material.albedo_color = Color(0.16, 0.19, 0.24, 0.035)


func _layout_domain_handles(bounds: Vector3) -> void:
	if _handle_root == null:
		return
	var half := bounds * 0.5
	var margin := 0.12
	var placements := {
		"x:min": Vector3(-half.x - margin, 0.0, 0.0),
		"x:max": Vector3(half.x + margin, 0.0, 0.0),
		"y:min": Vector3(0.0, -half.y - margin, 0.0),
		"y:max": Vector3(0.0, half.y + margin, 0.0),
		"z:min": Vector3(0.0, 0.0, half.z + margin),
		"z:max": Vector3(0.0, 0.0, -half.z - margin),
	}
	for child in _handle_root.get_children():
		var channel := str(child.get_meta("domain_channel", ""))
		var edge := str(child.get_meta("domain_edge", ""))
		var key := "%s:%s" % [channel, edge]
		if placements.has(key):
			child.position = placements[key]


func _has_property(target: Object, property_name: String) -> bool:
	for property: Dictionary in target.get_property_list():
		if property["name"] == property_name:
			return true
	return false


func _append_component_diagnostics(component: Object) -> void:
	if not _has_property(component, "diagnostics"):
		return
	for diagnostic: Dictionary in component.diagnostics:
		diagnostics.append(diagnostic.duplicate(true))
		frame_diagnostic.emit(diagnostic.duplicate(true))


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	frame_diagnostic.emit(diagnostic.duplicate(true))
