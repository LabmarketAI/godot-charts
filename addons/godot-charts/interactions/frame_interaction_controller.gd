class_name FrameInteractionController
extends RefCounted

signal mode_changed(mode: String)
signal selection_changed(selected: bool)
signal capture_changed(active: bool, operation: String, owner: String)
signal command_committed(command: Dictionary)
signal interaction_diagnostic(diagnostic: Dictionary)

const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")

const MODES: PackedStringArray = ["content", "frame", "navigate"]
const OPERATIONS: PackedStringArray = ["move", "rotate", "resize"]

var mode: String = "content"
var selected: bool = false
var diagnostics: Array[Dictionary] = []
var command_trace: Array[Dictionary] = []
var history_limit: int = 64

var _state: RefCounted
var _presentation: Node3D
var _capture_operation: String = ""
var _capture_owner: String = ""
var _capture_before: Dictionary = {}
var _history: Array[Dictionary] = []
var _history_cursor: int = 0


func bind(state: RefCounted, presentation: Node3D) -> bool:
	diagnostics.clear()
	if state == null or not state.has_method("replace_from") or not state.validate().is_empty():
		_report("invalid-frame-state", "Interaction controller requires valid mutable frame state.", "/interaction/frame")
		return false
	if presentation == null or not presentation.has_method("apply_frame_state"):
		_report("invalid-frame-presentation", "Interaction controller requires a frame presentation port.", "/interaction/presentation")
		return false
	if not presentation.apply_frame_state(state):
		_report("presentation-rejected-state", "Frame presentation rejected initial interaction state.", "/interaction/presentation")
		return false
	_state = state
	_presentation = presentation
	_sync_interaction_presentation()
	return true


func set_mode(next_mode: String) -> bool:
	if next_mode not in MODES:
		_report("invalid-input-mode", "Input mode is not supported.", "/interaction/mode")
		return false
	if is_capturing():
		cancel()
	if mode == next_mode:
		return true
	mode = next_mode
	_sync_interaction_presentation()
	_trace("mode", {"mode": mode})
	mode_changed.emit(mode)
	return true


func set_selected(next_selected: bool) -> void:
	if selected == next_selected:
		return
	if not next_selected and is_capturing():
		cancel()
	selected = next_selected
	_sync_interaction_presentation()
	_trace("selection", {"selected": selected})
	selection_changed.emit(selected)


func accepts_intent(intent: String) -> bool:
	match mode:
		"content": return intent in ["inspect", "select", "multi_select"]
		"frame": return intent in ["frame_select", "move", "rotate", "resize", "lock", "reset"]
		"navigate": return intent in ["navigate", "orbit", "focus", "teleport"]
	return false


func begin(operation: String, owner: String) -> bool:
	if mode != "frame":
		_report("wrong-input-mode", "Frame manipulation requires frame mode.", "/interaction/mode")
		return false
	if not selected:
		_report("frame-not-selected", "Frame must be selected before manipulation.", "/interaction/selection")
		return false
	if _state.locked:
		_report("frame-locked", "Locked frame cannot be manipulated.", "/frame/locked")
		return false
	if operation not in OPERATIONS or owner.is_empty():
		_report("invalid-capture", "Manipulation requires a supported operation and capture owner.", "/interaction/capture")
		return false
	if is_capturing():
		_report("capture-active", "Another manipulation already owns frame capture.", "/interaction/capture")
		return false
	_capture_operation = operation
	_capture_owner = owner
	_capture_before = _state.to_dictionary()
	_sync_interaction_presentation()
	_trace("begin", {"operation": operation, "owner": owner})
	capture_changed.emit(true, operation, owner)
	return true


func preview_move(delta: Vector3, owner: String) -> bool:
	if not _owns_capture("move", owner):
		return false
	var before := FrameState.from_dictionary(_capture_before)
	var next := FrameState.from_dictionary(_capture_before)
	next.transform.origin = before.transform.origin + delta
	return _preview(next, "move")


func preview_rotate(delta_euler: Vector3, owner: String) -> bool:
	if not _owns_capture("rotate", owner):
		return false
	var next := FrameState.from_dictionary(_capture_before)
	next.transform.basis = Basis.from_euler(delta_euler) * next.transform.basis
	return _preview(next, "rotate")


func preview_resize(next_bounds: Vector3, owner: String) -> bool:
	if not _owns_capture("resize", owner):
		return false
	var next := FrameState.from_dictionary(_capture_before)
	next.bounds = next_bounds
	if not next.validate().is_empty():
		_report("invalid-resize-preview", "Resize preview violates frame bounds.", "/frame/bounds")
		return false
	return _preview(next, "resize")


func commit(owner: String) -> bool:
	if not is_capturing() or owner != _capture_owner:
		_report("capture-owner-mismatch", "Only the active capture owner may commit.", "/interaction/capture/owner")
		return false
	var before := _capture_before.duplicate(true)
	var after: Dictionary = _state.to_dictionary()
	var operation := _capture_operation
	var capture_owner := _capture_owner
	_clear_capture()
	if before != after:
		_record_history(operation, before, after)
	var command := {"type": operation, "owner": capture_owner, "before": before, "after": after}
	_trace("commit", {"operation": operation, "owner": capture_owner})
	command_committed.emit(command.duplicate(true))
	return true


func cancel() -> bool:
	if not is_capturing():
		return false
	var operation := _capture_operation
	var owner := _capture_owner
	var restored := _restore(_capture_before)
	_clear_capture()
	_trace("cancel", {"operation": operation, "owner": owner})
	return restored


func set_locked(next_locked: bool) -> bool:
	if is_capturing():
		cancel()
	if _state.locked == next_locked:
		return true
	var before: Dictionary = _state.to_dictionary()
	_state.locked = next_locked
	if not _presentation.apply_frame_state(_state):
		_restore(before)
		return false
	var after: Dictionary = _state.to_dictionary()
	_record_history("lock" if next_locked else "unlock", before, after)
	_trace("lock", {"locked": next_locked})
	return true


func reset() -> bool:
	if is_capturing():
		cancel()
	if _state.locked:
		_report("frame-locked", "Locked frame cannot be reset.", "/frame/locked")
		return false
	var before: Dictionary = _state.to_dictionary()
	_state.reset_to_authored()
	if not _presentation.apply_frame_state(_state):
		_restore(before)
		return false
	var after: Dictionary = _state.to_dictionary()
	if before != after:
		_record_history("reset", before, after)
	_trace("reset", {})
	return true


func update_navigation(next_view_state: Dictionary) -> bool:
	if mode != "navigate":
		_report("wrong-input-mode", "Navigation state requires navigate mode.", "/interaction/mode")
		return false
	var frame_transform: Transform3D = _state.transform
	var frame_bounds: Vector3 = _state.bounds
	var before: Dictionary = _state.to_dictionary()
	_state.local_view_state = next_view_state.duplicate(true)
	if not _presentation.apply_frame_state(_state):
		_restore(before)
		return false
	_trace("navigate", {"local_view_state": next_view_state.duplicate(true)})
	return _state.transform.is_equal_approx(frame_transform) and _state.bounds.is_equal_approx(frame_bounds)


func undo() -> bool:
	if is_capturing() or _history_cursor <= 0:
		return false
	_history_cursor -= 1
	var command: Dictionary = _history[_history_cursor]
	if not _restore(command["before"]):
		_history_cursor += 1
		return false
	_trace("undo", {"command": command["type"]})
	return true


func redo() -> bool:
	if is_capturing() or _history_cursor >= _history.size():
		return false
	var command: Dictionary = _history[_history_cursor]
	if not _restore(command["after"]):
		return false
	_history_cursor += 1
	_trace("redo", {"command": command["type"]})
	return true


func is_capturing() -> bool:
	return not _capture_operation.is_empty()


func capture_snapshot() -> Dictionary:
	return {"active": is_capturing(), "operation": _capture_operation, "owner": _capture_owner}


func history_snapshot() -> Dictionary:
	return {"size": _history.size(), "cursor": _history_cursor, "can_undo": _history_cursor > 0, "can_redo": _history_cursor < _history.size()}


func _preview(next: RefCounted, operation: String) -> bool:
	var current: Dictionary = _state.to_dictionary()
	if not _state.replace_from(next) or not _presentation.apply_frame_state(_state):
		_restore(current)
		_report("preview-rejected", "Frame presentation rejected manipulation preview.", "/interaction/preview")
		return false
	_trace("preview", {"operation": operation})
	return true


func _owns_capture(operation: String, owner: String) -> bool:
	if _capture_operation == operation and _capture_owner == owner:
		return true
	_report("capture-owner-mismatch", "Preview does not match the active operation and owner.", "/interaction/capture")
	return false


func _restore(snapshot: Dictionary) -> bool:
	var restored := FrameState.from_dictionary(snapshot)
	if not restored.validate().is_empty() or not _state.replace_from(restored):
		return false
	return _presentation.apply_frame_state(_state)


func _record_history(command_type: String, before: Dictionary, after: Dictionary) -> void:
	if _history_cursor < _history.size():
		_history.resize(_history_cursor)
	_history.append({"type": command_type, "before": before.duplicate(true), "after": after.duplicate(true)})
	while _history.size() > maxi(history_limit, 1):
		_history.pop_front()
	_history_cursor = _history.size()


func _clear_capture() -> void:
	_capture_operation = ""
	_capture_owner = ""
	_capture_before.clear()
	_sync_interaction_presentation()
	capture_changed.emit(false, "", "")


func _trace(event: String, payload: Dictionary) -> void:
	var entry := {"event": event}
	entry.merge(payload, true)
	command_trace.append(entry)


func _sync_interaction_presentation() -> void:
	if _presentation != null and _presentation.has_method("apply_interaction_state"):
		_presentation.apply_interaction_state(mode, selected, capture_snapshot())


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	interaction_diagnostic.emit(diagnostic.duplicate(true))
