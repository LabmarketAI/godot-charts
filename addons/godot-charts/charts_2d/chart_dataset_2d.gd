@tool
class_name ChartDataset2D
extends Resource

## One named numeric series for categorical or longitudinal 2D charts.

@export var label := "":
	set(value):
		label = value
		emit_changed()
@export var values := PackedFloat32Array():
	set(value):
		values = value
		emit_changed()
@export var color := Color.TRANSPARENT:
	set(value):
		color = value
		emit_changed()
@export var visible := true:
	set(value):
		visible = value
		emit_changed()


func _init(
		series_label: String = "",
		series_values: PackedFloat32Array = PackedFloat32Array(),
		series_color: Color = Color.TRANSPARENT
) -> void:
	label = series_label
	values = series_values
	color = series_color
