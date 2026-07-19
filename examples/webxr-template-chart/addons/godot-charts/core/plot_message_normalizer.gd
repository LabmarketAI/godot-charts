class_name PlotMessageNormalizer
extends RefCounted

const Figure = preload("res://addons/godot-charts/core/plot_figure.gd")
const Categorical = preload("res://addons/godot-charts/core/categorical_scale.gd")
const Guide = preload("res://addons/godot-charts/core/plot_guide.gd")
const Layer = preload("res://addons/godot-charts/core/plot_layer.gd")
const Scale = preload("res://addons/godot-charts/core/linear_scale.gd")
const Table = preload("res://addons/godot-charts/core/plot_table.gd")
const View = preload("res://addons/godot-charts/core/plot_view.gd")


func normalize(message: Dictionary) -> Dictionary:
	var diagnostics: Array[Dictionary] = []
	var source_figure: Dictionary = message["payload"]["figure"]
	var tables: Dictionary = {}
	for table_index: int in source_figure["data"].size():
		var source_table: Dictionary = source_figure["data"][table_index]
		var table = Table.new(
			source_table["id"],
			int(source_table["revision"]),
			PackedStringArray(source_table["row_ids"]),
			source_table["columns"]
		)
		diagnostics.append_array(table.validate("/payload/figure/data/%d" % table_index))
		tables[table.id] = table

	var views: Array[RefCounted] = []
	for view_index: int in source_figure["views"].size():
		var source_view: Dictionary = source_figure["views"][view_index]
		var layers: Array[RefCounted] = []
		for layer_index: int in source_view["layers"].size():
			var source_layer: Dictionary = source_view["layers"][layer_index]
			var layer = Layer.new(source_layer["id"], source_layer["mark"], source_layer["data_id"], source_layer["mappings"])
			layers.append(layer)
			_validate_layer(layer, tables, "/payload/figure/views/%d/layers/%d" % [view_index, layer_index], diagnostics)
		var scales: Dictionary = {}
		for channel: Variant in source_view["scales"]:
			var source_scale: Dictionary = source_view["scales"][channel]
			var scale: RefCounted
			if source_scale["type"] == "categorical":
				scale = Categorical.new(PackedStringArray(source_scale["domain"]), source_scale["range"])
			else:
				var domain: Array = source_scale["domain"]
				var extent: Array = source_scale.get("extent", domain)
				scale = Scale.new(float(domain[0]), float(domain[1]), 0.0, 1.0, bool(source_scale.get("clamp", false)), float(extent[0]), float(extent[1]))
				if scale.has_method("configure_viewport"):
					scale.configure_viewport(
						float(extent[0]),
						float(extent[1]),
						float(domain[0]),
						float(domain[1]),
						source_scale.get("min_span", null),
						source_scale.get("max_span", null),
						float(source_scale.get("focus", 0.5)),
						bool(source_scale.get("allow_overscroll", false))
					)
			diagnostics.append_array(scale.validate("/payload/figure/views/%d/scales/%s" % [view_index, channel]))
			scales[channel] = scale
		var guides: Array[RefCounted] = []
		for source_guide: Dictionary in source_view["guides"]:
			guides.append(Guide.new(source_guide["id"], source_guide["type"], source_guide["channel"], source_guide["title"]))
		views.append(View.new(source_view["id"], source_view["coordinate_system"], layers, scales, guides))

	if not diagnostics.is_empty():
		return {"figure": null, "diagnostics": diagnostics}
	return {
		"figure": Figure.new(
			source_figure["id"], message["plot_id"], int(message["revision"]), source_figure.get("title", ""),
			views, tables, message["producer"], message["provenance"]
		),
		"diagnostics": diagnostics,
	}


func _validate_layer(layer: RefCounted, tables: Dictionary, path: String, diagnostics: Array[Dictionary]) -> void:
	if not tables.has(layer.data_id):
		diagnostics.append(_error("missing-table", "Layer references an unavailable table.", path + "/data_id"))
		return
	var table: RefCounted = tables[layer.data_id]
	for channel: Variant in layer.mappings:
		var column_id: String = layer.mappings[channel]
		if not table.columns.has(column_id):
			diagnostics.append(_error("missing-column", "Layer mapping references an unavailable column.", path + "/mappings/%s" % channel))


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
