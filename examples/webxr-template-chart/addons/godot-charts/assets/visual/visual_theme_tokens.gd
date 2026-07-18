class_name VisualThemeTokens
extends Resource

const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")

@export var theme_id := "instrument_light"
@export var schema_version := "1.0"

@export_group("Colors")
@export var data_primary := Color(0.02, 0.35, 0.72, 1.0)
@export var data_secondary := Color(0.0, 0.57, 0.50, 1.0)
@export var data_warning := Color(0.89, 0.43, 0.10, 1.0)
@export var surface := Color(0.96, 0.97, 0.98, 1.0)
@export var structure := Color(0.32, 0.36, 0.42, 0.76)
@export var structure_subtle := Color(0.41, 0.45, 0.52, 0.24)
@export var text := Color(0.10, 0.12, 0.16, 1.0)
@export var focus := Color(0.0, 0.48, 0.86, 1.0)
@export var selected := Color(0.97, 0.68, 0.18, 1.0)
@export var active := Color(0.87, 0.22, 0.30, 1.0)
@export var disabled := Color(0.52, 0.55, 0.60, 0.42)
@export var error := Color(0.82, 0.12, 0.18, 1.0)

@export_group("Dimensions")
@export var axis_radius := 0.012
@export var grid_radius := 0.004
@export var point_radius := 0.045
@export var bar_width := 0.16
@export var handle_radius := 0.09
@export var direct_touch_target_radius := 0.13
@export var slider_track_radius := 0.018
@export var focus_ring_radius := 0.115
@export var focus_ring_thickness := 0.008
@export var bounds_radius := 0.007

@export_group("Budgets")
@export var webxr_triangle_budget_per_asset := 256
@export var uses_shadows := false
@export var uses_transparency := true
@export var reduced_motion := true


static func instrument_light() -> VisualThemeTokens:
	return VisualThemeTokens.new()


static func webxr_performance() -> VisualThemeTokens:
	var tokens := VisualThemeTokens.new()
	tokens.theme_id = "webxr_performance"
	tokens.data_primary = Color(0.0, 0.44, 0.74, 1.0)
	tokens.data_secondary = Color(0.0, 0.56, 0.38, 1.0)
	tokens.surface = Color(0.92, 0.93, 0.94, 1.0)
	tokens.structure = Color(0.18, 0.20, 0.24, 0.82)
	tokens.structure_subtle = Color(0.28, 0.31, 0.36, 0.26)
	tokens.focus = Color(0.0, 0.50, 0.86, 1.0)
	tokens.selected = Color(0.92, 0.58, 0.12, 1.0)
	tokens.axis_radius = 0.01
	tokens.grid_radius = 0.003
	tokens.point_radius = 0.04
	tokens.handle_radius = 0.085
	tokens.direct_touch_target_radius = 0.14
	tokens.webxr_triangle_budget_per_asset = 128
	tokens.uses_transparency = false
	return tokens


func color_for(role: String, state := Roles.STATE_NORMAL) -> Color:
	if state == Roles.STATE_DISABLED:
		return disabled
	if state == Roles.STATE_ERROR:
		return error
	if state == Roles.STATE_WARNING:
		return data_warning
	if state == Roles.STATE_ACTIVE:
		return active
	if state == Roles.STATE_SELECTED:
		return selected
	if state == Roles.STATE_FOCUS:
		return focus
	if state == Roles.STATE_HOVER:
		return data_secondary
	if role.begins_with("structure/"):
		return structure
	if role == Roles.STRUCTURE_GRID_LINE or role == Roles.CONTROL_HOVER_HALO:
		return structure_subtle
	if role.begins_with("control/"):
		return focus
	if role.begins_with("fallback/"):
		return data_secondary
	return data_primary


func radius_for(role: String) -> float:
	match role:
		Roles.STRUCTURE_AXIS_LINE, Roles.STRUCTURE_TICK_MAJOR:
			return axis_radius
		Roles.STRUCTURE_GRID_LINE:
			return grid_radius
		Roles.STRUCTURE_PLOT_BOUNDS:
			return bounds_radius
		Roles.MARK_POINT, Roles.FALLBACK_MINIMAL_POINT:
			return point_radius
		Roles.MARK_BAR, Roles.FALLBACK_MINIMAL_BAR:
			return bar_width
		Roles.CONTROL_SLIDER_TRACK:
			return slider_track_radius
		Roles.CONTROL_FOCUS_RING:
			return focus_ring_radius
		Roles.CONTROL_HANDLE_LINEAR, Roles.CONTROL_SLIDER_THUMB, Roles.CONTROL_GRAB_ANCHOR, Roles.CONTROL_RESET, Roles.FALLBACK_MINIMAL_HANDLE:
			return handle_radius
	return axis_radius


func material_for(role: String, state := Roles.STATE_NORMAL) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "%s:%s:%s" % [theme_id, role, state]
	material.albedo_color = color_for(role, state)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_receive_shadows = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if material.albedo_color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func manifest() -> Dictionary:
	return {
		"schema": "godot-charts/visual-theme-tokens/1.0",
		"id": theme_id,
		"budgets": {
			"webxr_triangle_budget_per_asset": webxr_triangle_budget_per_asset,
			"uses_shadows": uses_shadows,
			"uses_transparency": uses_transparency,
			"reduced_motion": reduced_motion,
		},
		"roles": Array(Roles.all_roles()),
	}
