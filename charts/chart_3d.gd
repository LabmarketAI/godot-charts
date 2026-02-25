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

## Draw horizontal gridlines at each tick interval.
@export var show_grid: bool = false :
	set(v):
		show_grid = v
		_queue_rebuild()

## Draw tick marks along the Y axis.
@export var show_ticks: bool = true :
	set(v):
		show_ticks = v
		_queue_rebuild()

## Number of tick / grid intervals on the Y axis.
@export_range(2, 20, 1) var tick_count: int = 5 :
	set(v):
		tick_count = v
		_queue_rebuild()

## Draw a legend listing each dataset name with a colored swatch.
@export var show_legend: bool = true :
	set(v):
		show_legend = v
		_queue_rebuild()

@export_group("Materials")

## Override material for axis lines. null = default per-axis color.
## Assign any Material (including ShaderMaterial) to apply custom shaders.
@export var axis_material: Material = null :
	set(v):
		axis_material = v
		_queue_rebuild()

## Override material for gridlines. null = default grey.
@export var grid_material: Material = null :
	set(v):
		grid_material = v
		_queue_rebuild()

## Override material for tick marks. null = default grey.
@export var tick_material: Material = null :
	set(v):
		tick_material = v
		_queue_rebuild()

## Override material for all billboard labels. null = Label3D default.
@export var label_material: Material = null :
	set(v):
		label_material = v
		_queue_rebuild()

## Override material for legend swatches. null = auto-color per dataset.
@export var legend_material: Material = null :
	set(v):
		legend_material = v
		_queue_rebuild()

@export_group("")

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
	# Use an existing container when _ready() fires more than once
	# (e.g. node removed/re-added, or @tool script reload in editor).
	_container = get_node_or_null("ChartContent") as Node3D
	if not is_instance_valid(_container):
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

## Remove all children from the chart container immediately.
## Uses free() rather than queue_free() so geometry is gone before the next
## add_child() call in the same _rebuild() pass — prevents double-rendering.
func clear() -> void:
	if is_instance_valid(_container):
		for child in _container.get_children():
			child.free()

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
## If [member label_material] is set it is applied as the label's material override.
func _make_label(text: String, pos: Vector3, font_size: int = 56) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = pos
	lbl.font_size = font_size
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.modulate = Color(0.9, 0.9, 0.9)
	if label_material != null:
		lbl.material_override = label_material
	return lbl


## Draws a single line segment using [ImmediateMesh].
## Pass [param mat_override] to replace the default unshaded color material —
## any [Material] or [ShaderMaterial] is accepted.
## The returned [MeshInstance3D] is owned by the caller (add it to _container).
func _make_line(p0: Vector3, p1: Vector3, color: Color, mat_override: Material = null) -> MeshInstance3D:
	var mat: Material = mat_override if mat_override != null else _create_unshaded_material(color)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	mesh.surface_add_vertex(p0)
	mesh.surface_add_vertex(p1)
	mesh.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Draws the three axis lines spanning *extent* units from the origin, with
## optional end-labels for each axis, and a chart title.
## Set [member axis_material] to apply a custom shader to all axis lines.
func _draw_axes(extent_x: float, extent_y: float, extent_z: float) -> void:
	if not show_axes:
		return
	var origin := Vector3.ZERO
	_container.add_child(_make_line(origin, Vector3(extent_x, 0, 0), Color(0.8, 0.2, 0.2), axis_material))
	_container.add_child(_make_line(origin, Vector3(0, extent_y, 0), Color(0.2, 0.8, 0.2), axis_material))
	_container.add_child(_make_line(origin, Vector3(0, 0, extent_z), Color(0.2, 0.5, 0.9), axis_material))

	if not show_labels:
		return
	_container.add_child(_make_label(x_label, Vector3(extent_x + 0.15, 0, 0)))
	_container.add_child(_make_label(y_label, Vector3(0, extent_y + 0.15, 0)))
	_container.add_child(_make_label(z_label, Vector3(0, 0, extent_z + 0.15)))
	if title != "":
		_container.add_child(_make_label(title, Vector3(extent_x * 0.5, extent_y + 0.35, 0), 72))


## Draws horizontal gridlines at each Y tick interval across the XY plane.
## Lines sit at Z = -0.001 so they appear behind chart geometry at Z = 0.
## Set [member grid_material] to apply a custom shader.
func _draw_grid_xy(extent_x: float, extent_y: float) -> void:
	if not show_grid:
		return
	var mat: Material = grid_material if grid_material != null \
		else _create_unshaded_material(Color(0.3, 0.3, 0.3))
	for i in range(1, tick_count + 1):
		var y: float = extent_y * (float(i) / float(tick_count))
		_container.add_child(_make_line(
			Vector3(0.0, y, -0.001), Vector3(extent_x, y, -0.001),
			Color(0.3, 0.3, 0.3), mat))


## Draws tick marks along the Y axis and optional value labels.
## [param max_val] and [param min_val] define the data range mapped to *extent_y*.
## Set [member tick_material] to apply a custom shader.
func _draw_ticks_y(extent_y: float, max_val: float, min_val: float = 0.0) -> void:
	if not show_ticks:
		return
	var mat: Material = tick_material if tick_material != null \
		else _create_unshaded_material(Color(0.55, 0.55, 0.55))
	var tick_len: float = maxf(chart_size.x * 0.02, 0.05)
	for i in range(1, tick_count + 1):
		var t: float = float(i) / float(tick_count)
		var y: float = extent_y * t
		_container.add_child(_make_line(
			Vector3(-tick_len, y, 0.0), Vector3(0.0, y, 0.0),
			Color(0.55, 0.55, 0.55), mat))
		if show_labels:
			var val: float = min_val + (max_val - min_val) * t
			_container.add_child(_make_label("%.1f" % val, Vector3(-tick_len - 0.18, y, 0.0), 40))


## Draws a legend at the right edge of the chart: one colored swatch + name per dataset.
## [param dataset_names] and [param legend_colors] must be parallel arrays.
## Set [member legend_material] to override swatch materials (all swatches share it).
func _draw_legend(dataset_names: Array, legend_colors: Array, extent_x: float, extent_y: float) -> void:
	if not show_legend:
		return
	var swatch_w: float = 0.18
	var swatch_h: float = 0.11
	var row_gap: float = 0.26
	var start_x: float = extent_x + 0.25
	var start_y: float = extent_y * 0.9
	for i in dataset_names.size():
		var y: float = start_y - float(i) * row_gap
		var color: Color = legend_colors[i] if i < legend_colors.size() else Color.WHITE
		var swatch_mat: Material = legend_material if legend_material != null \
			else _create_material(color)
		var box := BoxMesh.new()
		box.size = Vector3(swatch_w, swatch_h, 0.05)
		var swatch_mi := MeshInstance3D.new()
		swatch_mi.mesh = box
		swatch_mi.material_override = swatch_mat
		swatch_mi.position = Vector3(start_x + swatch_w * 0.5, y, 0.0)
		_container.add_child(swatch_mi)
		var ds_name: String = dataset_names[i] if i < dataset_names.size() else ""
		_container.add_child(_make_label(ds_name, Vector3(start_x + swatch_w + 0.15, y, 0.0), 44))
