extends Node3D

const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameBinding = preload("res://addons/godot-charts/frames/frame_binding.gd")
const Frame = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const Scatter = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const Guides = preload("res://addons/godot-charts/renderers/cartesian_guides_3d.gd")
const ChartXRHandles = preload("res://game/zones/chart_xr_handles.gd")

@export var frame_bounds := Vector3(3.2, 2.0, 1.6)


func _ready() -> void:
	call_deferred("_build_chart")


func _build_chart() -> void:
	var frame := Frame.new()
	frame.name = "AnnualEnrollmentFrame"
	add_child(frame)

	var scatter := Scatter.new()
	scatter.name = "AnnualEnrollmentScatter"
	scatter.plot_size = frame_bounds
	scatter.point_radius = 0.045

	var guides := Guides.new()
	guides.name = "AnnualEnrollmentGuides"

	var binding := FrameBinding.new("static_plot", "plot-annual-trials", "follow_source", 2)
	var state := FrameState.new(
		"xr-template-chart",
		Transform3D.IDENTITY,
		frame_bounds,
		"Annual clinical trial enrollment",
		binding
	)

	var content_bound: bool = frame.bind_content(scatter)
	var guides_bound: bool = frame.bind_guide_renderer(guides)
	var frame_applied: bool = frame.apply_frame_state(state)
	if not content_bound or not guides_bound or not frame_applied:
		push_error("Failed to configure XR chart frame.")
		return

	var replay := Replay.new()
	replay.load_messages(_load_replay_messages())
	replay.run_to_end()
	if replay.active_figure == null:
		push_error("XR chart replay produced no active figure: %s" % [replay.diagnostics])
		return
	if not frame.apply_figure(replay.active_figure, replay.last_figure_diff):
		push_error("XR chart frame failed to apply figure: %s" % [frame.diagnostics])
		return

	var handles := ChartXRHandles.new()
	handles.setup(frame)
	print("XR template chart ready: points=%d revision=%d" % [frame.rendered_point_count(), replay.active_plot_revision])


func _load_replay_messages() -> Array[Dictionary]:
	var manifest := _load_json("res://fixtures/replay-manifest.json")
	var messages: Array[Dictionary] = []
	for filename: String in manifest.get("messages", []):
		messages.append(_load_json("res://fixtures/" + filename))
	return messages


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open chart fixture: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Chart fixture is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary
