## Godot Charts — full demo.
##
## Seven chart frames are pre-placed in the scene at octagon positions, each
## facing inward.  Charts sit 1 unit above the ground plane.
##
## Layout (top view, 7 of 8 octagon vertices, clockwise from +Z):
##   slot 0  (  0°) BarChart3D       slot 1  ( 45°) LineChart3D
##   slot 2  ( 90°) ScatterChart3D   slot 3  (135°) SurfaceChart3D
##   slot 4  (180°) HistogramChart3D slot 5  (225°) GraphNet2D
##   slot 6  (270°) GraphNet3D       [315° empty]
##
## Press [1]–[7] to snap the camera to that chart's radial viewing position.
extends Node3D

const FRAME_W        := 5.0
const FRAME_H        := 4.0
const OCTAGON_RADIUS := 7.5   # distance from origin to frame anchor
const CHART_Y        := 1.0   # Y of frame base (1 unit above ground)
const CAMERA_INSET   := 4.5   # how far inside the octagon the fly-to cam sits

# Precomputed octagon anchor positions and Y-rotation angles for all 7 slots.
# slot angle = slot_index * TAU / 8; rotation.y = angle + PI (inward-facing).
const _SLOT_ANCHORS = [
	Vector3(0.0,       1.0,  7.5),       # slot 0  (  0°)
	Vector3(5.303301,  1.0,  5.303301),   # slot 1  ( 45°)
	Vector3(7.5,       1.0,  0.0),        # slot 2  ( 90°)
	Vector3(5.303301,  1.0, -5.303301),   # slot 3  (135°)
	Vector3(0.0,       1.0, -7.5),        # slot 4  (180°)
	Vector3(-5.303301, 1.0, -5.303301),   # slot 5  (225°)
	Vector3(-7.5,      1.0,  0.0),        # slot 6  (270°)
]
const _SLOT_ANGLES = [
	0.0,               # slot 0
	PI / 4.0,          # slot 1
	PI / 2.0,          # slot 2
	3.0 * PI / 4.0,    # slot 3
	PI,                # slot 4
	5.0 * PI / 4.0,    # slot 5
	3.0 * PI / 2.0,    # slot 6
]

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_show_hint()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key_event := event as InputEventKey
	var k: int = key_event.keycode
	if k >= KEY_1 and k <= KEY_7:
		_fly_to(k - KEY_1)


## Snap the camera to the radial viewing position for chart [param idx].
## The camera sits CAMERA_INSET units inside the octagon on the same radial
## line as the chart, looking at the centre of its face.
func _fly_to(idx: int) -> void:
	var pos   := _SLOT_ANCHORS[idx]
	var angle := _SLOT_ANGLES[idx]

	# Camera on the same radial, inset toward the origin.
	var cam_r   := OCTAGON_RADIUS - CAMERA_INSET
	var cam_pos := Vector3(sin(angle) * cam_r, CHART_Y + FRAME_H * 0.4, cos(angle) * cam_r)
	_camera.position = cam_pos

	# World-space centre of the frame's visible face.
	# Frame local +X in world after rotation by (angle + PI): (-cos(angle), 0, sin(angle))
	var local_x := Vector3(-cos(angle), 0.0, sin(angle))
	var face_centre := pos + local_x * (FRAME_W * 0.5) + Vector3(0.0, FRAME_H * 0.5, 0.0)
	_camera.look_at(face_centre, Vector3.UP)


func _show_hint() -> void:
	print("Godot Charts Demo — press [1]-[7] to fly to each chart")
