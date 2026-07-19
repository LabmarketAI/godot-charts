extends SceneTree

const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")
const Tokens = preload("res://addons/godot-charts/assets/visual/visual_theme_tokens.gd")
const Factory = preload("res://addons/godot-charts/assets/visual/procedural_visual_asset_factory.gd")
const GlbProvider = preload("res://addons/godot-charts/assets/visual/glb_visual_asset_provider.gd")
const Gallery = preload("res://addons/godot-charts/assets/visual/visual_asset_gallery_3d.gd")

var _failures := 0


func _initialize() -> void:
	var tokens := Tokens.webxr_performance()
	var factory := Factory.new(tokens)
	for role: String in Roles.all_roles():
		var asset := factory.instantiate(role)
		root.add_child(asset)
		_assert(asset.get_meta("visual_role") == role, "asset carries role metadata: %s" % role)
		_assert(asset.has_meta("visual_descriptor"), "asset carries descriptor metadata: %s" % role)
		var descriptor: Dictionary = asset.get_meta("visual_descriptor")
		_assert(descriptor.get("role", "") == role, "descriptor role matches: %s" % role)
		_assert(descriptor.get("theme_id", "") == "webxr_performance", "descriptor includes theme id: %s" % role)
		_assert(not descriptor.get("sockets", []).is_empty(), "descriptor declares material/control sockets: %s" % role)
		_assert(_mesh_count(asset) > 0, "asset has visible mesh content: %s" % role)
		asset.queue_free()

	var handle := factory.instantiate(Roles.CONTROL_HANDLE_LINEAR, Roles.STATE_FOCUS)
	root.add_child(handle)
	_assert(_find_child(handle, "CollisionProxy") != null, "handle exposes a collision proxy")
	_assert(_find_child(handle, "RedundantFocusRing") != null, "handle includes non-color focus cue")
	handle.queue_free()

	var provider := GlbProvider.new()
	_assert(provider.role_count() >= 1, "GLB provider loads manifest roles")
	_assert(provider.supports_role(Roles.CONTROL_HANDLE_LINEAR), "GLB provider supports control/handle_linear")
	var glb_handle := provider.instantiate(Roles.CONTROL_HANDLE_LINEAR)
	root.add_child(glb_handle)
	_assert(glb_handle.get_meta("visual_role") == Roles.CONTROL_HANDLE_LINEAR, "GLB handle carries requested role metadata")
	_assert(glb_handle.get_meta("asset_source") == "glb", "GLB handle uses manifest asset source")
	_assert(_find_child(glb_handle, "role__control_handle_linear__axis_alignment_inset_x_lod0") != null, "GLB handle includes x axis cue")
	_assert(_find_child(glb_handle, "role__control_handle_linear__axis_alignment_inset_y_lod0") != null, "GLB handle includes y axis cue")
	_assert(_find_child(glb_handle, "socket__control_handle_linear__warning_stripe") == null, "GLB handle does not export visible warning stripe")
	_assert(_find_child(glb_handle, "socket__control_handle_linear__error_stripe") == null, "GLB handle does not export visible error stripe")
	var glb_collision := _find_child(glb_handle, "CollisionProxy")
	_assert(glb_collision is StaticBody3D, "GLB handle exposes runtime StaticBody collision proxy")
	_assert(_find_first_shape(glb_collision) is CollisionShape3D, "GLB handle collision proxy has a shape")
	glb_handle.queue_free()

	var fallback := provider.instantiate("control/not_in_manifest")
	root.add_child(fallback)
	_assert(fallback.get_meta("asset_source") == "procedural-fallback", "GLB provider falls back for missing role")
	_assert(_has_diagnostic(provider.diagnostics, "missing-role"), "GLB provider reports missing role diagnostic")
	fallback.queue_free()

	provider.diagnostics.clear()
	var tier_fallback := provider.instantiate(Roles.CONTROL_HANDLE_LINEAR, Roles.STATE_NORMAL, {"performance_tier": "watch_xr"})
	root.add_child(tier_fallback)
	_assert(tier_fallback.get_meta("asset_source") == "procedural-fallback", "GLB provider falls back for unsupported performance tier")
	_assert(_has_diagnostic(provider.diagnostics, "unsupported-performance-tier"), "GLB provider reports unsupported tier diagnostic")
	tier_fallback.queue_free()

	var gallery := Gallery.new()
	root.add_child(gallery)
	gallery.build_gallery()
	var snapshot := gallery.gallery_snapshot()
	_assert(snapshot["procedural_count"] == Roles.all_roles().size(), "gallery instantiates every procedural core role")
	_assert(snapshot["glb_count"] >= 1, "gallery instantiates GLB-backed variants")
	_assert(snapshot["asset_count"] == snapshot["procedural_count"] + snapshot["glb_count"], "gallery reports procedural and GLB variants separately")
	gallery.queue_free()

	var scene := load("res://main.tscn") as PackedScene
	_assert(scene != null, "visual asset gallery example scene loads")
	if scene != null:
		var instance := scene.instantiate()
		root.add_child(instance)
		await process_frame
		var example_gallery := instance.find_child("VisualAssetGallery3D", true, false)
		_assert(example_gallery != null, "visual asset gallery example creates gallery")
		instance.queue_free()

	if _failures > 0:
		quit(1)
	else:
		print("Visual asset generation checks passed roles=%d" % Roles.all_roles().size())
		quit(0)


func _mesh_count(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_count(child)
	return count


func _find_child(node: Node, child_name: String) -> Node:
	if node.name == child_name:
		return node
	for child in node.get_children():
		var match := _find_child(child, child_name)
		if match != null:
			return match
	return null


func _find_first_shape(node: Node) -> Node:
	if node is CollisionShape3D:
		return node
	for child in node.get_children():
		var match := _find_first_shape(child)
		if match != null:
			return match
	return null


func _has_diagnostic(diagnostics: Array[Dictionary], code: String) -> bool:
	for diagnostic in diagnostics:
		if diagnostic.get("code", "") == code:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
