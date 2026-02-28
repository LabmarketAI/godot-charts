@tool
class_name HistogramChart3D
extends BarChart3D

## A 3D histogram that automatically bins raw float data.
##
## Accepts a flat array of floats via [member raw_data], bins them with
## [ChartBinner], then renders the resulting bar chart using the inherited
## [BarChart3D] rendering pipeline.
##
## Bin count is determined by [member n_bins] (0 = use [method ChartBinner.suggest_bin_count]).
## Set [member bin_edges] to override with explicit bin boundaries (manual mode).
##
## [b]Usage[/b]
## [codeblock]
## var hist := HistogramChart3D.new()
## hist.raw_data = [1.2, 2.3, 3.1, 2.8, 1.9, 3.5, 2.2]
## hist.n_bins = 5
## add_child(hist)
## [/codeblock]
##
## [b]Manual binning[/b]
## [codeblock]
## hist.bin_edges = [0.0, 1.0, 2.0, 3.0, 4.0]   # 4 bins of width 1.0
## [/codeblock]

# ---------------------------------------------------------------------------
# Exported properties
# ---------------------------------------------------------------------------

## Raw float values to histogram.  Assigning triggers an immediate redraw.
@export var raw_data: Array[float] = [] :
	set(v):
		raw_data = v
		_queue_rebuild()

## Number of bins for automatic binning.
## Set to 0 to use [method ChartBinner.suggest_bin_count] (Sturges' rule).
@export_range(0, 100, 1) var n_bins: int = 10 :
	set(v):
		n_bins = v
		_queue_rebuild()

## Explicit bin edges for manual binning (must be sorted, ≥ 2 values).
## When non-empty, [member n_bins] is ignored.
## Clear this array to revert to automatic binning.
@export var bin_edges: Array[float] = [] :
	set(v):
		bin_edges = v
		_queue_rebuild()

# ---------------------------------------------------------------------------
# Override
# ---------------------------------------------------------------------------

func _rebuild() -> void:
	clear()
	if not is_instance_valid(_container):
		return

	# Use a local variable so demo data never mutates exported properties.
	var source: Array[float] = raw_data
	if source.is_empty():
		source = _demo_raw_data()

	var result: Dictionary
	if bin_edges.size() >= 2:
		result = ChartBinner.manual_bin(source, bin_edges)
	else:
		var k: int = n_bins if n_bins > 0 else ChartBinner.suggest_bin_count(source)
		result = ChartBinner.auto_bin(source, k)

	var edges: Array = result.get("edges", [])
	var counts: Array = result.get("counts", [])
	if counts.is_empty():
		return

	# Build a bar-chart-compatible dict: one dataset, labels = left bin edges.
	var labels: Array = []
	for i in counts.size():
		labels.append("%.2g" % edges[i])

	var float_counts: Array = []
	for c in counts:
		float_counts.append(float(c))

	var hist_data: Dictionary = {
		"labels": labels,
		"datasets": [{"name": y_label if y_label != "Y" else "Count", "values": float_counts}],
	}

	_render_bar_data(hist_data)
	emit_signal("data_changed")


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Returns a fixed 30-point demo dataset used when [member raw_data] is empty.
## Keeping the data local avoids mutating inspector-visible properties.
static func _demo_raw_data() -> Array[float]:
	return [
		1.2, 1.5, 1.8, 2.0, 2.1, 2.3, 2.5, 2.5, 2.7, 2.8,
		3.0, 3.0, 3.1, 3.2, 3.3, 3.3, 3.4, 3.5, 3.5, 3.6,
		3.7, 3.8, 3.9, 4.0, 4.1, 4.2, 4.5, 4.8, 5.0, 5.5,
	]
