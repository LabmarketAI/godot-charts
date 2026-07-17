extends Node

const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")
const Diagnostics = preload("res://addons/godot-charts/diagnostics/plot_diagnostics.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameBinding = preload("res://addons/godot-charts/frames/frame_binding.gd")
const Guides = preload("res://addons/godot-charts/renderers/cartesian_guides_3d.gd")
const Controller = preload("res://addons/godot-charts/interactions/frame_interaction_controller.gd")
const DesktopInput = preload("res://addons/godot-charts/interactions/desktop_frame_input_adapter.gd")

@onready var frame: Node3D = $AnalyticalFrame3D
@onready var scatter: Node3D = $ScatterRenderer3D
@onready var table: Control = $CanvasLayer/TableView
@onready var status_label: Label = $CanvasLayer/Status

var _replay: RefCounted
var _session: RefCounted
var _public_diagnostics: RefCounted
var _frame_state: RefCounted
var _controller: RefCounted
var _desktop: RefCounted
var _move_preview := Vector3.ZERO
var _resize_preview := Vector3.ZERO


func _ready() -> void:
	var binding = FrameBinding.new("static_plot", "plot-annual-trials", "follow_source", 1)
	_frame_state = FrameState.new("quickstart-frame", frame.transform, Vector3(6.0, 4.0, 3.0), "Annual clinical trial enrollment", binding)
	var guides = Guides.new()
	assert(frame.bind_content(scatter, table))
	assert(frame.bind_guide_renderer(guides))
	assert(frame.apply_frame_state(_frame_state))

	_controller = Controller.new()
	assert(_controller.bind(_frame_state, frame))
	_desktop = DesktopInput.new()
	assert(_desktop.bind(_controller))

	var manifest := _load_json("res://fixtures/replay-manifest.json")
	var messages: Array[Dictionary] = []
	for filename: String in manifest["messages"]:
		messages.append(_load_json("res://fixtures/" + filename))
	_replay = Replay.new()
	_session = Session.new()
	_session.bind(_replay, frame, table)
	_replay.load_messages(messages)
	_replay.step()
	_replay.step()

	_public_diagnostics = Diagnostics.new()
	_public_diagnostics.bind(_replay, _session, frame, table)
	_update_status("Initial plot ready")
	print("M2 quickstart ready: ", status_label.text)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _desktop.handle_keyboard("mode_content")
		KEY_2: _desktop.handle_keyboard("mode_frame")
		KEY_3: _desktop.handle_keyboard("mode_navigate")
		KEY_F: _desktop.handle_mouse("select_frame")
		KEY_M: _begin_preview("begin_move")
		KEY_B: _begin_preview("begin_resize")
		KEY_LEFT: _preview_move(Vector3(-0.25, 0.0, 0.0))
		KEY_RIGHT: _preview_move(Vector3(0.25, 0.0, 0.0))
		KEY_UP: _preview_move(Vector3(0.0, 0.25, 0.0))
		KEY_DOWN: _preview_move(Vector3(0.0, -0.25, 0.0))
		KEY_EQUAL, KEY_KP_ADD: _preview_resize(Vector3(0.5, 0.5, 0.5))
		KEY_MINUS, KEY_KP_SUBTRACT: _preview_resize(Vector3(-0.5, -0.5, -0.5))
		KEY_ENTER, KEY_KP_ENTER: _desktop.handle_mouse("commit")
		KEY_Z: _desktop.handle_keyboard("undo")
		KEY_Y: _desktop.handle_keyboard("redo")
		KEY_ESCAPE: _desktop.handle_mouse("cancel")
		KEY_R: _desktop.handle_keyboard("reset")
		KEY_SPACE: _step_replay()
	_update_status("Input handled")
	get_viewport().set_input_as_handled()


func _begin_preview(action: String) -> void:
	if _desktop.handle_mouse(action):
		_move_preview = Vector3.ZERO
		_resize_preview = _frame_state.bounds


func _preview_move(delta: Vector3) -> void:
	if _controller.capture_snapshot()["operation"] != "move":
		return
	_move_preview += delta
	_desktop.handle_mouse("preview_move", {"delta": _move_preview})


func _preview_resize(delta: Vector3) -> void:
	if _controller.capture_snapshot()["operation"] != "resize":
		return
	var candidate := _resize_preview + delta
	if _desktop.handle_mouse("preview_resize", {"bounds": candidate}):
		_resize_preview = candidate


func _step_replay() -> void:
	if _replay.status != _replay.Status.COMPLETE:
		_replay.step()


func _update_status(prefix: String) -> void:
	var snapshot: Dictionary = _public_diagnostics.snapshot()
	status_label.text = "%s · revision %d · mode %s · frame %s · capture %s · %d points\n1/2/3 modes  F select  M move  B resize  arrows or +/- preview  Enter commit  Esc cancel  Z/Y undo/redo  R reset  Space revision" % [
		prefix, snapshot["revision"], _controller.mode,
		"selected" if _controller.selected else "not selected",
		_controller.capture_snapshot()["operation"] if _controller.is_capturing() else "none",
		snapshot["renderer"]["rendered_points"]
	]


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
