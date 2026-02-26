@tool
class_name GraphNetworkChart2D
extends Chart3D

## A 2D graph network chart rendered in the XY plane.
##
## Nodes and edges are drawn from NetworkX / iGraph style data supplied via
## a [GraphNetworkDataSource] or the inline [member data] property.
## Three layout algorithms are available: PRESET uses [code]x[/code]/[code]y[/code]
## coordinates from the data, CIRCULAR distributes nodes evenly on a circle,
## and SPRING runs a Fruchterman-Reingold force-directed layout.
##
## [b]Basic usage[/b]
## [codeblock]
## var chart := GraphNetworkChart2D.new()
## chart.data = {
##     "nodes": [
##         { "id": "A", "label": "Alice", "type": "person" },
##         { "id": "B", "label": "Bob",   "type": "person" },
##     ],
##     "edges": [
##         { "source": "A", "target": "B", "label": "knows" }
##     ]
## }
## add_child(chart)
## [/codeblock]
##
## [b]Customisation[/b] — assign [member node_type_scenes] and/or
## [member node_type_materials] to map node [code]type[/code] strings to
## custom meshes and materials.  Similarly use [member edge_type_materials]
## for per-type edge styling.

## Layout algorithm enum for [member layout_mode].
enum LayoutMode {
	## Use [code]x[/code] and [code]y[/code] fields from each node in the data.
	PRESET   = 0,
	## Distribute nodes evenly on a circle.
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

## Maps edge [code]type[/code] string → [Material].
@export var edge_type_materials: Dictionary = {} :
	set(v):
		edge_type_materials = v
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
# Lifecycle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	# Drive hot-reload on any GraphNetworkDataSource assigned as data_source.
	if data_source != null and data_source.has_method("tick"):
		data_source.tick(delta)

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

	# 1. Compute layout positions (id -> Vector2).
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
# Layout computation
# ---------------------------------------------------------------------------

func _compute_layout(nodes: Array, edges: Array) -> Dictionary:
	match layout_mode:
		LayoutMode.CIRCULAR:
			return _layout_circular(nodes)
		LayoutMode.SPRING:
			return _layout_spring(nodes, edges)
		_:  # PRESET
			return _layout_preset(nodes)


func _layout_preset(nodes: Array) -> Dictionary:
	var raw: Dictionary = {}
	for n in nodes:
		var id := str(n.get("id", ""))
		raw[id] = Vector2(float(n.get("x", 0.0)), float(n.get("y", 0.0)))
	return _normalize_to_chart(raw)


func _layout_circular(nodes: Array) -> Dictionary:
	var result: Dictionary = {}
	var n := nodes.size()
	if n == 0:
		return result
	var cx := chart_size.x * 0.5
	var cy := chart_size.y * 0.5
	var r := minf(chart_size.x, chart_size.y) * 0.4
	for i in n:
		var id := str(nodes[i].get("id", ""))
		var angle := TAU * float(i) / float(n) - PI * 0.5
		result[id] = Vector2(cx + cos(angle) * r, cy + sin(angle) * r)
	return result


func _layout_spring(nodes: Array, edges: Array) -> Dictionary:
	var n := nodes.size()
	if n == 0:
		return {}

	# Seed positions on a unit circle for a well-distributed start.
	var ids: Array[String] = []
	var pos: Dictionary = {}  # id -> Vector2 (normalised unit coords)
	for i in n:
		var id := str(nodes[i].get("id", ""))
		ids.append(id)
		var angle := TAU * float(i) / float(n) - PI * 0.5
		pos[id] = Vector2(0.5 + cos(angle) * 0.4, 0.5 + sin(angle) * 0.4)

	var k := sqrt(1.0 / float(n)) if n > 0 else 1.0
	var temperature := 0.15  # fraction of unit area

	for _iter in spring_iterations:
		var disp: Dictionary = {}
		for id in ids:
			disp[id] = Vector2.ZERO

		# Repulsion between every pair.
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var vi: String = ids[i]
				var vj: String = ids[j]
				var delta: Vector2 = (pos[vi] as Vector2) - (pos[vj] as Vector2)
				var dist := maxf(delta.length(), 0.001)
				var force := k * k / dist
				var d_norm := delta / dist
				disp[vi] = (disp[vi] as Vector2) + d_norm * force
				disp[vj] = (disp[vj] as Vector2) - d_norm * force

		# Attraction along edges.
		for e in edges:
			var src := str(e.get("source", ""))
			var tgt := str(e.get("target", ""))
			if not (pos.has(src) and pos.has(tgt)):
				continue
			var delta: Vector2 = (pos[tgt] as Vector2) - (pos[src] as Vector2)
			var dist := maxf(delta.length(), 0.001)
			var force := dist * dist / k
			var d_norm := delta / dist
			disp[tgt] = (disp[tgt] as Vector2) - d_norm * force
			disp[src] = (disp[src] as Vector2) + d_norm * force

		# Apply displacement clamped by temperature.
		for id in ids:
			var d: Vector2 = disp[id]
			var d_len := maxf(d.length(), 0.001)
			pos[id] = (pos[id] as Vector2) + (d / d_len) * minf(d_len, temperature)

		temperature *= 0.95

	return _normalize_to_chart(pos)


## Scale raw positions so every node fits within the chart area with [member node_radius] margins.
func _normalize_to_chart(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return {}
	var min_x := INF;  var max_x := -INF
	var min_y := INF;  var max_y := -INF
	for id in raw:
		var p: Vector2 = raw[id]
		min_x = minf(min_x, p.x);  max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y);  max_y = maxf(max_y, p.y)
	var margin := node_radius * 2.0
	var range_x := max_x - min_x if max_x != min_x else 1.0
	var range_y := max_y - min_y if max_y != min_y else 1.0
	var target_w := maxf(chart_size.x - margin * 2.0, 0.01)
	var target_h := maxf(chart_size.y - margin * 2.0, 0.01)
	var result: Dictionary = {}
	for id in raw:
		var p: Vector2 = raw[id]
		result[id] = Vector2(
			margin + (p.x - min_x) / range_x * target_w,
			margin + (p.y - min_y) / range_y * target_h,
		)
	return result

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
		var pos2: Vector2 = layout.get(id, Vector2.ZERO)
		var pos3 := Vector3(pos2.x, pos2.y, 0.0)
		if _node_instances.has(id):
			(_node_instances[id] as Node3D).position = pos3
		else:
			var inst := _create_node_instance(n, pos3)
			_node_container.add_child(inst)
			_node_instances[id] = inst
			_pop_in(inst)


func _create_node_instance(n: Dictionary, pos: Vector3) -> Node3D:
	var ntype := str(n.get("type", ""))
	var color := _get_type_color(ntype)

	# PackedScene override takes priority.
	if node_type_scenes.has(ntype) and node_type_scenes[ntype] is PackedScene:
		var scene := node_type_scenes[ntype] as PackedScene
		var inst: Node3D = scene.instantiate() as Node3D
		inst.position = pos
		inst.scale = Vector3.ONE * node_radius
		var mat: Material = node_type_materials.get(ntype, null) as Material
		if mat != null:
			_apply_material_to_scene(inst, mat)
		_apply_animation(inst)
		return inst

	# Default: SphereMesh.
	var mesh := SphereMesh.new()
	mesh.radius = node_radius
	mesh.height = node_radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4

	var mat: Material
	if node_type_materials.has(ntype) and node_type_materials[ntype] is Material:
		mat = node_type_materials[ntype] as Material
	else:
		mat = _create_material(color)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

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
		var p0: Vector2 = layout[src]
		var p1: Vector2 = layout[tgt]
		var v0 := Vector3(p0.x, p0.y, 0.0)
		var v1 := Vector3(p1.x, p1.y, 0.0)

		var etype := str(e.get("type", ""))
		var mat: Material = edge_type_materials.get(etype, null) as Material
		var line := _make_line(v0, v1, Color(0.6, 0.6, 0.65), mat)
		_edge_container.add_child(line)

		if e.get("directed", false):
			_draw_arrow_tip(v0, v1, mat)


func _draw_arrow_tip(from: Vector3, to: Vector3, mat: Material) -> void:
	var dir := (to - from).normalized()
	if dir.length_squared() < 0.001:
		return
	var tip_pos := to - dir * (node_radius + edge_width * 3.0)

	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = edge_width * 2.5
	cone.height = edge_width * 5.0

	var mi := MeshInstance3D.new()
	mi.mesh = cone
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
		var pos2: Vector2 = layout.get(id, Vector2.ZERO)
		var lbl := _make_label(lbl_text, Vector3(pos2.x, pos2.y + node_radius + 0.12, 0.0), 44)
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
		var p0: Vector2 = layout[src]
		var p1: Vector2 = layout[tgt]
		var mid := Vector3((p0.x + p1.x) * 0.5, (p0.y + p1.y) * 0.5, 0.01)
		_label_container.add_child(_make_label(lbl_text, mid, 36))

# ---------------------------------------------------------------------------
# Public animation API (Phase 5)
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
	data = {
		"nodes": [
			{"id": "A", "label": "Alice",   "type": "person",   "x": 0.2, "y": 0.8},
			{"id": "B", "label": "Bob",     "type": "person",   "x": 0.8, "y": 0.8},
			{"id": "C", "label": "Charlie", "type": "person",   "x": 0.5, "y": 0.2},
			{"id": "D", "label": "Corp",    "type": "org",      "x": 0.5, "y": 0.5},
			{"id": "E", "label": "Project", "type": "resource", "x": 0.2, "y": 0.2},
		],
		"edges": [
			{"source": "A", "target": "B", "label": "knows"},
			{"source": "A", "target": "D", "label": "works at"},
			{"source": "B", "target": "D", "label": "works at"},
			{"source": "C", "target": "D", "label": "consults"},
			{"source": "D", "target": "E", "label": "owns",    "directed": true},
			{"source": "A", "target": "C", "label": "friends"},
		],
	}
