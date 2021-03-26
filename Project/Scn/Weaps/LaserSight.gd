extends ImmediateGeometry

var color: Color = Color.red

func _ready():
	if G.shadows != G.OFF:
		color = Color("64ff0000")

func draw_line(b: Vector3) -> void:
#	clear()
#	begin(Mesh.PRIMITIVE_LINE_STRIP)
#
#	set_color(color)
#	add_vertex(Vector3.ZERO)
#	add_vertex(b)
#	end()
	pass
