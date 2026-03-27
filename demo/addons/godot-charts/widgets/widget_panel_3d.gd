@tool
class_name WidgetPanel3D
extends Node3D


@export var panel_size: Vector2 = Vector2(1.2, 0.8):
	set(value):
		panel_size = Vector2(max(0.1, value.x), max(0.1, value.y))
		_queue_layout()
@export var auto_layout: bool = true:
	set(value):
		auto_layout = value
		_queue_layout()

var _layout_queued: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
	_queue_layout()


func _process(_delta: float) -> void:
	if _layout_queued:
		_layout_queued = false
		if auto_layout:
			request_layout()


func request_layout() -> void:
	for child in get_children():
		if child.has_method("request_layout"):
			child.request_layout(panel_size)


func _queue_layout() -> void:
	_layout_queued = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_queue_layout()
