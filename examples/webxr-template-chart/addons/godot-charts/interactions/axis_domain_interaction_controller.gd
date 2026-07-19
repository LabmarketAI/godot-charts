class_name AxisDomainInteractionController
extends RefCounted

signal domain_previewed(channel: String, part: String, domain_min: float, domain_max: float)
signal domain_committed(channel: String, part: String, domain_min: float, domain_max: float)
signal domain_cancelled(channel: String, part: String)
signal domain_diagnostic(diagnostic: Dictionary)

const SUPPORTED_CHANNELS := ["x", "y", "z"]
const SUPPORTED_PARTS := ["min", "max", "range"]
const MIN_DOMAIN_SPAN := 0.000001

var active_channel := ""
var active_part := ""
var diagnostics: Array[Dictionary] = []

var _frame: Node3D
var _figure: RefCounted
var _view_id := ""
var _start_domains: Dictionary = {}


func bind(frame: Node3D, figure: RefCounted, view_id := "") -> bool:
	diagnostics.clear()
	if frame == null or not frame.has_method("apply_figure"):
		_report("invalid-frame", "Axis-domain controller requires a frame with apply_figure.", "/frame")
		return false
	if figure == null or not figure.has_method("view"):
		_report("invalid-figure", "Axis-domain controller requires a retained figure.", "/figure")
		return false
	var view := _resolve_view(figure, view_id)
	if view == null:
		_report("missing-view", "Axis-domain controller could not resolve a supported view.", "/figure/views")
		return false
	for channel: String in SUPPORTED_CHANNELS:
		if not _scale_for(view, channel):
			_report("missing-scale", "Axis-domain controller requires a mutable linear scale.", "/figure/views/%s/scales/%s" % [view.id, channel])
			return false
	_frame = frame
	_figure = figure
	_view_id = view.id
	return true


func domain_snapshot() -> Dictionary:
	if _figure == null:
		return {}
	var view := _resolve_view(_figure, _view_id)
	if view == null:
		return {}
	return _capture_domains(view)


func begin(channel: String, part: String) -> bool:
	if not _can_operate(channel, part):
		return false
	if not active_channel.is_empty():
		_report("capture-active", "A domain manipulation is already active.", "/domain")
		return false
	var view := _resolve_view(_figure, _view_id)
	_start_domains = _capture_domains(view)
	active_channel = channel
	active_part = part
	return true


func begin_from_handle(target: Node) -> bool:
	if _frame == null or not _frame.has_method("resolve_domain_handle"):
		_report("missing-handle-resolver", "Axis-domain controller requires a frame that can resolve domain handles.", "/domain/handles")
		return false
	var resolved: Dictionary = _frame.resolve_domain_handle(target)
	if resolved.is_empty():
		_report("invalid-domain-handle", "Picked target is not an axis-domain handle.", "/domain/handles")
		return false
	return begin(str(resolved.get("channel", "")), str(resolved.get("part", resolved.get("edge", ""))))


func preview_delta(delta_unit: float) -> bool:
	if active_channel.is_empty():
		_report("no-active-capture", "No domain manipulation is active.", "/domain")
		return false
	if not is_finite(delta_unit):
		_report("non-finite-delta", "Domain preview delta must be finite.", "/domain/delta")
		return false
	var start: Dictionary = _start_domains[active_channel]
	var scale: RefCounted = _scale_for(_resolve_view(_figure, _view_id), active_channel)
	var span := float(start["max"]) - float(start["min"])
	var extent_span := _extent_span(scale)
	var next_min := float(start["min"])
	var next_max := float(start["max"])
	var delta_value := extent_span * delta_unit
	if active_part == "range":
		next_min += delta_value
		next_max += delta_value
	elif active_part == "min":
		next_min = minf(next_min + delta_value, next_max - maxf(span * 0.02, MIN_DOMAIN_SPAN))
	else:
		next_max = maxf(next_max + delta_value, next_min + maxf(span * 0.02, MIN_DOMAIN_SPAN))
	if not _apply_domain(active_channel, next_min, next_max):
		return false
	domain_previewed.emit(active_channel, active_part, scale.domain_min, scale.domain_max)
	return true


func preview_zoom(factor: float, focus_unit: float = 0.5) -> bool:
	if active_channel.is_empty():
		_report("no-active-capture", "No domain manipulation is active.", "/domain")
		return false
	var scale: RefCounted = _scale_for(_resolve_view(_figure, _view_id), active_channel)
	if scale == null or not scale.has_method("zoom_visible"):
		_report("missing-viewport-scale", "Axis zoom requires viewport-capable linear scale.", "/domain/%s" % active_channel)
		return false
	var start: Dictionary = _start_domains[active_channel]
	if not _set_scale_domain(active_channel, float(start["min"]), float(start["max"])):
		return false
	if not scale.zoom_visible(factor, focus_unit):
		return false
	if not _frame.apply_figure(_figure):
		return false
	domain_previewed.emit(active_channel, active_part, scale.domain_min, scale.domain_max)
	return true


func reset_channel(channel: String) -> bool:
	if _frame == null or _figure == null:
		_report("not-bound", "Axis-domain controller has not been bound.", "/domain")
		return false
	if channel not in SUPPORTED_CHANNELS:
		_report("unsupported-channel", "Axis-domain channel is unsupported.", "/domain/channel")
		return false
	var scale: RefCounted = _scale_for(_resolve_view(_figure, _view_id), channel)
	if scale == null or not scale.has_method("fit_extent"):
		_report("missing-viewport-scale", "Axis reset requires viewport-capable linear scale.", "/domain/%s" % channel)
		return false
	if not scale.fit_extent():
		return false
	if not _frame.apply_figure(_figure):
		return false
	domain_committed.emit(channel, "reset", scale.domain_min, scale.domain_max)
	return true


func commit() -> bool:
	if active_channel.is_empty():
		return false
	var scale: RefCounted = _scale_for(_resolve_view(_figure, _view_id), active_channel)
	var committed_channel := active_channel
	var committed_part := active_part
	active_channel = ""
	active_part = ""
	_start_domains.clear()
	domain_committed.emit(committed_channel, committed_part, scale.domain_min, scale.domain_max)
	return true


func cancel() -> bool:
	if active_channel.is_empty():
		return false
	var cancelled_channel := active_channel
	var cancelled_part := active_part
	for channel: String in _start_domains:
		var domain: Dictionary = _start_domains[channel]
		if not _set_scale_domain(channel, float(domain["min"]), float(domain["max"])):
			return false
	var applied: bool = _frame.apply_figure(_figure)
	active_channel = ""
	active_part = ""
	_start_domains.clear()
	domain_cancelled.emit(cancelled_channel, cancelled_part)
	return applied


func _can_operate(channel: String, part: String) -> bool:
	if _frame == null or _figure == null:
		_report("not-bound", "Axis-domain controller has not been bound.", "/domain")
		return false
	if channel not in SUPPORTED_CHANNELS:
		_report("unsupported-channel", "Axis-domain channel is unsupported.", "/domain/channel")
		return false
	if part not in SUPPORTED_PARTS:
		_report("unsupported-part", "Axis-domain scrubber part is unsupported.", "/domain/part")
		return false
	return _scale_for(_resolve_view(_figure, _view_id), channel) != null


func _apply_domain(channel: String, domain_min: float, domain_max: float) -> bool:
	if domain_min >= domain_max:
		_report("invalid-domain", "Domain preview produced an invalid range.", "/domain/%s" % channel)
		return false
	if not _set_scale_domain(channel, domain_min, domain_max):
		return false
	if not _frame.apply_figure(_figure):
		_report("figure-apply-failed", "Frame rejected the previewed figure.", "/figure")
		return false
	return true


func _set_scale_domain(channel: String, domain_min: float, domain_max: float) -> bool:
	var scale: RefCounted = _scale_for(_resolve_view(_figure, _view_id), channel)
	if scale == null:
		return false
	if scale.has_method("set_visible_domain"):
		return scale.set_visible_domain(domain_min, domain_max)
	scale.domain_min = domain_min
	scale.domain_max = domain_max
	return scale.validate("/figure/views/%s/scales/%s" % [_view_id, channel]).is_empty()


func _resolve_view(figure: RefCounted, view_id: String) -> RefCounted:
	if figure == null:
		return null
	if not view_id.is_empty():
		return figure.view(view_id)
	for view: RefCounted in figure.views:
		if view.coordinate_system == "cartesian_3d":
			return view
	return null


func _scale_for(view: RefCounted, channel: String) -> RefCounted:
	if view == null or not view.scales.has(channel):
		return null
	var scale: RefCounted = view.scales[channel]
	if scale == null or not scale.has_method("validate"):
		return null
	if not ("domain_min" in scale and "domain_max" in scale):
		return null
	return scale


func _capture_domains(view: RefCounted) -> Dictionary:
	var snapshot: Dictionary = {}
	for channel: String in SUPPORTED_CHANNELS:
		var scale: RefCounted = _scale_for(view, channel)
		if scale != null:
			snapshot[channel] = _scale_snapshot(scale)
	return snapshot


func _scale_snapshot(scale: RefCounted) -> Dictionary:
	var snapshot := {"min": scale.domain_min, "max": scale.domain_max}
	if "extent_min" in scale and "extent_max" in scale:
		snapshot["extent_min"] = scale.extent_min
		snapshot["extent_max"] = scale.extent_max
	if "min_span" in scale:
		snapshot["min_span"] = scale.min_span
	if "max_span" in scale:
		snapshot["max_span"] = scale.max_span
	if "focus" in scale:
		snapshot["focus"] = scale.focus
	return snapshot


func _extent_span(scale: RefCounted) -> float:
	if scale != null and "extent_min" in scale and "extent_max" in scale:
		return maxf(float(scale.extent_max) - float(scale.extent_min), MIN_DOMAIN_SPAN)
	return maxf(float(_start_domains[active_channel]["max"]) - float(_start_domains[active_channel]["min"]), MIN_DOMAIN_SPAN)


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	domain_diagnostic.emit(diagnostic.duplicate(true))
