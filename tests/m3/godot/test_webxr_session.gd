extends SceneTree

const WebXrSession = preload("res://addons/godot-charts/integrations/webxr_session_controller.gd")
const WebXrInput = preload("res://addons/godot-charts/interactions/webxr_frame_input_adapter.gd")
const MockXrInput = preload("res://addons/godot-charts/interactions/mock_xr_frame_input_adapter.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameView = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const Controller = preload("res://addons/godot-charts/interactions/frame_interaction_controller.gd")

var _failures := 0
var _xr_enabled := false


class FakeWebXrInterface extends RefCounted:
	signal session_supported(session_mode: String, supported: bool)
	signal session_started
	signal session_ended
	signal session_failed(message: String)
	signal selectstart(input_source_id: int)
	signal selectend(input_source_id: int)
	signal squeezestart(input_source_id: int)
	signal squeezeend(input_source_id: int)

	var session_mode := ""
	var required_features := ""
	var optional_features := ""
	var requested_reference_space_types := ""
	var reference_space_type := "local-floor"
	var enabled_features := "local-floor"
	var initialize_result := true
	var initialize_calls := 0
	var uninitialize_calls := 0
	var active_sources: Array[int] = [1]

	func is_session_supported(mode: String) -> void:
		session_supported.emit(mode, true)

	func initialize() -> bool:
		initialize_calls += 1
		return initialize_result

	func uninitialize() -> void:
		uninitialize_calls += 1

	func is_input_source_active(input_source_id: int) -> bool:
		return input_source_id in active_sources


func _initialize() -> void:
	var unavailable = WebXrSession.new()
	_assert(not unavailable.discover(_set_xr, null), "missing interface selects flat-web fallback")
	_assert(unavailable.snapshot()["state"] == "unavailable", "missing interface reports unavailable")

	var fake := FakeWebXrInterface.new()
	var session = WebXrSession.new()
	_assert(session.discover(_set_xr, fake), "fake WebXR interface is discovered")
	_assert(session.snapshot()["state"] == "ready", "support callback enables explicit entry")
	_assert(session.request_session(), "user gesture begins immersive session")
	_assert(fake.session_mode == "immersive-vr", "immersive VR mode is requested")
	_assert(fake.required_features == "local-floor", "safe floor reference is required")
	_assert("bounded-floor" in fake.requested_reference_space_types, "bounded floor is preferred")
	_assert(not _xr_enabled and session.snapshot()["state"] == "starting", "viewport waits for asynchronous session start")
	fake.session_started.emit()
	_assert(_xr_enabled and session.snapshot()["state"] == "active", "session start enables XR rendering")
	_assert(session.snapshot()["reference_space_type"] == "local-floor", "selected reference space is reported")
	_assert(session.end_session() and fake.uninitialize_calls == 1, "explicit exit uninitializes WebXR")
	_assert(not _xr_enabled and session.snapshot()["state"] == "ready", "exit restores flat-web rendering")

	var failure := WebXrSession.new()
	var failing_fake := FakeWebXrInterface.new()
	failing_fake.initialize_result = false
	failure.discover(_set_xr, failing_fake)
	_assert(not failure.request_session(), "synchronous initialization rejection is reported")
	_assert(failure.snapshot()["state"] == "failed" and not _xr_enabled, "failure preserves flat-web fallback")

	var async_failure := WebXrSession.new()
	var async_fake := FakeWebXrInterface.new()
	async_failure.discover(_set_xr, async_fake)
	async_failure.request_session()
	async_fake.session_failed.emit("permission denied")
	_assert(async_failure.snapshot()["last_error"] == "permission denied" and not _xr_enabled, "asynchronous failure remains readable and non-immersive")

	_test_real_input_adapter_parity()

	if _failures == 0:
		print("Godot Charts M3 WebXR session tests passed.")
		quit(0)
	else:
		push_error("M3 WebXR session tests failed: %d assertion(s)." % _failures)
		quit(1)


func _set_xr(enabled: bool) -> void:
	_xr_enabled = enabled


func _test_real_input_adapter_parity() -> void:
	var web_rig := _make_rig("webxr-parity")
	var mock_rig := _make_rig("webxr-parity")
	var fake := FakeWebXrInterface.new()
	var poses := {1: {"transform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0)), "origin": Vector3(0.0, 1.0, 0.0), "direction": Vector3.FORWARD, "target_ray_mode": 2}}
	var web = WebXrInput.new()
	var mock = MockXrInput.new()
	mock.owner = "webxr:1"
	_assert(web.bind(web_rig.controller, fake, func(id: int) -> Dictionary: return poses.get(id, {})), "real WebXR adapter binds interface and controller")
	_assert(mock.bind(mock_rig.controller), "mocked-XR parity adapter binds")
	web_rig.controller.set_mode("frame")
	mock.handle_ray("mode_frame")
	fake.selectstart.emit(1)
	mock.handle_ray("select_frame")
	_assert(web_rig.controller.selected and mock_rig.controller.selected, "ray select focuses the same frame")
	fake.selectstart.emit(1)
	mock.handle_grab("begin_move")
	poses[1] = {"transform": Transform3D(Basis.IDENTITY, Vector3(0.5, 1.25, -0.25)), "origin": Vector3(0.5, 1.25, -0.25), "direction": Vector3.FORWARD, "target_ray_mode": 2}
	web.update()
	mock.handle_grab("preview_move", {"delta": Vector3(0.5, 0.25, -0.25)})
	fake.selectend.emit(1)
	mock.handle_grab("commit")
	_assert(web_rig.state.to_dictionary() == mock_rig.state.to_dictionary(), "real and mocked XR reach identical committed frame state")
	_assert(web_rig.controller.command_trace == mock_rig.controller.command_trace, "real and mocked XR preserve exact command trace parity")
	fake.selectstart.emit(1)
	poses[1] = {"transform": Transform3D(Basis.IDENTITY, Vector3(2.0, 1.0, 0.0)), "origin": Vector3(2.0, 1.0, 0.0), "direction": Vector3.FORWARD, "target_ray_mode": 2}
	web.update()
	fake.session_ended.emit()
	_assert(not web_rig.controller.is_capturing(), "session loss cancels active WebXR capture")
	web_rig.view.queue_free()
	mock_rig.view.queue_free()


func _make_rig(frame_id: String) -> Dictionary:
	var state = FrameState.new(frame_id, Transform3D.IDENTITY, Vector3(6.0, 4.0, 2.0), "WebXR parity")
	var view = FrameView.new()
	root.add_child(view)
	var controller = Controller.new()
	_assert(controller.bind(state, view), "WebXR parity controller binds")
	return {"state": state, "view": view, "controller": controller}


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
