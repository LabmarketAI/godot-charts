@tool
class_name DictDataSource
extends ChartDataSource

## A [ChartDataSource] that wraps a plain [Dictionary].
##
## This is the simplest data source and a drop-in upgrade path for charts that
## already use the [code]data: Dictionary[/code] export.  Assign [member source_data]
## from the inspector or from GDScript; the connected chart redraws automatically.
##
## [b]GDScript usage[/b]
## [codeblock]
## var source := DictDataSource.new()
## source.source_data = {
##     "labels": ["Jan", "Feb", "Mar"],
##     "datasets": [{"name": "Revenue", "values": [1.2, 2.8, 2.3]}]
## }
## my_chart.data_source = source
## [/codeblock]
##
## [b]Inspector usage[/b]
## Save this resource as a [code].tres[/code] file, assign it to a chart's
## [code]data_source[/code] export, then edit [member source_data] values live
## in the inspector to see the chart update in the editor viewport.

## The chart data dictionary.
## Assigning triggers [signal ChartDataSource.data_updated] and redraws any
## connected chart.
@export var source_data: Dictionary = {} :
	set(v):
		source_data = v
		data_updated.emit(v)


func get_data() -> Dictionary:
	return source_data
