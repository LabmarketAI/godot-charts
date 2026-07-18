class_name VisualAssetRoles
extends RefCounted

const STRUCTURE_AXIS_LINE := "structure/axis_line"
const STRUCTURE_TICK_MAJOR := "structure/tick_major"
const STRUCTURE_GRID_LINE := "structure/grid_line"
const STRUCTURE_PLOT_BOUNDS := "structure/plot_bounds"
const STRUCTURE_ORIGIN := "structure/origin"
const STRUCTURE_RESET_LANDMARK := "structure/reset_landmark"

const MARK_POINT := "mark/point"
const MARK_BAR := "mark/bar"
const MARK_LINE := "mark/line"

const CONTROL_HANDLE_LINEAR := "control/handle_linear"
const CONTROL_SLIDER_TRACK := "control/slider_track"
const CONTROL_SLIDER_THUMB := "control/slider_thumb"
const CONTROL_BUTTON := "control/button"
const CONTROL_GRAB_ANCHOR := "control/grab_anchor"
const CONTROL_RESET := "control/reset"
const CONTROL_FOCUS_RING := "control/focus_ring"
const CONTROL_HOVER_HALO := "control/hover_halo"

const FALLBACK_MINIMAL_POINT := "fallback/minimal_point"
const FALLBACK_MINIMAL_LINE := "fallback/minimal_line"
const FALLBACK_MINIMAL_BAR := "fallback/minimal_bar"
const FALLBACK_MINIMAL_HANDLE := "fallback/minimal_handle"

const STATE_NORMAL := "normal"
const STATE_HOVER := "hover"
const STATE_FOCUS := "focus"
const STATE_SELECTED := "selected"
const STATE_ACTIVE := "active"
const STATE_DISABLED := "disabled"
const STATE_WARNING := "warning"
const STATE_ERROR := "error"


static func all_roles() -> PackedStringArray:
	return PackedStringArray([
		STRUCTURE_AXIS_LINE,
		STRUCTURE_TICK_MAJOR,
		STRUCTURE_GRID_LINE,
		STRUCTURE_PLOT_BOUNDS,
		STRUCTURE_ORIGIN,
		STRUCTURE_RESET_LANDMARK,
		MARK_POINT,
		MARK_BAR,
		MARK_LINE,
		CONTROL_HANDLE_LINEAR,
		CONTROL_SLIDER_TRACK,
		CONTROL_SLIDER_THUMB,
		CONTROL_BUTTON,
		CONTROL_GRAB_ANCHOR,
		CONTROL_RESET,
		CONTROL_FOCUS_RING,
		CONTROL_HOVER_HALO,
		FALLBACK_MINIMAL_POINT,
		FALLBACK_MINIMAL_LINE,
		FALLBACK_MINIMAL_BAR,
		FALLBACK_MINIMAL_HANDLE,
	])


static func role_metadata(role: String) -> Dictionary:
	var metadata := _metadata()
	return metadata.get(role, {}).duplicate(true)


static func supports_role(role: String) -> bool:
	return _metadata().has(role)


static func _metadata() -> Dictionary:
	return {
		STRUCTURE_AXIS_LINE: {
			"category": "structure",
			"pivot": "center",
			"forward": "-z",
			"batching": "line-mesh",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "opacity", "value_axis"],
		},
		STRUCTURE_TICK_MAJOR: {
			"category": "structure",
			"pivot": "center",
			"forward": "-z",
			"batching": "line-mesh",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "opacity", "value_axis"],
		},
		STRUCTURE_GRID_LINE: {
			"category": "structure",
			"pivot": "center",
			"forward": "-z",
			"batching": "line-mesh",
			"lod": ["minimal"],
			"sockets": ["data_color", "opacity"],
		},
		STRUCTURE_PLOT_BOUNDS: {
			"category": "structure",
			"pivot": "center",
			"forward": "-z",
			"batching": "line-mesh",
			"lod": ["minimal", "standard"],
			"sockets": ["outline", "opacity"],
		},
		STRUCTURE_ORIGIN: {
			"category": "structure",
			"pivot": "origin",
			"forward": "-z",
			"batching": "scene",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "secondary_color", "label_anchor"],
		},
		STRUCTURE_RESET_LANDMARK: {
			"category": "structure",
			"pivot": "floor-center",
			"forward": "-z",
			"batching": "scene",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "interaction_anchor", "label_anchor"],
		},
		MARK_POINT: {
			"category": "mark",
			"pivot": "center",
			"forward": "-z",
			"batching": "multimesh",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "outline", "opacity", "collision_shape"],
		},
		MARK_BAR: {
			"category": "mark",
			"pivot": "baseline-center",
			"forward": "-z",
			"batching": "multimesh",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "outline", "opacity", "value_axis", "collision_shape"],
		},
		MARK_LINE: {
			"category": "mark",
			"pivot": "centerline",
			"forward": "-z",
			"batching": "line-mesh",
			"lod": ["minimal", "standard"],
			"sockets": ["data_color", "opacity", "outline"],
		},
		CONTROL_HANDLE_LINEAR: _control_metadata(["data_color", "outline", "focus", "selection", "interaction_anchor", "collision_shape"]),
		CONTROL_SLIDER_TRACK: _control_metadata(["data_color", "secondary_color", "value_axis", "collision_shape"]),
		CONTROL_SLIDER_THUMB: _control_metadata(["data_color", "outline", "focus", "selection", "interaction_anchor", "collision_shape"]),
		CONTROL_BUTTON: _control_metadata(["data_color", "outline", "focus", "label_anchor", "interaction_anchor", "collision_shape"]),
		CONTROL_GRAB_ANCHOR: _control_metadata(["data_color", "outline", "focus", "interaction_anchor", "collision_shape"]),
		CONTROL_RESET: _control_metadata(["data_color", "secondary_color", "focus", "interaction_anchor", "collision_shape"]),
		CONTROL_FOCUS_RING: _control_metadata(["outline", "focus", "collision_shape"]),
		CONTROL_HOVER_HALO: _control_metadata(["secondary_color", "opacity"]),
		FALLBACK_MINIMAL_POINT: _fallback_metadata("center"),
		FALLBACK_MINIMAL_LINE: _fallback_metadata("centerline"),
		FALLBACK_MINIMAL_BAR: _fallback_metadata("baseline-center"),
		FALLBACK_MINIMAL_HANDLE: _fallback_metadata("center"),
	}


static func _control_metadata(sockets: Array[String]) -> Dictionary:
	return {
		"category": "control",
		"pivot": "center",
		"forward": "-z",
		"batching": "scene",
		"lod": ["minimal", "standard"],
		"sockets": sockets,
	}


static func _fallback_metadata(pivot: String) -> Dictionary:
	return {
		"category": "fallback",
		"pivot": pivot,
		"forward": "-z",
		"batching": "procedural",
		"lod": ["minimal"],
		"sockets": ["data_color", "opacity", "collision_shape"],
	}
