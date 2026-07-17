class_name PlotTable
extends RefCounted

var id: String
var revision: int
var row_ids: PackedStringArray
var columns: Dictionary


func _init(table_id: String, table_revision: int, table_row_ids: PackedStringArray, table_columns: Dictionary) -> void:
	id = table_id
	revision = table_revision
	row_ids = table_row_ids.duplicate()
	columns = table_columns.duplicate(true)


func validate(path: String = "/data") -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if id.is_empty():
		diagnostics.append(_error("empty-table-id", "Table identity must not be empty.", path + "/id"))
	var seen: Dictionary = {}
	for index: int in row_ids.size():
		var row_id := row_ids[index]
		if row_id.is_empty():
			diagnostics.append(_error("empty-row-id", "Row identity must not be empty.", path + "/row_ids/%d" % index))
		elif seen.has(row_id):
			diagnostics.append(_error("duplicate-row-id", "Row identities must be unique.", path + "/row_ids/%d" % index))
		seen[row_id] = true
	for column_id: Variant in columns:
		var values: Variant = columns[column_id]
		if not values is Array or values.size() != row_ids.size():
			diagnostics.append(_error("column-length", "Column length must equal row identity count.", path + "/columns/%s" % column_id))
	return diagnostics


func has_row(row_id: String) -> bool:
	return row_ids.has(row_id)


func value(row_id: String, column_id: String) -> Variant:
	var row_index := row_ids.find(row_id)
	if row_index < 0 or not columns.has(column_id):
		return null
	return columns[column_id][row_index]


func to_dictionary() -> Dictionary:
	return {"id": id, "revision": revision, "row_ids": Array(row_ids), "columns": columns.duplicate(true)}


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
