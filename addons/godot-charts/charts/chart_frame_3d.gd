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

## Radius of the rounded corners on the background panel (Godot units).
## 0.0 (default) = sharp BoxMesh corners.  Clamped to half the smaller of
## [member size].x / [member size].y so the geometry is always valid.
@export_range(0.0, 2.0, 0.01) var corner_radius: float = 0.0 :
	set(v):
		corner_radius = v
		_rebuild()

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
		var panel_mesh: Mesh
		if corner_radius > 0.0:
			panel_mesh = _build_rounded_panel_mesh(size.x, size.y, frame_depth, corner_radius)
		else:
			var box := BoxMesh.new()
			box.size = Vector3(size.x, size.y, frame_depth)
			panel_mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = background_color

		var mi := MeshInstance3D.new()
		mi.name = "Background"
		mi.mesh = panel_mesh
		mi.material_override = mat
		# Centre the mesh on (size/2) so the frame origin (0,0,0) is the
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


## Builds an [ArrayMesh] prism with a rounded-rectangle cross-section in the XY
## plane, extruded along the Z axis.  Matches the centering of [BoxMesh]:
## X ∈ [-w/2, w/2], Y ∈ [-h/2, h/2], Z ∈ [-d/2, d/2].
##
## [param r] is the corner radius (clamped to half the smaller XY dimension).
## [param segs] controls arc smoothness (segments per quarter-circle, min 1).
func _build_rounded_panel_mesh(w: float, h: float, d: float, r: float, segs: int = 5) -> ArrayMesh:
	r = clampf(r, 0.001, minf(w, h) * 0.5 - 0.001)
	segs = maxi(segs, 1)
	var hw := w * 0.5
	var hh := h * 0.5
	var hd := d * 0.5

	# --- Build 2D profile (XY plane, CCW viewed from +Z / front face) ---
	var profile: PackedVector2Array = []
	var corner_data: Array[Array] = [
		[hw - r,   hh - r,  0.0],          # +X +Y corner
		[-(hw-r),  hh - r,  PI * 0.5],     # -X +Y corner
		[-(hw-r), -(hh-r),  PI],           # -X -Y corner
		[hw - r,  -(hh-r),  PI * 1.5],     # +X -Y corner
	]
	for ci in corner_data.size():
		var cx: float  = corner_data[ci][0]
		var cy: float  = corner_data[ci][1]
		var sa: float  = corner_data[ci][2]
		var first: int = 0 if ci == 0 else 1
		for i in range(first, segs + 1):
			var a := sa + (PI * 0.5) * float(i) / float(segs)
			profile.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))

	var n := profile.size()  # 4*segs + 1

	# --- Vertex layout ---
	# [0 .. n-1]   back ring   z = -hd
	# [n .. 2n-1]  front ring  z = +hd
	# [2n]         back centre
	# [2n+1]       front centre
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var indices := PackedInt32Array()

	for p in profile:
		verts.append(Vector3(p.x, p.y, -hd))
	for p in profile:
		verts.append(Vector3(p.x, p.y,  hd))
	verts.append(Vector3(0.0, 0.0, -hd))
	verts.append(Vector3(0.0, 0.0,  hd))
	norms.resize(verts.size())
	norms.fill(Vector3.ZERO)

	var bc := n * 2       # back centre index
	var fc := n * 2 + 1   # front centre index

	for i in n:
		var j := (i + 1) % n
		# Side quads — winding verified to give outward normals for CCW XY profile.
		indices.append_array([i, j, j + n])
		indices.append_array([i, j + n, i + n])
		# Back cap (normal = -Z).
		indices.append_array([bc, j, i])
		# Front cap (normal = +Z).
		indices.append_array([fc, i + n, j + n])

	# Smooth normals via face-normal accumulation.
	for ti in range(0, indices.size(), 3):
		var a := indices[ti]; var b := indices[ti + 1]; var c := indices[ti + 2]
		var fn := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		norms[a] += fn;  norms[b] += fn;  norms[c] += fn
	for vi in norms.size():
		norms[vi] = norms[vi].normalized()

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX]  = indices
	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arr_mesh
