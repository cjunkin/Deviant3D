class_name Enemy
extends AI

var target: Player
var flying : bool # FIXME: Sync flying
# Physics
var vel := Vector3()
var speed := -2
var grav := 1
var acc := Vector3()
export var friction := .125

func _ready() -> void:
	add_to_group(G.ENEMY)
	if is_network_master():
		set_flying(randf() > .4)
	else:
		rpc_id(1, "req_syn")
#	else:
#		$Mesh.material_override = load()

puppetsync func set_flying(on := true) -> void:
	print(flying)
	flying = on
	if on:
		var mat := load("res://Gfx/Material/grid.material")
		$Mesh.material_override = mat
		mat = load("res://Gfx/Material/laser.material")
		Dust.material_override = mat

func set_target(t) -> void:
	target = t

func get_class() -> String:
	return G.BASIC_ENEMY

# MULTIPLAYER STUFF --------------------------------------------

func sync_self() -> void:
	rpc("s", translation, vel)

# Set translation, velocity
remote func s(master_translation: Vector3, velocity: Vector3) -> void:
	translation = master_translation
	vel = velocity

master func req_syn() -> void:
	sync_self()
	print(flying)
	rpc("set_flying", flying)

