@tool
extends EditorPlugin


func _get_plugin_name() -> String:
	return "Godot Charts"


func _enable_plugin() -> void:
	add_custom_type(
		"ChartFrame3D",
		"Node3D",
		preload("charts/chart_frame_3d.gd"),
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


func _disable_plugin() -> void:
	remove_custom_type("ChartFrame3D")
	remove_custom_type("BarChart3D")
	remove_custom_type("LineChart3D")
	remove_custom_type("ScatterChart3D")
	remove_custom_type("SurfaceChart3D")
