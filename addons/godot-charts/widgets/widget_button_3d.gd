@tool
class_name WidgetButton3D
extends WidgetControl3D

## Emitted when the button is clicked.
signal pressed

@export var text: String = "Button":
	set(value):
		text = value
		_queue_rebuild()

var _mesh_inst: MeshInstance3D
var _label: Label3D


func _rebuild() -> void:
	super._rebuild()
	_ensure_visuals()
	_apply_button_visuals()


func _ensure_visuals() -> void:
	if not is_instance_valid(_mesh_inst):
		_mesh_inst = MeshInstance3D.new()
		_mesh_inst.name = "_bg"
		add_child(_mesh_inst)
	if not is_instance_valid(_label):
		_label = Label3D.new()
		_label.name = "_label"
		_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_label.position = Vector3(0.0, 0.0, 0.003)
		add_child(_label)


func _apply_button_visuals() -> void:
	# Background quad
	var quad := QuadMesh.new()
	quad.size = widget_size
	_mesh_inst.mesh = quad
	_mesh_inst.material_override = _bg_mat

	# Label
	var t := theme_data
	_label.text = text
	_label.font_size = t.text_size if t else 18
	_label.modulate = _get_text_color()


func _apply_colors() -> void:
	super._apply_colors()
	if is_instance_valid(_label):
		_label.modulate = _get_text_color()


func _on_clicked() -> void:
	emit_signal("pressed")
