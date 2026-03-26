@tool
class_name WidgetStack3D
extends Node3D


@export var z_step: float = 0.001:
	set(value):
		z_step = value
		_queue_layout()
@export var default_child_size: Vector2 = Vector2(0.2, 0.08):
	set(value):
		default_child_size = Vector2(max(0.01, value.x), max(0.01, value.y))
		_queue_layout()

var _layout_queued: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
	_queue_layout()


func _process(_delta: float) -> void:
	if _layout_queued:
		_layout_queued = false
		request_layout()


func request_layout(available_size: Vector2 = Vector2.ZERO) -> void:
	if available_size == Vector2.ZERO:
		available_size = _measure_content_size()

	var children := _iter_widget_children()
	var center := Vector3(0.0, 0.0, 0.0)

	for i in range(children.size()):
		var child := children[i]
		child.position = Vector3(center.x, center.y, float(i) * z_step)
		if child.has_method("request_layout"):
			child.request_layout(available_size)


func _iter_widget_children() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child in get_children():
		if child is Node3D and not (child as Node3D).is_queued_for_deletion():
			out.append(child as Node3D)
	return out


func _measure_content_size() -> Vector2:
	var max_w: float = 0.0
	var max_h: float = 0.0
	for child in _iter_widget_children():
		var child_size := default_child_size
		if child.has_method("get_widget_size"):
			var size_from_method: Variant = child.call("get_widget_size")
			if size_from_method is Vector2:
				child_size = size_from_method as Vector2
		max_w = max(max_w, child_size.x)
		max_h = max(max_h, child_size.y)
	return Vector2(max_w, max_h)


func _queue_layout() -> void:
	_layout_queued = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_queue_layout()
