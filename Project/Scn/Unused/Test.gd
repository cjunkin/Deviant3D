extends MeshInstance


#func _ready():
#	var mdt := MeshDataTool.new()
##	print(PMesh.mesh)
#	mdt.create_from_surface(mesh, 0)
#	for i in range(mdt.get_vertex_count()):
#		var vert = mdt.get_vertex(i)
#		vert *= 2.0 # Scales the vertex by doubling size.
##		mdt.set_vertex(i, vert)
#		print(vert)
##	PMesh.mesh.surface_remove(0)
##	mdt.commit_to_surface(PMesh.mesh)


	
#
#	var normal := Vector3.UP
#	var normals := [normal, normal, normal, normal]
#
#	var cube_mesh := CubeMesh.new()
#	var cube_arrays := cube_mesh.get_mesh_arrays()
##	var cube_vertices : PoolVector3Array = cube_arrays[ArrayMesh.ARRAY_VERTEX]
#	var a = Vector3(5, 0, 5)
#	var b = Vector3(0, 0, 5)
#	var c = Vector3(4, 0, 0)
#	var d = Vector3(0, 0, 1)
#	var height := Vector3(0, 5, 0)
#
##	var cube_vertices : PoolVector3Array = [
##		a, a, b, a, 
##		c, a, d, a,
##		a, a, b, a, 
##		c, a, d, a,
##		a, a, b, a, 
##		c, a, d, a,
##	]
#	var cube_vertices : PoolVector3Array = cube_arrays[ArrayMesh.ARRAY_VERTEX]
#
#
#	var arrays := []
#	arrays.resize(ArrayMesh.ARRAY_MAX)
#	arrays[ArrayMesh.ARRAY_VERTEX] = cube_vertices
#	arrays[ArrayMesh.ARRAY_VERTEX][1] = Vector3(0, 0, 10)
#	"""
#	0, 2, 4, 6 - front
#	1, 3, 5, 7 - back
#	8, 10, 12, 14 - right
#	9, 11, 13, 15 - left
#	16, 18, 20, 22 - top
#	17, 19, 21, 23 - bottom
#	"""
#	arrays[ArrayMesh.ARRAY_NORMAL] = cube_arrays[ArrayMesh.ARRAY_NORMAL]
#	arrays[ArrayMesh.ARRAY_INDEX] = cube_arrays[ArrayMesh.ARRAY_INDEX]
#
#	var array_mesh := ArrayMesh.new()
#	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
#
#	var mesh_inst := MeshInstance.new()
#
#	mesh_inst.mesh = array_mesh
##	mesh = mesh_inst.mesh
#	mesh_inst.translation += Vector3(1, 1, 1)
#	add_child(mesh_inst)



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
	2,  8, 16, # b
	4, 15, 17, # c
	6, 12, 19, # d
	3,  9, 22, # e
	1, 10, 20, # f
	7, 13, 21, # g
	5, 14, 23  # h
	])

#var i := 0
func _input(event):
	if event.is_action_pressed("fire"):
#		print("VERTEX ", i)

		var normal := Vector3.UP
		var normals := [normal, normal, normal, normal]
		
		var cube_mesh := CubeMesh.new()
		var cube_arrays := cube_mesh.get_mesh_arrays()
	#	var cube_vertices : PoolVector3Array = cube_arrays[ArrayMesh.ARRAY_VERTEX]
		var a = Vector3(5, 0, 5)
		var b = Vector3(0, 0, 5)
		var c = Vector3(4, 0, 0)
		var d = Vector3(0, 0, 1)
		var height := Vector3(0, 5, 0)
		var cube_vertices : PoolVector3Array = cube_arrays[ArrayMesh.ARRAY_VERTEX]
		
		var arrays := []
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = cube_vertices
		
		var j = 0
		for i in range(points.size()):
			var index := points[i]
			arrays[ArrayMesh.ARRAY_VERTEX][index] = Vector3(-15, -10, 10)
		
	#	var cube_vertices : PoolVector3Array = [
	#		a, a, b, a, 
	#		c, a, d, a,
	#		a, a, b, a, 
	#		c, a, d, a,
	#		a, a, b, a, 
	#		c, a, d, a,
	#	]
		
		"""
		0, 2, 4, 6 - front
		1, 3, 5, 7 - back
		8, 10, 12, 14 - right
		9, 11, 13, 15 - left
		16, 18, 20, 22 - top
		17, 19, 21, 23 - bottom
		"""
		arrays[ArrayMesh.ARRAY_NORMAL] = cube_arrays[ArrayMesh.ARRAY_NORMAL]
		arrays[ArrayMesh.ARRAY_INDEX] = cube_arrays[ArrayMesh.ARRAY_INDEX]
		
		var array_mesh := ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		var mesh_inst := MeshInstance.new()
		
		mesh = array_mesh
#		i += 1
#	if event.is_action_pressed("sprint"):
#		i -= 1
#		print(i)
	#	mesh = mesh_inst.mesh
#		mesh_inst.translation += Vector3(1, 1, 1)
#		add_child(mesh_inst)
