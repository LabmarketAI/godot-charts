@tool
class_name WidgetToggle3D
extends WidgetControl3D

## Emitted when the toggle value changes.
signal toggled(value: bool)

@export var label_text: String = "Toggle":
	set(value):
		label_text = value
		_queue_rebuild()

@export var value: bool = false:
	set(v):
		value = v
		_queue_rebuild()
		if not Engine.is_editor_hint():
			emit_signal("toggled", value)

var _bg_inst: MeshInstance3D
var _check_inst: MeshInstance3D
var _check_mat: StandardMaterial3D
var _label: Label3D


func _rebuild() -> void:
	super._rebuild()
	_ensure_visuals()
	_apply_toggle_visuals()


func _ensure_visuals() -> void:
	if not is_instance_valid(_bg_inst):
		_bg_inst = MeshInstance3D.new()
		_bg_inst.name = "_bg"
		add_child(_bg_inst)
	if not is_instance_valid(_check_inst):
		_check_mat = StandardMaterial3D.new()
		_check_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_check_inst = MeshInstance3D.new()
		_check_inst.name = "_check"
		_check_inst.material_override = _check_mat
		add_child(_check_inst)
	if not is_instance_valid(_label):
		_label = Label3D.new()
		_label.name = "_label"
		_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		add_child(_label)


func _apply_toggle_visuals() -> void:
	var box_h := widget_size.y
	var check_size := box_h * 0.7

	# Background box (left side)
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(box_h, box_h)
	_bg_inst.mesh = bg_quad
	_bg_inst.position = Vector3(-widget_size.x * 0.5 + box_h * 0.5, 0.0, 0.0)
	_bg_inst.material_override = _bg_mat

	# Check mark (inner box)
	var check_quad := QuadMesh.new()
	check_quad.size = Vector2(check_size, check_size)
	_check_inst.mesh = check_quad
	_check_inst.position = Vector3(-widget_size.x * 0.5 + box_h * 0.5, 0.0, 0.002)
	_check_inst.visible = value

	var t := theme_data
	_check_mat.albedo_color = t.bg_checked if t else Color(0.12, 0.45, 0.82)

	# Label
	_label.text = label_text
	_label.font_size = t.text_size if t else 18
	_label.modulate = _get_text_color()
	_label.position = Vector3(-widget_size.x * 0.5 + box_h + 0.02, 0.0, 0.002)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _apply_colors() -> void:
	super._apply_colors()
	if is_instance_valid(_label):
		_label.modulate = _get_text_color()
	if is_instance_valid(_check_mat) and theme_data:
		_check_mat.albedo_color = theme_data.bg_checked


func _on_clicked() -> void:
	value = not value
