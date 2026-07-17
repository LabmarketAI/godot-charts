class_name PlotSession
extends RefCounted

signal revision_applied(revision: int)
signal session_diagnostic(diagnostic: Dictionary)

const Selection = preload("res://addons/godot-charts/interactions/linked_selection.gd")

var active_figure: RefCounted
var active_revision: int = -1
var diagnostics: Array[Dictionary] = []
var linked_selection: RefCounted = Selection.new()

var _replay: RefCounted
var _renderer: Node3D
var _table_view: Control


func bind(replay: RefCounted, renderer: Node3D, table_view: Control) -> void:
	_unbind_replay()
	_replay = replay
	_renderer = renderer
	_table_view = table_view
	linked_selection.bind_scatter_renderer(renderer)
	linked_selection.bind_table(table_view)
	_replay.plot_replaced.connect(_on_plot_replaced)
	_replay.selection_replaced.connect(_on_selection_replaced)


func _on_plot_replaced(figure: RefCounted, figure_diff: RefCounted, reset_scope: PackedStringArray) -> void:
	var current_offset: int = _table_view.window_offset
	var current_limit: int = _table_view.window_limit
	if current_limit <= 0:
		current_limit = mini(100, _table_view.max_visible_rows)
	var table: RefCounted = _primary_table(figure)
	if table == null:
		_report("missing-primary-table", "Replacement figure has no table for its primary layer.", "/figure/data")
		return
	if not _renderer.apply_figure(figure, figure_diff):
		for diagnostic: Dictionary in _renderer.diagnostics:
			_report(diagnostic["code"], diagnostic["message"], diagnostic["path"])
		return

	_table_view.display_window(table, current_offset, current_limit)
	var eligible := PackedStringArray()
	for row_id: String in linked_selection.row_ids:
		if table.has_row(row_id):
			eligible.append(row_id)
	if eligible.size() != linked_selection.row_ids.size() and "selection" not in reset_scope:
		_report("identity-break-undeclared", "Session refused to reset selection without a declared reset scope.", "/reset_scope")
		return
	linked_selection.replace(eligible, "revision")
	active_figure = figure
	active_revision = figure.revision
	revision_applied.emit(active_revision)


func _on_selection_replaced(row_ids: PackedStringArray, origin: String) -> void:
	linked_selection.replace(row_ids, origin)


func _primary_table(figure: RefCounted) -> RefCounted:
	for view: RefCounted in figure.views:
		for layer: RefCounted in view.layers:
			var table: RefCounted = figure.table(layer.data_id)
			if table != null:
				return table
	return null


func _unbind_replay() -> void:
	if _replay == null:
		return
	if _replay.plot_replaced.is_connected(_on_plot_replaced):
		_replay.plot_replaced.disconnect(_on_plot_replaced)
	if _replay.selection_replaced.is_connected(_on_selection_replaced):
		_replay.selection_replaced.disconnect(_on_selection_replaced)


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	session_diagnostic.emit(diagnostic)
