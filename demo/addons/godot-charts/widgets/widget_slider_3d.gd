@tool
class_name WidgetSlider3D
extends WidgetControl3D

## Emitted when the slider value changes.
signal value_changed(v: float)

@export var min_value: float = 0.0:
	set(v):
		min_value = v
		value = clampf(value, min_value, max_value)
		_queue_rebuild()

@export var max_value: float = 1.0:
	set(v):
		max_value = v
		value = clampf(value, min_value, max_value)
		_queue_rebuild()

@export var value: float = 0.5:
	set(v):
		var clamped := clampf(v, min_value, max_value)
		if is_equal_approx(value, clamped):
			return
		value = clamped
		_queue_rebuild()
		if not Engine.is_editor_hint():
			emit_signal("value_changed", value)

@export var step: float = 0.0  # 0 = continuous

var _track_inst: MeshInstance3D
var _track_mat: StandardMaterial3D
var _fill_inst: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _thumb_inst: MeshInstance3D
var _thumb_mat: StandardMaterial3D

var _dragging: bool = false
var _drag_start_x: float = 0.0
var _drag_start_val: float = 0.0


func _rebuild() -> void:
	super._rebuild()
	_ensure_visuals()
	_apply_slider_visuals()


func _ensure_visuals() -> void:
	if not is_instance_valid(_track_inst):
		_track_mat = StandardMaterial3D.new()
		_track_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_track_inst = MeshInstance3D.new()
		_track_inst.name = "_track"
		_track_inst.material_override = _track_mat
		add_child(_track_inst)

	if not is_instance_valid(_fill_inst):
		_fill_mat = StandardMaterial3D.new()
		_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fill_inst = MeshInstance3D.new()
		_fill_inst.name = "_fill"
		_fill_inst.material_override = _fill_mat
		add_child(_fill_inst)

	if not is_instance_valid(_thumb_inst):
		_thumb_mat = StandardMaterial3D.new()
		_thumb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_thumb_inst = MeshInstance3D.new()
		_thumb_inst.name = "_thumb"
		_thumb_inst.material_override = _thumb_mat
		add_child(_thumb_inst)


func _apply_slider_visuals() -> void:
	var t := theme_data
	var track_h := widget_size.y * 0.25
	var thumb_h := widget_size.y * 0.9
	var thumb_w := widget_size.y * 0.4

	var ratio := _normalized_value()
	var track_left := -widget_size.x * 0.5
	var track_w := widget_size.x

	# Track
	var track_q := QuadMesh.new()
	track_q.size = Vector2(track_w, track_h)
	_track_inst.mesh = track_q
	_track_inst.position = Vector3(0.0, 0.0, 0.001)
	_track_mat.albedo_color = t.slider_track if t else Color(0.25, 0.25, 0.28)

	# Fill (left of thumb)
	var fill_w := track_w * ratio
	if fill_w > 0.0:
		var fill_q := QuadMesh.new()
		fill_q.size = Vector2(fill_w, track_h)
		_fill_inst.mesh = fill_q
		_fill_inst.position = Vector3(track_left + fill_w * 0.5, 0.0, 0.0015)
		_fill_inst.visible = true
	else:
		_fill_inst.visible = false
	_fill_mat.albedo_color = t.slider_thumb if t else Color(0.12, 0.45, 0.82)

	# Thumb
	var thumb_q := QuadMesh.new()
	thumb_q.size = Vector2(thumb_w, thumb_h)
	_thumb_inst.mesh = thumb_q
	_thumb_inst.position = Vector3(track_left + track_w * ratio, 0.0, 0.003)
	_thumb_mat.albedo_color = t.slider_thumb if t else Color(0.12, 0.45, 0.82)


func _normalized_value() -> float:
	if is_equal_approx(max_value, min_value):
		return 0.0
	return (value - min_value) / (max_value - min_value)


func _on_input_event(camera: Node, event: InputEvent, pos: Vector3, normal: Vector3, idx: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_start_x = pos.x
				_drag_start_val = value
				_update_state(State.PRESSED)
			else:
				_dragging = false
				_update_state(State.HOVER)
	elif event is InputEventMouseMotion and _dragging:
		var dx := pos.x - _drag_start_x
		var range_val := max_value - min_value
		var new_val := _drag_start_val + dx / widget_size.x * range_val
		if step > 0.0:
			new_val = roundf(new_val / step) * step
		value = clampf(new_val, min_value, max_value)
