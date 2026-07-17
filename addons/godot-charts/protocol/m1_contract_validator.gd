class_name M1ContractValidator
extends RefCounted

const SUPPORTED_SCHEMAS: PackedStringArray = [
	"godot-charts/session-handshake/1.0",
	"godot-charts/plot-message/1.0",
	"godot-charts/table-result/1.0",
	"godot-charts/selection/1.0",
]

var max_message_bytes: int = 1_048_576
var max_rows: int = 10_000
var max_columns: int = 64
var max_layers: int = 16


func validate(message: Dictionary) -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	var encoded := JSON.stringify(message)
	if encoded.to_utf8_buffer().size() > max_message_bytes:
		diagnostics.append(_error("message-too-large", "Message exceeds the negotiated byte limit.", "/"))
		return diagnostics

	for field: String in ["schema", "message_id", "session_id", "sequence", "operation", "created_at", "payload"]:
		if not message.has(field):
			diagnostics.append(_error("missing-field", "Required field is absent.", "/" + field))
	if not diagnostics.is_empty():
		return diagnostics

	var schema: String = message["schema"]
	if schema not in SUPPORTED_SCHEMAS:
		diagnostics.append(_error("unsupported-schema", "Schema version is not supported.", "/schema"))
		return diagnostics
	if not _is_non_negative_integer(message["sequence"]):
		diagnostics.append(_error("invalid-sequence", "Sequence must be a non-negative integer.", "/sequence"))
	if not message["payload"] is Dictionary:
		diagnostics.append(_error("invalid-payload", "Payload must be an object.", "/payload"))
		return diagnostics

	match schema:
		"godot-charts/session-handshake/1.0":
			_validate_handshake(message, diagnostics)
		"godot-charts/plot-message/1.0":
			_validate_plot(message, diagnostics)
		"godot-charts/table-result/1.0":
			_validate_table(message, diagnostics)
		"godot-charts/selection/1.0":
			_validate_selection(message, diagnostics)
	return diagnostics


func _validate_handshake(message: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if message["operation"] != "hello":
		diagnostics.append(_error("invalid-operation", "Handshake operation must be hello.", "/operation"))
	var payload: Dictionary = message["payload"]
	for field: String in ["peer_id", "protocol_versions", "capabilities", "limits"]:
		_require(payload, field, "/payload", diagnostics)


func _validate_plot(message: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if message["operation"] != "replace":
		diagnostics.append(_error("invalid-operation", "M1 accepts plot replacement only.", "/operation"))
	for field: String in ["plot_id", "revision", "producer", "provenance"]:
		_require(message, field, "", diagnostics)
	var payload: Dictionary = message["payload"]
	if not _require(payload, "figure", "/payload", diagnostics):
		return
	var figure: Variant = payload["figure"]
	if not figure is Dictionary:
		diagnostics.append(_error("invalid-figure", "Figure must be an object.", "/payload/figure"))
		return
	for field: String in ["id", "views", "data"]:
		_require(figure, field, "/payload/figure", diagnostics)
	if not figure.has("data") or not figure["data"] is Array:
		return
	for data_index: int in figure["data"].size():
		var table: Variant = figure["data"][data_index]
		if not table is Dictionary:
			continue
		for field: String in ["id", "revision", "row_ids", "columns"]:
			_require(table, field, "/payload/figure/data/%d" % data_index, diagnostics)
		if table.has("row_ids") and table["row_ids"] is Array and table["row_ids"].size() > max_rows:
			diagnostics.append(_error("row-limit", "Inline table exceeds the row limit.", "/payload/figure/data/%d/row_ids" % data_index))
		if table.has("columns") and table["columns"] is Dictionary:
			if table["columns"].size() > max_columns:
				diagnostics.append(_error("column-limit", "Inline table exceeds the column limit.", "/payload/figure/data/%d/columns" % data_index))
			if table.has("row_ids") and table["row_ids"] is Array:
				for column_id: Variant in table["columns"]:
					var values: Variant = table["columns"][column_id]
					if not values is Array or values.size() != table["row_ids"].size():
						diagnostics.append(_error("column-length", "Column length must equal row identity count.", "/payload/figure/data/%d/columns/%s" % [data_index, column_id]))


func _validate_table(message: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if message["operation"] != "table.result":
		diagnostics.append(_error("invalid-operation", "Table operation must be table.result.", "/operation"))
	var payload: Dictionary = message["payload"]
	for field: String in ["request_id", "dataset_id", "revision", "offset", "limit", "total_rows", "columns", "rows"]:
		_require(payload, field, "/payload", diagnostics)
	if payload.has("rows") and payload["rows"] is Array and payload["rows"].size() > max_rows:
		diagnostics.append(_error("row-limit", "Table window exceeds the row limit.", "/payload/rows"))


func _validate_selection(message: Dictionary, diagnostics: Array[Dictionary]) -> void:
	if message["operation"] != "selection.replace":
		diagnostics.append(_error("invalid-operation", "Selection operation must be selection.replace.", "/operation"))
	var payload: Dictionary = message["payload"]
	for field: String in ["selection_id", "plot_id", "dataset_id", "dataset_revision", "row_ids", "mode"]:
		_require(payload, field, "/payload", diagnostics)


func _require(value: Dictionary, field: String, base_path: String, diagnostics: Array[Dictionary]) -> bool:
	if value.has(field):
		return true
	diagnostics.append(_error("missing-field", "Required field is absent.", base_path + "/" + field))
	return false


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}


func _is_non_negative_integer(value: Variant) -> bool:
	if value is int:
		return value >= 0
	if value is float:
		return value >= 0.0 and value == floor(value)
	return false
