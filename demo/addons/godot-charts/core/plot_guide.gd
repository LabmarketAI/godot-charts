class_name PlotGuide
extends RefCounted

var id: String
var type: String
var channel: String
var title: String


func _init(guide_id: String, guide_type: String, guide_channel: String, guide_title: String) -> void:
	id = guide_id
	type = guide_type
	channel = guide_channel
	title = guide_title


func to_dictionary() -> Dictionary:
	return {"id": id, "type": type, "channel": channel, "title": title}
