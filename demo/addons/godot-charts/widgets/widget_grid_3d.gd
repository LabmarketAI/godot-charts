@tool
class_name WidgetGrid3D
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


@export_range(1, 64, 1) var columns: int = 2:
	set(value):
		columns = max(1, value)
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
	if children.is_empty():
		return

	var cell_width: float = max(0.01, (available_size.x - padding.x * 2.0 - gap * float(columns - 1)) / float(columns))
	var max_child_height: float = default_child_size.y
	for child in children:
		max_child_height = max(max_child_height, _get_child_widget_size(child).y)
	var cell_height: float = max(0.01, max_child_height)

	var left_x: float = -available_size.x * 0.5 + padding.x
	var top_y: float = available_size.y * 0.5 - padding.y

	for i in range(children.size()):
		var child := children[i]
		var col: int = i % columns
		var row: int = i / columns
		var x: float = left_x + float(col) * (cell_width + gap) + cell_width * 0.5
		var y: float = top_y - float(row) * (cell_height + gap) - cell_height * 0.5
		child.position = Vector3(x, y, 0.0)
		if child.has_method("request_layout"):
			child.request_layout(Vector2(cell_width, cell_height))


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
	var children := _iter_widget_children()
	if children.is_empty():
		return Vector2(padding.x * 2.0, padding.y * 2.0)

	var max_h: float = 0.0
	for child in children:
		max_h = max(max_h, _get_child_widget_size(child).y)

	var rows: int = int(ceil(float(children.size()) / float(columns)))
	var width := float(columns) * default_child_size.x + float(columns - 1) * gap + padding.x * 2.0
	var height := float(rows) * max_h + float(max(0, rows - 1)) * gap + padding.y * 2.0
	return Vector2(width, height)


func _queue_layout() -> void:
	_layout_queued = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_queue_layout()
