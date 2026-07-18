class_name VisualAssetGallery3D
extends Node3D

const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")
const Factory = preload("res://addons/godot-charts/assets/visual/procedural_visual_asset_factory.gd")
const Tokens = preload("res://addons/godot-charts/assets/visual/visual_theme_tokens.gd")

@export var spacing := Vector3(0.42, 0.0, 0.42)
@export var columns := 5
@export var use_webxr_performance_theme := false

var _factory: ProceduralVisualAssetFactory


func _ready() -> void:
	build_gallery()


func build_gallery() -> void:
	for child in get_children():
		child.queue_free()
	var theme := Tokens.webxr_performance() if use_webxr_performance_theme else Tokens.instrument_light()
	_factory = Factory.new(theme)
	var roles := Roles.all_roles()
	for index: int in roles.size():
		var role := roles[index]
		var state := _state_for_index(index)
		var asset := _factory.instantiate(role, state, _options_for(role))
		asset.position = Vector3(float(index % columns) * spacing.x, 0.0, float(index / columns) * spacing.z)
		add_child(asset)


func gallery_snapshot() -> Dictionary:
	return {
		"asset_count": get_child_count(),
		"theme_id": "none" if _factory == null else _factory.tokens.theme_id,
		"roles": Array(Roles.all_roles()),
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
