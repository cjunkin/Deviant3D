class_name Enemy
extends KinematicBody

var target: Player
var vel := Vector3()
var speed := -2
var grav := 1
var acc := Vector3()
export var friction := .125

func _ready() -> void:
	set_physics_process(false)
	add_to_group("Enemy")

func set_target(t) -> void:
	target = t
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
#	vel = translation.direction_to(target.global_transform.origin)
	if is_instance_valid(target):
		# Look at target, but not looking up
		look_at(target.global_transform.origin, Vector3.UP)
		rotation.x = 0

	acc = transform.basis.z * speed
	vel.z = vel.z * .8 + acc.z
	vel.x = vel.x * .8 + acc.x
	vel += Vector3.DOWN * grav
	
	vel = move_and_slide(vel , Vector3.UP, false, 4, .75, false)
	# If fallen too low, die
	if translation.y < -5:
		rpc("d")

# MULTIPLAYER STUFF --------------------------------------------

# Die
remotesync func d() -> void:
	get_parent().remove_child(self)

# Set translation, velocity
remote func s(master_translation: Vector3, velocity: Vector3) -> void:
	translation = master_translation
	vel = velocity