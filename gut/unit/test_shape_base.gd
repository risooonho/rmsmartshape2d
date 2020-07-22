extends "res://addons/gut/test.gd"

var TEST_TEXTURE = preload("res://demo/assets/Spring/grass.png")


class z_sort:
	var z_index: int = 0

	func _init(z: int):
		z_index = z


func test_z_sort():
	var a = [z_sort.new(3), z_sort.new(5), z_sort.new(0), z_sort.new(-12)]
	a = RMSS2D_Shape_Base.sort_by_z_index(a)
	assert_eq(a[0].z_index, -12)
	assert_eq(a[1].z_index, 0)
	assert_eq(a[2].z_index, 3)
	assert_eq(a[3].z_index, 5)


func test_are_points_clockwise():
	var shape = RMSS2D_Shape_Base.new()
	add_child_autofree(shape)
	var points_clockwise = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	var points_c_clockwise = points_clockwise.duplicate()
	points_c_clockwise.invert()

	shape.add_points(points_clockwise)
	assert_true(shape.are_points_clockwise())

	shape.clear_points()
	shape.add_points(points_c_clockwise)
	assert_false(shape.are_points_clockwise())


func test_curve_duplicate():
	var shape = RMSS2D_Shape_Base.new()
	add_child_autofree(shape)
	shape.add_point(Vector2(-10, -20))
	var points = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	shape.curve_bake_interval = 35.0
	var curve = shape.get_curve()

	assert_eq(shape.get_point_count(), curve.get_point_count())
	assert_eq(shape.curve_bake_interval, curve.bake_interval)
	shape.curve_bake_interval = 25.0
	assert_ne(shape.curve_bake_interval, curve.bake_interval)

	curve.add_point(points[0])
	assert_ne(shape.get_point_count(), curve.get_point_count())
	shape.set_curve(curve)
	assert_eq(shape.get_point_count(), curve.get_point_count())


func test_tess_point_vertex_relationship():
	var shape_base = RMSS2D_Shape_Base.new()
	add_child_autofree(shape_base)
	var points = get_clockwise_points()

	shape_base.add_points(points)

	var verts = shape_base.get_vertices()
	var t_verts = shape_base.get_tessellated_points()
	assert_eq(points.size(), t_verts.size())

	var control_point_value = Vector2(-16, 0)
	var control_point_vtx_idx = 4

	shape_base.set_point_in(control_point_vtx_idx, control_point_value)
	shape_base.set_point_out(control_point_vtx_idx, control_point_value * -1)

	verts = shape_base.get_vertices()
	t_verts = shape_base.get_tessellated_points()
	assert_ne(points.size(), t_verts.size())

	var test_idx = 4
	var test_t_idx = shape_base.get_tessellated_idx_from_point(verts, t_verts, test_idx)
	assert_ne(test_idx, test_t_idx)
	assert_eq(verts[test_idx], t_verts[test_t_idx])
	var new_test_idx = shape_base.get_vertex_idx_from_tessellated_point(verts, t_verts, test_t_idx)
	assert_eq(test_idx, new_test_idx)

	var results = [
		shape_base.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx),
		shape_base.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 1),
		shape_base.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 2),
		shape_base.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 3)
	]
	assert_eq(0.0, results[0])
	var message = "Ratio increasing with distance from prev vector"
	for i in range(1, results.size(), 1):
		assert_true(results[i - 1] < results[i], message)

	results[-1] = shape_base.get_ratio_from_tessellated_point_to_vertex(
		verts, t_verts, test_t_idx - 1
	)
	assert_true(results[-1] > results[0], message)


func test_invert_point_order():
	var shape_base = RMSS2D_Shape_Base.new()
	add_child_autofree(shape_base)
	var points = get_clockwise_points()
	var size = points.size()
	var last_idx = size - 1
	var keys = shape_base.add_points(points)
	shape_base.set_point_width(keys[0], 5.0)
	assert_eq(points[0], shape_base.get_point_at_index(0).position)
	assert_eq(points[last_idx], shape_base.get_point_at_index(last_idx).position)

	assert_eq(1.0, shape_base.get_point_at_index(last_idx).properties.width)
	assert_eq(5.0, shape_base.get_point_at_index(0).properties.width)

	shape_base.invert_point_order()

	assert_eq(5.0, shape_base.get_point_at_index(last_idx).properties.width)
	assert_eq(1.0, shape_base.get_point_at_index(0).properties.width)

	assert_eq(points[0], shape_base.get_point_at_index(last_idx).position)
	assert_eq(points[last_idx], shape_base.get_point_at_index(0).position)

	assert_eq(points[1], shape_base.get_point_at_index(last_idx - 1).position)
	assert_eq(points[last_idx - 1], shape_base.get_point_at_index(1).position)

	assert_eq(points[2], shape_base.get_point_at_index(last_idx - 2).position)
	assert_eq(points[last_idx - 2], shape_base.get_point_at_index(2).position)


func test_duplicate():
	var shape_base = RMSS2D_Shape_Base.new()
	add_child_autofree(shape_base)
	var points = get_clockwise_points()
	shape_base.add_points(points)

	shape_base.set_point_width(0, 5.0)
	shape_base.set_point_width(2, 3.0)
	shape_base.set_point_width(5, 4.0)

	shape_base.set_point_texture_index(0, 1)
	shape_base.set_point_texture_index(2, 2)
	shape_base.set_point_texture_index(3, 3)
	shape_base.set_point_texture_index(5, 5)

	shape_base.set_point_texture_flip(1, true)
	shape_base.set_point_texture_flip(2, true)
	shape_base.set_point_texture_flip(4, true)

	var copy = shape_base.duplicate_self()
	add_child_autofree(copy)
	assert_ne(shape_base.get_curve(), copy.get_curve())
	assert_eq(shape_base.get_point_count(), copy.get_point_count())
	for i in range(-1, points.size(), 1):
		var s = "Test Point %s: " % i
		assert_eq(shape_base.get_point_width(i), copy.get_point_width(i), s + "Width")
		assert_eq(shape_base.get_point_texture_flip(i), copy.get_point_texture_flip(i), s + "Flip")
		assert_eq(
			shape_base.get_point_texture_index(i), copy.get_point_texture_index(i), s + "Index"
		)


func test_get_edge_materials():
	var shape_base = RMSS2D_Shape_Base.new()
	add_child_autofree(shape_base)

	var edge_mat = RMSS2D_Material_Edge.new()
	edge_mat.textures = [TEST_TEXTURE]

	var edge_mat_meta = RMSS2D_Material_Edge_Metadata.new()
	var normal_range = RMSS2D_NormalRange.new(0, 360.0)
	edge_mat_meta.edge_material = edge_mat
	edge_mat_meta.normal_range = normal_range
	assert_not_null(edge_mat_meta.edge_material)

	var s_m = RMSS2D_Material_Shape.new()
	s_m.set_edge_materials([edge_mat_meta])
	for e in s_m.get_edge_materials(Vector2(1, 0)):
		assert_not_null(e)
		assert_not_null(e.edge_material)
		assert_eq(e, edge_mat_meta)
		assert_eq(e.edge_material, edge_mat)

	var points = get_clockwise_points()
	var edge_data = shape_base.get_edge_materials(points, s_m, false)

	# Should be 1 edge, as the normal range specified covers the full 360.0 degrees
	assert_eq(edge_data.size(), 1, "Should be one EdgeData specified")
	for e in edge_data:
		assert_not_null(e)
		assert_not_null(e.material)
		assert_eq(e.material, edge_mat)


var scale_params = [1.0, 1.5, 0.5, 0.0, 10.0, -1.0]


func test_build_quad_from_point(scale = use_parameters(scale_params)):
	var shape_base = RMSS2D_Shape_Base.new()
	add_child_autofree(shape_base)

	var edge_mat = RMSS2D_Material_Edge.new()
	edge_mat.textures = [TEST_TEXTURE]

	var start_point_1 = Vector2(100, 150)
	var start_point_2 = Vector2(200, 100)
	var points = [start_point_1, start_point_2]

	var delta = points[1] - points[0]
	var normal = Vector2(delta.y, -delta.x).normalized()

	var tex_size = TEST_TEXTURE.get_size()
	var extents = ((tex_size / 2.0) * scale) * normal

	var quad = shape_base._build_quad_from_point(
		points, 0, null, null, tex_size, 1.0, false, false, false, scale, 0.0, 0.0
	)
	var expected_points = [
		# Top Left (A)
		start_point_1 + extents,
		# Bottom Left (B)
		start_point_1 - extents,
		# Bottom Right (C)
		start_point_2 - extents,
		# Top Right (D)
		start_point_2 + extents
	]
	assert_eq(quad.pt_a, expected_points[0])
	assert_eq(quad.pt_b, expected_points[1])
	assert_eq(quad.pt_c, expected_points[2])
	assert_eq(quad.pt_d, expected_points[3])

	# Flip edges
	quad = shape_base._build_quad_from_point(
		points, 0, null, null, tex_size, 1.0, true, false, false, scale, 0.0, 0.0
	)
	assert_eq(quad.pt_a, expected_points[1])
	assert_eq(quad.pt_b, expected_points[0])
	assert_eq(quad.pt_c, expected_points[3])
	assert_eq(quad.pt_d, expected_points[2])


func get_clockwise_points() -> Array:
	return [
		Vector2(0, 0),
		Vector2(50, -50),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(-50, 150),
		Vector2(-100, 100)
	]
