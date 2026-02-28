extends GdUnitTestSuite

# Tests for the ArrayMesh-building helpers in Chart3D and ChartFrame3D.
# The instances are NOT added to the scene tree, so _ready()/_process() never
# fire.  The geometry methods are pure computation and safe to call on orphan
# node instances.

# ---------------------------------------------------------------------------
# Chart3D._build_rounded_bar_mesh
# ---------------------------------------------------------------------------

func test_rounded_bar_mesh_returns_array_mesh() -> void:
	var chart := auto_free(Chart3D.new())
	var mesh := chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.1)
	assert_object(mesh).is_instanceof(ArrayMesh)


func test_rounded_bar_mesh_has_one_surface() -> void:
	var chart := auto_free(Chart3D.new())
	var mesh := chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.1)
	assert_int(mesh.get_surface_count()).is_equal(1)


func test_rounded_bar_mesh_has_vertices() -> void:
	var chart := auto_free(Chart3D.new())
	var mesh: ArrayMesh = chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.1)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_greater(0)


func test_rounded_bar_mesh_has_normals() -> void:
	var chart := auto_free(Chart3D.new())
	var mesh: ArrayMesh = chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.1)
	var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	assert_int(normals.size()).is_greater(0)


func test_rounded_bar_mesh_vertex_count_scales_with_segs() -> void:
	var chart := auto_free(Chart3D.new())
	var mesh_low:  ArrayMesh = chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.1, 2)
	var mesh_high: ArrayMesh = chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.1, 8)
	var n_low:  int = (mesh_low.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var n_high: int = (mesh_high.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	assert_int(n_high).is_greater(n_low)


func test_rounded_bar_mesh_large_radius_clamped() -> void:
	# An absurdly large radius must be silently clamped without errors.
	var chart := auto_free(Chart3D.new())
	var mesh := chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 999.0)
	assert_object(mesh).is_instanceof(ArrayMesh)


func test_rounded_bar_mesh_normals_are_unit_length() -> void:
	var chart := auto_free(Chart3D.new())
	var mesh: ArrayMesh = chart._build_rounded_bar_mesh(1.0, 2.0, 0.5, 0.15, 4)
	var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for n in normals:
		assert_float(n.length()).is_equal_approx(1.0, 0.001)


# ---------------------------------------------------------------------------
# ChartFrame3D._build_rounded_panel_mesh
# ---------------------------------------------------------------------------

func test_rounded_panel_mesh_returns_array_mesh() -> void:
	var frame := auto_free(ChartFrame3D.new())
	var mesh := frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 0.2)
	assert_object(mesh).is_instanceof(ArrayMesh)


func test_rounded_panel_mesh_has_one_surface() -> void:
	var frame := auto_free(ChartFrame3D.new())
	var mesh := frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 0.2)
	assert_int(mesh.get_surface_count()).is_equal(1)


func test_rounded_panel_mesh_has_vertices() -> void:
	var frame := auto_free(ChartFrame3D.new())
	var mesh: ArrayMesh = frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 0.2)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_greater(0)


func test_rounded_panel_mesh_vertex_count_scales_with_segs() -> void:
	var frame := auto_free(ChartFrame3D.new())
	var mesh_low:  ArrayMesh = frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 0.2, 2)
	var mesh_high: ArrayMesh = frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 0.2, 8)
	var n_low:  int = (mesh_low.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var n_high: int = (mesh_high.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	assert_int(n_high).is_greater(n_low)


func test_rounded_panel_mesh_large_radius_clamped() -> void:
	var frame := auto_free(ChartFrame3D.new())
	var mesh := frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 999.0)
	assert_object(mesh).is_instanceof(ArrayMesh)


func test_rounded_panel_mesh_normals_are_unit_length() -> void:
	var frame := auto_free(ChartFrame3D.new())
	var mesh: ArrayMesh = frame._build_rounded_panel_mesh(2.0, 1.5, 0.1, 0.2, 4)
	var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for n in normals:
		assert_float(n.length()).is_equal_approx(1.0, 0.001)
