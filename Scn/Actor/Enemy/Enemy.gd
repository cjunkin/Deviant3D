class_name Enemy
extends KinematicBody

var target: Player
var vel := Vector3()
var speed := -100
var grav := 30
var acc := Vector3()
export var friction := .125

func _ready() -> void:
	add_to_group("Enemy")
	set_physics_process(false)

func set_target(t) -> void:
	target = t
	set_physics_process(true)

func _physics_process(delta: float) -> void:
#	vel = translation.direction_to(target.global_transform.origin)
	look_at(target.global_transform.origin, Vector3.UP)
	rotation.x = 0
	acc = transform.basis.z * delta * speed
	vel.z = vel.z * .8 + acc.z
	vel.x = vel.x * .8 + acc.x
#	print(vel.length())
	vel += Vector3.DOWN * delta * grav
	
	vel = move_and_slide(vel , Vector3.UP, false, 4, .75, false)
