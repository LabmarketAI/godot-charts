class_name PlotLayer
extends RefCounted

var id: String
var mark: String
var data_id: String
var mappings: Dictionary


func _init(layer_id: String, layer_mark: String, layer_data_id: String, layer_mappings: Dictionary) -> void:
	id = layer_id
	mark = layer_mark
	data_id = layer_data_id
	mappings = layer_mappings.duplicate(true)


func to_dictionary() -> Dictionary:
	return {"id": id, "mark": mark, "data_id": data_id, "mappings": mappings.duplicate(true)}
