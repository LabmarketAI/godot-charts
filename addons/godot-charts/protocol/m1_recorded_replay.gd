class_name M1RecordedReplay
extends RefCounted

const ContractValidator = preload("res://addons/godot-charts/protocol/m1_contract_validator.gd")

enum Status { READY, RUNNING, PAUSED, COMPLETE }

var status: Status = Status.READY
var cursor: int = 0
var applied_messages: int = 0
var duplicate_messages: int = 0
var active_plot_revision: int = -1
var selection_row_ids: PackedStringArray = []
var diagnostics: Array[Dictionary] = []

var _messages: Array[Dictionary] = []
var _seen_message_ids: Dictionary = {}
var _last_sequence: int = -1
var _validator: RefCounted = ContractValidator.new()


func load_messages(messages: Array[Dictionary]) -> void:
	_messages = messages.duplicate(true)
	restart()


func restart() -> void:
	status = Status.READY
	cursor = 0
	applied_messages = 0
	duplicate_messages = 0
	active_plot_revision = -1
	selection_row_ids = PackedStringArray()
	diagnostics.clear()
	_seen_message_ids.clear()
	_last_sequence = -1


func pause() -> void:
	if status == Status.RUNNING:
		status = Status.PAUSED


func step() -> bool:
	if cursor >= _messages.size():
		status = Status.COMPLETE
		return false
	status = Status.RUNNING
	var message: Dictionary = _messages[cursor]
	cursor += 1
	_apply(message)
	status = Status.COMPLETE if cursor >= _messages.size() else Status.PAUSED
	return true


func run_to_end() -> void:
	status = Status.RUNNING
	while cursor < _messages.size():
		var message: Dictionary = _messages[cursor]
		cursor += 1
		_apply(message)
	status = Status.COMPLETE


func _apply(message: Dictionary) -> void:
	var validation: Array[Dictionary] = _validator.validate(message)
	if not validation.is_empty():
		diagnostics.append_array(validation)
		return
	var message_id: String = message["message_id"]
	if _seen_message_ids.has(message_id):
		duplicate_messages += 1
		return
	var sequence: int = int(message["sequence"])
	if sequence <= _last_sequence:
		diagnostics.append({"severity": "error", "code": "out-of-order", "message": "Message sequence does not advance.", "path": "/sequence"})
		return
	_seen_message_ids[message_id] = true
	_last_sequence = sequence

	match message["schema"]:
		"godot-charts/plot-message/1.0":
			_apply_plot(message)
		"godot-charts/selection/1.0":
			var payload: Dictionary = message["payload"]
			selection_row_ids = PackedStringArray(payload["row_ids"])
	applied_messages += 1


func _apply_plot(message: Dictionary) -> void:
	var revision: int = int(message["revision"])
	if revision <= active_plot_revision:
		diagnostics.append({"severity": "error", "code": "stale-revision", "message": "Plot revision does not advance.", "path": "/revision"})
		return
	active_plot_revision = revision
	var valid_rows: Dictionary = {}
	var data_tables: Array = message["payload"]["figure"]["data"]
	for table: Dictionary in data_tables:
		for row_id: String in table["row_ids"]:
			valid_rows[row_id] = true
	var preserved := PackedStringArray()
	for row_id: String in selection_row_ids:
		if valid_rows.has(row_id):
			preserved.append(row_id)
	selection_row_ids = preserved
