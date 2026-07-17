class_name AnalyticalFrameState
extends RefCounted

const Binding = preload("res://addons/godot-charts/frames/frame_binding.gd")
const STATUSES: PackedStringArray = ["ready", "loading", "paused", "stale", "disconnected", "error"]
const ASPECT_POLICIES: PackedStringArray = ["preserve", "fit", "free"]
const MIN_BOUND := 0.1

var id: String
var transform: Transform3D
var authored_transform: Transform3D
var bounds: Vector3
var aspect_policy: String
var title: String
var source_status: String
var theme_ref: String
var visible: bool
var locked: bool
var binding: RefCounted
var local_view_state: Dictionary


func _init(frame_id: String = "frame", frame_transform: Transform3D = Transform3D.IDENTITY, frame_bounds: Vector3 = Vector3(4.0, 3.0, 1.0), frame_title: String = "", frame_binding: RefCounted = null) -> void:
	id = frame_id
	transform = frame_transform
	authored_transform = frame_transform
	bounds = frame_bounds
	aspect_policy = "preserve"
	title = frame_title
	source_status = "ready"
	theme_ref = "theme-neutral"
	visible = true
	locked = false
	binding = frame_binding if frame_binding != null else Binding.new()
	local_view_state = {}


func validate(path: String = "/frame") -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if id.is_empty():
		diagnostics.append(_error("empty-frame-id", "Frame identity must not be empty.", path + "/id"))
	if not transform.is_finite() or not authored_transform.is_finite():
		diagnostics.append(_error("invalid-frame-transform", "Frame transforms must contain finite values.", path + "/transform"))
	if not bounds.is_finite() or bounds.x < MIN_BOUND or bounds.y < MIN_BOUND or bounds.z < MIN_BOUND:
		diagnostics.append(_error("invalid-frame-bounds", "Frame bounds must be finite and at least %.1f on every axis." % MIN_BOUND, path + "/bounds"))
	if aspect_policy not in ASPECT_POLICIES:
		diagnostics.append(_error("invalid-aspect-policy", "Frame aspect policy is not supported.", path + "/aspect_policy"))
	if source_status not in STATUSES:
		diagnostics.append(_error("invalid-source-status", "Frame source status is not supported.", path + "/source_status"))
	if theme_ref.is_empty():
		diagnostics.append(_error("empty-theme-reference", "Theme reference must not be empty.", path + "/theme_ref"))
	if binding == null or not binding.has_method("validate"):
		diagnostics.append(_error("invalid-frame-binding", "Frame binding must implement the binding contract.", path + "/binding"))
	else:
		diagnostics.append_array(binding.validate(path + "/binding"))
	return diagnostics


func reset_to_authored() -> void:
	transform = authored_transform
	local_view_state.clear()


func capture_authored_state() -> void:
	authored_transform = transform


func to_dictionary() -> Dictionary:
	return {
		"schema": "godot-charts/frame-state/1.0",
		"id": id,
		"transform": _transform_to_array(transform),
		"authored_transform": _transform_to_array(authored_transform),
		"bounds": [bounds.x, bounds.y, bounds.z],
		"aspect_policy": aspect_policy,
		"title": title,
		"source_status": source_status,
		"theme_ref": theme_ref,
		"visible": visible,
		"locked": locked,
		"binding": binding.to_dictionary(),
		"local_view_state": local_view_state.duplicate(true),
	}


static func from_dictionary(value: Dictionary) -> RefCounted:
	var bounds_value: Array = value.get("bounds", [4.0, 3.0, 1.0])
	var parsed_bounds := Vector3(float(bounds_value[0]), float(bounds_value[1]), float(bounds_value[2])) if bounds_value.size() >= 3 else Vector3(4.0, 3.0, 1.0)
	var parsed_transform := _transform_from_array(value.get("transform", []))
	var state := AnalyticalFrameState.new(
		str(value.get("id", "frame")),
		parsed_transform,
		parsed_bounds,
		str(value.get("title", "")),
		Binding.from_dictionary(value.get("binding", {})),
	)
	state.authored_transform = _transform_from_array(value.get("authored_transform", []), parsed_transform)
	state.aspect_policy = str(value.get("aspect_policy", "preserve"))
	state.source_status = str(value.get("source_status", "ready"))
	state.theme_ref = str(value.get("theme_ref", "theme-neutral"))
	state.visible = bool(value.get("visible", true))
	state.locked = bool(value.get("locked", false))
	state.local_view_state = value.get("local_view_state", {}).duplicate(true)
	return state


static func _transform_to_array(value: Transform3D) -> Array[float]:
	return [
		value.basis.x.x, value.basis.x.y, value.basis.x.z,
		value.basis.y.x, value.basis.y.y, value.basis.y.z,
		value.basis.z.x, value.basis.z.y, value.basis.z.z,
		value.origin.x, value.origin.y, value.origin.z,
	]


static func _transform_from_array(value: Array, fallback: Transform3D = Transform3D.IDENTITY) -> Transform3D:
	if value.size() != 12:
		return fallback
	return Transform3D(
		Basis(
			Vector3(float(value[0]), float(value[1]), float(value[2])),
			Vector3(float(value[3]), float(value[4]), float(value[5])),
			Vector3(float(value[6]), float(value[7]), float(value[8])),
		),
		Vector3(float(value[9]), float(value[10]), float(value[11])),
	)


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
