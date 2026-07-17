class_name M1RecordedReplay
extends RefCounted

signal plot_replaced(figure: RefCounted, figure_diff: RefCounted, reset_scope: PackedStringArray)
signal selection_replaced(row_ids: PackedStringArray, origin: String)

const ContractValidator = preload("res://addons/godot-charts/protocol/m1_contract_validator.gd")
const Diff = preload("res://addons/godot-charts/core/figure_diff.gd")
const Normalizer = preload("res://addons/godot-charts/core/plot_message_normalizer.gd")

enum Status { READY, RUNNING, PAUSED, COMPLETE }

var status: Status = Status.READY
var cursor: int = 0
var applied_messages: int = 0
var duplicate_messages: int = 0
var active_plot_revision: int = -1
var active_plot_schema: String = ""
var active_plot_message_id: String = ""
var active_figure: RefCounted
var last_figure_diff: RefCounted
var selection_row_ids: PackedStringArray = []
var diagnostics: Array[Dictionary] = []
var source_diagnostics: Array[Dictionary] = []

var _messages: Array[Dictionary] = []
var _seen_message_ids: Dictionary = {}
var _last_sequence: int = -1
var _validator: RefCounted = ContractValidator.new()
var _normalizer: RefCounted = Normalizer.new()


func load_messages(messages: Array) -> void:
	_messages.clear()
	for message: Dictionary in messages:
		_messages.append(message.duplicate(true))
	restart()


func begin_live() -> void:
	_messages.clear()
	restart()
	status = Status.RUNNING


func receive_message(message: Dictionary) -> bool:
	if status != Status.RUNNING:
		status = Status.RUNNING
	var applied_before := applied_messages
	var duplicates_before := duplicate_messages
	_apply(message.duplicate(true))
	return applied_messages > applied_before or duplicate_messages > duplicates_before


func complete_live() -> void:
	status = Status.COMPLETE


func restart() -> void:
	status = Status.READY
	cursor = 0
	applied_messages = 0
	duplicate_messages = 0
	active_plot_revision = -1
	active_plot_schema = ""
	active_plot_message_id = ""
	active_figure = null
	last_figure_diff = null
	selection_row_ids = PackedStringArray()
	diagnostics.clear()
	source_diagnostics.clear()
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
	if sequence != _last_sequence + 1:
		diagnostics.append({"severity": "error", "code": "sequence-gap", "message": "Message sequence contains a gap; a full resynchronization is required.", "path": "/sequence"})
		return

	var applied := true
	match message["schema"]:
		"godot-charts/plot-message/1.0":
			applied = _apply_plot(message)
		"godot-charts/selection/1.0":
			var payload: Dictionary = message["payload"]
			selection_row_ids = PackedStringArray(payload["row_ids"])
			selection_replaced.emit(selection_row_ids.duplicate(), str(payload.get("origin", "replay")))
	if not applied:
		return
	_seen_message_ids[message_id] = true
	_last_sequence = sequence
	applied_messages += 1


func _apply_plot(message: Dictionary) -> bool:
	var revision: int = int(message["revision"])
	if revision <= active_plot_revision:
		diagnostics.append({"severity": "error", "code": "stale-revision", "message": "Plot revision does not advance.", "path": "/revision"})
		return false
	var normalized: Dictionary = _normalizer.normalize(message)
	var model_diagnostics: Array = normalized["diagnostics"]
	if not model_diagnostics.is_empty():
		diagnostics.append_array(model_diagnostics)
		return false
	var next_figure: RefCounted = normalized["figure"]
	var valid_rows: Dictionary = {}
	for row_id: String in next_figure.all_row_ids():
		valid_rows[row_id] = true
	var preserved := PackedStringArray()
	for row_id: String in selection_row_ids:
		if valid_rows.has(row_id):
			preserved.append(row_id)
	if preserved.size() != selection_row_ids.size():
		var reset_scope: Array = message.get("reset_scope", [])
		if "selection" not in reset_scope:
			diagnostics.append({"severity": "error", "code": "identity-break-undeclared", "message": "Replacement invalidates selected row identities without declaring a selection reset.", "path": "/reset_scope"})
			return false
		diagnostics.append({"severity": "warning", "code": "identity-reset", "message": "Replacement reset row selections whose identities are no longer present.", "path": "/reset_scope"})
	last_figure_diff = null if active_figure == null else Diff.between(active_figure, next_figure)
	active_figure = next_figure
	active_plot_revision = revision
	active_plot_schema = message["schema"]
	active_plot_message_id = message["message_id"]
	source_diagnostics.clear()
	for diagnostic: Dictionary in message.get("diagnostics", []):
		source_diagnostics.append(diagnostic.duplicate(true))
	selection_row_ids = preserved
	plot_replaced.emit(active_figure, last_figure_diff, PackedStringArray(message.get("reset_scope", [])))
	return true


func protocol_limits() -> Dictionary:
	return _validator.limits_snapshot()
