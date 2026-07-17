extends SceneTree

const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameView = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const Controller = preload("res://addons/godot-charts/interactions/frame_interaction_controller.gd")
const DesktopAdapter = preload("res://addons/godot-charts/interactions/desktop_frame_input_adapter.gd")
const MockXrAdapter = preload("res://addons/godot-charts/interactions/mock_xr_frame_input_adapter.gd")

var _failures := 0


func _initialize() -> void:
	var desktop := _make_rig()
	var xr := _make_rig()
	_assert(desktop.adapter.bind(desktop.controller), "desktop adapter binds controller")
	_assert(xr.adapter.bind(xr.controller), "mocked-XR adapter binds controller")

	_assert(_desktop_workflow(desktop.adapter), "desktop workflow completes")
	_assert(_xr_workflow(xr.adapter), "mocked-XR workflow completes")
	_assert(desktop.state.to_dictionary() == xr.state.to_dictionary(), "desktop and mocked-XR reach identical serialized frame state")
	_assert(desktop.controller.command_trace == xr.controller.command_trace, "desktop and mocked-XR emit identical command traces")
	_assert(desktop.controller.mode == "frame" and desktop.controller.selected, "desktop restores frame focus after mode switch")
	_assert(xr.controller.mode == "frame" and xr.controller.selected, "mocked-XR restores frame focus after mode switch")
	_assert(not desktop.controller.is_capturing() and not xr.controller.is_capturing(), "both adapters release capture")
	var desktop_lifecycle: Dictionary = desktop.view.lifecycle_snapshot()
	var xr_lifecycle: Dictionary = xr.view.lifecycle_snapshot()
	for iteration: int in 100:
		var delta := Vector3(0.01 if iteration % 2 == 0 else -0.01, 0.0, 0.0)
		_assert(desktop.adapter.handle_mouse("begin_move") and desktop.adapter.handle_mouse("preview_move", {"delta": delta}) and desktop.adapter.handle_mouse("commit"), "desktop stress command commits: %d" % iteration)
		_assert(xr.adapter.handle_grab("begin_move") and xr.adapter.handle_grab("preview_move", {"delta": delta}) and xr.adapter.handle_grab("commit"), "mocked-XR stress command commits: %d" % iteration)
	_assert(desktop.state.to_dictionary() == xr.state.to_dictionary(), "stress replay preserves adapter state parity")
	_assert(desktop.controller.command_trace == xr.controller.command_trace, "stress replay preserves exact trace parity")
	_assert(desktop.view.lifecycle_snapshot() == desktop_lifecycle, "desktop manipulation replay does not grow frame resources")
	_assert(xr.view.lifecycle_snapshot() == xr_lifecycle, "mocked-XR manipulation replay does not grow frame resources")
	_assert(desktop.controller.history_snapshot()["size"] == desktop.controller.history_limit, "desktop replay history remains bounded")
	_assert(xr.controller.history_snapshot()["size"] == xr.controller.history_limit, "mocked-XR replay history remains bounded")

	_assert(not desktop.adapter.handle_mouse("unsupported"), "desktop rejects unknown mouse actions")
	_assert(not xr.adapter.handle_grab("unsupported"), "mocked-XR rejects unknown grab actions")
	desktop.view.queue_free()
	xr.view.queue_free()

	if _failures == 0:
		print("Godot Charts M2 input-adapter tests passed.")
		quit(0)
	else:
		push_error("M2 input-adapter tests failed: %d assertion(s)." % _failures)
		quit(1)


func _make_rig() -> Dictionary:
	var state = FrameState.new("frame-parity", Transform3D.IDENTITY, Vector3(6.0, 4.0, 2.0), "Parity frame")
	var view = FrameView.new()
	root.add_child(view)
	var controller = Controller.new()
	_assert(controller.bind(state, view), "parity controller binds")
	return {"state": state, "view": view, "controller": controller, "adapter": DesktopAdapter.new() if root.get_child_count() == 1 else MockXrAdapter.new()}


func _desktop_workflow(adapter: RefCounted) -> bool:
	return (
		adapter.handle_keyboard("mode_frame")
		and adapter.handle_mouse("select_frame")
		and adapter.handle_mouse("begin_move")
		and adapter.handle_mouse("preview_move", {"delta": Vector3(2.0, 1.0, -1.0)})
		and adapter.handle_mouse("commit")
		and adapter.handle_mouse("begin_resize")
		and adapter.handle_mouse("preview_resize", {"bounds": Vector3(8.0, 5.0, 3.0)})
		and adapter.focus_lost()
		and adapter.handle_keyboard("mode_navigate")
		and adapter.handle_keyboard("navigate", {"view_state": {"orbit": [0.0, 0.5, 0.0]}})
		and adapter.handle_keyboard("mode_frame")
		and adapter.handle_keyboard("select_frame")
		and adapter.handle_keyboard("undo")
		and adapter.handle_keyboard("redo")
	)


func _xr_workflow(adapter: RefCounted) -> bool:
	return (
		adapter.handle_ray("mode_frame")
		and adapter.handle_ray("select_frame")
		and adapter.handle_grab("begin_move")
		and adapter.handle_grab("preview_move", {"delta": Vector3(2.0, 1.0, -1.0)})
		and adapter.handle_grab("commit")
		and adapter.handle_grab("begin_resize")
		and adapter.handle_grab("preview_resize", {"bounds": Vector3(8.0, 5.0, 3.0)})
		and adapter.tracking_lost()
		and adapter.handle_ray("mode_navigate")
		and adapter.handle_ray("navigate", {"view_state": {"orbit": [0.0, 0.5, 0.0]}})
		and adapter.handle_ray("mode_frame")
		and adapter.handle_ray("select_frame")
		and adapter.handle_button("undo")
		and adapter.handle_button("redo")
	)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
