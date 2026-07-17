extends SceneTree

const Binding = preload("res://addons/godot-charts/frames/frame_binding.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")

var _failures := 0


func _initialize() -> void:
	var binding = Binding.new("live_plot", "plot-annual-trials", "follow_source", 2, {"transport": "websocket"})
	_assert(binding.validate().is_empty(), "valid live binding passes")
	var authored := Transform3D(Basis.from_euler(Vector3(0.1, 0.4, 0.0)).scaled(Vector3(1.2, 1.2, 1.2)), Vector3(2.0, 1.0, -3.0))
	var state = FrameState.new("frame-annual-trials", authored, Vector3(6.0, 4.0, 2.5), "Annual trials", binding)
	state.local_view_state = {"orientation": [0.2, 0.5, 0.0], "selected_view_id": "view-main"}
	_assert(state.validate().is_empty(), "valid frame state passes")
	_assert(state.binding.source_id == "plot-annual-trials", "frame retains binding identity")

	var encoded := state.to_dictionary()
	var decoded = FrameState.from_dictionary(encoded)
	_assert(decoded.validate().is_empty(), "round-tripped frame validates")
	_assert(decoded.to_dictionary() == encoded, "frame serialization round-trips deterministically")
	_assert(decoded.transform.is_equal_approx(authored), "frame transform round-trips")
	_assert(decoded.authored_transform.is_equal_approx(authored), "authored reset transform round-trips")
	_assert(decoded.binding.to_dictionary() == binding.to_dictionary(), "binding serialization round-trips")

	decoded.transform = Transform3D(Basis.IDENTITY, Vector3(9.0, 8.0, 7.0))
	decoded.local_view_state["orientation"] = [1.0, 1.0, 1.0]
	decoded.reset_to_authored()
	_assert(decoded.transform.is_equal_approx(authored), "reset restores exact authored transform")
	_assert(decoded.local_view_state.is_empty(), "reset clears local view overrides")
	decoded.transform = Transform3D(Basis.IDENTITY, Vector3(-2.0, 3.0, 4.0))
	decoded.capture_authored_state()
	decoded.transform = Transform3D.IDENTITY
	decoded.reset_to_authored()
	_assert(decoded.transform.origin.is_equal_approx(Vector3(-2.0, 3.0, 4.0)), "captured authored state becomes reset target")

	var invalid_binding = Binding.new("socket", "", "automatic", -1)
	var invalid_codes := _codes(invalid_binding.validate())
	_assert("invalid-binding-kind" in invalid_codes, "invalid binding kind is diagnosed")
	_assert("empty-binding-source" in invalid_codes, "empty binding source is diagnosed")
	_assert("invalid-representation-policy" in invalid_codes, "invalid representation policy is diagnosed")
	_assert("invalid-source-revision" in invalid_codes, "invalid source revision is diagnosed")
	var invalid_state = FrameState.new("", Transform3D.IDENTITY, Vector3(0.0, 2.0, 3.0), "", invalid_binding)
	invalid_state.source_status = "unknown"
	invalid_state.aspect_policy = "stretch-data"
	invalid_state.theme_ref = ""
	var invalid_frame_codes := _codes(invalid_state.validate())
	_assert("empty-frame-id" in invalid_frame_codes, "empty frame identity is diagnosed")
	_assert("invalid-frame-bounds" in invalid_frame_codes, "invalid frame bounds are diagnosed")
	_assert("invalid-source-status" in invalid_frame_codes, "invalid source status is diagnosed")
	_assert("invalid-aspect-policy" in invalid_frame_codes, "invalid aspect policy is diagnosed")
	_assert("empty-theme-reference" in invalid_frame_codes, "empty theme reference is diagnosed")
	_assert("invalid-binding-kind" in invalid_frame_codes, "binding diagnostics retain frame path")

	if _failures == 0:
		print("Godot Charts M2 frame-state tests passed.")
		quit(0)
	else:
		push_error("M2 frame-state tests failed: %d assertion(s)." % _failures)
		quit(1)


func _codes(diagnostics: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for diagnostic: Dictionary in diagnostics:
		result.append(diagnostic["code"])
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
