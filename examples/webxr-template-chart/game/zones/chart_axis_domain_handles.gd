extends Node3D

const AxisDomainController = preload("res://addons/godot-charts/interactions/axis_domain_interaction_controller.gd")
const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")
const Tokens = preload("res://addons/godot-charts/assets/visual/visual_theme_tokens.gd")
const Factory = preload("res://addons/godot-charts/assets/visual/procedural_visual_asset_factory.gd")

const HANDLE_LAYER := 1 << 18
const HELD_LAYER := 1 << 16
const POINTABLE_LAYER := 1 << 20
const HANDLE_RADIUS := 0.14
const HANDLE_OUTSET := 0.22


class PointableDomainHandle:
	extends StaticBody3D

	var controller: Node

	func pointer_event(event: Object) -> void:
		if controller != null and controller.has_method("_on_pointable_event"):
			controller._on_pointable_event(self, event)

var _frame: AnalyticalFrame3D
var _controller: AxisDomainInteractionController
var _asset_factory: ProceduralVisualAssetFactory
var _handles: Dictionary = {}
var _active_grabs: Dictionary = {}
var _active_pointers: Dictionary = {}


func setup(frame: AnalyticalFrame3D, figure: RefCounted) -> void:
	_frame = frame
	name = "ChartAxisDomainHandles"
	_controller = AxisDomainController.new()
	_asset_factory = Factory.new(Tokens.webxr_performance())
	if not _controller.bind(frame, figure):
		push_error("Failed to bind chart axis-domain controller: %s" % [_controller.diagnostics])
		return
	_controller.domain_previewed.connect(_on_domain_previewed)
	_controller.domain_committed.connect(_on_domain_committed)
	_controller.domain_cancelled.connect(_on_domain_cancelled)
	_frame.chrome_root().add_child(self)
	_rebuild()


func _process(_delta: float) -> void:
	if _frame == null:
		return
	for handle: XRToolsInteractableHandle in _active_grabs.keys():
		_update_grab(handle)


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_handles.clear()
	_active_grabs.clear()
	_active_pointers.clear()
	var bounds: Vector3 = _frame.active_state.bounds if _frame.active_state != null else Vector3(3.2, 2.0, 1.6)
	_create_axis_pair("x", Vector3.RIGHT, bounds.x)
	_create_axis_pair("y", Vector3.UP, bounds.y)
	_create_axis_pair("z", Vector3.BACK, bounds.z)


func _create_axis_pair(channel: String, direction: Vector3, length: float) -> void:
	var half := length * 0.5 + HANDLE_OUTSET
	_create_handle(channel, "min", -direction * half, direction, length)
	_create_handle(channel, "max", direction * half, direction, length)


func _create_handle(channel: String, edge: String, local_position: Vector3, axis: Vector3, axis_length: float) -> void:
	var origin := Node3D.new()
	origin.name = "%sDomain%sOrigin" % [channel.to_upper(), edge.capitalize()]
	origin.position = local_position
	origin.set_meta("axis_channel", channel)
	origin.set_meta("axis_edge", edge)
	origin.set_meta("axis_vector", axis.normalized())
	origin.set_meta("axis_length", maxf(axis_length, 0.001))
	add_child(origin)

	var handle := XRToolsInteractableHandle.new()
	handle.name = "%sDomain%s" % [channel.to_upper(), edge.capitalize()]
	handle.collision_layer = HANDLE_LAYER
	handle.collision_mask = 0
	handle.gravity_scale = 0.0
	handle.freeze = true
	handle.picked_up_layer = HELD_LAYER
	handle.snap_distance = 1.5
	handle.set_meta("axis_channel", channel)
	handle.set_meta("axis_edge", edge)
	handle.set_meta("axis_vector", axis.normalized())
	handle.set_meta("axis_length", maxf(axis_length, 0.001))
	origin.add_child(handle)
	_handles[channel + ":" + edge] = handle

	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = HANDLE_RADIUS
	shape.shape = sphere_shape
	handle.add_child(shape)

	var state := Roles.STATE_FOCUS if edge == "min" else Roles.STATE_ACTIVE
	var asset := _asset_factory.instantiate(Roles.CONTROL_SLIDER_THUMB, state)
	asset.name = "AxisDomainVisual"
	asset.scale = Vector3.ONE * 0.88
	handle.add_child(asset)

	_add_grab_point(handle, "GrabPointLeft", XRToolsGrabPointHand.Hand.LEFT)
	_add_grab_point(handle, "GrabPointRight", XRToolsGrabPointHand.Hand.RIGHT)
	handle.picked_up.connect(_on_handle_picked_up.bind(handle))
	handle.dropped.connect(_on_handle_dropped.bind(handle))
	_add_pointable_target(origin, handle)


func _add_pointable_target(parent: Node3D, handle: XRToolsInteractableHandle) -> void:
	var target := PointableDomainHandle.new()
	target.name = handle.name + "PointerTarget"
	target.controller = self
	target.collision_layer = POINTABLE_LAYER
	target.collision_mask = 0
	target.set_meta("chart_domain_handle", handle)
	parent.add_child(target)

	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = HANDLE_RADIUS * 1.8
	shape.shape = sphere_shape
	target.add_child(shape)


func _add_grab_point(parent: Node, point_name: String, hand: XRToolsGrabPointHand.Hand) -> void:
	var point := XRToolsGrabPointHand.new()
	point.name = point_name
	point.hand = hand
	point.snap_hand = false
	parent.add_child(point)


func _on_handle_picked_up(_pickable: XRToolsPickable, handle: XRToolsInteractableHandle) -> void:
	var channel := str(handle.get_meta("axis_channel"))
	var edge := str(handle.get_meta("axis_edge"))
	if not _controller.begin(channel, edge):
		return
	_active_grabs[handle] = {
		"start_position": handle.global_position,
		"axis_vector": _frame.global_transform.basis * (handle.get_meta("axis_vector") as Vector3),
		"axis_length": float(handle.get_meta("axis_length")),
	}
	_frame.apply_interaction_state("frame", true, {"active": true})
	set_process(true)


func _on_handle_dropped(_pickable: XRToolsPickable, handle: XRToolsInteractableHandle) -> void:
	if _active_grabs.has(handle):
		_controller.commit()
	_active_grabs.erase(handle)
	_frame.apply_interaction_state("frame", true, {"active": not _active_grabs.is_empty() or not _active_pointers.is_empty()})
	set_process(not _active_grabs.is_empty() or not _active_pointers.is_empty())


func _update_grab(handle: XRToolsInteractableHandle) -> void:
	var grab: Dictionary = _active_grabs[handle]
	var axis: Vector3 = grab["axis_vector"]
	var delta: Vector3 = handle.global_position - grab["start_position"]
	var delta_unit := delta.dot(axis.normalized()) / float(grab["axis_length"])
	_controller.preview_delta(delta_unit)


func _on_pointable_event(target: PointableDomainHandle, event: Object) -> void:
	if _frame == null or event == null:
		return
	var pointer: Node = event.pointer
	var handle: XRToolsInteractableHandle = target.get_meta("chart_domain_handle") as XRToolsInteractableHandle
	if pointer == null or handle == null:
		return
	match int(event.event_type):
		XRToolsPointerEvent.Type.ENTERED:
			_frame.apply_interaction_state("frame", true)
		XRToolsPointerEvent.Type.PRESSED:
			_begin_pointer_drag(pointer, handle, event.position)
		XRToolsPointerEvent.Type.MOVED:
			_update_pointer_drag(pointer, event.position)
		XRToolsPointerEvent.Type.RELEASED:
			_end_pointer_drag(pointer)
		XRToolsPointerEvent.Type.EXITED:
			if not _active_pointers.has(pointer):
				_frame.apply_interaction_state("frame", true)


func _begin_pointer_drag(pointer: Node, handle: XRToolsInteractableHandle, hit_position: Vector3) -> void:
	var channel := str(handle.get_meta("axis_channel"))
	var edge := str(handle.get_meta("axis_edge"))
	if not _controller.begin(channel, edge):
		return
	_active_pointers[pointer] = {
		"start_position": hit_position,
		"axis_vector": _frame.global_transform.basis * (handle.get_meta("axis_vector") as Vector3),
		"axis_length": float(handle.get_meta("axis_length")),
	}
	_frame.apply_interaction_state("frame", true, {"active": true})
	set_process(true)


func _update_pointer_drag(pointer: Node, hit_position: Vector3) -> void:
	if not _active_pointers.has(pointer):
		return
	var drag: Dictionary = _active_pointers[pointer]
	var axis: Vector3 = drag["axis_vector"]
	var delta: Vector3 = hit_position - drag["start_position"]
	var delta_unit := delta.dot(axis.normalized()) / float(drag["axis_length"])
	_controller.preview_delta(delta_unit)


func _end_pointer_drag(pointer: Node) -> void:
	if _active_pointers.has(pointer):
		_controller.commit()
	_active_pointers.erase(pointer)
	_frame.apply_interaction_state("frame", true, {"active": not _active_grabs.is_empty() or not _active_pointers.is_empty()})
	set_process(not _active_grabs.is_empty() or not _active_pointers.is_empty())


func _on_domain_previewed(channel: String, edge: String, domain_min: float, domain_max: float) -> void:
	print("chart-domain-preview channel=%s edge=%s min=%.5f max=%.5f" % [channel, edge, domain_min, domain_max])


func _on_domain_committed(channel: String, edge: String, domain_min: float, domain_max: float) -> void:
	print("chart-domain-commit channel=%s edge=%s min=%.5f max=%.5f" % [channel, edge, domain_min, domain_max])


func _on_domain_cancelled(channel: String, edge: String) -> void:
	print("chart-domain-cancel channel=%s edge=%s" % [channel, edge])
