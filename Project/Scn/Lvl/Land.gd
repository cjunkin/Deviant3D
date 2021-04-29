extends Spatial

export var grid_mat : Material = preload("res://Gfx/Material/Grid.tres")
export (Material) var land_mat : Material
export (Material) var grass_mat : Material
export (Material) var water_mat : Material
const NUM_PTS := 38
const SPACING := 8
const RAND_OFFSET_MAX := SPACING / 4

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


func gen_terrain():
	var rng := RandomNumberGenerator.new()
	rng.seed = G.TERRAIN_SEED
	
	var start : float = -NUM_PTS * SPACING / 2
	var pts := PoolVector2Array([])
	for y in range(start, SPACING * NUM_PTS + start, SPACING):
		for x in range(start, SPACING * NUM_PTS + start, SPACING):
			pts.append(Vector2(x, y) + (Vector2(rng.randf(), rng.randf()) - Vector2.ONE * .5) * RAND_OFFSET_MAX * 2)
	
	var noise := OpenSimplexNoise.new()
	noise.seed = G.TERRAIN_SEED
	noise.octaves = 4
	noise.period = 20
	noise.persistence = .8
	
	for y in range(NUM_PTS - 1):
		for x in range(NUM_PTS - 1):
			var rand_height := (noise.get_noise_2d(x + rng.randf() - .5, y + rng.randf() - .5) + .9) * 4
#			print(rand_height)
			var mat: Material
			if rand_height < 3.5:
				mat = water_mat
				rand_height -= 3
			elif rand_height < 4.25:
				mat = land_mat
#			elif rand_height < 6:
#				mat = land_mat
			else:
				mat = grass_mat
				rand_height += .1
			create_cube_from(
				pts[x + y * NUM_PTS], 
				pts[x + 1 + y * NUM_PTS], 
				pts[x + (y + 1) * NUM_PTS], 
				pts[x + 1 + (y + 1) * NUM_PTS],
				-8,
				4,
				rand_height,
				mat
			)

func create_cube_from(a, b, c, d, start := 0.0, height := 5.0, rand_offset := 0, mat = null) -> void:
	var cube_mesh := CubeMesh.new()
	var cube_arrays := cube_mesh.get_mesh_arrays()

	a = Vector3(a.x, start, a.y)
	b = Vector3(b.x, start, b.y)
	c = Vector3(c.x, start, c.y)
	d = Vector3(d.x, start, d.y)
	var up := Vector3(0, height + rand_offset, 0)
	var cube_vertices : PoolVector3Array = cube_arrays[ArrayMesh.ARRAY_VERTEX]
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = cube_vertices

	var j := 0
	for pt in [a,b,c,d]:
		for i in range(3):
			var index := points[i + j]
			arrays[ArrayMesh.ARRAY_VERTEX][index] = pt
			index = points[i + j + 3]
			arrays[ArrayMesh.ARRAY_VERTEX][index] = pt + up
		j += 6


	arrays[ArrayMesh.ARRAY_NORMAL] = cube_arrays[ArrayMesh.ARRAY_NORMAL]


	var top_bot := [16, 18, 20, 22, 17, 19, 21, 23]
	for i in range(arrays[ArrayMesh.ARRAY_NORMAL].size()):
		if (i in top_bot):
			arrays[ArrayMesh.ARRAY_NORMAL][i] *= -1

	arrays[ArrayMesh.ARRAY_INDEX] = cube_arrays[ArrayMesh.ARRAY_INDEX]

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mesh_inst := MeshInstance.new()
	mesh_inst.mesh = array_mesh
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	mesh_inst.create_trimesh_collision()


