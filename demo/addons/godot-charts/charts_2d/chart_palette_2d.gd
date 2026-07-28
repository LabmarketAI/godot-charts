@tool
class_name ChartPalette2D
extends Resource

## Colorblind-separated categorical colors ported from bevy-charts.

const DARK_SERIES := [
	Color8(0x39, 0x87, 0xe5),
	Color8(0xd9, 0x59, 0x26),
	Color8(0x19, 0x9e, 0x70),
	Color8(0xc9, 0x85, 0x00),
	Color8(0xd5, 0x51, 0x81),
	Color8(0x00, 0x83, 0x00),
	Color8(0x90, 0x85, 0xe9),
	Color8(0xe6, 0x67, 0x67),
]

@export var background := Color8(0x1c, 0x1e, 0x20):
	set(value):
		background = value
		emit_changed()
@export var foreground := Color8(0xc3, 0xc2, 0xb7):
	set(value):
		foreground = value
		emit_changed()
@export var grid := Color8(0x50, 0x50, 0x4c):
	set(value):
		grid = value
		emit_changed()


func series_color(index: int) -> Color:
	return DARK_SERIES[clampi(index, 0, DARK_SERIES.size() - 1)]
