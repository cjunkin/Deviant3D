class_name Enemy
extends AI

var target: Player
var flying := randf() > .4 # FIXME: Sync flying
# Physics
var vel := Vector3()
var speed := -2
var grav := 1
var acc := Vector3()
export var friction := .125

func _ready() -> void:
	add_to_group(G.ENEMY)
	if flying:
		var mat := load("res://Gfx/Material/grid.material")
		$Mesh.material_override = mat
		mat = load("res://Gfx/Material/laser.material")
		Dust.material_override = mat
#	else:
#		$Mesh.material_override = load()

func set_target(t) -> void:
	target = t

func get_class() -> String:
	return G.BASIC_ENEMY

# MULTIPLAYER STUFF --------------------------------------------

# Set translation, velocity
remote func s(master_translation: Vector3, velocity: Vector3) -> void:
	translation = master_translation
	vel = velocity

