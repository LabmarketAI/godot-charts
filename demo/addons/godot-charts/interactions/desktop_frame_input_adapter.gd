class_name DesktopFrameInputAdapter
extends RefCounted

const IntentRouter = preload("res://addons/godot-charts/interactions/frame_input_intent_router.gd")

var owner: String = "primary"
var _router := IntentRouter.new()


func bind(controller: RefCounted) -> bool:
	return _router.bind(controller)


func handle_mouse(action: String, payload: Dictionary = {}) -> bool:
	if action not in ["select_frame", "begin_move", "begin_rotate", "begin_resize", "preview_move", "preview_rotate", "preview_resize", "commit", "cancel", "capture_lost"]:
		return false
	var normalized := payload.duplicate(true)
	normalized["owner"] = owner
	return _router.dispatch(action, normalized)


func handle_keyboard(action: String, payload: Dictionary = {}) -> bool:
	if action not in ["mode_content", "mode_frame", "mode_navigate", "select_frame", "cancel", "undo", "redo", "reset", "lock", "unlock", "navigate"]:
		return false
	return _router.dispatch(action, payload)


func focus_lost() -> bool:
	return _router.dispatch("capture_lost", {"owner": owner})
