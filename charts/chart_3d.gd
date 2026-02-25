@tool
class_name Chart3D
extends Node3D

## Base class for all 3D charts in the Godot Charts addon.
##
## Provides shared properties (title, axis labels, color palette) and helper
## methods used by every concrete chart type.  Sub-classes override [method _rebuild]
## to draw their specific geometry inside [member _container].

## Emitted after the chart geometry has been rebuilt.
signal data_changed

# ---------------------------------------------------------------------------
# Exported properties – changes automatically redraw the chart in the editor.
# ---------------------------------------------------------------------------

## Title shown above the chart (billboard Label3D).
@export var title: String = "" :
	set(v):
		title = v
		_queue_rebuild()

## Label for the horizontal (X) axis.
@export var x_label: String = "X" :
	set(v):
		x_label = v
		_queue_rebuild()

## Label for the vertical (Y) axis.
@export var y_label: String = "Y" :
	set(v):
		y_label = v
		_queue_rebuild()

## Label for the depth (Z) axis.
@export var z_label: String = "Z" :
	set(v):
		z_label = v
		_queue_rebuild()

## Target bounding box of the chart geometry (width × height in Godot units).
## ChartFrame3D sets this automatically when charts are added as children.
## All chart types normalise their geometry to fill this area.
@export var chart_size: Vector2 = Vector2(4.0, 3.0) :
	set(v):
		chart_size = Vector2(maxf(v.x, 0.01), maxf(v.y, 0.01))
		_queue_rebuild()

## Color palette cycled across datasets / series.
@export var colors: Array[Color] = [
	Color(0.204, 0.596, 1.000),  # blue
	Color(1.000, 0.408, 0.216),  # orange
	Color(0.216, 0.784, 0.408),  # green
	Color(0.988, 0.729, 0.012),  # yellow
	Color(0.608, 0.243, 0.906),  # purple
	Color(0.976, 0.341, 0.573),  # pink
] :
	set(v):
		colors = v
		_queue_rebuild()

## Draw X / Y / Z axis lines.
@export var show_axes: bool = true :
	set(v):
		show_axes = v
		_queue_rebuild()

## Draw axis name labels.
@export var show_labels: bool = true :
	set(v):
		show_labels = v
		_queue_rebuild()

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## Root node that holds all generated geometry.  Cleared on every rebuild.
var _container: Node3D = null
var _rebuild_queued: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_container = Node3D.new()
	_container.name = "ChartContent"
	add_child(_container)
	_rebuild()


func _process(_delta: float) -> void:
	if _rebuild_queued:
		_rebuild_queued = false
		_rebuild()

# ---------------------------------------------------------------------------
# Overridable API
# ---------------------------------------------------------------------------

## Queue a deferred rebuild so rapid property changes only trigger one redraw.
func _queue_rebuild() -> void:
	_rebuild_queued = true


## Override in sub-classes to emit geometry into [member _container].
func _rebuild() -> void:
	pass

# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

## Remove all children from the chart container.
func clear() -> void:
	if is_instance_valid(_container):
		for child in _container.get_children():
			child.queue_free()

# ---------------------------------------------------------------------------
# Protected helpers available to sub-classes
# ---------------------------------------------------------------------------

## Returns the color for the given zero-based dataset index (wraps around).
func _get_color(index: int) -> Color:
	if colors.is_empty():
		return Color.WHITE
	return colors[index % colors.size()]


## Creates a simple lit [StandardMaterial3D] with the given albedo color.
func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat


## Creates an unshaded [StandardMaterial3D] – good for axis lines and wireframes.
func _create_unshaded_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


## Creates a billboard [Label3D] at *pos* with the given *text*.
func _make_label(text: String, pos: Vector3, font_size: int = 56) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = pos
	lbl.font_size = font_size
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.modulate = Color(0.9, 0.9, 0.9)
	return lbl


## Draws a single line segment using [ImmediateMesh].
## The returned [MeshInstance3D] is owned by the caller (add it to _container).
func _make_line(p0: Vector3, p1: Vector3, color: Color) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _create_unshaded_material(color))
	mesh.surface_add_vertex(p0)
	mesh.surface_add_vertex(p1)
	mesh.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Draws the three axis lines spanning *extent* units from the origin, with
## optional end-labels for each axis, and a chart title.
func _draw_axes(extent_x: float, extent_y: float, extent_z: float) -> void:
	if not show_axes:
		return
	var origin := Vector3.ZERO
	_container.add_child(_make_line(origin, Vector3(extent_x, 0, 0), Color(0.8, 0.2, 0.2)))
	_container.add_child(_make_line(origin, Vector3(0, extent_y, 0), Color(0.2, 0.8, 0.2)))
	_container.add_child(_make_line(origin, Vector3(0, 0, extent_z), Color(0.2, 0.5, 0.9)))

	if not show_labels:
		return
	_container.add_child(_make_label(x_label, Vector3(extent_x + 0.15, 0, 0)))
	_container.add_child(_make_label(y_label, Vector3(0, extent_y + 0.15, 0)))
	_container.add_child(_make_label(z_label, Vector3(0, 0, extent_z + 0.15)))
	if title != "":
		_container.add_child(_make_label(title, Vector3(extent_x * 0.5, extent_y + 0.35, 0), 72))
