class_name LinearScale
extends RefCounted

var domain_min: float
var domain_max: float
var extent_min: float
var extent_max: float
var min_span: float
var max_span: float
var focus: float
var allow_overscroll: bool
var range_min: float
var range_max: float
var clamp: bool


func _init(minimum: float, maximum: float, output_minimum: float = 0.0, output_maximum: float = 1.0, should_clamp: bool = false, full_minimum: Variant = null, full_maximum: Variant = null) -> void:
	domain_min = minimum
	domain_max = maximum
	extent_min = minimum if full_minimum == null else float(full_minimum)
	extent_max = maximum if full_maximum == null else float(full_maximum)
	min_span = maxf((extent_max - extent_min) * 0.02, 0.000001)
	max_span = extent_max - extent_min
	focus = 0.5
	allow_overscroll = false
	range_min = output_minimum
	range_max = output_maximum
	clamp = should_clamp


func validate(path: String = "/scale") -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if not is_finite(domain_min) or not is_finite(domain_max):
		diagnostics.append(_error("non-finite-domain", "Linear scale domain must be finite.", path + "/domain"))
	elif domain_min >= domain_max:
		diagnostics.append(_error("invalid-domain", "Linear scale minimum must be less than its maximum.", path + "/domain"))
	if not is_finite(extent_min) or not is_finite(extent_max):
		diagnostics.append(_error("non-finite-extent", "Linear scale extent must be finite.", path + "/extent"))
	elif extent_min >= extent_max:
		diagnostics.append(_error("invalid-extent", "Linear scale extent minimum must be less than its maximum.", path + "/extent"))
	elif not allow_overscroll and (domain_min < extent_min or domain_max > extent_max):
		diagnostics.append(_error("domain-outside-extent", "Linear scale visible domain must stay inside extent unless overscroll is enabled.", path + "/domain"))
	if not is_finite(min_span) or min_span <= 0.0:
		diagnostics.append(_error("invalid-min-span", "Linear scale minimum visible span must be positive and finite.", path + "/min_span"))
	if not is_finite(max_span) or max_span <= 0.0:
		diagnostics.append(_error("invalid-max-span", "Linear scale maximum visible span must be positive and finite.", path + "/max_span"))
	elif max_span < min_span:
		diagnostics.append(_error("max-span-smaller-than-min", "Linear scale maximum span must be greater than or equal to minimum span.", path + "/max_span"))
	if not is_finite(range_min) or not is_finite(range_max) or range_min == range_max:
		diagnostics.append(_error("invalid-range", "Linear scale range must be finite and non-zero.", path + "/range"))
	return diagnostics


func configure_viewport(full_minimum: float, full_maximum: float, visible_minimum: Variant = null, visible_maximum: Variant = null, minimum_span: Variant = null, maximum_span: Variant = null, zoom_focus: float = 0.5, overscroll: bool = false) -> bool:
	extent_min = full_minimum
	extent_max = full_maximum
	min_span = maxf((extent_max - extent_min) * 0.02, 0.000001) if minimum_span == null else float(minimum_span)
	max_span = extent_max - extent_min if maximum_span == null else float(maximum_span)
	focus = clampf(zoom_focus, 0.0, 1.0)
	allow_overscroll = overscroll
	var next_min := domain_min if visible_minimum == null else float(visible_minimum)
	var next_max := domain_max if visible_maximum == null else float(visible_maximum)
	return set_visible_domain(next_min, next_max)


func set_visible_domain(visible_minimum: float, visible_maximum: float) -> bool:
	var next := clamped_domain(visible_minimum, visible_maximum)
	domain_min = next["min"]
	domain_max = next["max"]
	return validate().is_empty()


func pan_visible(delta_value: float) -> bool:
	return set_visible_domain(domain_min + delta_value, domain_max + delta_value)


func resize_visible(part: String, delta_value: float) -> bool:
	if part == "min":
		return set_visible_domain(domain_min + delta_value, domain_max)
	if part == "max":
		return set_visible_domain(domain_min, domain_max + delta_value)
	return false


func zoom_visible(factor: float, focus_unit: float = focus) -> bool:
	if not is_finite(factor) or factor <= 0.0:
		return false
	var span := domain_max - domain_min
	var next_span := clampf(span * factor, min_span, max_span)
	var clamped_focus := clampf(focus_unit, 0.0, 1.0)
	var anchor := lerpf(domain_min, domain_max, clamped_focus)
	return set_visible_domain(anchor - next_span * clamped_focus, anchor + next_span * (1.0 - clamped_focus))


func fit_extent() -> bool:
	return set_visible_domain(extent_min, extent_max)


func visible_span() -> float:
	return domain_max - domain_min


func extent_span() -> float:
	return extent_max - extent_min


func normalized_visible_window() -> Dictionary:
	var span := extent_span()
	if span <= 0.0:
		return {"start": 0.0, "end": 1.0, "size": 1.0, "center": 0.5}
	var start := clampf((domain_min - extent_min) / span, 0.0, 1.0)
	var end := clampf((domain_max - extent_min) / span, 0.0, 1.0)
	return {"start": start, "end": end, "size": maxf(end - start, 0.0), "center": (start + end) * 0.5}


func visible_contains(value: Variant) -> bool:
	if value == null or not (value is int or value is float):
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric >= domain_min and numeric <= domain_max


func clamped_domain(visible_minimum: float, visible_maximum: float) -> Dictionary:
	var next_min := visible_minimum
	var next_max := visible_maximum
	var extent_span_value := extent_span()
	var bounded_min_span := minf(maxf(min_span, 0.000001), maxf(extent_span_value, 0.000001))
	var bounded_max_span := minf(maxf(max_span, bounded_min_span), maxf(extent_span_value, bounded_min_span))
	var span := next_max - next_min
	if span < bounded_min_span:
		var center := (next_min + next_max) * 0.5
		next_min = center - bounded_min_span * 0.5
		next_max = center + bounded_min_span * 0.5
	elif span > bounded_max_span:
		var center := (next_min + next_max) * 0.5
		next_min = center - bounded_max_span * 0.5
		next_max = center + bounded_max_span * 0.5
	if not allow_overscroll:
		if next_min < extent_min:
			next_max += extent_min - next_min
			next_min = extent_min
		if next_max > extent_max:
			next_min -= next_max - extent_max
			next_max = extent_max
		next_min = maxf(next_min, extent_min)
		next_max = minf(next_max, extent_max)
		if next_max - next_min < bounded_min_span:
			next_max = minf(extent_max, next_min + bounded_min_span)
			next_min = maxf(extent_min, next_max - bounded_min_span)
	return {"min": next_min, "max": next_max}


func map(value: Variant) -> Variant:
	if value == null or not (value is int or value is float):
		return null
	var numeric := float(value)
	if not is_finite(numeric) or domain_min >= domain_max:
		return null
	var unit := (numeric - domain_min) / (domain_max - domain_min)
	if clamp:
		unit = clampf(unit, 0.0, 1.0)
	return lerpf(range_min, range_max, unit)


func invert(value: float) -> Variant:
	if not is_finite(value) or range_min == range_max:
		return null
	var unit := (value - range_min) / (range_max - range_min)
	if clamp:
		unit = clampf(unit, 0.0, 1.0)
	return lerpf(domain_min, domain_max, unit)


func to_dictionary() -> Dictionary:
	return {
		"type": "linear",
		"domain": [domain_min, domain_max],
		"extent": [extent_min, extent_max],
		"min_span": min_span,
		"max_span": max_span,
		"focus": focus,
		"allow_overscroll": allow_overscroll,
		"range": [range_min, range_max],
		"clamp": clamp,
	}


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
