@tool
class_name ChartReferenceLine2D
extends Resource

## A labeled horizontal reference value such as a target or warning threshold.

@export var value := 0.0:
	set(next_value):
		value = next_value
		emit_changed()
@export var label := "":
	set(next_value):
		label = next_value
		emit_changed()
@export var color := Color(1.0, 0.75, 0.2, 0.9):
	set(next_value):
		color = next_value
		emit_changed()
@export_range(1.0, 8.0, 0.5) var width := 2.0:
	set(next_value):
		width = next_value
		emit_changed()


func _init(
		line_value := 0.0,
		line_label := "",
		line_color := Color(1.0, 0.75, 0.2, 0.9)
) -> void:
	value = line_value
	label = line_label
	color = line_color
