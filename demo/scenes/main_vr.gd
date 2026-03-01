## Godot Charts — VR demo.
##
## Initialises OpenXR on startup.  Run with a VR headset connected and the
## correct runtime set as the system OpenXR runtime:
##   • Windows  : ALVR + SteamVR  (see README — VR Quickstart)
##   • Linux    : WiVRn            (see README — VR Quickstart)
##
## [b]Controls[/b] (standard Godot XR Tools defaults)
## Left thumbstick  — direct movement (forward/back/strafe)
## Left thumbstick  — snap turn (with MovementTurn node)
## Right trigger    — aim teleport arc, release to teleport
##
## The data room is the same [DataRoom] subscene as the desktop demo, so any
## change to chart data or layout automatically appears in both scenes.
extends Node3D


func _ready() -> void:
	var openxr := XRServer.find_interface("OpenXR")
	if openxr and openxr.initialize():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		print("OpenXR initialised — headset active.")
	else:
		push_warning("OpenXR not available — headset not connected or runtime not set. See README for VR Quickstart.")
