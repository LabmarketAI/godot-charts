@tool
class_name StreamDataSource
extends ChartDataSource

## A [ChartDataSource] that maintains a rolling window of real-time data points.
##
## Call [method append_point] (or [method append_frame]) from any game loop,
## physics process, or timer callback.  The source keeps a fixed-size FIFO buffer
## per series; oldest points are dropped when [member max_window] is exceeded.
## [signal ChartDataSource.data_updated] is emitted after every append so any
## connected [LineChart3D] or [BarChart3D] redraws immediately.
##
## [b]Single-series usage[/b]
## [codeblock]
## var stream := StreamDataSource.new()
## stream.max_window = 60
## my_chart.data_source = stream
##
## func _process(delta: float) -> void:
##     stream.append_point("FPS", Engine.get_frames_per_second())
## [/codeblock]
##
## [b]Multi-series usage[/b] (append several series atomically per frame)
## [codeblock]
## func _physics_process(_delta: float) -> void:
##     stream.append_frame({
##         "CPU": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
##         "GPU": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
##     })
## [/codeblock]

## Maximum number of data points kept per series.
## Older points are discarded when the buffer exceeds this size.
@export_range(2, 1000, 1) var max_window: int = 50

# Ring buffer per series name.  Ordered dict so series appear in insertion order.
var _buffers: Dictionary = {}   # String -> Array[float]
var _series_order: Array = []   # preserves insertion order


## Append a single data point to the named series.
## If the series does not yet exist it is created automatically.
## Emits [signal ChartDataSource.data_updated] after updating the buffer.
func append_point(series: String, value: float) -> void:
	_ensure_series(series)
	_push(_buffers[series] as Array, value)
	data_updated.emit(get_data())


## Append one data point to each series in [param frame] simultaneously.
## [param frame] is a [Dictionary] mapping series name ([String]) → value ([float]).
## All series are updated before the signal fires, so the chart sees a consistent
## snapshot.
func append_frame(frame: Dictionary) -> void:
	for series_name: String in frame:
		_ensure_series(series_name)
		_push(_buffers[series_name] as Array, float(frame[series_name]))
	data_updated.emit(get_data())


## Remove all buffered data and emit [signal ChartDataSource.data_updated] with
## an empty dictionary.
func clear_data() -> void:
	_buffers.clear()
	_series_order.clear()
	data_updated.emit({})


## Return the list of series names in the order they were first added.
func get_series_names() -> Array:
	return _series_order.duplicate()


func get_data() -> Dictionary:
	if _series_order.is_empty():
		return {}

	var max_len: int = 0
	for s: String in _series_order:
		max_len = maxi(max_len, (_buffers[s] as Array).size())

	var labels: Array[String] = []
	for i in max_len:
		labels.append(str(i))

	var datasets: Array = []
	for s: String in _series_order:
		datasets.append({
			"name": s,
			"values": (_buffers[s] as Array).duplicate(),
		})

	return {"labels": Array(labels), "datasets": datasets}


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _ensure_series(series: String) -> void:
	if not _buffers.has(series):
		_buffers[series] = []
		_series_order.append(series)


func _push(buf: Array, value: float) -> void:
	buf.append(value)
	while buf.size() > max_window:
		buf.pop_front()
