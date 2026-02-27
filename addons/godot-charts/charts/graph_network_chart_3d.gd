@tool
class_name GraphNetworkChart3D
extends Chart3D

const _DEFAULT_NODE_MESH := preload("res://addons/godot-charts/assets/meshes/node_sphere.tres")
const _DEFAULT_ARROW_HEAD := preload("res://addons/godot-charts/assets/meshes/arrow_head.tres")

## A 3D graph network chart rendered in full XYZ space.
##
## Nodes and edges are drawn from NetworkX / iGraph style data supplied via
## a [GraphNetworkDataSource] or the inline [member data] property.
## Three layout algorithms are available: PRESET reads [code]x[/code],
## [code]y[/code], [code]z[/code] from the data, CIRCULAR places nodes on a
## sphere surface, and SPRING runs a 3D Fruchterman-Reingold layout.
##
## When [member spring_per_frame] is enabled the spring simulation runs one
## step per [code]_process[/code] tick, animating nodes as they settle into
## their final positions.
##
## [b]Basic usage[/b]
## [codeblock]
## var chart := GraphNetworkChart3D.new()
## chart.data = {
##     "nodes": [
##         { "id": "A", "label": "Alice", "x": 0.5, "y": 1.0, "z": 0.3 },
##         { "id": "B", "label": "Bob",   "x": 1.5, "y": 0.5, "z": 0.8 },
##     ],
##     "edges": [
##         { "source": "A", "target": "B" }
##     ]
## }
## add_child(chart)
## [/codeblock]

## Layout algorithm enum for [member layout_mode].
enum LayoutMode {
	## Use [code]x[/code], [code]y[/code], and [code]z[/code] fields from each node.
	PRESET   = 0,
	## Distribute nodes evenly on the surface of a sphere.
	CIRCULAR = 1,
	## Run a 3D Fruchterman-Reingold force-directed layout.
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

## Width of edge lines / arrow cone base (Godot units).
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

## Total Fruchterman-Reingold iterations.
## Used in batch mode (spring_per_frame = false) or as the stop count per-frame.
@export_range(10, 500, 10) var spring_iterations: int = 80 :
	set(v):
		spring_iterations = v
		_queue_rebuild()

## When [code]true[/code], the spring layout runs one iteration per
## [code]_process[/code] tick so nodes visibly settle into position.
## When [code]false[/code] (default), all iterations run synchronously.
@export var spring_per_frame: bool = false :
	set(v):
		spring_per_frame = v
		_queue_rebuild()

@export_group("Type Overrides")

## Maps node [code]type[/code] string → [PackedScene] to replace the default sphere.
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

# Per-frame spring simulation state.
var _spring_running: bool = false
var _spring_pos: Dictionary = {}   # id (String) -> Vector3
var _spring_ids: Array[String] = []
var _spring_edges: Array = []       # raw edge dicts
var _spring_nodes: Array = []       # raw node dicts
var _spring_temp: float = 0.0
var _spring_step: int = 0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)

	# Drive hot-reload on any GraphNetworkDataSource assigned as data_source.
	if data_source != null and data_source.has_method("tick"):
		data_source.tick(delta)

	# Advance per-frame spring simulation one step.
	if _spring_running:
		_spring_step_3d()

# ---------------------------------------------------------------------------
# Chart3D override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	if not is_instance_valid(_container):
		return
	_ensure_sub_containers()

	# Stop any in-progress per-frame simulation before starting fresh.
	_spring_running = false

	var d: Dictionary = _get_source_data() if data_source != null else data
	var nodes: Array = d.get("nodes", [])
	var edges: Array = d.get("edges", [])

	if nodes.is_empty():
		_clear_all()
		_draw_demo()
		return

	# 1. Compute (or start) layout.
	var layout: Dictionary  # id -> Vector3
	if layout_mode == LayoutMode.SPRING and spring_per_frame:
		layout = _start_spring_3d(nodes, edges)
	else:
		layout = _compute_layout_3d(nodes, edges)

	# 2. Differential node sync.
	_sync_nodes(nodes, layout)

	# 3. Edges — full rebuild each time.
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
# Layout computation (3D)
# ---------------------------------------------------------------------------

func _compute_layout_3d(nodes: Array, edges: Array) -> Dictionary:
	match layout_mode:
		LayoutMode.CIRCULAR:
			return _layout_sphere(nodes)
		LayoutMode.SPRING:
			return _layout_spring_3d_sync(nodes, edges)
		_:  # PRESET
			return _layout_preset_3d(nodes)


func _layout_preset_3d(nodes: Array) -> Dictionary:
	var raw: Dictionary = {}
	for n in nodes:
		var id := str(n.get("id", ""))
		raw[id] = Vector3(float(n.get("x", 0.0)), float(n.get("y", 0.0)), float(n.get("z", 0.0)))
	return _normalize_to_chart_3d(raw)


## Distribute nodes on a Fibonacci sphere for near-uniform spacing.
func _layout_sphere(nodes: Array) -> Dictionary:
	var result: Dictionary = {}
	var n := nodes.size()
	if n == 0:
		return result
	var cx := chart_size.x * 0.5
	var cy := chart_size.y * 0.5
	var cz := minf(chart_size.x, chart_size.y) * 0.5
	var r := minf(chart_size.x, chart_size.y) * 0.38
	var golden_angle := PI * (3.0 - sqrt(5.0))
	for i in n:
		var id := str(nodes[i].get("id", ""))
		var t := float(i) / float(maxi(n - 1, 1))
		var inc := acos(1.0 - 2.0 * t)
		var az := golden_angle * float(i)
		result[id] = Vector3(
			cx + r * sin(inc) * cos(az),
			cy + r * cos(inc),
			cz + r * sin(inc) * sin(az)
		)
	return result


func _layout_spring_3d_sync(nodes: Array, edges: Array) -> Dictionary:
	var n := nodes.size()
	if n == 0:
		return {}

	var ids: Array[String] = []
	var pos: Dictionary = {}   # id -> Vector3 (normalised unit coords)
	var golden_angle := PI * (3.0 - sqrt(5.0))
	for i in n:
		var id := str(nodes[i].get("id", ""))
		ids.append(id)
		var t := float(i) / float(maxi(n - 1, 1))
		var inc := acos(1.0 - 2.0 * t)
		var az := golden_angle * float(i)
		pos[id] = Vector3(
			0.5 + 0.4 * sin(inc) * cos(az),
			0.5 + 0.4 * cos(inc),
			0.5 + 0.4 * sin(inc) * sin(az)
		)

	var k := pow(1.0 / float(maxi(n, 1)), 1.0 / 3.0)
	var temperature := 0.15

	for _iter in spring_iterations:
		var disp: Dictionary = {}
		for id in ids:
			disp[id] = Vector3.ZERO

		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var vi: String = ids[i]
				var vj: String = ids[j]
				var delta: Vector3 = (pos[vi] as Vector3) - (pos[vj] as Vector3)
				var dist := maxf(delta.length(), 0.001)
				var force := k * k / dist
				var d_norm := delta / dist
				disp[vi] = (disp[vi] as Vector3) + d_norm * force
				disp[vj] = (disp[vj] as Vector3) - d_norm * force

		for e in edges:
			var src := str(e.get("source", ""))
			var tgt := str(e.get("target", ""))
			if not (pos.has(src) and pos.has(tgt)):
				continue
			var delta: Vector3 = (pos[tgt] as Vector3) - (pos[src] as Vector3)
			var dist := maxf(delta.length(), 0.001)
			var force := dist * dist / k
			var d_norm := delta / dist
			disp[tgt] = (disp[tgt] as Vector3) - d_norm * force
			disp[src] = (disp[src] as Vector3) + d_norm * force

		for id in ids:
			var dv: Vector3 = disp[id]
			var d_len := maxf(dv.length(), 0.001)
			pos[id] = (pos[id] as Vector3) + (dv / d_len) * minf(d_len, temperature)

		temperature *= 0.95

	return _normalize_to_chart_3d(pos)


## Start a per-frame spring simulation, return initial (circular) positions.
func _start_spring_3d(nodes: Array, edges: Array) -> Dictionary:
	_spring_nodes = nodes
	_spring_edges = edges
	_spring_ids.clear()
	_spring_pos.clear()

	var n := nodes.size()
	var golden_angle := PI * (3.0 - sqrt(5.0))
	for i in n:
		var id := str(nodes[i].get("id", ""))
		_spring_ids.append(id)
		var t := float(i) / float(maxi(n - 1, 1))
		var inc := acos(1.0 - 2.0 * t)
		var az := golden_angle * float(i)
		_spring_pos[id] = Vector3(
			0.5 + 0.4 * sin(inc) * cos(az),
			0.5 + 0.4 * cos(inc),
			0.5 + 0.4 * sin(inc) * sin(az)
		)

	_spring_temp = 0.15
	_spring_step = 0
	_spring_running = true

	return _normalize_to_chart_3d(_spring_pos)


## Run one Fruchterman-Reingold step, update node positions in the scene.
func _spring_step_3d() -> void:
	if _spring_step >= spring_iterations:
		_spring_running = false
		return

	var k := pow(1.0 / float(maxi(_spring_ids.size(), 1)), 1.0 / 3.0)
	var disp: Dictionary = {}
	for id in _spring_ids:
		disp[id] = Vector3.ZERO

	for i in _spring_ids.size():
		for j in range(i + 1, _spring_ids.size()):
			var vi: String = _spring_ids[i]
			var vj: String = _spring_ids[j]
			var delta: Vector3 = (_spring_pos[vi] as Vector3) - (_spring_pos[vj] as Vector3)
			var dist := maxf(delta.length(), 0.001)
			var force := k * k / dist
			var d_norm := delta / dist
			disp[vi] = (disp[vi] as Vector3) + d_norm * force
			disp[vj] = (disp[vj] as Vector3) - d_norm * force

	for e in _spring_edges:
		var src := str(e.get("source", ""))
		var tgt := str(e.get("target", ""))
		if not (_spring_pos.has(src) and _spring_pos.has(tgt)):
			continue
		var delta: Vector3 = (_spring_pos[tgt] as Vector3) - (_spring_pos[src] as Vector3)
		var dist := maxf(delta.length(), 0.001)
		var force := dist * dist / k
		var d_norm := delta / dist
		disp[tgt] = (disp[tgt] as Vector3) - d_norm * force
		disp[src] = (disp[src] as Vector3) + d_norm * force

	for id in _spring_ids:
		var dv: Vector3 = disp[id]
		var d_len := maxf(dv.length(), 0.001)
		_spring_pos[id] = (_spring_pos[id] as Vector3) + (dv / d_len) * minf(d_len, _spring_temp)

	_spring_temp *= 0.95
	_spring_step += 1

	# Push updated positions to the scene.
	var layout := _normalize_to_chart_3d(_spring_pos)
	for id in _spring_ids:
		if _node_instances.has(id):
			(_node_instances[id] as Node3D).position = layout.get(id, Vector3.ZERO)

	# Rebuild edges every step so they track new positions.
	if is_instance_valid(_edge_container):
		for child in _edge_container.get_children():
			child.free()
		_draw_edges(_spring_edges, layout)


## Scale raw 3D positions so every node fits within chart bounds with margins.
func _normalize_to_chart_3d(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return {}
	var min_x := INF;  var max_x := -INF
	var min_y := INF;  var max_y := -INF
	var min_z := INF;  var max_z := -INF
	for id in raw:
		var p: Vector3 = raw[id]
		min_x = minf(min_x, p.x);  max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y);  max_y = maxf(max_y, p.y)
		min_z = minf(min_z, p.z);  max_z = maxf(max_z, p.z)
	var margin := node_radius * 2.0
	var range_x := max_x - min_x if max_x != min_x else 1.0
	var range_y := max_y - min_y if max_y != min_y else 1.0
	var range_z := max_z - min_z if max_z != min_z else 1.0
	var tw := maxf(chart_size.x - margin * 2.0, 0.01)
	var th := maxf(chart_size.y - margin * 2.0, 0.01)
	var td := maxf(minf(chart_size.x, chart_size.y) - margin * 2.0, 0.01)
	var result: Dictionary = {}
	for id in raw:
		var p: Vector3 = raw[id]
		result[id] = Vector3(
			margin + (p.x - min_x) / range_x * tw,
			margin + (p.y - min_y) / range_y * th,
			(p.z - min_z) / range_z * td - td * 0.5
		)
	return result

# ---------------------------------------------------------------------------
# Differential node sync
# ---------------------------------------------------------------------------

func _sync_nodes(nodes: Array, layout: Dictionary) -> void:
	var new_ids: Dictionary = {}
	for n in nodes:
		new_ids[str(n.get("id", ""))] = n

	for id in _node_instances.keys():
		if not new_ids.has(id):
			_collapse_and_free(id)

	_assign_type_indices(nodes)

	for id in new_ids:
		var n: Dictionary = new_ids[id]
		var pos: Vector3 = layout.get(id, Vector3.ZERO)
		if _node_instances.has(id):
			(_node_instances[id] as Node3D).position = pos
		else:
			var inst := _create_node_instance(n, pos)
			_node_container.add_child(inst)
			_node_instances[id] = inst
			_pop_in(inst)


func _create_node_instance(n: Dictionary, pos: Vector3) -> Node3D:
	var ntype := str(n.get("type", ""))
	var color := _get_type_color(ntype)

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

	var mat: Material
	if node_type_materials.has(ntype) and node_type_materials[ntype] is Material:
		mat = node_type_materials[ntype] as Material
	else:
		mat = _create_material(color)

	var mi := MeshInstance3D.new()
	mi.mesh = _DEFAULT_NODE_MESH
	mi.scale = Vector3.ONE * node_radius
	mi.material_override = mat
	mi.position = pos
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
		var v0: Vector3 = layout[src]
		var v1: Vector3 = layout[tgt]

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

	var mi := MeshInstance3D.new()
	mi.mesh = _DEFAULT_ARROW_HEAD
	mi.scale = Vector3(edge_width * 2.5, edge_width * 5.0, edge_width * 2.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mat if mat != null else _create_unshaded_material(Color(0.6, 0.6, 0.65))
	mi.position = tip_pos

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
		var pos: Vector3 = layout.get(id, Vector3.ZERO)
		var lbl := _make_label(lbl_text, pos + Vector3(0.0, node_radius + 0.12, 0.0), 44)
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
		var mid := ((layout[src] as Vector3) + (layout[tgt] as Vector3)) * 0.5
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
	_spring_running = false
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
			{"id": "A", "label": "Alpha",   "type": "source", "x": 0.0, "y": 0.0, "z": 0.0},
			{"id": "B", "label": "Beta",    "type": "node",   "x": 1.0, "y": 0.5, "z": 0.5},
			{"id": "C", "label": "Gamma",   "type": "node",   "x": 0.5, "y": 1.0, "z": 0.2},
			{"id": "D", "label": "Delta",   "type": "node",   "x": 0.2, "y": 0.5, "z": 1.0},
			{"id": "E", "label": "Epsilon", "type": "sink",   "x": 0.8, "y": 0.2, "z": 0.8},
		],
		"edges": [
			{"source": "A", "target": "B", "directed": true},
			{"source": "A", "target": "C", "directed": true},
			{"source": "B", "target": "E", "directed": true},
			{"source": "C", "target": "D"},
			{"source": "D", "target": "E", "directed": true},
		],
	}
