@tool
class_name WidgetListItem3D
extends WidgetControl3D

## Emitted when this item is selected.
signal selected(item: WidgetListItem3D)

@export var item_text: String = "Item":
	set(value):
		item_text = value
		_queue_rebuild()

@export var selected_item: bool = false:
	set(v):
		selected_item = v
		_queue_rebuild()

var _bg_inst: MeshInstance3D
var _label: Label3D


func _rebuild() -> void:
	super._rebuild()
	_ensure_visuals()
	_apply_item_visuals()


func _ensure_visuals() -> void:
	if not is_instance_valid(_bg_inst):
		_bg_inst = MeshInstance3D.new()
		_bg_inst.name = "_bg"
		add_child(_bg_inst)
	if not is_instance_valid(_label):
		_label = Label3D.new()
		_label.name = "_label"
		_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_label.position = Vector3(0.0, 0.0, 0.003)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(_label)


func _apply_item_visuals() -> void:
	var quad := QuadMesh.new()
	quad.size = widget_size
	_bg_inst.mesh = quad
	_bg_inst.material_override = _bg_mat

	if selected_item:
		_bg_mat.albedo_color = _get_accent_color()
	else:
		_bg_mat.albedo_color = _get_bg_color()

	var t := theme_data
	_label.text = item_text
	_label.font_size = t.text_size if t else 18
	_label.modulate = _get_text_color()
	_label.position = Vector3(-widget_size.x * 0.5 + 0.02, 0.0, 0.003)


func _get_accent_color() -> Color:
	var t := theme_data
	return t.accent if t else Color(0.12, 0.45, 0.82)


func _apply_colors() -> void:
	if is_instance_valid(_bg_inst) and is_instance_valid(_bg_mat):
		_bg_mat.albedo_color = _get_accent_color() if selected_item else _get_bg_color()
	if is_instance_valid(_label):
		_label.modulate = _get_text_color()


func _on_clicked() -> void:
	selected_item = true
	emit_signal("selected", self)
