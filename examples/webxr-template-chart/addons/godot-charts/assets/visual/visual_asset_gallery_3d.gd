class_name VisualAssetGallery3D
extends Node3D

const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")
const Factory = preload("res://addons/godot-charts/assets/visual/procedural_visual_asset_factory.gd")
const GlbProvider = preload("res://addons/godot-charts/assets/visual/glb_visual_asset_provider.gd")
const Tokens = preload("res://addons/godot-charts/assets/visual/visual_theme_tokens.gd")

@export var spacing := Vector3(0.42, 0.0, 0.42)
@export var columns := 5
@export var use_webxr_performance_theme := false
@export var show_glb_variants := true
@export var variant_spacing := 0.18

var _factory: ProceduralVisualAssetFactory
var _provider: GlbVisualAssetProvider


func _ready() -> void:
	build_gallery()


func build_gallery() -> void:
	for child in get_children():
		child.queue_free()
	var theme := Tokens.webxr_performance() if use_webxr_performance_theme else Tokens.instrument_light()
	_factory = Factory.new(theme)
	_provider = GlbProvider.new(GlbProvider.DEFAULT_MANIFEST_PATH, theme)
	var roles := Roles.all_roles()
	for index: int in roles.size():
		var role := roles[index]
		var state := _state_for_index(index)
		var base_position := Vector3(float(index % columns) * spacing.x, 0.0, float(index / columns) * spacing.z)
		var procedural := _factory.instantiate(role, state, _options_for(role))
		procedural.name = "Procedural_%s" % procedural.name
		procedural.position = base_position + Vector3(-variant_spacing if show_glb_variants else 0.0, 0.0, 0.0)
		procedural.set_meta("gallery_variant", "procedural")
		add_child(procedural)
		if show_glb_variants and _provider.supports_role(role):
			var glb := _provider.instantiate(role, state, _options_for(role))
			glb.name = "Glb_%s" % glb.name
			glb.position = base_position + Vector3(variant_spacing, 0.0, 0.0)
			glb.set_meta("gallery_variant", "glb")
			add_child(glb)


func gallery_snapshot() -> Dictionary:
	return {
		"asset_count": get_child_count(),
		"theme_id": "none" if _factory == null else _factory.tokens.theme_id,
		"roles": Array(Roles.all_roles()),
		"procedural_count": _variant_count("procedural"),
		"glb_count": _variant_count("glb"),
	}


func _state_for_index(index: int) -> String:
	var states := [
		Roles.STATE_NORMAL,
		Roles.STATE_HOVER,
		Roles.STATE_FOCUS,
		Roles.STATE_SELECTED,
		Roles.STATE_ACTIVE,
	]
	return states[index % states.size()]


func _options_for(role: String) -> Dictionary:
	match role:
		Roles.STRUCTURE_PLOT_BOUNDS:
			return {"size": Vector3(0.28, 0.2, 0.24)}
		Roles.MARK_BAR, Roles.FALLBACK_MINIMAL_BAR:
			return {"size": Vector3(0.14, 0.24, 0.14)}
		Roles.STRUCTURE_AXIS_LINE, Roles.STRUCTURE_TICK_MAJOR, Roles.STRUCTURE_GRID_LINE, Roles.MARK_LINE, Roles.FALLBACK_MINIMAL_LINE, Roles.CONTROL_SLIDER_TRACK:
			return {"length": 0.32}
	return {}


func _variant_count(variant: String) -> int:
	var count := 0
	for child in get_children():
		if child.get_meta("gallery_variant", "") == variant:
			count += 1
	return count
