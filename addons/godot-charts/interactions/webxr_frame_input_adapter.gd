class_name WebXrFrameInputAdapter
extends RefCounted

signal ray_updated(input_source_id: int, ray: Dictionary)
signal input_diagnostic(diagnostic: Dictionary)

const IntentRouter = preload("res://addons/godot-charts/interactions/frame_input_intent_router.gd")

var _router := IntentRouter.new()
var _controller: RefCounted
var _interface: Variant
var _pose_reader: Callable
var _active_source := -1
var _capture_origin := Vector3.ZERO


func bind(controller: RefCounted, interface: Variant, pose_reader: Callable = Callable()) -> bool:
	if controller == null or interface == null or not _router.bind(controller):
		return false
	_controller = controller
	_interface = interface
	_pose_reader = pose_reader
	_connect_once("selectstart", _on_select_start)
	_connect_once("selectend", _on_select_end)
	_connect_once("squeezestart", _on_squeeze_start)
	_connect_once("squeezeend", _on_squeeze_end)
	_connect_once("session_ended", _on_tracking_lost)
	_connect_once("session_failed", _on_session_failed)
	return true


func update() -> bool:
	if _interface == null:
		return false
	var updated := false
	for input_source_id: int in _active_input_sources():
		var ray := ray_snapshot(input_source_id)
		if ray.is_empty():
			continue
		ray_updated.emit(input_source_id, ray.duplicate(true))
		updated = true
		if input_source_id == _active_source and _controller.is_capturing():
			_router.dispatch("preview_move", {
				"owner": _owner(input_source_id),
				"delta": ray["transform"].origin - _capture_origin,
			})
	return updated


func ray_snapshot(input_source_id: int) -> Dictionary:
	if _pose_reader.is_valid():
		var supplied: Variant = _pose_reader.call(input_source_id)
		return supplied if supplied is Dictionary else {}
	if not _interface.is_input_source_active(input_source_id):
		return {}
	var tracker: Variant = _interface.get_input_source_tracker(input_source_id)
	if tracker == null:
		return {}
	var pose: Variant = tracker.get_pose(&"aim")
	if pose == null or not pose.has_tracking_data:
		return {}
	var transform: Transform3D = pose.transform
	return {
		"transform": transform,
		"origin": transform.origin,
		"direction": -transform.basis.z.normalized(),
		"target_ray_mode": int(_interface.get_input_source_target_ray_mode(input_source_id)),
	}


func cancel_capture() -> bool:
	_active_source = -1
	return _router.dispatch("capture_lost")


func _on_select_start(input_source_id: int) -> void:
	if _controller.mode != "frame":
		return
	if not _controller.selected:
		_router.dispatch("select_frame")
		return
	_begin_move(input_source_id)


func _on_select_end(input_source_id: int) -> void:
	_commit(input_source_id)


func _on_squeeze_start(input_source_id: int) -> void:
	if _controller.mode == "frame" and _controller.selected:
		_begin_move(input_source_id)


func _on_squeeze_end(input_source_id: int) -> void:
	_commit(input_source_id)


func _begin_move(input_source_id: int) -> bool:
	var ray := ray_snapshot(input_source_id)
	if ray.is_empty():
		_report("webxr-pose-unavailable", "The WebXR input source has no tracked aim pose.")
		return false
	var owner := _owner(input_source_id)
	if not _router.dispatch("begin_move", {"owner": owner}):
		return false
	_active_source = input_source_id
	_capture_origin = ray["transform"].origin
	return true


func _commit(input_source_id: int) -> bool:
	if input_source_id != _active_source:
		return false
	var owner := _owner(input_source_id)
	_active_source = -1
	return _router.dispatch("commit", {"owner": owner})


func _on_tracking_lost() -> void:
	cancel_capture()


func _on_session_failed(_message: String) -> void:
	cancel_capture()


func _active_input_sources() -> Array[int]:
	var result: Array[int] = []
	for input_source_id: int in range(1, 17):
		if _pose_reader.is_valid() or _interface.is_input_source_active(input_source_id):
			var ray := ray_snapshot(input_source_id)
			if not ray.is_empty():
				result.append(input_source_id)
	return result


func _connect_once(signal_name: StringName, callback: Callable) -> void:
	if _interface.has_signal(signal_name) and not _interface.is_connected(signal_name, callback):
		_interface.connect(signal_name, callback)


func _owner(input_source_id: int) -> String:
	return "webxr:%d" % input_source_id


func _report(code: String, message: String) -> void:
	input_diagnostic.emit({"severity": "warning", "code": code, "message": message, "path": "/webxr/input"})
