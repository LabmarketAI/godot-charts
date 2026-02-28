@tool
class_name GraphNetworkChart3D
extends GraphNetworkChartBase

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

## When [code]true[/code], the spring layout runs one iteration per
## [code]_process[/code] tick so nodes visibly settle into position.
## When [code]false[/code] (default), all iterations run synchronously.
@export var spring_per_frame: bool = false :
	set(v):
		spring_per_frame = v
		_queue_rebuild()

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
		layout = _compute_layout(nodes, edges)

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

func _compute_layout(nodes: Array, edges: Array) -> Dictionary:
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
# Demo data
# ---------------------------------------------------------------------------

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
