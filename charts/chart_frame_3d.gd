@tool
class_name ChartFrame3D
extends Node3D

## A movable, resizable 3D panel that hosts [Chart3D] children.
##
## The frame renders as a thin [BoxMesh] panel (depth = [member frame_depth],
## default 0.1) so it appears as a solid object rather than a flat image.
## Any [Chart3D] added as a direct child is automatically fitted to the frame's
## inner area and repositioned behind the panel front-face.
##
## [b]Basic usage[/b]
## [codeblock]
## var frame := ChartFrame3D.new()
## frame.size = Vector2(6.0, 4.0)
## var chart := BarChart3D.new()
## frame.add_child(chart)
## add_child(frame)
## [/codeblock]
##
## At runtime, call [method resize] or set [member size] directly to resize.
## The [signal resized] signal fires after every size change.

## Emitted after [member size] is changed.
signal resized(new_size: Vector2)

# ---------------------------------------------------------------------------
# Exported properties
# ---------------------------------------------------------------------------

## Width and height of the frame in Godot units.
@export var size: Vector2 = Vector2(4.0, 3.0) :
	set(v):
		size = Vector2(maxf(v.x, 0.1), maxf(v.y, 0.1))
		_rebuild()
		resized.emit(size)

## Thickness of the background panel along the local -Z axis (default 0.1).
@export_range(0.01, 1.0, 0.005) var frame_depth: float = 0.1 :
	set(v):
		frame_depth = v
		_rebuild()

## Background panel colour.
@export var background_color: Color = Color(0.10, 0.10, 0.12, 1.0) :
	set(v):
		background_color = v
		_rebuild()

## Border outline colour.
@export var border_color: Color = Color(0.45, 0.45, 0.50, 1.0) :
	set(v):
		border_color = v
		_rebuild()

## Show the background panel mesh.
@export var show_background: bool = true :
	set(v):
		show_background = v
		_rebuild()

## Show a border outline around the front face.
@export var show_border: bool = true :
	set(v):
		show_border = v
		_rebuild()

## Padding between the frame edge and the inner chart area (Godot units).
@export_range(0.0, 1.0, 0.01) var padding: float = 0.15 :
	set(v):
		padding = v
		_fit_child_charts()

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## Holds all frame geometry (background panel + border lines).
## Kept separate from user-added Chart3D children.
var _internal: Node3D = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Reuse an existing internal node when _ready() fires more than once
	# (e.g. node removed/re-added, or @tool script reload in editor).
	_internal = get_node_or_null("_FrameInternal") as Node3D
	if not is_instance_valid(_internal):
		_internal = Node3D.new()
		_internal.name = "_FrameInternal"
		add_child(_internal)
	_rebuild()


func _notification(what: int) -> void:
	# Refit charts whenever children are added/removed (e.g. the user drops a
	# Chart3D onto the frame node in the editor).
	if what == NOTIFICATION_CHILD_ORDER_CHANGED and is_instance_valid(_internal):
		_fit_child_charts()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Programmatically resize the frame.  Equivalent to setting [member size].
func resize(new_size: Vector2) -> void:
	size = new_size  # setter triggers _rebuild() and emits resized


## Returns the usable inner area after subtracting padding from both sides.
func get_inner_size() -> Vector2:
	return Vector2(
		maxf(size.x - padding * 2.0, 0.01),
		maxf(size.y - padding * 2.0, 0.01)
	)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	if not is_instance_valid(_internal):
		return
	for child in _internal.get_children():
		child.free()
	_build_panel()
	_fit_child_charts()


func _build_panel() -> void:
	if show_background:
		var box := BoxMesh.new()
		box.size = Vector3(size.x, size.y, frame_depth)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = background_color

		var mi := MeshInstance3D.new()
		mi.name = "Background"
		mi.mesh = box
		mi.material_override = mat
		# Centre the box on (size/2) so the frame origin (0,0,0) is the
		# bottom-left corner; push it back so the front face sits at Z=0.
		mi.position = Vector3(size.x * 0.5, size.y * 0.5, -frame_depth * 0.5)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_internal.add_child(mi)

	if show_border:
		_build_border()


func _build_border() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = border_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	# Slight Z offset so the border sits in front of the background face.
	var z: float = 0.001
	var cx: float = size.x
	var cy: float = size.y
	# Four edges as eight vertices (line pairs).
	var verts: PackedVector3Array = [
		Vector3(0,  0,  z), Vector3(cx, 0,  z),
		Vector3(cx, 0,  z), Vector3(cx, cy, z),
		Vector3(cx, cy, z), Vector3(0,  cy, z),
		Vector3(0,  cy, z), Vector3(0,  0,  z),
	]
	for v in verts:
		mesh.surface_add_vertex(v)
	mesh.surface_end()

	var mi := MeshInstance3D.new()
	mi.name = "Border"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_internal.add_child(mi)


## Propagates chart_size to all direct Chart3D children and positions them
## so their bottom-left corner aligns with the padded inner area.
func _fit_child_charts() -> void:
	var inner := get_inner_size()
	for child in get_children():
		if child == _internal:
			continue
		if child is Chart3D:
			var chart := child as Chart3D
			chart.chart_size = inner
			# Place the chart origin at the inner bottom-left, slightly in
			# front of the background panel.
			chart.position = Vector3(padding, padding, 0.005)
