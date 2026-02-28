@tool
class_name SurfaceChart3D
extends Chart3D

## A 3D surface (height-map) chart.
##
## Renders a smooth mesh whose Y coordinate represents a scalar value over an
## X-Z grid.  Data can be supplied either as a 2-D array of floats or as a
## [Callable] that maps (x, z) → float, enabling procedural surfaces.
##
## [b]Grid array format[/b]
## [codeblock]
## chart.grid_data = [
##     [0.0, 0.5, 1.0],   # row z = 0
##     [0.5, 1.5, 0.8],   # row z = 1
##     [1.0, 0.8, 0.3],   # row z = 2
## ]
## [/codeblock]
##
## [b]Callable format[/b]
## [codeblock]
## chart.surface_function = func(x: float, z: float) -> float:
##     return sin(x) * cos(z)
## chart.grid_cols = 32
## chart.grid_rows = 32
## chart.x_range = Vector2(-PI, PI)
## chart.z_range = Vector2(-PI, PI)
## [/codeblock]

# ---------------------------------------------------------------------------
# Exported properties
# ---------------------------------------------------------------------------

## 2-D array of float rows.  Each inner array is one row along X; rows advance
## along Z.  Ignored when [member surface_function] is set.
@export var grid_data: Array = [] :
	set(v):
		grid_data = v
		_queue_rebuild()

## Optional callable [code]func(x: float, z: float) -> float[/code].
## When set, [member grid_data] is ignored.
@export var surface_function: Callable = Callable() :
	set(v):
		surface_function = v
		_queue_rebuild()

## Number of grid columns (X resolution) used in callable mode.
@export_range(2, 128, 1) var grid_cols: int = 20 :
	set(v):
		grid_cols = v
		_queue_rebuild()

## Number of grid rows (Z resolution) used in callable mode.
@export_range(2, 128, 1) var grid_rows: int = 20 :
	set(v):
		grid_rows = v
		_queue_rebuild()

## X range [min, max] used in callable mode.
@export var x_range: Vector2 = Vector2(0.0, 1.0) :
	set(v):
		x_range = v
		_queue_rebuild()

## Z range [min, max] used in callable mode.
@export var z_range: Vector2 = Vector2(0.0, 1.0) :
	set(v):
		z_range = v
		_queue_rebuild()

## Use a gradient to color the surface by height.  When false uses [member colors][0].
@export var use_height_gradient: bool = true :
	set(v):
		use_height_gradient = v
		_queue_rebuild()

## Low-height gradient color (used when [member use_height_gradient] is true).
@export var gradient_low: Color = Color(0.1, 0.3, 0.9) :
	set(v):
		gradient_low = v
		_queue_rebuild()

## High-height gradient color (used when [member use_height_gradient] is true).
@export var gradient_high: Color = Color(0.9, 0.2, 0.1) :
	set(v):
		gradient_high = v
		_queue_rebuild()

@export_group("Materials")

## Override material for the surface mesh.  null = built-in vertex-color material.
## Assign any [Material] (including [ShaderMaterial]) for custom shader effects.
## Note: custom materials must read COLOR or use vertex color to retain the height
## gradient; otherwise set [member use_height_gradient] to false.
@export var surface_material: Material = null :
	set(v):
		surface_material = v
		_queue_rebuild()

## Optional texture to overlay on the surface mesh.
## Applied as [code]albedo_texture[/code] to the material (requires [StandardMaterial3D] or compatible).
## Composes with [member use_height_gradient] — the texture is modulated by the height-based vertex colors.
@export var surface_texture: Texture2D = null :
	set(v):
		surface_texture = v
		_queue_rebuild()

@export_group("")

# ---------------------------------------------------------------------------
# Override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	clear()
	if not is_instance_valid(_container):
		return

	# Resolve the height grid.
	var heights: Array = _resolve_heights()
	if heights.is_empty():
		_draw_demo()
		return

	var rows: int = heights.size()
	var cols: int = (heights[0] as Array).size()
	if rows < 2 or cols < 2:
		return

	# Build vertices, normals, colors, and indices for an ArrayMesh.
	var verts := PackedVector3Array()
	var norms  := PackedVector3Array()
	var col_arr := PackedColorArray()
	var indices := PackedInt32Array()

	# Find height range for gradient mapping.
	var min_h: float = INF
	var max_h: float = -INF
	for row: Variant in heights:
		for h: Variant in row as Array:
			min_h = minf(min_h, float(h))
			max_h = maxf(max_h, float(h))
	if max_h == min_h:
		max_h = min_h + 1.0

	# Create one vertex per grid cell, normalised to chart_size.
	for zi in rows:
		for xi in cols:
			var x: float = float(xi) / float(cols - 1) * chart_size.x
			var z: float = float(zi) / float(rows - 1) * chart_size.x
			var h: float = float((heights[zi] as Array)[xi])
			var h_norm: float = (h - min_h) / (max_h - min_h) * chart_size.y
			verts.append(Vector3(x, h_norm, z))
			var t: float = (h - min_h) / (max_h - min_h)
			col_arr.append(gradient_low.lerp(gradient_high, t) if use_height_gradient else _get_color(0))
			norms.append(Vector3.UP)  # will be recalculated below

	# Compute smooth normals from adjacent vertices.
	for zi in rows:
		for xi in cols:
			var idx: int = zi * cols + xi
			var n := Vector3.ZERO
			var center: Vector3 = verts[idx]
			if xi + 1 < cols and zi + 1 < rows:
				n += (verts[idx + 1] - center).cross(verts[idx + cols] - center)
			if xi - 1 >= 0 and zi + 1 < rows:
				n += (verts[idx + cols] - center).cross(verts[idx - 1] - center)
			if xi - 1 >= 0 and zi - 1 >= 0:
				n += (verts[idx - 1] - center).cross(verts[idx - cols] - center)
			if xi + 1 < cols and zi - 1 >= 0:
				n += (verts[idx - cols] - center).cross(verts[idx + 1] - center)
			norms[idx] = n.normalized() if n.length_squared() > 0.0 else Vector3.UP

	# Build triangle indices (two triangles per quad).
	for zi in rows - 1:
		for xi in cols - 1:
			var tl: int = zi * cols + xi
			var tr: int = tl + 1
			var bl: int = tl + cols
			var br: int = bl + 1
			indices.append_array(PackedInt32Array([tl, bl, tr, tr, bl, br]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR]  = col_arr
	arrays[Mesh.ARRAY_INDEX]  = indices

	var amesh := ArrayMesh.new()
	amesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat: Material = surface_material
	if mat == null:
		var std_mat := StandardMaterial3D.new()
		std_mat.vertex_color_use_as_albedo = true
		if surface_texture != null:
			std_mat.albedo_texture = surface_texture
		mat = std_mat
	elif surface_texture != null and mat is StandardMaterial3D:
		# Apply texture to user-provided StandardMaterial3D
		(mat as StandardMaterial3D).albedo_texture = surface_texture
	amesh.surface_set_material(0, mat)

	var mi := MeshInstance3D.new()
	mi.mesh = amesh
	_container.add_child(mi)

	_draw_axes(chart_size.x * 1.05, chart_size.y * 1.1, chart_size.x * 1.05)
	emit_signal("data_changed")


func _resolve_heights() -> Array:
	if surface_function.is_valid():
		var heights: Array = []
		for zi in grid_rows:
			var row: Array = []
			var zv: float = z_range.x + (z_range.y - z_range.x) * float(zi) / float(grid_rows - 1)
			for xi in grid_cols:
				var xv: float = x_range.x + (x_range.y - x_range.x) * float(xi) / float(grid_cols - 1)
				row.append(float(surface_function.call(xv, zv)))
			heights.append(row)
		return heights
	return grid_data


func _draw_demo() -> void:
	surface_function = func(x: float, z: float) -> float:
		return sin(x * TAU) * cos(z * TAU) * 0.5 + 0.5
	grid_cols = 24
	grid_rows = 24
	x_range = Vector2(0.0, 1.0)
	z_range = Vector2(0.0, 1.0)
