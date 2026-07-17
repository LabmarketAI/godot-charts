class_name FrameInputIntentRouter
extends RefCounted

var controller: RefCounted


func bind(next_controller: RefCounted) -> bool:
	if next_controller == null or not next_controller.has_method("set_mode") or not next_controller.has_method("begin"):
		return false
	controller = next_controller
	return true


func dispatch(intent: String, payload: Dictionary = {}) -> bool:
	if controller == null:
		return false
	var owner: String = payload.get("owner", "")
	match intent:
		"mode_content": return controller.set_mode("content")
		"mode_frame": return controller.set_mode("frame")
		"mode_navigate": return controller.set_mode("navigate")
		"select_frame":
			controller.set_selected(payload.get("selected", true))
			return true
		"begin_move": return controller.begin("move", owner)
		"begin_rotate": return controller.begin("rotate", owner)
		"begin_resize": return controller.begin("resize", owner)
		"preview_move": return controller.preview_move(payload.get("delta", Vector3.ZERO), owner)
		"preview_rotate": return controller.preview_rotate(payload.get("delta", Vector3.ZERO), owner)
		"preview_resize": return controller.preview_resize(payload.get("bounds", Vector3.ZERO), owner)
		"commit": return controller.commit(owner)
		"cancel", "capture_lost": return controller.cancel()
		"undo": return controller.undo()
		"redo": return controller.redo()
		"reset": return controller.reset()
		"lock": return controller.set_locked(true)
		"unlock": return controller.set_locked(false)
		"navigate": return controller.update_navigation(payload.get("view_state", {}))
	return false
