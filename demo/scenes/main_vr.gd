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
		# Fall back to a desktop camera so the window is not a blank white screen.
		var cam := Camera3D.new()
		cam.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.7, 5.0))
		$XROrigin3D.add_child(cam)
		cam.make_current()

	_setup_desktop_capture.call_deferred()

func _setup_desktop_capture() -> void:
	var panel = $DataRoom/DesktopPanel as MeshInstance3D
	if not panel: return
	var mat = panel.get_surface_override_material(0) as StandardMaterial3D
	if not mat: return
	var tex = mat.albedo_texture
	if not tex or not tex.has_method("get_available_windows"): return
	
	var windows = tex.get_available_windows()
	print("Available windows for capture:")
	var target_id = 0
	for w in windows:
		var title = str(w["title"])
		print(" - ", title, " (ID: ", w["id"], ")")
		if target_id == 0 and title.strip_edges() != "" and title.find("Godot") == -1:
			target_id = w["id"]
			
	if target_id != 0:
		tex.set("window_id", target_id)
		print("Auto-selected window ID: ", target_id)
