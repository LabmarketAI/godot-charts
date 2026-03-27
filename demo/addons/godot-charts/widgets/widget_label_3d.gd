@tool
class_name WidgetLabel3D
extends Node3D

@export var text: String = "Label":
	set(value):
		text = value
		_update_label()

@export var font_size: int = 18:
	set(value):
		font_size = max(6, value)
		_update_label()

@export var color: Color = Color(0.95, 0.95, 0.95, 1.0):
	set(value):
		color = value
		_update_label()

@export var widget_size: Vector2 = Vector2(0.36, 0.06):
	set(value):
		widget_size = Vector2(max(0.01, value.x), max(0.01, value.y))

var _label: Label3D


func _ready() -> void:
	_ensure_label()
	_update_label()


func _ensure_label() -> void:
	if not is_instance_valid(_label):
		_label = Label3D.new()
		_label.name = "_label"
		_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_label.no_depth_test = false
		_label.position = Vector3.ZERO
		add_child(_label)


func _update_label() -> void:
	_ensure_label()
	_label.text = text
	_label.font_size = font_size
	_label.modulate = color


func get_widget_size() -> Vector2:
	return widget_size
