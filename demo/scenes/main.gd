## Godot Charts — desktop demo.
##
## Seven chart frames are arranged at octagon positions around a central room.
## Walk with WASD, look with the mouse.  Press [1]–[7] to instantly teleport
## to the viewing position in front of each chart.
## Press [Escape] to release / recapture the mouse cursor.
##
## Layout (top view, 7 of 8 octagon vertices, clockwise from +Z):
##   slot 0  (  0°) BarChart3D       slot 1  ( 45°) LineChart3D
##   slot 2  ( 90°) ScatterChart3D   slot 3  (135°) SurfaceChart3D
##   slot 4  (180°) HistogramChart3D slot 5  (225°) GraphNet2D
##   slot 6  (270°) GraphNet3D       [315° empty]
extends Node3D

const FRAME_H        := 4.0
const OCTAGON_RADIUS := 7.5   # distance from origin to frame anchor
const CAMERA_INSET   := 4.5   # inset from octagon radius to viewing position

# Precomputed octagon anchor positions and Y-rotation angles for all 7 slots.
const _SLOT_ANCHORS: Array[Vector3] = [
	Vector3(0.0,       1.0,  7.5),       # slot 0  (  0°)
	Vector3(5.303301,  1.0,  5.303301),   # slot 1  ( 45°)
	Vector3(7.5,       1.0,  0.0),        # slot 2  ( 90°)
	Vector3(5.303301,  1.0, -5.303301),   # slot 3  (135°)
	Vector3(0.0,       1.0, -7.5),        # slot 4  (180°)
	Vector3(-5.303301, 1.0, -5.303301),   # slot 5  (225°)
	Vector3(-7.5,      1.0,  0.0),        # slot 6  (270°)
]
const _SLOT_ANGLES: Array[float] = [
	0.0,
	PI / 4.0,
	PI / 2.0,
	3.0 * PI / 4.0,
	PI,
	5.0 * PI / 4.0,
	3.0 * PI / 2.0,
]

@onready var _player: CharacterBody3D = $FPSPlayer


func _ready() -> void:
	_show_hint()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var k: int = (event as InputEventKey).keycode
	if k >= KEY_1 and k <= KEY_7:
		_fly_to(k - KEY_1)


## Teleport the player to the radial viewing position for chart [param idx].
## The player stands 3 m in front of the chart frame and faces the chart centre.
func _fly_to(idx: int) -> void:
	var angle: float    = _SLOT_ANGLES[idx]
	var cam_r           := OCTAGON_RADIUS - CAMERA_INSET  # = 3.0 m
	var player_pos      := Vector3(sin(angle) * cam_r, 0.9, cos(angle) * cam_r)
	var anchor: Vector3  = _SLOT_ANCHORS[idx]
	var chart_centre    := anchor + Vector3(0.0, FRAME_H * 0.5, 0.0)
	_player.teleport_to(player_pos, chart_centre)


func _show_hint() -> void:
	print("Godot Charts Demo — WASD to walk, mouse to look, [1]-[7] to jump to a chart, [Esc] to toggle mouse lock.")
