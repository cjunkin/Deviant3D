extends Spatial

export var grid_mat : Material = preload("res://Gfx/Material/Grid.tres")
export (Material) var land_mat : Material
export (Material) var grass_mat : Material
export (Material) var water_mat : Material

var rng := RandomNumberGenerator.new()

# TODO: make it a plane

func gen_terrain(s := G.TERRAIN_SEED, NUM_PTS := 32, SPACING := 32.0) -> void:
	var RAND_OFFSET_MAX := SPACING / 4.0
	# Cube looks like 
	#    e-------f
	#   /|      /|
	#  / |     / |
	# a--|----b  |
	# |  g----|--h
	# | /     | /
	# c-------d
	var points := PoolIntArray([
	0, 11, 18, # a
	4, 15, 17, # c

	2,  8, 16, # b
	6, 12, 19, # d

	3,  9, 22, # e
	7, 13, 21, # g

	1, 10, 20, # f
	5, 14, 23  # h
	])
	
	rng.seed = s
	
	var start : float = -NUM_PTS * SPACING / 2.0
	var pts := PoolVector2Array([])
	var should_offset := false
	for y in range(start, SPACING * NUM_PTS + start, SPACING):
		for x in range(start, SPACING * NUM_PTS + start, SPACING):
			pts.append(
				Vector2(
					x, 
					y )# + int(should_offset) * SPACING / 2)
				 # initial point
				+ (Vector2(
					rng.randf(), 
					rng.randf()
				) - Vector2.ONE * .5) * RAND_OFFSET_MAX * 2 # random offset
			)
			should_offset = !should_offset
	
	var noise := OpenSimplexNoise.new()
	noise.seed = s
	noise.octaves = 4
	noise.period = 20
	noise.persistence = .8
	
	var vertices := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var ignored_normals := PoolIntArray([
			8, 10, 12, 14, # right
			9, 11, 13, 15 # left
	])
	# var top_bot := [16, 18, 20, 22, 17, 19, 21, 23]
	for y in range(NUM_PTS - 1):
		for x in range(NUM_PTS - 1):
			var rand_height := (noise.get_noise_2d(x + rng.randf() - .5, y + rng.randf() - .5) + .9) * 4.0
#			print(rand_height)
			var mat: Material
			if rand_height < 3.5:
				continue
#				mat = water_mat
#				rand_height -= 3
			elif rand_height < 4.25:
				mat = land_mat
#			elif rand_height < 6:
#				mat = land_mat
			else:
				mat = grass_mat
				rand_height += .5
			vertices[0] = pts[x + y * NUM_PTS]
			vertices[1] = pts[x + 1 + y * NUM_PTS]
			vertices[2] = pts[x + (y + 1) * NUM_PTS]
			vertices[3] = pts[x + 1 + (y + 1) * NUM_PTS]
			var rand_bottom := rng.randf() * 5
			create_cube_from(
				vertices,
				points,
				rand_bottom,
				rand_height + 5.5,
				mat,
				ignored_normals
			)

const START := -8.0
func create_cube_from(vertices: PoolVector2Array, points: PoolIntArray, bottom := 0.0, height := 5.0, mat = null, ignored_normals := PoolIntArray([])) -> void:
	
	var cube_mesh := CubeMesh.new()
	var cube_arrays := cube_mesh.get_mesh_arrays()

	var a := Vector3(vertices[0].x, START, vertices[0].y)
	var b := Vector3(vertices[1].x, START, vertices[1].y)
	var c := Vector3(vertices[2].x, START, vertices[2].y)
	var d := Vector3(vertices[3].x, START, vertices[3].y)
	var cube_vertices : PoolVector3Array = cube_arrays[ArrayMesh.ARRAY_VERTEX]
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = cube_vertices

	var j := 0
	for pt in [a,b,c,d]:
		for i in range(3):
			var index := points[i + j]
			arrays[ArrayMesh.ARRAY_VERTEX][index] = pt - Vector3(0, bottom, 0)
			index = points[i + j + 3]
			arrays[ArrayMesh.ARRAY_VERTEX][index] = pt + Vector3(0, height, 0)
			# TODO: random slants + Vector3(0, rng.randf(), 0)
		j += 6


	arrays[ArrayMesh.ARRAY_NORMAL] = cube_arrays[ArrayMesh.ARRAY_NORMAL]



	for i in range(arrays[ArrayMesh.ARRAY_NORMAL].size()):
		if !(i in ignored_normals):
			arrays[ArrayMesh.ARRAY_NORMAL][i] *= -1

	arrays[ArrayMesh.ARRAY_INDEX] = cube_arrays[ArrayMesh.ARRAY_INDEX]

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mesh_inst := MeshInstance.new()
	mesh_inst.mesh = array_mesh
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	mesh_inst.create_trimesh_collision()
	for child in mesh_inst.get_children():
		if child is StaticBody:
			child.set_collision_mask_bit(1, true)
			child.set_collision_mask_bit(2, true)


