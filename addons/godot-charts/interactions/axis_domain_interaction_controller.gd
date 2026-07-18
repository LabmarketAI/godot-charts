class_name AxisDomainInteractionController
extends RefCounted

signal domain_previewed(channel: String, edge: String, domain_min: float, domain_max: float)
signal domain_committed(channel: String, edge: String, domain_min: float, domain_max: float)
signal domain_cancelled(channel: String, edge: String)
signal domain_diagnostic(diagnostic: Dictionary)

const SUPPORTED_CHANNELS := ["x", "y", "z"]
const SUPPORTED_EDGES := ["min", "max"]
const MIN_DOMAIN_SPAN := 0.000001

var active_channel := ""
var active_edge := ""
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


func begin(channel: String, edge: String) -> bool:
	if not _can_operate(channel, edge):
		return false
	if not active_channel.is_empty():
		_report("capture-active", "A domain manipulation is already active.", "/domain")
		return false
	var view := _resolve_view(_figure, _view_id)
	_start_domains = _capture_domains(view)
	active_channel = channel
	active_edge = edge
	return true


func preview_delta(delta_unit: float) -> bool:
	if active_channel.is_empty():
		_report("no-active-capture", "No domain manipulation is active.", "/domain")
		return false
	if not is_finite(delta_unit):
		_report("non-finite-delta", "Domain preview delta must be finite.", "/domain/delta")
		return false
	var start: Dictionary = _start_domains[active_channel]
	var span := float(start["max"]) - float(start["min"])
	var next_min := float(start["min"])
	var next_max := float(start["max"])
	var delta_value := span * delta_unit
	if active_edge == "min":
		next_min = minf(next_min + delta_value, next_max - maxf(span * 0.02, MIN_DOMAIN_SPAN))
	else:
		next_max = maxf(next_max + delta_value, next_min + maxf(span * 0.02, MIN_DOMAIN_SPAN))
	if not _apply_domain(active_channel, next_min, next_max):
		return false
	domain_previewed.emit(active_channel, active_edge, next_min, next_max)
	return true


func commit() -> bool:
	if active_channel.is_empty():
		return false
	var scale: RefCounted = _scale_for(_resolve_view(_figure, _view_id), active_channel)
	var committed_channel := active_channel
	var committed_edge := active_edge
	active_channel = ""
	active_edge = ""
	_start_domains.clear()
	domain_committed.emit(committed_channel, committed_edge, scale.domain_min, scale.domain_max)
	return true


func cancel() -> bool:
	if active_channel.is_empty():
		return false
	var cancelled_channel := active_channel
	var cancelled_edge := active_edge
	for channel: String in _start_domains:
		var domain: Dictionary = _start_domains[channel]
		if not _set_scale_domain(channel, float(domain["min"]), float(domain["max"])):
			return false
	var applied: bool = _frame.apply_figure(_figure)
	active_channel = ""
	active_edge = ""
	_start_domains.clear()
	domain_cancelled.emit(cancelled_channel, cancelled_edge)
	return applied


func _can_operate(channel: String, edge: String) -> bool:
	if _frame == null or _figure == null:
		_report("not-bound", "Axis-domain controller has not been bound.", "/domain")
		return false
	if channel not in SUPPORTED_CHANNELS:
		_report("unsupported-channel", "Axis-domain channel is unsupported.", "/domain/channel")
		return false
	if edge not in SUPPORTED_EDGES:
		_report("unsupported-edge", "Axis-domain edge is unsupported.", "/domain/edge")
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
			snapshot[channel] = {"min": scale.domain_min, "max": scale.domain_max}
	return snapshot


func _report(code: String, message: String, path: String) -> void:
	var diagnostic := {"severity": "error", "code": code, "message": message, "path": path}
	diagnostics.append(diagnostic)
	domain_diagnostic.emit(diagnostic.duplicate(true))
