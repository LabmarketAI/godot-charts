@tool
extends Node3D

const AxisDomainController = preload("res://addons/godot-charts/interactions/axis_domain_interaction_controller.gd")

const POINTABLE_LAYER := 1 << 20
const SCRUBBER_OUTSET := 0.22
const MIN_WINDOW_FRACTION := 0.04

var _frame: AnalyticalFrame3D
var _controller: AxisDomainInteractionController
var _scrubbers: Dictionary = {}
var _active_pointers: Dictionary = {}
var _status_label: Label3D
var _hover_target: ChartDomainPointerTarget


func setup(frame: AnalyticalFrame3D, figure: RefCounted) -> void:
	_frame = frame
	name = "ChartAxisDomainScrubbers"
	_controller = AxisDomainController.new()
	if not _controller.bind(frame, figure):
		push_error("Failed to bind chart axis-domain scrubber controller: %s" % [_controller.diagnostics])
		return
	_controller.domain_previewed.connect(_on_domain_previewed)
	_controller.domain_committed.connect(_on_domain_committed)
	_controller.domain_cancelled.connect(_on_domain_cancelled)
	_bind_editor_scrubbers()
	_status_label = get_node_or_null("StatusLabel") as Label3D
	_update_all_scrubber_windows()
	_set_status("Trigger ray: drag axis window to scrub; drag ends to zoom.")


func desktop_begin_drag(target: ChartDomainPointerTarget, hit_position: Vector3, pointer: Node) -> bool:
	if target == null or pointer == null:
		return false
	return _begin_pointer_drag(pointer, target, hit_position)


func desktop_update_drag(pointer: Node, hit_position: Vector3) -> bool:
	if pointer == null or not _active_pointers.has(pointer):
		return false
	_update_pointer_drag(pointer, hit_position)
	return true


func desktop_end_drag(pointer: Node) -> bool:
	if pointer == null or not _active_pointers.has(pointer):
		return false
	_end_pointer_drag(pointer)
	return true


func desktop_cancel_drag(pointer: Node) -> bool:
	if pointer == null or not _active_pointers.has(pointer):
		return false
	var target: ChartDomainPointerTarget = _active_pointers[pointer].get("target")
	if _controller.cancel() and target != null:
		_set_target_state(target, "idle")
	_update_all_scrubber_windows()
	_active_pointers.erase(pointer)
	_frame.apply_interaction_state("frame", true, {"active": not _active_pointers.is_empty()})
	_set_status("Axis domain preview cancelled")
	return true


func desktop_reset_axis(target: ChartDomainPointerTarget) -> bool:
	if target == null:
		return false
	var channel := str(target.get_meta("axis_channel"))
	if not _controller.reset_channel(channel):
		return false
	_update_scrubber_window(channel)
	_set_status("Fit %s axis to full extent" % channel.to_upper())
	return true


func desktop_zoom_axis(target: ChartDomainPointerTarget, factor: float, focus_unit: float = 0.5) -> bool:
	if target == null:
		return false
	var channel := str(target.get_meta("axis_channel"))
	if not _controller.begin(channel, "range"):
		return false
	var ok := _controller.preview_zoom(factor, focus_unit) and _controller.commit()
	_update_scrubber_window(channel)
	_set_status("Zoom %s axis" % channel.to_upper())
	return ok


func _bind_editor_scrubbers() -> void:
	_scrubbers.clear()
	_active_pointers.clear()
	var bounds: Vector3 = _frame.active_state.bounds if _frame.active_state != null else Vector3(3.2, 2.0, 2.0)
	_bind_axis("x", Vector3.RIGHT, bounds.x, Vector3(0.0, -bounds.y * 0.5 - SCRUBBER_OUTSET, bounds.z * 0.5 + SCRUBBER_OUTSET), -1.0)
	_bind_axis("y", Vector3.UP, bounds.y, Vector3(-bounds.x * 0.5 - SCRUBBER_OUTSET, 0.0, bounds.z * 0.5 + SCRUBBER_OUTSET))
	_bind_axis("z", Vector3.BACK, bounds.z, Vector3(-bounds.x * 0.5 - SCRUBBER_OUTSET, -bounds.y * 0.5 - SCRUBBER_OUTSET, 0.0))


func _bind_axis(channel: String, axis: Vector3, axis_length: float, offset: Vector3, drag_sign: float = 1.0) -> void:
	var scrubber := get_node_or_null("%sAxisScrubber" % channel.to_upper()) as Node3D
	if scrubber == null:
		push_error("Missing editor-authored %s axis scrubber." % channel.to_upper())
		return
	scrubber.position = offset
	scrubber.set_meta("axis_channel", channel)
	scrubber.set_meta("axis_vector", axis.normalized())
	scrubber.set_meta("axis_length", maxf(axis_length, 0.001))
	scrubber.set_meta("axis_drag_sign", drag_sign)
	_scrubbers[channel] = {
		"root": scrubber,
		"axis": axis.normalized(),
		"axis_length": maxf(axis_length, 0.001),
		"drag_sign": drag_sign,
		"window": scrubber.get_node_or_null("Window"),
		"range_target": scrubber.get_node_or_null("RangeTarget"),
		"min_target": scrubber.get_node_or_null("MinTarget"),
		"max_target": scrubber.get_node_or_null("MaxTarget"),
		"focus_marker": scrubber.get_node_or_null("FocusMarker"),
	}
	_bind_part(scrubber, "RangeTarget", channel, "range", axis, axis_length, drag_sign)
	_bind_part(scrubber, "MinTarget", channel, "min", axis, axis_length, drag_sign)
	_bind_part(scrubber, "MaxTarget", channel, "max", axis, axis_length, drag_sign)
	var label := scrubber.get_node_or_null("Label") as Label3D
	if label != null:
		label.text = "%s domain" % channel.to_upper()


func _bind_part(scrubber: Node3D, node_name: String, channel: String, part: String, axis: Vector3, axis_length: float, drag_sign: float) -> void:
	var target := scrubber.get_node_or_null(node_name) as ChartDomainPointerTarget
	if target == null:
		push_error("Missing editor-authored scrubber target: %s/%s" % [scrubber.name, node_name])
		return
	target.controller = self
	target.collision_layer = POINTABLE_LAYER
	target.collision_mask = 0
	target.set_meta("interaction_role", "axis_domain_scrubber")
	target.set_meta("axis_channel", channel)
	target.set_meta("axis_part", part)
	target.set_meta("axis_vector", axis.normalized())
	target.set_meta("axis_length", maxf(axis_length, 0.001))
	target.set_meta("axis_drag_sign", drag_sign)


func _place_endpoint(scrubber: Node3D, node_name: String, position: Vector3) -> void:
	var target := scrubber.get_node_or_null(node_name) as Node3D
	if target != null:
		target.position = position


func _on_pointable_event(target: ChartDomainPointerTarget, event: Object) -> void:
	if _frame == null or event == null:
		return
	var pointer: Node = event.pointer
	if pointer == null:
		return
	match int(event.event_type):
		XRToolsPointerEvent.Type.ENTERED:
			_hover_target = target
			_set_target_state(target, "hover")
			_frame.apply_interaction_state("frame", true)
			_set_status("Target %s %s: trigger drag along the axis" % [target.get_meta("axis_channel"), target.get_meta("axis_part")])
		XRToolsPointerEvent.Type.PRESSED:
			_begin_pointer_drag(pointer, target, event.position)
		XRToolsPointerEvent.Type.MOVED:
			_update_pointer_drag(pointer, event.position)
		XRToolsPointerEvent.Type.RELEASED:
			_end_pointer_drag(pointer)
		XRToolsPointerEvent.Type.EXITED:
			if _hover_target == target:
				_hover_target = null
			_set_target_state(target, "idle")
			if not _active_pointers.has(pointer):
				_frame.apply_interaction_state("frame", true)


func _begin_pointer_drag(pointer: Node, target: ChartDomainPointerTarget, hit_position: Vector3) -> bool:
	var channel := str(target.get_meta("axis_channel"))
	var part := str(target.get_meta("axis_part"))
	if not _controller.begin(channel, part):
		return false
	_set_target_state(target, "active")
	_set_status("Dragging %s %s" % [channel.to_upper(), part])
	_active_pointers[pointer] = {
		"target": target,
		"start_position": hit_position,
		"axis_vector": _frame.global_transform.basis * (target.get_meta("axis_vector") as Vector3),
		"axis_length": float(target.get_meta("axis_length")),
		"drag_sign": float(target.get_meta("axis_drag_sign", 1.0)),
	}
	_frame.apply_interaction_state("frame", true, {"active": true})
	return true


func _update_pointer_drag(pointer: Node, hit_position: Vector3) -> void:
	if not _active_pointers.has(pointer):
		return
	var drag: Dictionary = _active_pointers[pointer]
	var axis: Vector3 = drag["axis_vector"]
	var delta: Vector3 = hit_position - drag["start_position"]
	var delta_unit := delta.dot(axis.normalized()) / float(drag["axis_length"]) * float(drag.get("drag_sign", 1.0))
	_controller.preview_delta(delta_unit)


func _end_pointer_drag(pointer: Node) -> void:
	if _active_pointers.has(pointer):
		var target: ChartDomainPointerTarget = _active_pointers[pointer].get("target")
		_controller.commit()
		if target != null:
			_set_target_state(target, "hover" if target == _hover_target else "idle")
		_set_status("Axis domain committed")
	_active_pointers.erase(pointer)
	_frame.apply_interaction_state("frame", true, {"active": not _active_pointers.is_empty()})


func _on_domain_previewed(channel: String, part: String, domain_min: float, domain_max: float) -> void:
	_update_scrubber_window(channel)
	print("chart-domain-preview channel=%s part=%s min=%.5f max=%.5f" % [channel, part, domain_min, domain_max])


func _on_domain_committed(channel: String, part: String, domain_min: float, domain_max: float) -> void:
	_update_scrubber_window(channel)
	print("chart-domain-commit channel=%s part=%s min=%.5f max=%.5f" % [channel, part, domain_min, domain_max])


func _on_domain_cancelled(channel: String, part: String) -> void:
	_update_scrubber_window(channel)
	print("chart-domain-cancel channel=%s part=%s" % [channel, part])


func _set_status(text: String) -> void:
	print("chart-domain-status %s" % text)
	if _status_label != null:
		_status_label.text = text


func _update_all_scrubber_windows() -> void:
	for channel: String in _scrubbers.keys():
		_update_scrubber_window(channel)


func _update_scrubber_window(channel: String) -> void:
	if _frame == null or _controller == null or not _scrubbers.has(channel):
		return
	var snapshot := _controller.domain_snapshot()
	if not snapshot.has(channel):
		return
	var domain: Dictionary = snapshot[channel]
	var extent_min := float(domain.get("extent_min", domain["min"]))
	var extent_max := float(domain.get("extent_max", domain["max"]))
	var extent_span := maxf(extent_max - extent_min, 0.000001)
	var start := clampf((float(domain["min"]) - extent_min) / extent_span, 0.0, 1.0)
	var end := clampf((float(domain["max"]) - extent_min) / extent_span, 0.0, 1.0)
	var window_size := maxf(end - start, MIN_WINDOW_FRACTION)
	var center := (start + end) * 0.5
	var scrubber: Dictionary = _scrubbers[channel]
	var axis: Vector3 = scrubber["axis"]
	var axis_length := float(scrubber["axis_length"])
	var body_length := axis_length * window_size
	var body_center := axis * ((center - 0.5) * axis_length)
	_set_axis_node_position(scrubber.get("window"), body_center)
	_set_axis_node_scale(scrubber.get("window"), channel, body_length)
	_set_axis_node_position(scrubber.get("range_target"), body_center)
	_set_axis_node_scale(scrubber.get("range_target"), channel, body_length)
	_set_axis_node_position(scrubber.get("min_target"), axis * ((start - 0.5) * axis_length))
	_set_axis_node_position(scrubber.get("max_target"), axis * ((end - 0.5) * axis_length))
	_set_axis_node_position(scrubber.get("focus_marker"), axis * ((float(domain.get("focus", 0.5)) - 0.5) * axis_length))


func _set_axis_node_position(node: Variant, position: Vector3) -> void:
	if node is Node3D:
		(node as Node3D).position = position


func _set_axis_node_scale(node: Variant, channel: String, body_length: float) -> void:
	if not (node is Node3D):
		return
	var node_3d := node as Node3D
	var scale := Vector3.ONE
	match channel:
		"x": scale.x = maxf(body_length / 2.35, 0.02)
		"y": scale.y = maxf(body_length / 1.45, 0.02)
		"z": scale.z = maxf(body_length / 1.45, 0.02)
	node_3d.scale = scale


func _set_target_state(target: ChartDomainPointerTarget, state: String) -> void:
	if target == null:
		return
	target.set_meta("interaction_state", state)
