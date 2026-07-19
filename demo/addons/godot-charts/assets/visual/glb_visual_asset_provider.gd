class_name GlbVisualAssetProvider
extends RefCounted

const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")
const Tokens = preload("res://addons/godot-charts/assets/visual/visual_theme_tokens.gd")
const Factory = preload("res://addons/godot-charts/assets/visual/procedural_visual_asset_factory.gd")

const DEFAULT_MANIFEST_PATH := "res://addons/godot-charts/assets/visual/glb/asset_pack_manifest.json"

var manifest_path: String
var manifest: Dictionary = {}
var diagnostics: Array[Dictionary] = []
var fallback_factory: ProceduralVisualAssetFactory


func _init(path := DEFAULT_MANIFEST_PATH, theme_tokens: VisualThemeTokens = null) -> void:
	manifest_path = path
	fallback_factory = Factory.new(theme_tokens if theme_tokens != null else Tokens.instrument_light())
	load_manifest()


func load_manifest() -> bool:
	diagnostics.clear()
	manifest = {}
	if not FileAccess.file_exists(manifest_path):
		_report("missing-manifest", "GLB asset manifest is unavailable.", manifest_path)
		return false
	var text := FileAccess.get_file_as_string(manifest_path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		_report("invalid-manifest-json", "GLB asset manifest must parse as a Dictionary.", manifest_path)
		return false
	if str(parsed.get("schema", "")) != "godot-charts/visual-asset-pack/1.0":
		_report("unsupported-manifest-schema", "GLB asset manifest schema is unsupported.", manifest_path)
		return false
	if not parsed.get("roles", {}) is Dictionary:
		_report("missing-role-map", "GLB asset manifest must contain a roles map.", manifest_path)
		return false
	manifest = parsed
	return true


func supports_role(role: String) -> bool:
	return _role_entry(role) != null


func instantiate(role: String, state := Roles.STATE_NORMAL, options: Dictionary = {}) -> Node3D:
	var entry := _role_entry(role)
	if entry != null:
		var tier := str(options.get("performance_tier", "desktop"))
		if not _supports_tier(role, entry, tier):
			return _fallback(role, state, options, entry)
		var asset_path := str(entry.get("asset", ""))
		var packed := load(asset_path) as PackedScene
		if packed != null:
			var instance := packed.instantiate() as Node3D
			if instance != null:
				instance.name = _node_name(role)
				instance.set_meta("visual_role", role)
				instance.set_meta("asset_source", "glb")
				instance.set_meta("asset_pack_id", str(manifest.get("id", "")))
				instance.set_meta("visual_descriptor", descriptor(role))
				_attach_collision_proxy(instance, role, entry)
				return instance
		_report("glb-load-failed", "GLB asset could not be loaded or instantiated.", asset_path)
	return _fallback(role, state, options, entry)


func descriptor(role: String) -> Dictionary:
	var entry := _role_entry(role)
	if entry == null:
		var procedural := fallback_factory.descriptor(_fallback_role_for(role, null))
		procedural["requested_role"] = role
		procedural["source"] = "procedural-fallback"
		procedural["provider"] = "glb"
		return procedural
	var result: Dictionary = entry.duplicate(true)
	result["role"] = role
	result["source"] = "glb"
	result["provider"] = "glb"
	result["asset_pack_id"] = str(manifest.get("id", ""))
	return result


func role_count() -> int:
	var roles: Dictionary = manifest.get("roles", {})
	return roles.size()


func _role_entry(role: String) -> Variant:
	if manifest.is_empty():
		load_manifest()
	var roles: Dictionary = manifest.get("roles", {})
	if not roles.has(role):
		_report("missing-role", "GLB asset manifest does not define the requested role.", role)
		return null
	var entry: Variant = roles[role]
	if not entry is Dictionary:
		_report("invalid-role-entry", "GLB asset manifest role entry is not a Dictionary.", role)
		return null
	return entry if entry is Dictionary else null


func _fallback(role: String, state: String, options: Dictionary, entry: Variant) -> Node3D:
	var fallback_role := _fallback_role_for(role, entry)
	var asset: Node3D = fallback_factory.instantiate(fallback_role, state, options)
	asset.set_meta("requested_visual_role", role)
	asset.set_meta("asset_source", "procedural-fallback")
	return asset


func _supports_tier(role: String, entry: Dictionary, tier_name: String) -> bool:
	var tiers: Variant = entry.get("performance_tiers", {})
	if not tiers is Dictionary:
		_report("missing-performance-tiers", "GLB asset role does not declare performance tiers.", role)
		return false
	var tier: Variant = tiers.get(tier_name)
	if not tier is Dictionary:
		_report("unsupported-performance-tier", "GLB asset role does not support the requested performance tier.", "%s:%s" % [role, tier_name])
		return false
	if str(tier.get("lod", "")).is_empty() or int(tier.get("max_triangles", 0)) <= 0:
		_report("invalid-performance-tier", "GLB asset performance tier is missing lod or triangle budget.", "%s:%s" % [role, tier_name])
		return false
	return true


func _attach_collision_proxy(instance: Node3D, role: String, entry: Dictionary) -> void:
	if instance.find_child("CollisionProxy", true, false) != null:
		return
	var collision: Variant = entry.get("collision", {})
	if not collision is Dictionary:
		return
	var shape := CollisionShape3D.new()
	match str(collision.get("type", "")):
		"sphere":
			var sphere := SphereShape3D.new()
			sphere.radius = maxf(float(collision.get("diameter_m", 0.16)) * 0.5, 0.01)
			shape.shape = sphere
		"box":
			var box := BoxShape3D.new()
			var size: Variant = collision.get("size_m", [0.16, 0.16, 0.16])
			if size is Array and size.size() >= 3:
				box.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
			else:
				box.size = Vector3(0.16, 0.16, 0.16)
			shape.shape = box
		_:
			return
	var body := StaticBody3D.new()
	body.name = "CollisionProxy"
	body.collision_layer = int(collision.get("collision_layer", 1))
	body.collision_mask = 0
	body.set_meta("visual_role", role)
	body.set_meta("asset_source", "glb")
	body.set_meta("collision_role", "picking")
	body.add_child(shape)
	instance.add_child(body)


func _fallback_role_for(role: String, entry: Variant) -> String:
	if entry is Dictionary and not str(entry.get("fallback", "")).is_empty():
		return str(entry["fallback"])
	match role:
		Roles.MARK_POINT:
			return Roles.FALLBACK_MINIMAL_POINT
		Roles.MARK_BAR:
			return Roles.FALLBACK_MINIMAL_BAR
		Roles.MARK_LINE:
			return Roles.FALLBACK_MINIMAL_LINE
		_:
			return Roles.FALLBACK_MINIMAL_HANDLE


func _node_name(role: String) -> String:
	var result := ""
	for part: String in role.split("/"):
		result += part.capitalize().replace(" ", "")
	return result


func _report(code: String, message: String, path: String) -> void:
	diagnostics.append({
		"severity": "error",
		"code": code,
		"message": message,
		"path": path,
	})
