class_name PlotFigure
extends RefCounted

var id: String
var plot_id: String
var revision: int
var title: String
var views: Array[RefCounted]
var tables: Dictionary
var producer: Dictionary
var provenance: Dictionary


func _init(figure_id: String, source_plot_id: String, figure_revision: int, figure_title: String, figure_views: Array[RefCounted], figure_tables: Dictionary, figure_producer: Dictionary, figure_provenance: Dictionary) -> void:
	id = figure_id
	plot_id = source_plot_id
	revision = figure_revision
	title = figure_title
	views = figure_views.duplicate()
	tables = figure_tables.duplicate()
	producer = figure_producer.duplicate(true)
	provenance = figure_provenance.duplicate(true)


func table(table_id: String) -> RefCounted:
	return tables.get(table_id)


func view(view_id: String) -> RefCounted:
	for candidate: RefCounted in views:
		if candidate.id == view_id:
			return candidate
	return null


func all_row_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for table_id: Variant in tables:
		for row_id: String in tables[table_id].row_ids:
			if not result.has(row_id):
				result.append(row_id)
	return result


func to_dictionary() -> Dictionary:
	var view_values: Array[Dictionary] = []
	for candidate: RefCounted in views:
		view_values.append(candidate.to_dictionary())
	var table_values: Array[Dictionary] = []
	var table_ids: Array = tables.keys()
	table_ids.sort()
	for table_id: Variant in table_ids:
		table_values.append(tables[table_id].to_dictionary())
	return {
		"id": id,
		"plot_id": plot_id,
		"revision": revision,
		"title": title,
		"views": view_values,
		"data": table_values,
		"producer": producer.duplicate(true),
		"provenance": provenance.duplicate(true),
	}
