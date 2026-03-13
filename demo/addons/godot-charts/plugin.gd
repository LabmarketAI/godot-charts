@tool
extends EditorPlugin


func _get_plugin_name() -> String:
	return "Godot Charts"


func _enable_plugin() -> void:
	add_custom_type(
		"ChartDataSource",
		"Resource",
		load("res://addons/godot-charts/utils/ChartDataSource.cs"),
		null
	)
	add_custom_type(
		"DictDataSource",
		"Resource",
		load("res://addons/godot-charts/utils/DictDataSource.cs"),
		null
	)
	add_custom_type(
		"CSVDataSource",
		"Resource",
		load("res://addons/godot-charts/utils/CsvDataSource.cs"),
		null
	)
	add_custom_type(
		"StreamDataSource",
		"Resource",
		load("res://addons/godot-charts/utils/StreamDataSource.cs"),
		null
	)
	add_custom_type(
		"GraphNetworkDataSource",
		"Resource",
		load("res://addons/godot-charts/utils/GraphNetworkDataSource.cs"),
		null
	)
	add_custom_type(
		"ChartFrame3D",
		"Node3D",
		load("res://addons/godot-charts/charts/ChartFrame3D.cs"),
		null
	)
	add_custom_type(
		"PointChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/PointChart3D.cs"),
		null
	)
	add_custom_type(
		"BarChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/BarChart3D.cs"),
		null
	)
	add_custom_type(
		"LineChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/LineChart3D.cs"),
		null
	)
	add_custom_type(
		"ScatterChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/ScatterChart3D.cs"),
		null
	)
	add_custom_type(
		"SurfaceChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/SurfaceChart3D.cs"),
		null
	)
	add_custom_type(
		"HistogramChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/HistogramChart3D.cs"),
		null
	)
	add_custom_type(
		"GraphNetworkChart3D",
		"Node3D",
		load("res://addons/godot-charts/charts/GraphNetworkChart3D.cs"),
		null
	)
	add_custom_type(
		"CircuitChart3D",
		"Node3D",
		load("res://addons/godot-charts/circuits/CircuitChart3D.cs"),
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
