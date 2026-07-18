class_name ProceduralVisualAssetFactory
extends RefCounted

const Roles = preload("res://addons/godot-charts/assets/visual/visual_asset_roles.gd")
const Tokens = preload("res://addons/godot-charts/assets/visual/visual_theme_tokens.gd")

var tokens: VisualThemeTokens


func _init(theme_tokens: VisualThemeTokens = null) -> void:
	tokens = theme_tokens if theme_tokens != null else Tokens.instrument_light()


func instantiate(role: String, state := Roles.STATE_NORMAL, options: Dictionary = {}) -> Node3D:
	match role:
		Roles.STRUCTURE_AXIS_LINE, Roles.STRUCTURE_TICK_MAJOR, Roles.STRUCTURE_GRID_LINE, Roles.MARK_LINE, Roles.FALLBACK_MINIMAL_LINE:
			return _line_asset(role, state, options)
		Roles.STRUCTURE_PLOT_BOUNDS:
			return _bounds_asset(role, state, options)
		Roles.STRUCTURE_ORIGIN:
			return _origin_asset(role, state)
		Roles.STRUCTURE_RESET_LANDMARK, Roles.CONTROL_RESET:
			return _reset_landmark_asset(role, state)
		Roles.MARK_POINT, Roles.FALLBACK_MINIMAL_POINT:
			return _sphere_asset(role, state, tokens.radius_for(role), 12, 6)
		Roles.MARK_BAR, Roles.FALLBACK_MINIMAL_BAR:
			return _bar_asset(role, state, options)
		Roles.CONTROL_HANDLE_LINEAR, Roles.CONTROL_SLIDER_THUMB, Roles.CONTROL_GRAB_ANCHOR, Roles.FALLBACK_MINIMAL_HANDLE:
			return _handle_asset(role, state)
		Roles.CONTROL_SLIDER_TRACK:
			return _slider_track_asset(role, state, options)
		Roles.CONTROL_BUTTON:
			return _button_asset(role, state, options)
		Roles.CONTROL_FOCUS_RING:
			return _focus_ring_asset(role, state)
		Roles.CONTROL_HOVER_HALO:
			return _sphere_asset(role, state, tokens.focus_ring_radius, 16, 4, 0.18)
		_:
			return _handle_asset(Roles.FALLBACK_MINIMAL_HANDLE, Roles.STATE_WARNING)


func descriptor(role: String) -> Dictionary:
	var metadata := Roles.role_metadata(role)
	metadata["role"] = role
	metadata["theme_id"] = tokens.theme_id
	metadata["license"] = "MIT"
	metadata["source"] = "procedural"
	metadata["dimensions"] = _dimensions_for(role)
	metadata["webxr_triangle_budget"] = tokens.webxr_triangle_budget_per_asset
	return metadata


func _line_asset(role: String, state: String, options: Dictionary) -> Node3D:
	var length := float(options.get("length", 1.0))
	var root := _root(role)
	var radius := tokens.radius_for(role)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(radius * 2.0, radius * 2.0, length)
	mesh.material = tokens.material_for(role, state)
	root.add_child(_mesh_instance("Line", mesh))
	return root


func _bounds_asset(role: String, state: String, options: Dictionary) -> Node3D:
	var size: Vector3 = options.get("size", Vector3(1.0, 1.0, 1.0))
	var root := _root(role)
	var low := size * -0.5
	var high := size * 0.5
	var edges: Array[Array] = [
		[Vector3(low.x, low.y, low.z), Vector3(high.x, low.y, low.z)],
		[Vector3(low.x, high.y, low.z), Vector3(high.x, high.y, low.z)],
		[Vector3(low.x, low.y, high.z), Vector3(high.x, low.y, high.z)],
		[Vector3(low.x, high.y, high.z), Vector3(high.x, high.y, high.z)],
		[Vector3(low.x, low.y, low.z), Vector3(low.x, high.y, low.z)],
		[Vector3(high.x, low.y, low.z), Vector3(high.x, high.y, low.z)],
		[Vector3(low.x, low.y, high.z), Vector3(low.x, high.y, high.z)],
		[Vector3(high.x, low.y, high.z), Vector3(high.x, high.y, high.z)],
		[Vector3(low.x, low.y, low.z), Vector3(low.x, low.y, high.z)],
		[Vector3(high.x, low.y, low.z), Vector3(high.x, low.y, high.z)],
		[Vector3(low.x, high.y, low.z), Vector3(low.x, high.y, high.z)],
		[Vector3(high.x, high.y, low.z), Vector3(high.x, high.y, high.z)],
	]
	for edge: Array in edges:
		root.add_child(_axis_aligned_segment(role, state, edge[0], edge[1]))
	return root


func _origin_asset(role: String, state: String) -> Node3D:
	var root := _root(role)
	var x := _line_asset(Roles.STRUCTURE_AXIS_LINE, state, {"length": 0.28})
	x.name = "XAxis"
	x.position.x = 0.14
	x.rotation_degrees.y = 90.0
	root.add_child(x)
	var y := _line_asset(Roles.STRUCTURE_AXIS_LINE, state, {"length": 0.28})
	y.name = "YAxis"
	y.position.y = 0.14
	y.rotation_degrees.x = 90.0
	root.add_child(y)
	var z := _line_asset(Roles.STRUCTURE_AXIS_LINE, state, {"length": 0.28})
	z.name = "ZAxis"
	z.position.z = -0.14
	root.add_child(z)
	return root


func _reset_landmark_asset(role: String, state: String) -> Node3D:
	var root := _root(role)
	var half := 0.095
	root.add_child(_axis_aligned_segment(role, state, Vector3(-half, 0.0, -half), Vector3(half, 0.0, -half)))
	root.add_child(_axis_aligned_segment(role, state, Vector3(half, 0.0, -half), Vector3(half, 0.0, half)))
	root.add_child(_axis_aligned_segment(role, state, Vector3(half, 0.0, half), Vector3(-half, 0.0, half)))
	root.add_child(_axis_aligned_segment(role, state, Vector3(-half, 0.0, half), Vector3(-half, 0.0, -half)))
	var mark := _line_asset(Roles.STRUCTURE_AXIS_LINE, state, {"length": 0.16})
	mark.name = "ForwardMark"
	mark.position.z = -0.11
	root.add_child(mark)
	return root


func _sphere_asset(role: String, state: String, radius: float, radial_segments: int, rings: int, alpha_override := -1.0) -> Node3D:
	var root := _root(role)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	var material := tokens.material_for(role, state)
	if alpha_override >= 0.0:
		material.albedo_color.a = alpha_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	root.add_child(_mesh_instance("Sphere", mesh))
	_add_sphere_collision(root, radius)
	return root


func _bar_asset(role: String, state: String, options: Dictionary) -> Node3D:
	var root := _root(role)
	var size: Vector3 = options.get("size", Vector3(tokens.bar_width, 0.5, tokens.bar_width))
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = tokens.material_for(role, state)
	var instance := _mesh_instance("Bar", mesh)
	instance.position.y = size.y * 0.5
	root.add_child(instance)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_collision(root, shape, Vector3(0.0, size.y * 0.5, 0.0))
	return root


func _handle_asset(role: String, state: String) -> Node3D:
	var root := _sphere_asset(role, state, tokens.handle_radius, 16, 8)
	root.name = _node_name(role)
	var focus_ring := _focus_ring_asset(Roles.CONTROL_FOCUS_RING, state)
	focus_ring.name = "RedundantFocusRing"
	root.add_child(focus_ring)
	_add_sphere_collision(root, tokens.direct_touch_target_radius)
	return root


func _slider_track_asset(role: String, state: String, options: Dictionary) -> Node3D:
	var length := float(options.get("length", 0.72))
	var root := _line_asset(role, state, {"length": length})
	root.name = _node_name(role)
	return root


func _button_asset(role: String, state: String, options: Dictionary) -> Node3D:
	var root := _root(role)
	var size: Vector3 = options.get("size", Vector3(0.28, 0.09, 0.035))
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = tokens.material_for(role, state)
	root.add_child(_mesh_instance("ButtonPlate", mesh))
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x + 0.04, size.y + 0.04, size.z + 0.04)
	_add_collision(root, shape)
	return root


func _focus_ring_asset(role: String, state: String) -> Node3D:
	var root := _root(role)
	var half := tokens.focus_ring_radius
	var ring_state := state if state != Roles.STATE_NORMAL else Roles.STATE_FOCUS
	root.add_child(_axis_aligned_segment(role, ring_state, Vector3(-half, -half, 0.0), Vector3(half, -half, 0.0)))
	root.add_child(_axis_aligned_segment(role, ring_state, Vector3(half, -half, 0.0), Vector3(half, half, 0.0)))
	root.add_child(_axis_aligned_segment(role, ring_state, Vector3(half, half, 0.0), Vector3(-half, half, 0.0)))
	root.add_child(_axis_aligned_segment(role, ring_state, Vector3(-half, half, 0.0), Vector3(-half, -half, 0.0)))
	return root


func _root(role: String) -> Node3D:
	var root := Node3D.new()
	root.name = _node_name(role)
	root.set_meta("visual_role", role)
	root.set_meta("visual_descriptor", descriptor(role))
	return root


func _mesh_instance(instance_name: String, mesh: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = instance_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _add_sphere_collision(root: Node3D, radius: float) -> void:
	var shape := SphereShape3D.new()
	shape.radius = radius
	_add_collision(root, shape)


func _add_collision(root: Node3D, shape: Shape3D, local_position := Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionProxy"
	body.collision_layer = 0
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = local_position
	body.add_child(collision)
	root.add_child(body)


func _axis_aligned_segment(role: String, state: String, start: Vector3, end: Vector3) -> Node3D:
	var root := _root(role)
	var radius := tokens.radius_for(role)
	var delta := end - start
	var mesh := BoxMesh.new()
	mesh.size = Vector3(
		maxf(absf(delta.x), radius * 2.0),
		maxf(absf(delta.y), radius * 2.0),
		maxf(absf(delta.z), radius * 2.0)
	)
	mesh.material = tokens.material_for(role, state)
	root.position = (start + end) * 0.5
	root.add_child(_mesh_instance("Segment", mesh))
	return root


func _dimensions_for(role: String) -> Dictionary:
	return {
		"radius": tokens.radius_for(role),
		"direct_touch_target_radius": tokens.direct_touch_target_radius,
		"unit": "meters",
	}


func _node_name(role: String) -> String:
	var parts := role.split("/")
	var name := ""
	for part: String in parts:
		name += part.capitalize().replace(" ", "")
	return name
