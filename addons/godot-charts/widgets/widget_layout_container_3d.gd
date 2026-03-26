@tool
class_name WidgetLayoutContainer3D
extends Node3D


@export var gap: float = 0.05:
	set(value):
		gap = max(0.0, value)
		_queue_layout()
@export var padding: Vector2 = Vector2(0.05, 0.05):
	set(value):
		padding = Vector2(max(0.0, value.x), max(0.0, value.y))
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
	# Base class is a no-op; derived classes place children.
	if available_size == Vector2.ZERO:
		available_size = _measure_content_size()
	for child in _iter_widget_children():
		if child is WidgetLayoutContainer3D:
			(child as WidgetLayoutContainer3D).request_layout(available_size)


func _iter_widget_children() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child in get_children():
		if child is Node3D and not (child as Node3D).is_queued_for_deletion():
			out.append(child as Node3D)
	return out


func _get_child_widget_size(child: Node3D) -> Vector2:
	if child.has_method("get_widget_size"):
		var size_from_method: Variant = child.call("get_widget_size")
		if size_from_method is Vector2:
			var method_size := size_from_method as Vector2
			return Vector2(max(0.01, method_size.x), max(0.01, method_size.y))
	if child.has_meta("widget_size"):
		var size_from_meta: Variant = child.get_meta("widget_size")
		if size_from_meta is Vector2:
			var meta_size := size_from_meta as Vector2
			return Vector2(max(0.01, meta_size.x), max(0.01, meta_size.y))
	return default_child_size


func _measure_content_size() -> Vector2:
	var max_w: float = 0.0
	var max_h: float = 0.0
	for child in _iter_widget_children():
		var child_size := _get_child_widget_size(child)
		max_w = max(max_w, child_size.x)
		max_h = max(max_h, child_size.y)
	return Vector2(max_w + padding.x * 2.0, max_h + padding.y * 2.0)


func _queue_layout() -> void:
	_layout_queued = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_queue_layout()
