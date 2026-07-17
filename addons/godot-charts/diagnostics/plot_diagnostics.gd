class_name PlotDiagnostics
extends RefCounted

var _replay: RefCounted
var _session: RefCounted
var _renderer: Node3D
var _table_view: Control


func bind(replay: RefCounted, session: RefCounted, renderer: Node3D, table_view: Control) -> void:
	_replay = replay
	_session = session
	_renderer = renderer
	_table_view = table_view


func snapshot() -> Dictionary:
	var figure: RefCounted = _session.active_figure
	var combined: Array[Dictionary] = []
	for diagnostic: Dictionary in _replay.source_diagnostics:
		combined.append(diagnostic.duplicate(true))
	for diagnostic: Dictionary in _replay.diagnostics:
		combined.append(diagnostic.duplicate(true))
	for diagnostic: Dictionary in _session.diagnostics:
		combined.append(diagnostic.duplicate(true))
	for diagnostic: Dictionary in _renderer.diagnostics:
		combined.append(diagnostic.duplicate(true))

	var approximations: Array[Dictionary] = []
	var rejected_fields: Array[Dictionary] = []
	for diagnostic: Dictionary in combined:
		var code: String = diagnostic.get("code", "")
		if code.contains("approximat") or diagnostic.get("fidelity", "") == "approximated":
			approximations.append(diagnostic.duplicate(true))
		if diagnostic.get("severity", "") == "error" and not diagnostic.get("path", "").is_empty():
			rejected_fields.append({"code": code, "path": diagnostic["path"]})

	return {
		"schema": _replay.active_plot_schema,
		"message_id": _replay.active_plot_message_id,
		"plot_id": "" if figure == null else figure.plot_id,
		"figure_id": "" if figure == null else figure.id,
		"revision": _session.active_revision,
		"producer": {} if figure == null else figure.producer.duplicate(true),
		"provenance": {} if figure == null else figure.provenance.duplicate(true),
		"protocol_limits": _replay.protocol_limits(),
		"replay": {
			"status": _status_name(_replay.status),
			"cursor": _replay.cursor,
			"applied_messages": _replay.applied_messages,
			"duplicate_messages": _replay.duplicate_messages,
		},
		"renderer": _renderer.lifecycle_snapshot(),
		"table": {
			"dataset_id": _table_view.dataset_id,
			"dataset_revision": _table_view.dataset_revision,
			"offset": _table_view.window_offset,
			"limit": _table_view.window_limit,
			"visible_row_ids": Array(_table_view.visible_row_ids()),
		},
		"selection": {
			"row_ids": Array(_session.linked_selection.row_ids),
			"renderer_row_ids": Array(_renderer.selected_row_ids()),
			"visible_table_row_ids": Array(_table_view.selected_row_ids()),
		},
		"source_diagnostics": _replay.source_diagnostics.duplicate(true),
		"diagnostics": combined,
		"approximations": approximations,
		"rejected_fields": rejected_fields,
	}


func to_json() -> String:
	return JSON.stringify(snapshot())


func _status_name(status: int) -> String:
	match status:
		0:
			return "ready"
		1:
			return "running"
		2:
			return "paused"
		3:
			return "complete"
	return "unknown"
