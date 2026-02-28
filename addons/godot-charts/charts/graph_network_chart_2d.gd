@tool
class_name GraphNetworkChart2D
extends GraphNetworkChartBase

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

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	# Drive hot-reload on any GraphNetworkDataSource assigned as data_source.
	if data_source != null and data_source.has_method("tick"):
		data_source.tick(delta)

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
# Demo data
# ---------------------------------------------------------------------------

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
