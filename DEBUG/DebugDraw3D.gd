extends Control

#var player: KinematicBody
#var camera: Camera
#var width := 2.0
#
#
#
#func _draw():
#	var color = Color(0, 1, 0)
#	var start = camera.unproject_position(player.global_transform.origin)
#	var end = camera.unproject_position(player.global_transform.origin + player.grapple_vel)
#	draw_line(start, end, color, width)
#	draw_triangle(end, start.direction_to(end), width*2, color)

func draw_triangle(pos, dir, size, color):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = PoolVector2Array([a, b, c])
	draw_polygon(points, PoolColorArray([color]))


class Vector:
	var object  # The node to follow

	var property  # The property to draw

	var scale  # Scale factor

	var width  # Line width

	var color  # Draw color


	func _init(_object, _property, _scale, _width, _color):
		object = _object
		property = _property
		scale = _scale
		width = _width
		color = _color

	func draw(node, camera):
		var start = camera.unproject_position(object.global_transform.origin)
		var end = camera.unproject_position(object.global_transform.origin + object.get(property) * scale)
		node.draw_line(start, end, color, width)
		node.draw_triangle(end, start.direction_to(end), width*2, color)

func _physics_process(_delta):
	if not visible:
		return
	update()
	
var vectors = []  # Array to hold all registered values.

func add_vector(object, property, scale, width, color):
	vectors.append(Vector.new(object, property, scale, width, color))


func _draw():
	var camera = get_viewport().get_camera()
	for vector in vectors:
		vector.draw(self, camera)
