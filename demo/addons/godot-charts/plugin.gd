@tool
extends EditorPlugin


func _get_plugin_name() -> String:
	return "Godot Charts"


func _enable_plugin() -> void:
	add_custom_type(
		"ChartDataSource",
		"Resource",
		preload("utils/chart_data_source.gd"),
		null
	)
	add_custom_type(
		"DictDataSource",
		"Resource",
		preload("utils/dict_data_source.gd"),
		null
	)
	add_custom_type(
		"CSVDataSource",
		"Resource",
		preload("utils/csv_data_source.gd"),
		null
	)
	add_custom_type(
		"StreamDataSource",
		"Resource",
		preload("utils/stream_data_source.gd"),
		null
	)
	add_custom_type(
		"GraphNetworkDataSource",
		"Resource",
		preload("utils/graph_network_data_source.gd"),
		null
	)
	add_custom_type(
		"ChartFrame3D",
		"Node3D",
		preload("charts/chart_frame_3d.gd"),
		null
	)
	add_custom_type(
		"PointChart3D",
		"Node3D",
		preload("charts/point_chart_3d.gd"),
		null
	)
	add_custom_type(
		"BarChart3D",
		"Node3D",
		preload("charts/bar_chart_3d.gd"),
		null
	)
	add_custom_type(
		"LineChart3D",
		"Node3D",
		preload("charts/line_chart_3d.gd"),
		null
	)
	add_custom_type(
		"ScatterChart3D",
		"Node3D",
		preload("charts/scatter_chart_3d.gd"),
		null
	)
	add_custom_type(
		"SurfaceChart3D",
		"Node3D",
		preload("charts/surface_chart_3d.gd"),
		null
	)
	add_custom_type(
		"HistogramChart3D",
		"Node3D",
		preload("charts/histogram_chart_3d.gd"),
		null
	)
	add_custom_type(
		"GraphNetworkChart3D",
		"Node3D",
		preload("charts/graph_network_chart_3d.gd"),
		null
	)
	add_custom_type(
		"CircuitChart3D",
		"Node3D",
		preload("circuits/circuit_chart_3d.gd"),
		null
	)


func _disable_plugin() -> void:
	remove_custom_type("ChartDataSource")
	remove_custom_type("DictDataSource")
	remove_custom_type("CSVDataSource")
	remove_custom_type("StreamDataSource")
	remove_custom_type("GraphNetworkDataSource")
	remove_custom_type("ChartFrame3D")
	remove_custom_type("PointChart3D")
	remove_custom_type("BarChart3D")
	remove_custom_type("LineChart3D")
	remove_custom_type("ScatterChart3D")
	remove_custom_type("SurfaceChart3D")
	remove_custom_type("HistogramChart3D")
	remove_custom_type("GraphNetworkChart3D")
	remove_custom_type("CircuitChart3D")
