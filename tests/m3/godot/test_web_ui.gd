extends SceneTree

var _failures := 0


func _initialize() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var controls: HFlowContainer = app.get_node("CanvasLayer/PointerControls")
	_assert(controls.get_child_count() == 18, "flat-web workflow exposes every pointer control")
	var xr_status: Label = app.get_node("CanvasLayer/WebXrStatus")
	_assert(not xr_status.text.is_empty(), "WebXR availability has a persistent textual explanation")
	var frame: Node3D = app.get_node("AnalyticalFrame3D")
	var before := frame.position
	_press(controls, "ModeFrame")
	_press(controls, "SelectFrame")
	_press(controls, "BeginMove")
	_press(controls, "Right")
	_press(controls, "Commit")
	_assert(frame.position.is_equal_approx(before + Vector3(0.25, 0.0, 0.0)), "pointer workflow commits frame movement")
	_press(controls, "Undo")
	_assert(frame.position.is_equal_approx(before), "pointer undo restores exact frame position")
	_press(controls, "Redo")
	_assert(frame.position.is_equal_approx(before + Vector3(0.25, 0.0, 0.0)), "pointer redo reapplies movement")
	_press(controls, "Reset")
	_assert(frame.position.is_equal_approx(before), "pointer reset restores authored position")
	var status: Label = app.get_node("CanvasLayer/Status")
	_assert("Pointer control" in status.text and "capture none" in status.text, "pointer actions update readable status")
	app.queue_free()

	if _failures == 0:
		print("Godot Charts M3 flat-web UI tests passed.")
		quit(0)
	else:
		push_error("M3 flat-web UI tests failed: %d assertion(s)." % _failures)
		quit(1)


func _press(container: Control, child_name: String) -> void:
	var button: Button = container.get_node(child_name)
	_assert(not button.disabled and button.visible, "pointer control is operable: " + child_name)
	button.pressed.emit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
