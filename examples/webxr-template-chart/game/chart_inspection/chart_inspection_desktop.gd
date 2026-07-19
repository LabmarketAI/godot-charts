extends Node3D

const MOVE_SPEED := 2.8
const SPRINT_MULTIPLIER := 2.2
const MOUSE_SENSITIVITY := 0.0025
const LOOK_PITCH_LIMIT := 1.35
const SCRUBBER_POINTER_LAYER := 1 << 20
const RAY_LENGTH := 100.0

var _camera_rig: Node3D
var _camera: Camera3D
var _yaw := 0.0
var _pitch := -0.12
var _mouse_captured := false
var _scrubber_root: Node
var _active_scrubber_target: ChartDomainPointerTarget
var _active_scrubber_pointer: Node
var _active_scrubber_axis := Vector3.ZERO
var _active_scrubber_axis_origin := Vector3.ZERO


func _ready() -> void:
	_camera_rig = get_node("DesktopCameraRig") as Node3D
	_camera = get_node("DesktopCameraRig/DesktopCamera") as Camera3D
	_scrubber_root = get_node_or_null("ChartInspectionRoot/InspectionLayout/InspectionChartFrame/ChromeRoot/ChartAxisDomainScrubbers")
	_active_scrubber_pointer = self
	_apply_camera_rotation()


func _process(delta: float) -> void:
	_update_desktop_controls(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click and _try_reset_scrubber_axis(event.position):
				get_viewport().set_input_as_handled()
				return
			if _try_begin_scrubber_drag(event.position):
				get_viewport().set_input_as_handled()
				return
			_set_mouse_captured(true)
		else:
			if _end_scrubber_drag():
				get_viewport().set_input_as_handled()
				return
	elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if _try_zoom_scrubber_axis(event.position, 0.86 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.16):
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_cancel_scrubber_drag()
		_set_mouse_captured(false)
	elif event is InputEventMouseMotion and _active_scrubber_target != null:
		_update_scrubber_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_captured:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -LOOK_PITCH_LIMIT, LOOK_PITCH_LIMIT)
		_apply_camera_rotation()


func _update_desktop_controls(delta: float) -> void:
	if _camera_rig == null:
		return
	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction -= _camera_rig.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += _camera_rig.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= _camera_rig.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += _camera_rig.basis.x
	if Input.is_key_pressed(KEY_E):
		direction += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		direction -= Vector3.UP
	if direction.length_squared() == 0.0:
		return
	var speed := MOVE_SPEED * (SPRINT_MULTIPLIER if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	_camera_rig.position += direction.normalized() * speed * delta


func _apply_camera_rotation() -> void:
	if _camera_rig == null or _camera == null:
		return
	_camera_rig.basis = Basis(Vector3.UP, _yaw)
	_camera.basis = Basis(Vector3.RIGHT, _pitch)


func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured = captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _try_begin_scrubber_drag(screen_position: Vector2) -> bool:
	if _camera == null or _scrubber_root == null:
		return false
	var hit := _raycast_scrubber(screen_position)
	var target := _target_from_hit(hit.get("collider")) if not hit.is_empty() else null
	if target == null:
		return false
	_active_scrubber_target = target
	_active_scrubber_axis = (target.global_transform.basis * (target.get_meta("axis_vector") as Vector3)).normalized()
	_active_scrubber_axis_origin = target.global_position
	var start_position := _point_on_active_axis(screen_position, hit["position"])
	if not bool(_scrubber_root.call("desktop_begin_drag", target, start_position, _active_scrubber_pointer)):
		_clear_scrubber_drag()
		return false
	_set_mouse_captured(false)
	return true


func _update_scrubber_drag(screen_position: Vector2) -> void:
	if _active_scrubber_target == null or _scrubber_root == null:
		return
	_scrubber_root.call("desktop_update_drag", _active_scrubber_pointer, _point_on_active_axis(screen_position, _active_scrubber_axis_origin))


func _end_scrubber_drag() -> bool:
	if _active_scrubber_target == null or _scrubber_root == null:
		return false
	var ended := bool(_scrubber_root.call("desktop_end_drag", _active_scrubber_pointer))
	_clear_scrubber_drag()
	return ended


func _cancel_scrubber_drag() -> bool:
	if _active_scrubber_target == null or _scrubber_root == null:
		return false
	var cancelled := bool(_scrubber_root.call("desktop_cancel_drag", _active_scrubber_pointer))
	_clear_scrubber_drag()
	return cancelled


func _clear_scrubber_drag() -> void:
	_active_scrubber_target = null
	_active_scrubber_axis = Vector3.ZERO
	_active_scrubber_axis_origin = Vector3.ZERO


func _try_reset_scrubber_axis(screen_position: Vector2) -> bool:
	if _scrubber_root == null:
		return false
	var hit := _raycast_scrubber(screen_position)
	var target := _target_from_hit(hit.get("collider")) if not hit.is_empty() else null
	if target == null:
		return false
	return bool(_scrubber_root.call("desktop_reset_axis", target))


func _try_zoom_scrubber_axis(screen_position: Vector2, factor: float) -> bool:
	if _scrubber_root == null:
		return false
	var hit := _raycast_scrubber(screen_position)
	var target := _target_from_hit(hit.get("collider")) if not hit.is_empty() else null
	if target == null:
		return false
	return bool(_scrubber_root.call("desktop_zoom_axis", target, factor, _focus_unit_for_target(target, hit["position"])))


func _raycast_scrubber(screen_position: Vector2) -> Dictionary:
	var origin := _camera.project_ray_origin(screen_position)
	var endpoint := origin + _camera.project_ray_normal(screen_position) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint, SCRUBBER_POINTER_LAYER)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)


func _target_from_hit(collider: Object) -> ChartDomainPointerTarget:
	var node := collider as Node
	while node != null:
		if node is ChartDomainPointerTarget:
			return node as ChartDomainPointerTarget
		node = node.get_parent()
	return null


func _focus_unit_for_target(target: ChartDomainPointerTarget, hit_position: Vector3) -> float:
	var scrubber := target.get_parent() as Node3D
	if scrubber == null:
		return 0.5
	var axis := (target.get_meta("axis_vector") as Vector3).normalized()
	var axis_length := maxf(float(target.get_meta("axis_length")), 0.001)
	var local_hit := scrubber.global_transform.affine_inverse() * hit_position
	return clampf(local_hit.dot(axis) / axis_length + 0.5, 0.0, 1.0)


func _point_on_active_axis(screen_position: Vector2, fallback: Vector3) -> Vector3:
	if _camera == null or _active_scrubber_axis == Vector3.ZERO:
		return fallback
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position).normalized()
	var axis := _active_scrubber_axis.normalized()
	var between := _active_scrubber_axis_origin - ray_origin
	var axis_dot_ray := axis.dot(ray_direction)
	var denominator := 1.0 - axis_dot_ray * axis_dot_ray
	if absf(denominator) < 0.0001:
		return fallback
	var axis_distance := (between.dot(axis) - between.dot(ray_direction) * axis_dot_ray) / denominator
	return _active_scrubber_axis_origin + axis * axis_distance
