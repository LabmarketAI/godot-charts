extends Node3D

const HANDLE_LAYER := 1 << 18
const HELD_LAYER := 1 << 16
const POINTABLE_LAYER := 1 << 20
const MOVE_COLOR := Color(0.1, 0.85, 1.0, 1.0)
const ROTATE_COLOR := Color(1.0, 0.64, 0.16, 1.0)


class PointableHandle:
	extends StaticBody3D

	var controller: Node

	func pointer_event(event: Object) -> void:
		if controller != null and controller.has_method("_on_pointable_event"):
			controller._on_pointable_event(self, event)


var _frame: AnalyticalFrame3D
var _move_handle: XRToolsInteractableHandle
var _rotate_handle: XRToolsInteractableHandle
var _active_grabs: Dictionary = {}
var _active_pointers: Dictionary = {}


func setup(frame: AnalyticalFrame3D) -> void:
	_frame = frame
	name = "ChartXRHandles"
	_frame.handle_root().add_child(self)
	_frame.apply_interaction_state("frame", true)
	_rebuild()


func _process(_delta: float) -> void:
	if _frame == null:
		return
	_update_move()
	_update_rotate()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_active_grabs.clear()
	_active_pointers.clear()

	var bounds: Vector3 = _frame.active_state.bounds if _frame.active_state != null else Vector3(3.2, 2.0, 1.6)
	_move_handle = _create_handle(
		"MoveHandle",
		Vector3(-bounds.x * 0.24, -bounds.y * 0.34, bounds.z * 0.5 + 0.2),
		0.13,
		MOVE_COLOR
	)
	_rotate_handle = _create_handle(
		"RotateHandle",
		Vector3(bounds.x * 0.24, -bounds.y * 0.34, bounds.z * 0.5 + 0.2),
		0.13,
		ROTATE_COLOR
	)


func _create_handle(handle_name: String, local_position: Vector3, radius: float, color: Color) -> XRToolsInteractableHandle:
	var origin := Node3D.new()
	origin.name = handle_name + "Origin"
	origin.position = local_position
	add_child(origin)

	var handle := XRToolsInteractableHandle.new()
	handle.name = handle_name
	handle.collision_layer = HANDLE_LAYER
	handle.collision_mask = 0
	handle.gravity_scale = 0.0
	handle.freeze = true
	handle.picked_up_layer = HELD_LAYER
	handle.snap_distance = 1.5
	origin.add_child(handle)

	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	shape.shape = sphere_shape
	handle.add_child(shape)

	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	sphere_mesh.material = material
	mesh.mesh = sphere_mesh
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	handle.add_child(mesh)

	_add_grab_point(handle, "GrabPointLeft", XRToolsGrabPointHand.Hand.LEFT)
	_add_grab_point(handle, "GrabPointRight", XRToolsGrabPointHand.Hand.RIGHT)
	handle.picked_up.connect(_on_handle_picked_up.bind(handle))
	handle.dropped.connect(_on_handle_dropped.bind(handle))
	_add_pointable_target(origin, handle, radius * 1.8)
	return handle


func _add_pointable_target(parent: Node3D, handle: XRToolsInteractableHandle, radius: float) -> void:
	var target := PointableHandle.new()
	target.name = handle.name + "PointerTarget"
	target.controller = self
	target.collision_layer = POINTABLE_LAYER
	target.collision_mask = 0
	target.set_meta("chart_handle", handle)
	parent.add_child(target)

	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	shape.shape = sphere_shape
	target.add_child(shape)


func _add_grab_point(parent: Node, point_name: String, hand: XRToolsGrabPointHand.Hand) -> void:
	var point := XRToolsGrabPointHand.new()
	point.name = point_name
	point.hand = hand
	point.snap_hand = false
	parent.add_child(point)


func _on_handle_picked_up(_pickable: XRToolsPickable, handle: XRToolsInteractableHandle) -> void:
	_active_grabs[handle] = {
		"frame_transform": _frame.global_transform,
		"frame_origin": _frame.global_position,
		"handle_position": handle.global_position,
		"handle_offset": handle.global_position - _frame.global_position,
	}
	_frame.apply_interaction_state("frame", true, {"active": true})
	set_process(true)


func _on_handle_dropped(_pickable: XRToolsPickable, handle: XRToolsInteractableHandle) -> void:
	_active_grabs.erase(handle)
	_frame.apply_interaction_state("frame", true, {"active": not _active_grabs.is_empty()})
	set_process(not _active_grabs.is_empty())


func _update_move() -> void:
	if not _active_grabs.has(_move_handle):
		return
	var grab: Dictionary = _active_grabs[_move_handle]
	var next_transform: Transform3D = grab["frame_transform"]
	next_transform.origin = grab["frame_origin"] + (_move_handle.global_position - grab["handle_position"])
	_frame.global_transform = next_transform


func _update_rotate() -> void:
	if not _active_grabs.has(_rotate_handle):
		return
	var grab: Dictionary = _active_grabs[_rotate_handle]
	var start_offset: Vector3 = grab["handle_offset"]
	var next_offset := _rotate_handle.global_position - _frame.global_position
	start_offset.y = 0.0
	next_offset.y = 0.0
	if start_offset.length() < 0.01 or next_offset.length() < 0.01:
		return
	var angle := start_offset.normalized().signed_angle_to(next_offset.normalized(), Vector3.UP)
	var start_transform: Transform3D = grab["frame_transform"]
	_frame.global_transform = Transform3D(Basis(Vector3.UP, angle) * start_transform.basis, start_transform.origin)


func _on_pointable_event(target: PointableHandle, event: Object) -> void:
	if _frame == null or event == null:
		return
	var pointer: Node = event.pointer
	var handle: XRToolsInteractableHandle = target.get_meta("chart_handle") as XRToolsInteractableHandle
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
	_active_pointers[pointer] = {
		"handle": handle,
		"frame_transform": _frame.global_transform,
		"frame_origin": _frame.global_position,
		"start_position": hit_position,
	}
	_frame.apply_interaction_state("frame", true, {"active": true})
	set_process(true)


func _update_pointer_drag(pointer: Node, hit_position: Vector3) -> void:
	if not _active_pointers.has(pointer):
		return
	var drag: Dictionary = _active_pointers[pointer]
	var handle: XRToolsInteractableHandle = drag["handle"]
	if handle == _move_handle:
		var next_transform: Transform3D = drag["frame_transform"]
		next_transform.origin = drag["frame_origin"] + (hit_position - drag["start_position"])
		_frame.global_transform = next_transform
	elif handle == _rotate_handle:
		var start_origin: Vector3 = drag["frame_origin"]
		var start_offset: Vector3 = drag["start_position"] - start_origin
		var next_offset := hit_position - start_origin
		start_offset.y = 0.0
		next_offset.y = 0.0
		if start_offset.length() < 0.01 or next_offset.length() < 0.01:
			return
		var angle := start_offset.normalized().signed_angle_to(next_offset.normalized(), Vector3.UP)
		var start_transform: Transform3D = drag["frame_transform"]
		_frame.global_transform = Transform3D(Basis(Vector3.UP, angle) * start_transform.basis, start_transform.origin)


func _end_pointer_drag(pointer: Node) -> void:
	_active_pointers.erase(pointer)
	_frame.apply_interaction_state("frame", true, {"active": not _active_grabs.is_empty() or not _active_pointers.is_empty()})
	set_process(not _active_grabs.is_empty())
