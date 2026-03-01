@tool
class_name GraphNetworkChartBase
extends Chart3D

const _DEFAULT_NODE_MESH := preload("res://addons/godot-charts/assets/meshes/node_sphere.tres")
const _DEFAULT_ARROW_HEAD := preload("res://addons/godot-charts/assets/meshes/arrow_head.tres")

## Abstract base class for 2D and 3D graph network charts.
##
## Nodes and edges are drawn from NetworkX / iGraph style data supplied via
## a [GraphNetworkDataSource] or the inline [member data] property.
## Subclasses implement specific layout algorithms and 3D positioning strategies.

## Layout algorithm enum for [member layout_mode].
enum LayoutMode {
	## Use preset coordinates from the data (x/y for 2D, x/y/z for 3D).
	PRESET   = 0,
	## Distribute nodes on a geometric pattern (circle for 2D, sphere for 3D).
	CIRCULAR = 1,
	## Run a Fruchterman-Reingold force-directed layout.
	SPRING   = 2,
}

# ---------------------------------------------------------------------------
# Exported properties
# ---------------------------------------------------------------------------

## Inline graph data dictionary.  Assigning triggers a rebuild.
## Ignored when [member Chart3D.data_source] is set.
@export var data: Dictionary = {} :
	set(v):
		data = v
		_queue_rebuild()

## Layout algorithm used to position nodes.
@export_enum("Preset:0", "Circular:1", "Spring:2") var layout_mode: int = LayoutMode.PRESET :
	set(v):
		layout_mode = v
		_queue_rebuild()

## Radius of each node sphere (Godot units).
@export_range(0.05, 1.0, 0.005) var node_radius: float = 0.15 :
	set(v):
		node_radius = v
		_queue_rebuild()

## Width of edge lines (Godot units, used for directed arrow cone base radius).
@export_range(0.005, 0.5, 0.005) var edge_width: float = 0.02 :
	set(v):
		edge_width = v
		_queue_rebuild()

## Radius of cylindrical edges when edge_radius > 0 (Godot units).
## Set to 0 to draw edges as lines (default behavior).
@export_range(0.0, 0.2, 0.005) var edge_radius: float = 0.0 :
	set(v):
		edge_radius = v
		_queue_rebuild()

## Multiplier applied to the per-edge [code]weight[/code] field when drawing
## cylindrical edges.  Edge weights are clamped to (0, 1] before scaling, so
## a weight of 1.0 (the default) renders at full [member edge_radius].
## Set to 0.0 to ignore weights entirely (uniform radius).
@export_range(0.0, 2.0, 0.01) var edge_weight_scale: float = 1.0 :
	set(v):
		edge_weight_scale = v
		_queue_rebuild()

## Draw a billboard label above each node.
@export var show_node_labels: bool = true :
	set(v):
		show_node_labels = v
		_queue_rebuild()

## Draw a label at the midpoint of each edge.
@export var show_edge_labels: bool = false :
	set(v):
		show_edge_labels = v
		_queue_rebuild()

## Number of Fruchterman-Reingold iterations.
## Only used when [member layout_mode] = SPRING.
@export_range(10, 500, 10) var spring_iterations: int = 50 :
	set(v):
		spring_iterations = v
		_queue_rebuild()

@export_group("Type Overrides")

## Maps node [code]type[/code] string → [PackedScene] to replace the default sphere.
## e.g. [code]{ "person": preload("res://person.tscn") }[/code]
@export var node_type_scenes: Dictionary = {} :
	set(v):
		node_type_scenes = v
		_queue_rebuild()

## Maps node [code]type[/code] string → [Material].
## Nodes without an entry use auto-indexed colors from [member Chart3D.colors].
@export var node_type_materials: Dictionary = {} :
	set(v):
		node_type_materials = v
		_queue_rebuild()

## Maps node [code]type[/code] string → [Mesh] override.
## Lower priority than [member node_type_scenes], higher than [member node_default_mesh].
@export var node_type_meshes: Dictionary = {} :
	set(v):
		node_type_meshes = v
		_queue_rebuild()

## Single [Mesh] override applied to all nodes (unless type-specific override exists).
@export var node_default_mesh: Mesh :
	set(v):
		node_default_mesh = v
		_queue_rebuild()

## Maps node [code]type[/code] string → [Texture2D] overlay.
@export var node_type_textures: Dictionary = {} :
	set(v):
		node_type_textures = v
		_queue_rebuild()

## Single [Texture2D] overlay applied to all nodes (unless type-specific override exists).
@export var node_default_texture: Texture2D :
	set(v):
		node_default_texture = v
		_queue_rebuild()

## Maps edge [code]type[/code] string → [Material].
@export var edge_type_materials: Dictionary = {} :
	set(v):
		edge_type_materials = v
		_queue_rebuild()

## Maps edge [code]type[/code] string → [Texture2D] overlay.
@export var edge_type_textures: Dictionary = {} :
	set(v):
		edge_type_textures = v
		_queue_rebuild()

## Single [Texture2D] overlay applied to all edges (unless type-specific override exists).
@export var edge_default_texture: Texture2D :
	set(v):
		edge_default_texture = v
		_queue_rebuild()

## Custom [PackedScene] to instantiate for all edges when [member edge_radius] = 0.
## If set, overrides the default line drawing behavior.
@export var edge_mesh_scene: PackedScene :
	set(v):
		edge_mesh_scene = v
		_queue_rebuild()

@export_group("")

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## Live node instances keyed by node id; updated differentially on each rebuild.
var _node_instances: Dictionary = {}   # id (String) -> Node3D
var _node_container: Node3D = null
var _edge_container: Node3D = null
var _label_container: Node3D = null

## Stable type → color-index mapping so node colors survive rebuilds.
var _type_color_index: Dictionary = {}  # type_string -> int

# ---------------------------------------------------------------------------
# Abstract methods (implemented by subclasses)
# ---------------------------------------------------------------------------

## Subclass should override to return the layout positions for all nodes.
## For 2D, return a Dictionary[id → Vector2].
## For 3D, return a Dictionary[id → Vector3].
func _compute_layout(_nodes: Array, _edges: Array) -> Dictionary:
	push_error("GraphNetworkChartBase._compute_layout() not implemented in subclass")
	return {}

# ---------------------------------------------------------------------------
# Chart3D override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	if not is_instance_valid(_container):
		return
	_ensure_sub_containers()

	var d: Dictionary = _get_source_data() if data_source != null else data
	var nodes: Array = d.get("nodes", [])
	var edges: Array = d.get("edges", [])

	if nodes.is_empty():
		_clear_all()
		_draw_demo()
		return

	# 1. Compute layout positions.
	var layout: Dictionary = _compute_layout(nodes, edges)

	# 2. Differential node sync — reuse existing instances, pop-in new, collapse removed.
	_sync_nodes(nodes, layout)

	# 3. Edges — full rebuild each time (simpler than diffing).
	for child in _edge_container.get_children():
		child.free()
	_draw_edges(edges, layout)

	# 4. Labels — full rebuild each time.
	for child in _label_container.get_children():
		child.free()
	if show_node_labels:
		_draw_node_labels(nodes, layout)
	if show_edge_labels:
		_draw_edge_labels(edges, layout)

	emit_signal("data_changed")

# ---------------------------------------------------------------------------
# Differential node sync
# ---------------------------------------------------------------------------

func _sync_nodes(nodes: Array, layout: Dictionary) -> void:
	# Build the new id set.
	var new_ids: Dictionary = {}
	for n in nodes:
		new_ids[str(n.get("id", ""))] = n

	# Collapse nodes that are no longer in the data.
	for id in _node_instances.keys():
		if not new_ids.has(id):
			_collapse_and_free(id)

	# Build stable type → color index before creating any meshes.
	_assign_type_indices(nodes)

	# Create or reposition each node.
	for id in new_ids:
		var n: Dictionary = new_ids[id]
		var pos: Vector3 = _layout_position_to_vector3(layout.get(id))
		if _node_instances.has(id):
			(_node_instances[id] as Node3D).position = pos
		else:
			var inst := _create_node_instance(n, pos)
			_node_container.add_child(inst)
			_node_instances[id] = inst
			_pop_in(inst)


## Subclass helper: Convert layout position (Vector2 or Vector3) to Vector3 for 3D placement.
func _layout_position_to_vector3(pos) -> Vector3:
	if pos is Vector2:
		return Vector3(pos.x, pos.y, 0.0)
	elif pos is Vector3:
		return pos
	else:
		return Vector3.ZERO


func _create_node_instance(n: Dictionary, pos: Vector3) -> Node3D:
	var ntype := str(n.get("type", ""))
	var color := _get_type_color(ntype)

	# PackedScene override takes priority.
	if node_type_scenes.has(ntype) and node_type_scenes[ntype] is PackedScene:
		var scene := node_type_scenes[ntype] as PackedScene
		var inst: Node3D = scene.instantiate() as Node3D
		inst.position = pos
		inst.scale = Vector3.ONE * node_radius
		var m: Material = node_type_materials.get(ntype, null) as Material
		if m != null:
			_apply_material_to_scene(inst, m)
		_apply_animation(inst)
		return inst

	# Resolve material (type override > auto-color).
	var mat: Material
	if node_type_materials.has(ntype) and node_type_materials[ntype] is Material:
		mat = node_type_materials[ntype] as Material
	else:
		# Apply texture if available.
		var tex := _get_node_texture(ntype)
		mat = _create_material_with_texture(color, tex, null)

	# Resolve mesh (type override > default > fallback).
	var mesh := _get_node_mesh(ntype)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = Vector3.ONE * node_radius
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Get the mesh for a node of the given type. Override resolution:
## type-specific mesh > default mesh > preloaded default.
func _get_node_mesh(ntype: String) -> Mesh:
	if node_type_meshes.has(ntype) and node_type_meshes[ntype] is Mesh:
		return node_type_meshes[ntype] as Mesh
	if node_default_mesh != null:
		return node_default_mesh
	return _DEFAULT_NODE_MESH


## Get the texture for a node of the given type. Override resolution:
## type-specific texture > default texture > null.
func _get_node_texture(ntype: String) -> Texture2D:
	if node_type_textures.has(ntype) and node_type_textures[ntype] is Texture2D:
		return node_type_textures[ntype] as Texture2D
	if node_default_texture != null:
		return node_default_texture
	return null


## Get the texture for an edge of the given type. Override resolution:
## type-specific texture > default texture > null.
func _get_edge_texture(etype: String) -> Texture2D:
	if edge_type_textures.has(etype) and edge_type_textures[etype] is Texture2D:
		return edge_type_textures[etype] as Texture2D
	if edge_default_texture != null:
		return edge_default_texture
	return null

# ---------------------------------------------------------------------------
# Node animation helpers
# ---------------------------------------------------------------------------

func _pop_in(inst: Node3D) -> void:
	var target := inst.scale
	inst.scale = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(inst, "scale", target, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _collapse_and_free(id: String) -> void:
	if not _node_instances.has(id):
		return
	var inst := _node_instances[id] as Node3D
	_node_instances.erase(id)
	if not is_instance_valid(inst):
		return
	var tween := create_tween()
	tween.tween_property(inst, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(inst.queue_free)

# ---------------------------------------------------------------------------
# Edge drawing
# ---------------------------------------------------------------------------

func _draw_edges(edges: Array, layout: Dictionary) -> void:
	for e in edges:
		var src := str(e.get("source", ""))
		var tgt := str(e.get("target", ""))
		if not (layout.has(src) and layout.has(tgt)):
			continue
		
		var p0 = layout[src]
		var p1 = layout[tgt]
		var v0 := _layout_position_to_vector3(p0)
		var v1 := _layout_position_to_vector3(p1)

		var etype := str(e.get("type", ""))
		var mat: Material = edge_type_materials.get(etype, null) as Material
		
		# Apply edge texture if available.
		var tex := _get_edge_texture(etype)
		if tex != null:
			var edge_color := Color(0.6, 0.6, 0.65) if mat == null else Color.WHITE
			mat = _create_material_with_texture(edge_color, tex, mat)
		elif mat == null:
			mat = _create_unshaded_material(Color(0.6, 0.6, 0.65))

		# Weight-adjusted cylinder radius: clamp weight to (0,1], scale by edge_weight_scale.
		var weight := clampf(float(e.get("weight", 1.0)), 0.001, 1.0)
		var eff_radius := edge_radius * (1.0 if edge_weight_scale == 0.0 else weight * edge_weight_scale)

		# Draw edge (line or cylindrical).
		if edge_radius > 0.0 and edge_mesh_scene == null:
			_draw_edge_cylinder(v0, v1, etype, mat, eff_radius)
		elif edge_mesh_scene != null:
			_draw_edge_scene(v0, v1, etype, mat)
		else:
			var line := _make_line(v0, v1, Color(0.6, 0.6, 0.65), mat)
			_edge_container.add_child(line)

		# Draw arrow tip if directed.
		if e.get("directed", false):
			_draw_arrow_tip(v0, v1, mat)


## Draw a cylindrical edge between two 3D points.
## [param radius] overrides [member edge_radius] so per-edge weight scaling can be applied.
func _draw_edge_cylinder(v0: Vector3, v1: Vector3, _etype: String, mat: Material, radius: float = -1.0) -> void:
	var dir := (v1 - v0)
	var dist := dir.length()
	if dist < 0.001:
		return

	var cyl := CylinderMesh.new()
	cyl.height = dist
	cyl.radius = radius if radius >= 0.0 else edge_radius
	
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.position = (v0 + v1) * 0.5
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mat if mat != null else _create_unshaded_material(Color(0.6, 0.6, 0.65))
	
	# Orient cylinder along edge direction (default is Y-up).
	var cross := Vector3.UP.cross(dir.normalized())
	if cross.length_squared() > 1e-6:
		mi.basis = Basis(cross.normalized(), Vector3.UP.angle_to(dir.normalized()))
	elif dir.dot(Vector3.UP) < 0.0:
		mi.basis = Basis(Vector3.RIGHT, PI)
	
	_edge_container.add_child(mi)


## Instantiate a custom scene for each edge.
func _draw_edge_scene(v0: Vector3, v1: Vector3, _etype: String, mat: Material) -> void:
	var inst := edge_mesh_scene.instantiate() as Node3D
	if inst == null:
		return
	
	var dir := (v1 - v0)
	var dist := dir.length()
	inst.position = (v0 + v1) * 0.5
	
	if dist > 0.001:
		var cross := Vector3.UP.cross(dir.normalized())
		if cross.length_squared() > 1e-6:
			inst.basis = Basis(cross.normalized(), Vector3.UP.angle_to(dir.normalized()))
		elif dir.dot(Vector3.UP) < 0.0:
			inst.basis = Basis(Vector3.RIGHT, PI)
		inst.scale = Vector3(1.0, dist, 1.0)
	
	if mat != null:
		_apply_material_to_scene(inst, mat)
	
	_edge_container.add_child(inst)


func _draw_arrow_tip(from: Vector3, to: Vector3, mat: Material) -> void:
	var dir := (to - from).normalized()
	if dir.length_squared() < 0.001:
		return
	var tip_pos := to - dir * (node_radius + edge_width * 3.0)

	var mi := MeshInstance3D.new()
	mi.mesh = _DEFAULT_ARROW_HEAD
	mi.scale = Vector3(edge_width * 2.5, edge_width * 5.0, edge_width * 2.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mat if mat != null else _create_unshaded_material(Color(0.6, 0.6, 0.65))
	mi.position = tip_pos

	# Rotate the default CylinderMesh (Y-up) to align with edge direction.
	var cross := Vector3.UP.cross(dir)
	if cross.length_squared() > 1e-6:
		mi.basis = Basis(cross.normalized(), Vector3.UP.angle_to(dir))
	elif dir.dot(Vector3.UP) < 0.0:
		mi.basis = Basis(Vector3.RIGHT, PI)

	_edge_container.add_child(mi)

# ---------------------------------------------------------------------------
# Label drawing
# ---------------------------------------------------------------------------

func _draw_node_labels(nodes: Array, layout: Dictionary) -> void:
	for n in nodes:
		var id := str(n.get("id", ""))
		var lbl_text := str(n.get("label", id))
		var pos = layout.get(id)
		var pos3 := _layout_position_to_vector3(pos)
		var lbl := _make_label(lbl_text, pos3 + Vector3(0.0, node_radius + 0.12, 0.0), 44)
		_label_container.add_child(lbl)


func _draw_edge_labels(edges: Array, layout: Dictionary) -> void:
	for e in edges:
		var src := str(e.get("source", ""))
		var tgt := str(e.get("target", ""))
		var lbl_text := str(e.get("label", ""))
		if lbl_text.is_empty():
			continue
		if not (layout.has(src) and layout.has(tgt)):
			continue
		var p0 = layout[src]
		var p1 = layout[tgt]
		var v0 := _layout_position_to_vector3(p0)
		var v1 := _layout_position_to_vector3(p1)
		var mid := (v0 + v1) * 0.5
		_label_container.add_child(_make_label(lbl_text, mid, 36))

# ---------------------------------------------------------------------------
# Public animation API
# ---------------------------------------------------------------------------

## Play pop-in animation on the node with [param id] (must already exist).
func pop_node(id: String) -> void:
	if _node_instances.has(id):
		_pop_in(_node_instances[id] as Node3D)


## Play collapse animation then remove the node with [param id].
func collapse_node(id: String) -> void:
	_collapse_and_free(id)


## Pop all current nodes in with an optional per-node stagger delay.
func pop_all(stagger_sec: float = 0.05) -> void:
	var i := 0
	for id in _node_instances:
		var inst := _node_instances[id] as Node3D
		var target := Vector3.ONE * node_radius
		inst.scale = Vector3.ZERO
		var tween := create_tween()
		tween.tween_interval(stagger_sec * float(i))
		tween.tween_property(inst, "scale", target, 0.3) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		i += 1


## Collapse all nodes with an optional per-node stagger delay.
func collapse_all(stagger_sec: float = 0.05) -> void:
	var i := 0
	for id in _node_instances.keys():
		var inst := _node_instances[id] as Node3D
		_node_instances.erase(id)
		if not is_instance_valid(inst):
			continue
		var tween := create_tween()
		tween.tween_interval(stagger_sec * float(i))
		tween.tween_property(inst, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
		tween.tween_callback(inst.queue_free)
		i += 1

# ---------------------------------------------------------------------------
# Type → color helpers
# ---------------------------------------------------------------------------

func _assign_type_indices(nodes: Array) -> void:
	for n in nodes:
		var t := str(n.get("type", ""))
		if not _type_color_index.has(t):
			_type_color_index[t] = _type_color_index.size()


func _get_type_color(ntype: String) -> Color:
	if not _type_color_index.has(ntype):
		_type_color_index[ntype] = _type_color_index.size()
	return _get_color(_type_color_index[ntype])

# ---------------------------------------------------------------------------
# Sub-container management
# ---------------------------------------------------------------------------

func _ensure_sub_containers() -> void:
	_node_container = _container.get_node_or_null("Nodes") as Node3D
	if not is_instance_valid(_node_container):
		_node_container = Node3D.new()
		_node_container.name = "Nodes"
		_container.add_child(_node_container)

	_edge_container = _container.get_node_or_null("Edges") as Node3D
	if not is_instance_valid(_edge_container):
		_edge_container = Node3D.new()
		_edge_container.name = "Edges"
		_container.add_child(_edge_container)

	_label_container = _container.get_node_or_null("Labels") as Node3D
	if not is_instance_valid(_label_container):
		_label_container = Node3D.new()
		_label_container.name = "Labels"
		_container.add_child(_label_container)


func _clear_all() -> void:
	for id in _node_instances.keys():
		var inst: Node3D = _node_instances[id]
		if is_instance_valid(inst):
			inst.free()
	_node_instances.clear()
	for ctr in [_node_container, _edge_container, _label_container]:
		if is_instance_valid(ctr):
			for child in ctr.get_children():
				child.free()


func _draw_demo() -> void:
	push_error("GraphNetworkChartBase._draw_demo() not implemented in subclass")
