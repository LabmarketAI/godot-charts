class_name LinkedSelection
extends RefCounted

signal selection_changed(row_ids: PackedStringArray, origin: String)

var row_ids: PackedStringArray = []

var _table_view: Control
var _scatter_renderer: Node3D


func bind_table(table_view: Control) -> void:
	if _table_view != null and _table_view.selection_changed.is_connected(_on_table_selection):
		_table_view.selection_changed.disconnect(_on_table_selection)
	_table_view = table_view
	if _table_view != null:
		_table_view.selection_changed.connect(_on_table_selection)
		_table_view.set_selected_rows(row_ids)


func bind_scatter_renderer(renderer: Node3D) -> void:
	_scatter_renderer = renderer
	if _scatter_renderer != null:
		_scatter_renderer.set_selected_rows(row_ids)


func replace(next_row_ids: PackedStringArray, origin: String = "external") -> void:
	var normalized := PackedStringArray()
	for row_id: String in next_row_ids:
		if not normalized.has(row_id):
			normalized.append(row_id)
	row_ids = normalized
	if _table_view != null:
		_table_view.set_selected_rows(row_ids)
	if _scatter_renderer != null:
		_scatter_renderer.set_selected_rows(row_ids)
	selection_changed.emit(row_ids.duplicate(), origin)


func select_from_chart(row_id: String, additive: bool = false) -> void:
	var next := row_ids.duplicate()
	if not additive:
		next.clear()
	if not next.has(row_id):
		next.append(row_id)
	replace(next, "chart")


func clear(origin: String = "external") -> void:
	replace(PackedStringArray(), origin)


func _on_table_selection(selected: PackedStringArray, _origin: String) -> void:
	replace(selected, "table")
