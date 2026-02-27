@tool
class_name ChartDataSource
extends Resource

## Abstract base class for all chart data sources.
##
## Sub-classes override [method get_data] to return the chart's data dictionary
## and emit [signal data_updated] whenever the underlying data changes.
## Charts that have a [member Chart3D.data_source] assigned subscribe to
## [signal data_updated] and redraw automatically.
##
## [b]Data contract[/b] — every concrete source must return a dictionary that
## follows the standard chart layout understood by [BarChart3D], [LineChart3D],
## and [ScatterChart3D]:
## [codeblock]
## {
##     "labels":   ["A", "B", "C"],          # optional category / x-axis names
##     "datasets": [
##         {"name": "Series 1", "values": [1.0, 2.0, 3.0]},
##         {"name": "Series 2", "values": [4.0, 5.0, 6.0]},
##     ]
## }
## [/codeblock]
##
## Built-in concrete implementations:
## - [DictDataSource]   — wraps a plain [Dictionary]
## - [CSVDataSource]    — loads and parses a CSV file from disk
## - [StreamDataSource] — maintains a rolling window for real-time data

## Emitted whenever the underlying data changes.
## Connected charts automatically redraw when this fires.
signal data_updated(new_data: Dictionary)

## Returns the current chart data dictionary.
## Override in sub-classes to return actual data; the default returns an empty dict.
func get_data() -> Dictionary:
	return {}
