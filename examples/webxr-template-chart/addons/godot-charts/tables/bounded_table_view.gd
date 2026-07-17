class_name BoundedTableView
extends Control

signal selection_changed(row_ids: PackedStringArray, origin: String)
signal row_inspected(row_id: String, values: Dictionary)

@export_range(1, 1000, 1) var max_visible_rows: int = 200

var dataset_id: String = ""
var dataset_revision: int = -1
var window_offset: int = 0
var window_limit: int = 0

var _table: RefCounted
var _tree: Tree
var _column_ids: PackedStringArray = []
var _row_items: Dictionary = {}
var _visible_row_ids: PackedStringArray = []
var _synchronizing_selection: bool = false


func display_window(table: RefCounted, offset: int = 0, limit: int = 100) -> void:
	_ensure_tree()
	var preserved_selection := selected_row_ids()
	_table = table
	dataset_id = table.id
	dataset_revision = table.revision
	window_offset = clampi(offset, 0, table.row_ids.size())
	window_limit = clampi(limit, 1, max_visible_rows)
	_column_ids = PackedStringArray(table.columns.keys())
	_tree.clear()
	_tree.columns = _column_ids.size() + 1
	_tree.set_column_title(0, "Row")
	for column_index: int in _column_ids.size():
		_tree.set_column_title(column_index + 1, _column_ids[column_index])
	var root_item := _tree.create_item()
	_row_items.clear()
	_visible_row_ids.clear()
	var end := mini(window_offset + window_limit, table.row_ids.size())
	for row_index: int in range(window_offset, end):
		var row_id: String = table.row_ids[row_index]
		var item := _tree.create_item(root_item)
		item.set_text(0, row_id)
		item.set_metadata(0, row_id)
		for column_index: int in _column_ids.size():
			item.set_text(column_index + 1, _format_value(table.value(row_id, _column_ids[column_index])))
		_row_items[row_id] = item
		_visible_row_ids.append(row_id)
	set_selected_rows(preserved_selection)


func set_selected_rows(row_ids: PackedStringArray, emit_change: bool = false, origin: String = "external") -> void:
	_ensure_tree()
	_synchronizing_selection = true
	_tree.deselect_all()
	for row_id: String in row_ids:
		if _row_items.has(row_id):
			_row_items[row_id].select(0)
	_synchronizing_selection = false
	if emit_change:
		selection_changed.emit(selected_row_ids(), origin)


func selected_row_ids() -> PackedStringArray:
	var selected := PackedStringArray()
	if _tree == null:
		return selected
	var item: TreeItem = _tree.get_next_selected(null)
	while item != null:
		var row_id: Variant = item.get_metadata(0)
		if row_id != null and not selected.has(str(row_id)):
			selected.append(str(row_id))
		item = _tree.get_next_selected(item)
	return selected


func visible_row_ids() -> PackedStringArray:
	return _visible_row_ids.duplicate()


func displayed_row_count() -> int:
	return _visible_row_ids.size()


func inspect_row(row_id: String) -> Dictionary:
	if _table == null or not _table.has_row(row_id):
		return {}
	var values: Dictionary = {}
	for column_id: String in _column_ids:
		values[column_id] = _table.value(row_id, column_id)
	row_inspected.emit(row_id, values.duplicate(true))
	if _row_items.has(row_id):
		_tree.scroll_to_item(_row_items[row_id], true)
	return values


func tree_control() -> Tree:
	_ensure_tree()
	return _tree


func _ensure_tree() -> void:
	if _tree != null:
		return
	_tree = Tree.new()
	_tree.name = "AnalyticalTable"
	_tree.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tree.hide_root = true
	_tree.column_titles_visible = true
	_tree.select_mode = Tree.SELECT_MULTI
	_tree.item_selected.connect(_on_tree_selection_changed)
	_tree.multi_selected.connect(_on_tree_multi_selected)
	add_child(_tree)


func _on_tree_selection_changed() -> void:
	if not _synchronizing_selection:
		selection_changed.emit(selected_row_ids(), "table")


func _on_tree_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	if not _synchronizing_selection:
		selection_changed.emit(selected_row_ids(), "table")


func _format_value(value: Variant) -> String:
	if value == null:
		return "∅"
	if value is float:
		return String.num(value)
	return str(value)
