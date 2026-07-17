class_name FigureDiff
extends RefCounted

var from_revision: int
var to_revision: int
var changed_tables: PackedStringArray = []
var changed_views: PackedStringArray = []
var changed_layers: PackedStringArray = []
var changed_scales: PackedStringArray = []
var changed_guides: PackedStringArray = []
var added_row_ids: PackedStringArray = []
var removed_row_ids: PackedStringArray = []


static func between(previous: RefCounted, current: RefCounted) -> RefCounted:
	var result: RefCounted = load("res://addons/godot-charts/core/figure_diff.gd").new()
	result.from_revision = previous.revision
	result.to_revision = current.revision
	result._compare_tables(previous, current)
	result._compare_views(previous, current)
	return result


func is_empty() -> bool:
	return changed_tables.is_empty() and changed_views.is_empty() and changed_layers.is_empty() and changed_scales.is_empty() and changed_guides.is_empty()


func to_dictionary() -> Dictionary:
	return {
		"from_revision": from_revision,
		"to_revision": to_revision,
		"changed_tables": Array(changed_tables),
		"changed_views": Array(changed_views),
		"changed_layers": Array(changed_layers),
		"changed_scales": Array(changed_scales),
		"changed_guides": Array(changed_guides),
		"added_row_ids": Array(added_row_ids),
		"removed_row_ids": Array(removed_row_ids),
	}


func _compare_tables(previous: RefCounted, current: RefCounted) -> void:
	for table_id: Variant in previous.tables:
		if not current.tables.has(table_id):
			changed_tables.append(table_id)
			for row_id: String in previous.tables[table_id].row_ids:
				removed_row_ids.append(row_id)
			continue
		var old_table: RefCounted = previous.tables[table_id]
		var new_table: RefCounted = current.tables[table_id]
		if old_table.to_dictionary() != new_table.to_dictionary():
			changed_tables.append(table_id)
		for row_id: String in old_table.row_ids:
			if not new_table.has_row(row_id):
				removed_row_ids.append(row_id)
		for row_id: String in new_table.row_ids:
			if not old_table.has_row(row_id):
				added_row_ids.append(row_id)
	for table_id: Variant in current.tables:
		if previous.tables.has(table_id):
			continue
		changed_tables.append(table_id)
		for row_id: String in current.tables[table_id].row_ids:
			added_row_ids.append(row_id)


func _compare_views(previous: RefCounted, current: RefCounted) -> void:
	for new_view: RefCounted in current.views:
		var old_view: RefCounted = previous.view(new_view.id)
		if old_view == null:
			changed_views.append(new_view.id)
			continue
		for new_layer: RefCounted in new_view.layers:
			var old_layer: RefCounted = old_view.layer(new_layer.id)
			if old_layer == null or old_layer.to_dictionary() != new_layer.to_dictionary():
				changed_layers.append(new_layer.id)
		for channel: Variant in new_view.scales:
			if not old_view.scales.has(channel) or old_view.scales[channel].to_dictionary() != new_view.scales[channel].to_dictionary():
				changed_scales.append("%s:%s" % [new_view.id, channel])
		var old_guides: Array[Dictionary] = []
		for guide: RefCounted in old_view.guides:
			old_guides.append(guide.to_dictionary())
		var new_guides: Array[Dictionary] = []
		for guide: RefCounted in new_view.guides:
			new_guides.append(guide.to_dictionary())
		if old_guides != new_guides:
			changed_guides.append(new_view.id)
