extends Node

const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")
const Diagnostics = preload("res://addons/godot-charts/diagnostics/plot_diagnostics.gd")

@onready var scatter: Node3D = $ScatterRenderer3D
@onready var table: Control = $CanvasLayer/TableView
@onready var status_label: Label = $CanvasLayer/Status

var _replay: RefCounted
var _session: RefCounted
var _public_diagnostics: RefCounted


func _ready() -> void:
	var manifest := _load_json("res://fixtures/replay-manifest.json")
	var messages: Array[Dictionary] = []
	for filename: String in manifest["messages"]:
		messages.append(_load_json("res://fixtures/" + filename))

	_replay = Replay.new()
	_session = Session.new()
	_session.bind(_replay, scatter, table)
	_replay.load_messages(messages)
	_replay.run_to_end()

	_public_diagnostics = Diagnostics.new()
	_public_diagnostics.bind(_replay, _session, scatter, table)
	var snapshot: Dictionary = _public_diagnostics.snapshot()
	status_label.text = "Plot %s · revision %d · %d rendered rows · %d table rows" % [
		snapshot["plot_id"], snapshot["revision"], snapshot["renderer"]["rendered_points"],
		snapshot["table"]["visible_row_ids"].size()
	]
	print("M1 quickstart ready: ", status_label.text)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open M1 fixture: " + path)
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary:
		push_error("Invalid M1 fixture: " + path)
		return {}
	return value
