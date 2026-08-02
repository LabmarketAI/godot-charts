@tool
class_name LineChart2D
extends Control

## Resizable, multi-series 2D line chart for HUDs and SubViewport surfaces.

const LinearTicksScript = preload("../core/linear_ticks.gd")
const ChartReferenceLine = preload("chart_reference_line_2d.gd")
const ChartAxis = preload("chart_axis_2d.gd")

var _chart_data: ChartData2D
var _palette: ChartPalette2D
var _reference_lines: Array[Resource] = []
var _y_axes: Array[Resource] = []

@export var chart_data: ChartData2D:
	get:
		return _chart_data
	set(value):
		_set_chart_data(value)
@export var palette: ChartPalette2D:
	get:
		return _palette
	set(value):
		_set_palette(value)
@export var reference_lines: Array[Resource] = []:
	get:
		return _reference_lines
	set(value):
		_set_reference_lines(value)
@export var y_axes: Array[Resource] = []:
	get:
		return _y_axes
	set(value):
		_set_y_axes(value)
@export var title := "":
	set(value):
		title = value
		queue_redraw()
@export var begin_at_zero := false:
	set(value):
		begin_at_zero = value
		queue_redraw()
@export_range(1.0, 12.0, 0.5) var line_width := 4.0:
	set(value):
		line_width = value
		queue_redraw()
@export_range(0.0, 16.0, 0.5) var marker_radius := 4.0:
	set(value):
		marker_radius = value
		queue_redraw()
@export var show_legend := true:
	set(value):
		show_legend = value
		queue_redraw()
@export var show_latest_values := false:
	set(value):
		show_latest_values = value
		queue_redraw()
@export var show_x_labels := true:
	set(value):
		show_x_labels = value
		queue_redraw()
@export var show_y_labels := true:
	set(value):
		show_y_labels = value
		queue_redraw()
@export var show_grid := true:
	set(value):
		show_grid = value
		queue_redraw()
@export var compact_mode := false:
	set(value):
		compact_mode = value
		queue_redraw()
@export var domain_override_enabled := false:
	set(value):
		domain_override_enabled = value
		queue_redraw()
@export var domain_override := Vector2(0.0, 1.0):
	set(value):
		domain_override = value
		queue_redraw()
@export_range(2, 12, 1) var x_label_target_count := 6:
	set(value):
		x_label_target_count = value
		queue_redraw()
@export_range(0.0, 512.0, 1.0) var content_inset_left := 0.0:
	set(value):
		content_inset_left = value
		queue_redraw()
@export var empty_text := "No samples yet":
	set(value):
		empty_text = value
		queue_redraw()
@export var plot_padding := Vector4(92.0, 40.0, 36.0, 64.0):
	set(value):
		plot_padding = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	if palette == null:
		palette = ChartPalette2D.new()
	queue_redraw()


func _draw() -> void:
	var colors := palette if palette != null else ChartPalette2D.new()
	draw_rect(Rect2(Vector2.ZERO, size), colors.background)
	var plot := _plot_rect()
	if plot.size.x <= 0.0 or plot.size.y <= 0.0:
		return
	var axes := _resolved_axes(colors)
	var domains := _axis_domains(axes)
	if domains.is_empty():
		_draw_empty(colors)
		return
	_draw_axes_and_grid(plot, axes, domains, colors)
	_draw_reference_lines(plot, domains, colors)
	_draw_series(plot, domains, colors)
	_draw_header(colors)


static func value_domain(data: ChartData2D, include_zero: bool = false) -> Variant:
	if data == null:
		return null
	var raw: Variant = data.finite_value_range()
	if raw == null:
		return null
	var minimum: float = raw.x
	var maximum: float = raw.y
	if include_zero:
		minimum = minf(minimum, 0.0)
		maximum = maxf(maximum, 0.0)
	if is_equal_approx(minimum, maximum):
		var padding := maxf(absf(minimum) * 0.05, 1.0)
		minimum -= padding
		maximum += padding
	else:
		var padding := (maximum - minimum) * 0.05
		minimum -= padding
		maximum += padding
	return Vector2(minimum, maximum)


static func resolved_domain(
		data: ChartData2D,
		include_zero: bool = false,
		use_override: bool = false,
		override: Vector2 = Vector2.ZERO
) -> Variant:
	if use_override and is_finite(override.x) and is_finite(override.y) \
			and override.x < override.y:
		return override
	return value_domain(data, include_zero)


static func domain_with_reference_lines(
		domain: Variant,
		lines: Array[Resource]
) -> Variant:
	var result: Variant = domain
	for line in lines:
		if line == null or not is_finite(line.value):
			continue
		if result == null:
			result = Vector2(line.value - 1.0, line.value + 1.0)
		else:
			result = Vector2(
				minf(result.x, line.value),
				maxf(result.y, line.value))
	if result is Vector2 and is_equal_approx(result.x, result.y):
		result = Vector2(result.x - 1.0, result.y + 1.0)
	return result


## Map an ordered category index across the horizontal plot span. A chart with
## one sample represents the beginning of a series, so it belongs at the left
## origin rather than floating at the midpoint.
static func category_unit(index: int, category_count: int) -> float:
	if category_count <= 1:
		return 0.0
	return clampf(
		float(index) / float(category_count - 1),
		0.0,
		1.0
	)


static func latest_finite_value(dataset: Resource) -> Variant:
	if dataset == null or not "values" in dataset:
		return null
	for index in range(dataset.values.size() - 1, -1, -1):
		var value: float = dataset.values[index]
		if is_finite(value):
			return value
	return null


static func legend_text(dataset: Resource, include_latest_value: bool) -> String:
	if dataset == null:
		return ""
	var result := str(dataset.label)
	if not include_latest_value:
		return result
	var latest: Variant = latest_finite_value(dataset)
	if latest == null:
		return result
	return "%s  %s" % [result, _format_display_value(float(latest))]


static func _format_display_value(value: float) -> String:
	var magnitude := absf(value)
	if magnitude >= 1.0e6 or (magnitude > 0.0 and magnitude < 1.0e-4):
		return "%.3e" % value
	return String.num(value, 2)


func _plot_rect() -> Rect2:
	var padding := plot_padding
	if compact_mode:
		padding = Vector4(
			minf(plot_padding.x, 64.0),
			minf(plot_padding.y, 32.0),
			minf(plot_padding.z, 20.0),
			minf(plot_padding.w, 40.0))
	padding.x += content_inset_left
	var side_counts := _configured_side_counts()
	var left_axis_count := int(side_counts["left"])
	var right_axis_count := int(side_counts["right"])
	padding.x += float(maxi(left_axis_count - 1, 0)) \
		* (96.0 if compact_mode else 112.0)
	padding.z += float(right_axis_count) * (96.0 if compact_mode else 112.0)
	return Rect2(
		Vector2(padding.x, padding.y),
		Vector2(
			size.x - padding.x - padding.z,
			size.y - padding.y - padding.w
		)
	)


func _draw_axes_and_grid(
		plot: Rect2,
		axes: Array,
		domains: Dictionary,
		colors: ChartPalette2D
) -> void:
	var left_index := 0
	var right_index := 0
	for axis_index in axes.size():
		var axis: Dictionary = axes[axis_index]
		var axis_id: StringName = axis["id"]
		if not domains.has(axis_id):
			continue
		var domain: Vector2 = domains[axis_id]
		var ticks: Array[float] = LinearTicksScript.generate(
			domain.x, domain.y, 5)
		var step := ticks[1] - ticks[0] \
			if ticks.size() > 1 else domain.y - domain.x
		var axis_color: Color = axis["color"]
		var is_left := int(axis["side"]) == ChartAxis.Side.LEFT
		var side_index := left_index if is_left else right_index
		var axis_x := plot.position.x - float(side_index) \
			* (96.0 if compact_mode else 112.0) if is_left \
			else plot.end.x + float(side_index) \
				* (96.0 if compact_mode else 112.0)
		if is_left:
			left_index += 1
		else:
			right_index += 1
		for value in ticks:
			var unit := (value - domain.x) / (domain.y - domain.x)
			var y := lerpf(plot.end.y, plot.position.y, unit)
			if show_grid and axis_index == 0:
				draw_line(
					Vector2(plot.position.x, y),
					Vector2(plot.end.x, y),
					colors.grid, 1.0)
			if show_y_labels:
				var label_x := axis_x - (96.0 if compact_mode else 112.0) \
					if is_left else axis_x + 6.0
				var width := (92.0 if compact_mode else 108.0) \
					if is_left \
					else (92.0 if compact_mode else 108.0)
				draw_string(
					ThemeDB.fallback_font,
					Vector2(label_x, y + ThemeDB.fallback_font_size * 0.35),
					LinearTicksScript.format(value, step),
					HORIZONTAL_ALIGNMENT_RIGHT \
						if is_left else HORIZONTAL_ALIGNMENT_LEFT,
					width,
					ThemeDB.fallback_font_size,
					axis_color)
		draw_line(
			Vector2(axis_x, plot.position.y),
			Vector2(axis_x, plot.end.y),
			axis_color, 2.0)
		if not str(axis["label"]).is_empty():
			var title_y := plot.position.y \
				+ ThemeDB.fallback_font_size \
				* float(side_index + 1)
			draw_string(
				ThemeDB.fallback_font,
				Vector2(
					axis_x - (96.0 if compact_mode else 112.0) \
						if is_left else axis_x + 6.0,
					title_y),
				str(axis["label"]),
				HORIZONTAL_ALIGNMENT_RIGHT \
					if is_left else HORIZONTAL_ALIGNMENT_LEFT,
				92.0 if compact_mode else 108.0,
				ThemeDB.fallback_font_size,
				axis_color)
	draw_line(Vector2(plot.position.x, plot.end.y), plot.end, colors.foreground, 2.0)
	if show_x_labels:
		_draw_x_labels(plot, colors)


func _draw_series(
		plot: Rect2,
		domains: Dictionary,
		colors: ChartPalette2D
) -> void:
	if chart_data == null:
		return
	var category_count := maxi(chart_data.labels.size(), _maximum_value_count())
	if category_count <= 0:
		return
	for series_index in chart_data.datasets.size():
		var dataset := chart_data.datasets[series_index]
		if dataset == null or not dataset.visible:
			continue
		var axis_id: StringName = dataset.y_axis_id
		if not domains.has(axis_id):
			axis_id = &"y"
		if not domains.has(axis_id):
			continue
		var domain: Vector2 = domains[axis_id]
		var color := dataset.color if dataset.color.a > 0.0 else colors.series_color(series_index)
		var segment := PackedVector2Array()
		for value_index in dataset.values.size():
			var value := dataset.values[value_index]
			if not is_finite(value):
				_draw_segment(segment, color)
				segment.clear()
				continue
			var x_unit := category_unit(value_index, category_count)
			var y_unit := (value - domain.x) / (domain.y - domain.x)
			segment.append(Vector2(
				lerpf(plot.position.x, plot.end.x, x_unit),
				lerpf(plot.end.y, plot.position.y, y_unit)
			))
		_draw_segment(segment, color)


func _draw_reference_lines(
		plot: Rect2,
		domains: Dictionary,
		_colors: ChartPalette2D
) -> void:
	for line in reference_lines:
		if line == null or not is_finite(line.value):
			continue
		var axis_id: StringName = line.y_axis_id
		if not domains.has(axis_id):
			axis_id = &"y"
		if not domains.has(axis_id):
			continue
		var domain: Vector2 = domains[axis_id]
		var unit := (float(line.value) - domain.x) / (domain.y - domain.x)
		var y := lerpf(plot.end.y, plot.position.y, unit)
		draw_line(
			Vector2(plot.position.x, y),
			Vector2(plot.end.x, y),
			line.color,
			line.width)
		if not line.label.is_empty():
			var label_y := clampf(
				y - 5.0,
				plot.position.y + ThemeDB.fallback_font_size,
				plot.end.y - 4.0)
			draw_string(
				ThemeDB.fallback_font,
				Vector2(plot.position.x + 8.0, label_y),
				line.label,
				HORIZONTAL_ALIGNMENT_LEFT,
				plot.size.x - 16.0,
				ThemeDB.fallback_font_size,
				line.color)


func _draw_segment(points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 2:
		draw_polyline(points, color, line_width, true)
	if marker_radius > 0.0:
		for point in points:
			draw_circle(point, marker_radius, color)


func _draw_header(colors: ChartPalette2D) -> void:
	var x := (8.0 if compact_mode else plot_padding.x) + content_inset_left
	var y := 22.0
	if not title.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x, y),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size,
			colors.foreground
		)
		x += ThemeDB.fallback_font.get_string_size(
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size
		).x + 32.0
	if not show_legend or chart_data == null:
		return
	for index in chart_data.datasets.size():
		var dataset := chart_data.datasets[index]
		if dataset == null or not dataset.visible:
			continue
		var color := dataset.color if dataset.color.a > 0.0 else colors.series_color(index)
		var label := legend_text(dataset, show_latest_values)
		draw_line(Vector2(x, y - 5.0), Vector2(x + 24.0, y - 5.0), color, line_width)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x + 32.0, y),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size,
			colors.foreground
		)
		x += 48.0 + ThemeDB.fallback_font.get_string_size(
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size
		).x


func _draw_x_labels(plot: Rect2, colors: ChartPalette2D) -> void:
	if chart_data == null or chart_data.labels.is_empty():
		return
	var count := chart_data.labels.size()
	var target := mini(maxi(x_label_target_count, 2), count)
	var stride := maxi(ceili(float(count - 1) / float(target - 1)), 1) \
		if count > 1 else 1
	var indices: Array[int] = []
	for index in range(0, count, stride):
		indices.append(index)
	if indices[-1] != count - 1:
		indices.append(count - 1)
	for index in indices:
		var x_unit := 0.5 if count == 1 else float(index) / float(count - 1)
		var x := lerpf(plot.position.x, plot.end.x, x_unit)
		var label := chart_data.labels[index]
		var width := ThemeDB.fallback_font.get_string_size(
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size
		).x
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x - width * 0.5, plot.end.y + ThemeDB.fallback_font_size + 8.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			ThemeDB.fallback_font_size,
			colors.foreground
		)


func _draw_empty(colors: ChartPalette2D) -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0.0, size.y * 0.5),
		empty_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		ThemeDB.fallback_font_size * 1.5,
		colors.foreground
	)


func _maximum_value_count() -> int:
	var result := 0
	if chart_data != null:
		for dataset in chart_data.datasets:
			if dataset != null and dataset.visible:
				result = maxi(result, dataset.values.size())
	return result


func _set_chart_data(value: ChartData2D) -> void:
	if _chart_data != null and _chart_data.changed.is_connected(queue_redraw):
		_chart_data.changed.disconnect(queue_redraw)
	_chart_data = value
	if _chart_data != null and not _chart_data.changed.is_connected(queue_redraw):
		_chart_data.changed.connect(queue_redraw)
	queue_redraw()


func _set_palette(value: ChartPalette2D) -> void:
	if _palette != null and _palette.changed.is_connected(queue_redraw):
		_palette.changed.disconnect(queue_redraw)
	_palette = value
	if _palette != null and not _palette.changed.is_connected(queue_redraw):
		_palette.changed.connect(queue_redraw)
	queue_redraw()


func _set_reference_lines(value: Array[Resource]) -> void:
	for line in _reference_lines:
		if line != null and line.changed.is_connected(queue_redraw):
			line.changed.disconnect(queue_redraw)
	_reference_lines = value
	for line in _reference_lines:
		if line != null and not line.changed.is_connected(queue_redraw):
			line.changed.connect(queue_redraw)
	queue_redraw()


func _set_y_axes(value: Array[Resource]) -> void:
	for axis in _y_axes:
		if axis != null and axis.changed.is_connected(queue_redraw):
			axis.changed.disconnect(queue_redraw)
	_y_axes = value
	for axis in _y_axes:
		if axis != null and not axis.changed.is_connected(queue_redraw):
			axis.changed.connect(queue_redraw)
	queue_redraw()


func _configured_side_counts() -> Dictionary:
	if y_axes.is_empty():
		return {"left": 1, "right": 0}
	var left := 0
	var right := 0
	for axis in y_axes:
		if axis != null and axis.side == ChartAxis.Side.LEFT:
			left += 1
		elif axis != null:
			right += 1
	return {"left": left, "right": right}


func _resolved_axes(colors: ChartPalette2D) -> Array:
	if y_axes.is_empty():
		return [{
			"id": &"y",
			"label": "",
			"color": colors.foreground,
			"side": ChartAxis.Side.LEFT,
			"begin_at_zero": begin_at_zero,
			"override_enabled": domain_override_enabled,
			"override": domain_override,
		}]
	var result: Array = []
	for index in y_axes.size():
		var axis: Resource = y_axes[index]
		if axis == null:
			continue
		var axis_color: Color = axis.color
		if axis_color.a <= 0.0:
			axis_color = _first_axis_series_color(
				axis.axis_id, colors)
		result.append({
			"id": axis.axis_id,
			"label": axis.label,
			"color": axis_color,
			"side": axis.side,
			"begin_at_zero": axis.begin_at_zero,
			"override_enabled": axis.domain_override_enabled,
			"override": axis.domain_override,
		})
	return result


func _axis_domains(axes: Array) -> Dictionary:
	var result: Dictionary = {}
	for axis in axes:
		var axis_id: StringName = axis["id"]
		var domain := _dataset_domain_for_axis(
			axis_id, bool(axis["begin_at_zero"]))
		if bool(axis["override_enabled"]):
			var override: Vector2 = axis["override"]
			if is_finite(override.x) and is_finite(override.y) \
					and override.x < override.y:
				domain = override
		domain = _domain_with_axis_reference_lines(
			domain, axis_id)
		if domain != null:
			result[axis_id] = domain
	return result


func _dataset_domain_for_axis(
		axis_id: StringName,
		include_zero: bool
) -> Variant:
	if chart_data == null:
		return null
	var found := false
	var minimum := INF
	var maximum := -INF
	for dataset in chart_data.datasets:
		if dataset == null or not dataset.visible \
				or dataset.y_axis_id != axis_id:
			continue
		for value in dataset.values:
			if not is_finite(value):
				continue
			found = true
			minimum = minf(minimum, value)
			maximum = maxf(maximum, value)
	if not found:
		return null
	if include_zero:
		minimum = minf(minimum, 0.0)
		maximum = maxf(maximum, 0.0)
	if is_equal_approx(minimum, maximum):
		var constant_padding := maxf(absf(minimum) * 0.05, 1.0)
		return Vector2(
			minimum - constant_padding,
			maximum + constant_padding)
	var padding := (maximum - minimum) * 0.05
	return Vector2(minimum - padding, maximum + padding)


func _domain_with_axis_reference_lines(
		domain: Variant,
		axis_id: StringName
) -> Variant:
	var result: Variant = domain
	for line in reference_lines:
		if line == null or line.y_axis_id != axis_id \
				or not is_finite(line.value):
			continue
		if result == null:
			result = Vector2(line.value - 1.0, line.value + 1.0)
		else:
			result = Vector2(
				minf(result.x, line.value),
				maxf(result.y, line.value))
	return result


func _first_axis_series_color(
		axis_id: StringName,
		colors: ChartPalette2D
) -> Color:
	if chart_data != null:
		for index in chart_data.datasets.size():
			var dataset := chart_data.datasets[index]
			if dataset != null and dataset.visible \
					and dataset.y_axis_id == axis_id:
				return dataset.color if dataset.color.a > 0.0 \
					else colors.series_color(index)
	return colors.foreground
