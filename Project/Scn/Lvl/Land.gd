class_name Land
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
	
	# Setup noise, vertices, normals
	var noise := OpenSimplexNoise.new()
	noise.seed = s
	noise.octaves = 4
	noise.period = 20
	noise.persistence = .8
	var vertices := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var ignored_normals := PoolIntArray([
			8, 10, 12, 14, # right
			9, 11, 13, 15  # left
	])

	var i := 0
	var mm: MultiMesh = $Trees.multimesh
	var tree_hitbox_s := preload("res://Scn/Env/Tree.tscn")
	# var top_bot := [16, 18, 20, 22, 17, 19, 21, 23]
	mm.instance_count = NUM_PTS * (NUM_PTS - 1)
	for y in range(NUM_PTS - 1):
		for x in range(NUM_PTS - 1):
			var rand_height_offset := noise.get_noise_2d(x + rng.randf() - .5, y + rng.randf() - .5) + .9
			var mat: Material
			if rand_height_offset < .85:
#				mat = water_mat
#				rand_height_offset -= 3
				continue
			# Dirt
			elif rand_height_offset < 1.0:
				mat = land_mat
			# Grass
			else:
				mat = grass_mat
				rand_height_offset += .1
			
			# Create the cube
			rand_height_offset = rand_height_offset * 6.0 + 5.5 # scale height
			vertices[0] = pts[x + y * NUM_PTS]
			vertices[1] = pts[x + 1 + y * NUM_PTS]
			vertices[2] = pts[x + (y + 1) * NUM_PTS]
			vertices[3] = pts[x + 1 + (y + 1) * NUM_PTS]
			var rand_bottom_offset := rng.randf() * 5
			create_cube_from(
				vertices,
				points,
				rand_bottom_offset,
				rand_height_offset,
				mat,
				ignored_normals
			)
			# Height of terrain is rand_height_offset + START, 
			# TODO: TWEAK SPAWN FREQUENCY, MAKE POWERUPS GLOW, HAVE BETTER MATERIAL
			# Rafael's Code, spawns powerup: ---------------------------------
			var powerup_check := rng.randf() # random number btwn 0 and 1
			var powerup_height_offset := rng.randf_range(5, 700)
			
			var prob := .025
			if powerup_check < prob:
				var power_up_height := rand_height_offset + START + powerup_height_offset
				if powerup_check < prob / 3:
					var prefab := preload("res://TODO_PHYSICS/Rafael/Low_friction_powerup_2.tscn")
					var powerup := prefab.instance()
					powerup.translation = Vector3(vertices[0][0], power_up_height, vertices[0][1])
					get_tree().get_root().add_child(powerup)
				elif powerup_check < prob * 2 / 3:
					var prefab := preload("res://TODO_PHYSICS/Rafael/High_friction.tscn")
					var powerup := prefab.instance()
					powerup.translation = Vector3(vertices[0][0], power_up_height, vertices[0][1])
					get_tree().get_root().add_child(powerup)
				else:
					var prefab := preload("res://TODO_PHYSICS/Sambodh/Low_grav_powerup.tscn")
					var powerup := prefab.instance()
					powerup.translation = Vector3(vertices[0][0], power_up_height, vertices[0][1])
					get_tree().get_root().add_child(powerup)
			# End Raf's code ---------------------------------
			
			if powerup_check < prob * 2:
				# Spawn tree
				var tx := vertices[0][0]
				var ty := rand_height_offset + START
				var tz := vertices[0][1]
				# Scale
				var size := rng.randf_range(12, 24)
				# Sets position to origin, scale to size
				var t := Transform(
					Vector3(size, 0, 0),
					Vector3(0, size, 0),
					Vector3(0, 0, size),
					Vector3.ZERO
					)
				# Rotate to point up
				t = t.rotated(Vector3.RIGHT, PI/2)
				# Offset from origin
				t.origin += (Vector3(tx, ty, tz))
				mm.set_instance_transform(i, t)
				i += 1
				
				# Create hitbox for the mesh
				var b : Spatial = tree_hitbox_s.instance()
				b.transform = t
				add_child(b)
	mm.visible_instance_count = i

const START := -8.0 # Base height of terrain

# Create a cube with the bottom face being vertices, starting from height START - bottom_offset to START + top_offset, with material MAT
func create_cube_from(vertices: PoolVector2Array, points: PoolIntArray, bottom_offset := 0.0, top_offset := 5.0, mat = null, ignored_normals := PoolIntArray([])) -> void:
	
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
			# Make our bottom vertex
			arrays[ArrayMesh.ARRAY_VERTEX][index] = pt - Vector3(0, bottom_offset, 0)
			index = points[i + j + 3]
			# Make point right above bottom vertex
			arrays[ArrayMesh.ARRAY_VERTEX][index] = pt + Vector3(0, top_offset, 0)
			# TODO: random slants + Vector3(0, rng.randf(), 0)
		j += 6

	arrays[ArrayMesh.ARRAY_NORMAL] = cube_arrays[ArrayMesh.ARRAY_NORMAL]

	# Flip normals if incorrect
	for i in range(arrays[ArrayMesh.ARRAY_NORMAL].size()):
		if !(i in ignored_normals):
			arrays[ArrayMesh.ARRAY_NORMAL][i] *= -1
			# TODO: I KNOW NORMALS ARE INCORRECT FOR SIDES, NEED TO TAKE CROSS PRODUCT and recompute normals

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
	
#func spawn_tree(x: float, y: float, z: float) -> void:
#


