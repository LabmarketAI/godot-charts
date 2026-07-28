@tool
class_name ChartAxis2D
extends Resource

## Named Y axis used by one or more datasets in an overlaid multi-axis chart.

enum Side { LEFT, RIGHT }

@export var axis_id: StringName = &"y":
	set(value):
		axis_id = value
		emit_changed()
@export var label := "":
	set(value):
		label = value
		emit_changed()
@export var side := Side.LEFT:
	set(value):
		side = value
		emit_changed()
@export var color := Color.TRANSPARENT:
	set(value):
		color = value
		emit_changed()
@export var begin_at_zero := false:
	set(value):
		begin_at_zero = value
		emit_changed()
@export var domain_override_enabled := false:
	set(value):
		domain_override_enabled = value
		emit_changed()
@export var domain_override := Vector2(0.0, 1.0):
	set(value):
		domain_override = value
		emit_changed()


func _init(
		id: StringName = &"y",
		axis_label := "",
		axis_side := Side.LEFT,
		axis_color := Color.TRANSPARENT,
		zero_based := false
) -> void:
	axis_id = id
	label = axis_label
	side = axis_side
	color = axis_color
	begin_at_zero = zero_based
