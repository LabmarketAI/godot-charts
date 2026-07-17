class_name PlotView
extends RefCounted

var id: String
var coordinate_system: String
var layers: Array[RefCounted]
var scales: Dictionary
var guides: Array[RefCounted]


func _init(view_id: String, coordinates: String, view_layers: Array[RefCounted], view_scales: Dictionary, view_guides: Array[RefCounted]) -> void:
	id = view_id
	coordinate_system = coordinates
	layers = view_layers.duplicate()
	scales = view_scales.duplicate()
	guides = view_guides.duplicate()


func layer(layer_id: String) -> RefCounted:
	for candidate: RefCounted in layers:
		if candidate.id == layer_id:
			return candidate
	return null


func to_dictionary() -> Dictionary:
	var layer_values: Array[Dictionary] = []
	for candidate: RefCounted in layers:
		layer_values.append(candidate.to_dictionary())
	var scale_values: Dictionary = {}
	for channel: Variant in scales:
		scale_values[channel] = scales[channel].to_dictionary()
	var guide_values: Array[Dictionary] = []
	for guide: RefCounted in guides:
		guide_values.append(guide.to_dictionary())
	return {"id": id, "coordinate_system": coordinate_system, "layers": layer_values, "scales": scale_values, "guides": guide_values}
