@tool
extends Node3D
class_name ChartInspectionRoot

const AnalyticalFrame = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const ScatterRenderer = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const Guides = preload("res://addons/godot-charts/renderers/cartesian_guides_3d.gd")
const PlotFigureModel = preload("res://addons/godot-charts/core/plot_figure.gd")
const PlotViewModel = preload("res://addons/godot-charts/core/plot_view.gd")
const PlotLayerModel = preload("res://addons/godot-charts/core/plot_layer.gd")
const PlotTableModel = preload("res://addons/godot-charts/core/plot_table.gd")
const LinearScaleModel = preload("res://addons/godot-charts/core/linear_scale.gd")
const CategoricalScaleModel = preload("res://addons/godot-charts/core/categorical_scale.gd")
const PlotGuideModel = preload("res://addons/godot-charts/core/plot_guide.gd")
const ChartAxisDomainScrubbers = preload("res://game/zones/chart_axis_domain_handles.gd")

@export var frame_bounds := Vector3(3.2, 2.0, 2.0)
@export var include_axis_domain_scrubbers := true
@export var include_reference_floor := true
@export var include_status_labels := true

var chart_frame: AnalyticalFrame3D
var active_figure: RefCounted


func _ready() -> void:
	if include_reference_floor:
		_set_reference_floor_visible(true)
	else:
		_set_reference_floor_visible(false)
	_build_chart_frame()
	if include_status_labels:
		_configure_status_labels()
	else:
		var labels := get_node_or_null("InspectionLayout/StatusLabels")
		if labels != null:
			labels.visible = false


func _set_reference_floor_visible(next_visible: bool) -> void:
	var floor := get_node_or_null("InspectionLayout/ReferenceFloor")
	if floor != null:
		floor.visible = next_visible


func _build_chart_frame() -> void:
	chart_frame = get_node_or_null("InspectionLayout/InspectionChartFrame") as AnalyticalFrame3D
	if chart_frame == null:
		push_error("Inspection scene is missing editor-authored InspectionChartFrame.")
		return

	var state := FrameState.new(
		"inspection-chart-frame",
		chart_frame.transform,
		frame_bounds,
		"Asset Lab Chart"
	)
	state.aspect_policy = "fit"
	chart_frame.apply_frame_state(state)

	var scatter := chart_frame.get_node_or_null("ContentRoot/InspectionScatterRenderer") as ScatterRenderer3D
	if scatter == null:
		push_error("Inspection scene is missing editor-authored InspectionScatterRenderer.")
		return
	scatter.point_radius = 0.045
	var guides := chart_frame.get_node_or_null("GuideRoot/InspectionCartesianGuides") as CartesianGuides3D
	if guides == null:
		push_error("Inspection scene is missing editor-authored InspectionCartesianGuides.")
		return
	guides.target_tick_count = 4
	chart_frame.bind_content(scatter)
	chart_frame.bind_guide_renderer(guides)

	active_figure = _sample_figure()
	chart_frame.apply_figure(active_figure)

	if include_axis_domain_scrubbers:
		var domain_scrubbers := chart_frame.get_node_or_null("ChromeRoot/ChartAxisDomainScrubbers") as ChartAxisDomainScrubbers
		if domain_scrubbers == null:
			push_error("Inspection scene is missing editor-authored ChartAxisDomainScrubbers.")
			return
		domain_scrubbers.setup(chart_frame, active_figure)


func _configure_status_labels() -> void:
	var labels := get_node_or_null("InspectionLayout/StatusLabels") as Node3D
	if labels == null:
		push_error("Inspection scene is missing editor-authored StatusLabels.")
		return
	labels.visible = true
	_ensure_label(labels, "TitleLabel", "Shared chart inspection scene", Vector3(0.0, 2.82, -2.7), 0.004)
	_ensure_label(labels, "ActionLabel", "Trigger ray: drag axis window to scrub; drag ends to zoom.", Vector3(0.0, 2.67, -2.7), 0.004)


func _ensure_label(parent: Node, node_name: String, text: String, position: Vector3, pixel_size: float) -> Label3D:
	var label := parent.get_node_or_null(node_name) as Label3D
	if label == null:
		push_error("Inspection scene is missing editor-authored label: %s" % node_name)
		return null
	label.text = text
	label.position = position
	label.pixel_size = pixel_size
	return label


func _inspection_layout() -> Node3D:
	var layout := get_node_or_null("InspectionLayout") as Node3D
	if layout == null:
		push_error("Inspection scene is missing editor-authored InspectionLayout.")
	return layout


func _sample_figure() -> RefCounted:
	var rows := PackedStringArray()
	var xs: Array[float] = []
	var ys: Array[float] = []
	var zs: Array[float] = []
	var groups: Array[String] = []
	for index: int in 32:
		rows.append("row-%02d" % index)
		var unit := float(index) / 31.0
		xs.append(unit * 10.0)
		ys.append(1.2 + sin(unit * TAU * 1.25) * 1.4 + unit * 4.8)
		zs.append(1.0 + cos(unit * TAU * 0.85) * 1.2 + unit * 5.6)
		groups.append(["A", "B", "C"][index % 3])

	var table := PlotTableModel.new("inspection-data", 1, rows, {
		"x": xs,
		"y": ys,
		"z": zs,
		"group": groups,
	})
	var layer := PlotLayerModel.new("points", "point", "inspection-data", {
		"x": "x",
		"y": "y",
		"z": "z",
		"color": "group",
	})
	var x_scale := LinearScaleModel.new(0.0, 6.0, 0.0, 1.0, true, 0.0, 10.0)
	x_scale.configure_viewport(0.0, 10.0, 0.0, 6.0, 1.0, 10.0)
	var view := PlotViewModel.new("main", "cartesian_3d", [layer], {
		"x": x_scale,
		"y": LinearScaleModel.new(0.0, 8.0, 0.0, 1.0, true),
		"z": LinearScaleModel.new(0.0, 8.0, 0.0, 1.0, true),
		"color": CategoricalScaleModel.new(PackedStringArray(["A", "B", "C"]), [
			"#2f80ed",
			"#27ae60",
			"#f2994a",
		]),
	}, [
		PlotGuideModel.new("x-axis", "axis", "x", "X"),
		PlotGuideModel.new("y-axis", "axis", "y", "Y"),
		PlotGuideModel.new("z-axis", "axis", "z", "Z"),
	])
	return PlotFigureModel.new(
		"inspection-asset-lab-figure",
		"inspection-asset-lab",
		1,
		"Asset Lab Scatter",
		[view],
		{"inspection-data": table},
		{"name": "inspection"},
		{"source": "shared-scene"},
	)
