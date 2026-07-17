extends Node

const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")
const Diagnostics = preload("res://addons/godot-charts/diagnostics/plot_diagnostics.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameBinding = preload("res://addons/godot-charts/frames/frame_binding.gd")
const Guides = preload("res://addons/godot-charts/renderers/cartesian_guides_3d.gd")
const Controller = preload("res://addons/godot-charts/interactions/frame_interaction_controller.gd")
const DesktopInput = preload("res://addons/godot-charts/interactions/desktop_frame_input_adapter.gd")
const WebXrSession = preload("res://addons/godot-charts/integrations/webxr_session_controller.gd")
const WebXrInput = preload("res://addons/godot-charts/interactions/webxr_frame_input_adapter.gd")
const WebSocketClient = preload("res://addons/godot-charts/integrations/websocket_session_client.gd")

@onready var frame: Node3D = $AnalyticalFrame3D
@onready var scatter: Node3D = $ScatterRenderer3D
@onready var camera: Camera3D = $Camera3D
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_hand: XRController3D = $XROrigin3D/LeftHand
@onready var right_hand: XRController3D = $XROrigin3D/RightHand
@onready var table: Control = $CanvasLayer/TableView
@onready var table_panel: ColorRect = $CanvasLayer/TablePanel
@onready var status_label: Label = $CanvasLayer/Status
@onready var immersive_button: Button = $CanvasLayer/ImmersiveButton
@onready var webxr_status: Label = $CanvasLayer/WebXrStatus
@onready var pointer_controls: HFlowContainer = $CanvasLayer/PointerControls

var _replay: RefCounted
var _session: RefCounted
var _public_diagnostics: RefCounted
var _frame_state: RefCounted
var _controller: RefCounted
var _desktop: RefCounted
var _webxr: RefCounted
var _webxr_input: RefCounted
var _live_transport: Node
var _live_replay: RefCounted
var _move_preview := Vector3.ZERO
var _resize_preview := Vector3.ZERO


func _ready() -> void:
	var binding = FrameBinding.new("static_plot", "plot-annual-trials", "follow_source", 1)
	_frame_state = FrameState.new("quickstart-frame", frame.transform, Vector3(6.0, 4.0, 3.0), "Annual clinical trial enrollment", binding)
	var guides = Guides.new()
	var content_bound: bool = frame.bind_content(scatter, table)
	var guides_bound: bool = frame.bind_guide_renderer(guides)
	var frame_applied: bool = frame.apply_frame_state(_frame_state)
	assert(content_bound)
	assert(guides_bound)
	assert(frame_applied)

	_controller = Controller.new()
	var controller_bound: bool = _controller.bind(_frame_state, frame)
	assert(controller_bound)
	_desktop = DesktopInput.new()
	var desktop_bound: bool = _desktop.bind(_controller)
	assert(desktop_bound)
	_webxr = WebXrSession.new()
	_webxr.state_changed.connect(_on_webxr_state_changed)
	_webxr.discover(_set_xr_enabled)
	if _webxr.interface_handle() != null:
		_webxr_input = WebXrInput.new()
		var webxr_input_bound: bool = _webxr_input.bind(_controller, _webxr.interface_handle())
		assert(webxr_input_bound)
	immersive_button.pressed.connect(_toggle_immersive)
	_connect_xr_controller_logging(left_hand, "left")
	_connect_xr_controller_logging(right_hand, "right")
	_configure_pointer_controls()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

	var manifest := _load_json("res://fixtures/replay-manifest.json")
	var messages: Array[Dictionary] = []
	for filename: String in manifest["messages"]:
		var message := _load_json("res://fixtures/" + filename)
		messages.append(message)
	_replay = Replay.new()
	_session = Session.new()
	_session.bind(_replay, frame, table)
	_replay.load_messages(messages)
	_replay.step()
	_replay.step()

	_public_diagnostics = Diagnostics.new()
	_public_diagnostics.bind(_replay, _session, frame, table)
	_configure_optional_live_transport()
	_update_status("Initial plot ready")
	print("M2 quickstart ready: ", status_label.text)


func _toggle_immersive() -> void:
	if _webxr.state == _webxr.State.ACTIVE:
		_webxr.end_session()
	else:
		_webxr.request_session()


func _set_xr_enabled(enabled: bool) -> void:
	get_viewport().use_xr = enabled
	xr_camera.current = enabled
	camera.current = not enabled
	if enabled:
		_prime_vr_frame_interaction()


func _on_webxr_state_changed(snapshot: Dictionary) -> void:
	if not is_instance_valid(immersive_button):
		return
	immersive_button.visible = snapshot["immersive_vr_supported"] or snapshot["state"] in ["starting", "active", "failed"]
	immersive_button.disabled = snapshot["state"] in ["checking", "starting"]
	immersive_button.text = "Exit VR" if snapshot["state"] == "active" else "Enter VR"
	immersive_button.tooltip_text = snapshot["last_error"] if not snapshot["last_error"].is_empty() else "Enter immersive WebXR when supported"
	var detail: String = snapshot["last_error"]
	if detail.is_empty():
		match snapshot["state"]:
			"checking": detail = "Checking this browser for immersive VR…"
			"ready": detail = "WebXR immersive VR is available. Enter VR requires a user click."
			"starting": detail = "Starting the immersive session…"
			"active": detail = "Immersive VR active · Quest thumbsticks use XR Tools locomotion · reference space %s" % snapshot["reference_space_type"]
			_: detail = "WebXR is unavailable here. All flat-web controls remain usable."
	webxr_status.text = detail
	_publish_web_smoke_state()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var handled := true
	match event.keycode:
		KEY_1: _desktop.handle_keyboard("mode_content")
		KEY_2: _desktop.handle_keyboard("mode_frame")
		KEY_3: _desktop.handle_keyboard("mode_navigate")
		KEY_W: handled = _navigate_camera(Vector3(0.0, 0.0, -0.35))
		KEY_S: handled = _navigate_camera(Vector3(0.0, 0.0, 0.35))
		KEY_A: handled = _navigate_camera(Vector3(-0.35, 0.0, 0.0))
		KEY_D: handled = _navigate_camera(Vector3(0.35, 0.0, 0.0))
		KEY_Q: handled = _navigate_camera(Vector3(0.0, -0.35, 0.0))
		KEY_E: handled = _navigate_camera(Vector3(0.0, 0.35, 0.0))
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
		_: handled = false
	if not handled:
		return
	_update_status("Input handled")
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _webxr_input != null and _webxr.state == _webxr.State.ACTIVE:
		_webxr_input.update()


func _connect_xr_controller_logging(controller: XRController3D, hand: String) -> void:
	if controller.has_signal("button_pressed"):
		controller.button_pressed.connect(func(action: StringName) -> void:
			_webxr_host_log("info", "xr-button-pressed", {"hand": hand, "action": str(action)})
		)
	if controller.has_signal("button_released"):
		controller.button_released.connect(func(action: StringName) -> void:
			_webxr_host_log("info", "xr-button-released", {"hand": hand, "action": str(action)})
		)
	if controller.has_signal("input_float_changed"):
		controller.input_float_changed.connect(func(action: StringName, value: float) -> void:
			if absf(value) >= 0.05:
				_webxr_host_log("info", "xr-float", {"hand": hand, "action": str(action), "value": value})
		)
	if controller.has_signal("input_vector2_changed"):
		controller.input_vector2_changed.connect(func(action: StringName, value: Vector2) -> void:
			if value.length() >= 0.05:
				_webxr_host_log("info", "xr-vector2", {"hand": hand, "action": str(action), "x": value.x, "y": value.y})
		)


func _prime_vr_frame_interaction() -> void:
	_desktop.handle_keyboard("mode_frame")
	if not _controller.selected:
		_desktop.handle_mouse("select_frame")
	_update_status("VR scene active")
	_webxr_host_log("info", "webxr-session-active", {
		"left_tracker": str(left_hand.tracker),
		"right_tracker": str(right_hand.tracker),
	})


func _configure_optional_live_transport() -> void:
	if not OS.has_feature("web"):
		return
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	for parameter: String in query.trim_prefix("?").split("&", false):
		var pair := parameter.split("=", true, 1)
		if pair.size() != 2 or pair[0] != "live_wss":
			continue
		var endpoint: String = pair[1].uri_decode()
		if not endpoint.begins_with("wss://"):
			push_warning("Ignoring non-WSS live endpoint in web build.")
			return
		_live_replay = Replay.new()
		_live_transport = WebSocketClient.new()
		_live_transport.state_changed.connect(func(_state: int) -> void: _publish_web_smoke_state())
		_live_transport.transport_diagnostic.connect(func(_diagnostic: Dictionary) -> void: _publish_web_smoke_state())
		add_child(_live_transport)
		_live_transport.connect_session(endpoint, _live_replay)
		return


func _configure_pointer_controls() -> void:
	_add_pointer_button("ModeContent", "Content", "Inspect and select chart content", func() -> void: _desktop.handle_keyboard("mode_content"))
	_add_pointer_button("ModeFrame", "Frame", "Manipulate the whole analytical frame", func() -> void: _desktop.handle_keyboard("mode_frame"))
	_add_pointer_button("ModeNavigate", "Navigate", "Move the observer without changing data", func() -> void: _desktop.handle_keyboard("mode_navigate"))
	_add_pointer_button("SelectFrame", "Select", "Select the analytical frame", func() -> void: _desktop.handle_mouse("select_frame"))
	_add_pointer_button("BeginMove", "Move", "Begin a reversible frame move", func() -> void: _begin_preview("begin_move"))
	_add_pointer_button("BeginResize", "Resize", "Begin a reversible frame resize", func() -> void: _begin_preview("begin_resize"))
	_add_pointer_button("Left", "←", "Preview left or navigate left", func() -> void: _pointer_direction(Vector3(-0.25, 0.0, 0.0)))
	_add_pointer_button("Right", "→", "Preview right or navigate right", func() -> void: _pointer_direction(Vector3(0.25, 0.0, 0.0)))
	_add_pointer_button("Up", "↑", "Preview up or navigate up", func() -> void: _pointer_direction(Vector3(0.0, 0.25, 0.0)))
	_add_pointer_button("Down", "↓", "Preview down or navigate down", func() -> void: _pointer_direction(Vector3(0.0, -0.25, 0.0)))
	_add_pointer_button("Grow", "+ Size", "Preview a larger frame", func() -> void: _preview_resize(Vector3(0.5, 0.5, 0.5)))
	_add_pointer_button("Shrink", "− Size", "Preview a smaller frame", func() -> void: _preview_resize(Vector3(-0.5, -0.5, -0.5)))
	_add_pointer_button("Commit", "Commit", "Commit the active preview", func() -> void: _desktop.handle_mouse("commit"))
	_add_pointer_button("Cancel", "Cancel", "Cancel and restore the exact prior state", func() -> void: _desktop.handle_mouse("cancel"))
	_add_pointer_button("Undo", "Undo", "Undo the last committed frame command", func() -> void: _desktop.handle_keyboard("undo"))
	_add_pointer_button("Redo", "Redo", "Redo the next frame command", func() -> void: _desktop.handle_keyboard("redo"))
	_add_pointer_button("Reset", "Reset", "Restore the authored frame and view", func() -> void: _desktop.handle_keyboard("reset"))
	_add_pointer_button("NextRevision", "Next data", "Apply the next recorded plot revision", _step_replay)


func _add_pointer_button(node_name: String, label: String, description: String, action: Callable) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.tooltip_text = description
	button.custom_minimum_size = Vector2(76.0, 38.0)
	button.pressed.connect(func() -> void:
		action.call()
		_update_status("Pointer control")
	)
	pointer_controls.add_child(button)


func _pointer_direction(delta: Vector3) -> void:
	if _controller.capture_snapshot()["operation"] == "move":
		_preview_move(delta)
	elif _controller.mode == "navigate":
		_navigate_camera(delta)


func _apply_responsive_layout() -> void:
	var narrow := get_viewport().get_visible_rect().size.x < 900.0
	if narrow:
		table_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		table_panel.anchor_top = 0.62
		table_panel.offset_top = 0.0
		table.anchor_left = 0.03
		table.anchor_top = 0.68
		table.anchor_right = 0.97
		table.anchor_bottom = 0.97
	else:
		table_panel.anchor_left = 0.62
		table_panel.anchor_top = 0.0
		table_panel.anchor_right = 1.0
		table_panel.anchor_bottom = 1.0
		table_panel.offset_left = 0.0
		table_panel.offset_top = 0.0
		table_panel.offset_right = 0.0
		table_panel.offset_bottom = 0.0
		table.anchor_left = 0.64
		table.anchor_top = 0.12
		table.anchor_right = 0.98
		table.anchor_bottom = 0.96


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


func _navigate_camera(local_delta: Vector3) -> bool:
	if _controller.mode != "navigate":
		return false
	camera.position += camera.basis * local_delta
	return _desktop.handle_keyboard("navigate", {"view_state": {
		"camera_position": [camera.position.x, camera.position.y, camera.position.z],
		"camera_basis": [
			camera.basis.x.x, camera.basis.x.y, camera.basis.x.z,
			camera.basis.y.x, camera.basis.y.y, camera.basis.y.z,
			camera.basis.z.x, camera.basis.z.y, camera.basis.z.z,
		],
	}})


func _update_status(prefix: String) -> void:
	var snapshot: Dictionary = _public_diagnostics.snapshot()
	status_label.text = "%s · revision %d · mode %s · frame %s · capture %s · %d points" % [
		prefix, snapshot["revision"], _controller.mode,
		"selected" if _controller.selected else "not selected",
		_controller.capture_snapshot()["operation"] if _controller.is_capturing() else "none",
		snapshot["renderer"]["rendered_points"]
	]
	_publish_web_smoke_state()


func _webxr_host_log(level: String, message: String, fields: Dictionary = {}) -> void:
	var payload := {
		"source": "godot",
		"level": level,
		"message": message,
		"webxr_state": _webxr.snapshot()["state"] if _webxr != null else "unavailable",
	}
	for key: Variant in fields.keys():
		payload[str(key)] = fields[key]
	print("[webxr] ", JSON.stringify(payload))
	if not OS.has_feature("web"):
		return
	var body := JSON.stringify(payload)
	JavaScriptBridge.eval(
		"fetch('/__webxr_log',{method:'POST',headers:{'content-type':'application/json'},body:%s,keepalive:true}).catch(()=>{});" % JSON.stringify(body),
		true
	)


func _publish_web_smoke_state() -> void:
	if not OS.has_feature("web") or _public_diagnostics == null or _controller == null:
		return
	var diagnostic_snapshot: Dictionary = _public_diagnostics.snapshot()
	var smoke := {
		"ready": true,
		"revision": diagnostic_snapshot["revision"],
		"mode": _controller.mode,
		"selected": _controller.selected,
		"capture": _controller.capture_snapshot()["operation"] if _controller.is_capturing() else "none",
		"rendered_points": diagnostic_snapshot["renderer"]["rendered_points"],
		"replay_cursor": _replay.cursor,
		"replay_applied": _replay.applied_messages,
		"replay_diagnostics": _replay.diagnostics,
		"frame_position": [frame.position.x, frame.position.y, frame.position.z],
		"webxr_state": _webxr.snapshot()["state"] if _webxr != null else "unavailable",
		"webxr_message": webxr_status.text,
		"live_transport": _live_transport.snapshot() if _live_transport != null else {},
	}
	JavaScriptBridge.eval("window.godotChartsSmoke = %s;" % JSON.stringify(smoke), true)


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
