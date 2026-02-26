@tool
class_name GraphNetworkDataSource
extends ChartDataSource

## A [ChartDataSource] that holds a graph network (nodes + edges).
##
## Supports loading from a JSON file or an inline [Dictionary].  The JSON
## format is a superset compatible with NetworkX / iGraph exports:
##
## [codeblock]
## {
##   "nodes": [
##     { "id": "A", "label": "Alice", "type": "person",
##       "x": 0.2, "y": 0.8, "z": 0.0, "properties": {} }
##   ],
##   "edges": [
##     { "source": "A", "target": "B", "label": "knows",
##       "type": "relation", "weight": 1.0, "directed": false }
##   ]
## }
## [/codeblock]
##
## [b]Mutation API[/b] — call [method add_node], [method remove_node],
## [method add_edge], [method remove_edge] to modify the graph at runtime;
## each emits [signal ChartDataSource.data_updated] automatically.
##
## [b]Hot-reload[/b] — set [member watch_file] = [code]true[/code].
## [GraphNetworkChart2D] and [GraphNetworkChart3D] call [method tick]
## automatically from their [code]_process[/code] loop.

## Path to a JSON file.  Assigning triggers an immediate load.
@export_file("*.json") var file_path: String = "" :
	set(v):
		file_path = v
		if not file_path.is_empty():
			load_from_file(file_path)

## When [code]true[/code], [method tick] re-reads [member file_path] whenever
## the file modification time changes.
@export var watch_file: bool = false

## How often (seconds) the file modification time is checked.
## Ignored when [member watch_file] is [code]false[/code].
@export_range(0.5, 30.0, 0.5) var watch_interval: float = 2.0

# ---- internal state ----
var _nodes: Array = []          # Array[Dictionary]
var _edges: Array = []          # Array[Dictionary]
var _node_map: Dictionary = {}  # id (String) -> index in _nodes
var _watch_elapsed: float = 0.0
var _last_mtime: int = 0

# ---------------------------------------------------------------------------
# Public API — data loading
# ---------------------------------------------------------------------------

## Replace the current graph with [param d] ([code]{ "nodes": [...], "edges": [...] }[/code]).
## Emits [signal ChartDataSource.data_updated].
func load_from_dict(d: Dictionary) -> void:
	_nodes = (d.get("nodes", []) as Array).duplicate(true)
	_edges = (d.get("edges", []) as Array).duplicate(true)
	_rebuild_index()
	data_updated.emit(get_data())


## Load a JSON file from [param path] and replace the current graph.
## Returns [code]true[/code] on success.
func load_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("GraphNetworkDataSource: file not found — %s" % path)
		return false
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		push_warning("GraphNetworkDataSource: cannot open — %s" % path)
		return false
	var text := fa.get_as_text()
	fa.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("GraphNetworkDataSource: invalid JSON in — %s" % path)
		return false
	_last_mtime = FileAccess.get_modified_time(path)
	load_from_dict(parsed as Dictionary)
	return true


## Serialise the current node/edge state to [param path] as formatted JSON.
## Returns [code]true[/code] on success.
func save_to_json(path: String) -> bool:
	var fa := FileAccess.open(path, FileAccess.WRITE)
	if fa == null:
		push_warning("GraphNetworkDataSource: cannot write — %s" % path)
		return false
	fa.store_string(JSON.stringify(get_data(), "\t"))
	fa.close()
	return true

# ---------------------------------------------------------------------------
# Public API — mutation
# ---------------------------------------------------------------------------

## Add or replace a node.  [param props] may contain any keys; [code]id[/code]
## is required and is always set to [param id].
## Emits [signal ChartDataSource.data_updated].
func add_node(id: String, props: Dictionary = {}) -> void:
	var entry := props.duplicate()
	entry["id"] = id
	if _node_map.has(id):
		_nodes[_node_map[id]] = entry
	else:
		_node_map[id] = _nodes.size()
		_nodes.append(entry)
	data_updated.emit(get_data())


## Remove the node with [param id] and all edges incident to it.
## Emits [signal ChartDataSource.data_updated].
func remove_node(id: String) -> void:
	if not _node_map.has(id):
		return
	var idx: int = _node_map[id]
	_nodes.remove_at(idx)
	_edges = _edges.filter(func(e: Dictionary) -> bool:
		return e.get("source", "") != id and e.get("target", "") != id)
	_rebuild_index()
	data_updated.emit(get_data())


## Add an edge from [param source] to [param target].
## [param props] may include [code]label[/code], [code]type[/code],
## [code]weight[/code], [code]directed[/code], etc.
## Emits [signal ChartDataSource.data_updated].
func add_edge(source: String, target: String, props: Dictionary = {}) -> void:
	var entry := props.duplicate()
	entry["source"] = source
	entry["target"] = target
	_edges.append(entry)
	data_updated.emit(get_data())


## Remove the first edge matching [param source] → [param target].
## Emits [signal ChartDataSource.data_updated].
func remove_edge(source: String, target: String) -> void:
	for i in _edges.size():
		var e: Dictionary = _edges[i]
		if e.get("source", "") == source and e.get("target", "") == target:
			_edges.remove_at(i)
			data_updated.emit(get_data())
			return

# ---------------------------------------------------------------------------
# ChartDataSource interface
# ---------------------------------------------------------------------------

func get_data() -> Dictionary:
	return {
		"nodes": _nodes.duplicate(true),
		"edges": _edges.duplicate(true),
	}

# ---------------------------------------------------------------------------
# Hot-reload — called by GraphNetworkChart* from _process
# ---------------------------------------------------------------------------

## Drive file hot-reload.  Call this once per frame (or at your own cadence).
## [GraphNetworkChart2D] and [GraphNetworkChart3D] invoke this automatically.
func tick(delta: float) -> void:
	if not watch_file or file_path.is_empty():
		return
	_watch_elapsed += delta
	if _watch_elapsed < watch_interval:
		return
	_watch_elapsed = 0.0
	if not FileAccess.file_exists(file_path):
		return
	var mtime: int = FileAccess.get_modified_time(file_path)
	if mtime != _last_mtime:
		load_from_file(file_path)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _rebuild_index() -> void:
	_node_map.clear()
	for i in _nodes.size():
		var n: Dictionary = _nodes[i]
		if n.has("id"):
			_node_map[str(n["id"])] = i
