class_name Box
extends KinematicBody


# Declare instance variables
var speed : float = 0.0 	# declares "speed" as a float
var vel := Vector3.ZERO 	# walrus := auto-types it because it's pretty obvious what the type is
export var acc := Vector3(0, 0, 0) # export allows you to edit it in the editor inspector (to your right)
export var grav := Vector3.DOWN
onready var t := $Tween

# Initialization, called when object enters scene tree (the right panel, "scene" is a scene tree) for the first time.
func _ready() -> void:
	add_to_group(G.ENEMY)


# Called every frame. 'delta' is the elapsed time since the previous frame.
# physics_process has a steady 60 fps, whereas process does it as fast as possible
func _physics_process(delta: float) -> void:
	"""TODO: try uncommenting this/commenting this
			disabling lines 23 and 24 disable gravity on non player prefabs."""
	
	acc += grav * delta
	vel += acc
	
#	vel 
	vel = move_and_slide(vel, Vector3.UP)
	
	if is_on_floor():
		vel = Vector3.ZERO
	
#	translation = Vector3(0, 10, 0) 
	
	# control click the function if you're not sure how it works, 
	# To play, open TODO_PHYSICS/TestScene.tscn 
	# Once you open the test scene, play it using the upper right button or f6 key


# Short for "damage", called when laser hits it, 
# hitpt is point of collision, in global coordinates
# don't worry about amt (AMount)
func dmg(proj: Projectile, amt := 1) -> void:
	var hitpt: Vector3 = proj.Ray.get_collision_point()
	var surface_normal : Vector3 = proj.Ray.get_collision_normal()
	var force: Vector3 = proj.get_vel()
	# Remove grappling hooks safely (if we decide to remove the box, hooks aren't stuck in)
	for child in get_children():
		if child is Hook:
			remove_child(child)
			child.player.call(child.name)
	
	# spawn particle
	G.game.exp_i = (G.game.exp_i + 1) % G.game.num_explosions
	var e : Particles = G.game.explosions[G.game.exp_i]
	e.translation = translation
	e.scale = Vector3.ONE
	e.emitting = true

	# Remove self if hp <= 0
#	get_parent().remove_child(self)
	#vel += Vector3.UP * 100 # apply velocity
	#rotation += Vector3(3, 4, 5) # torque
	
	var normalvec : Vector3 = surface_normal - global_transform.origin
	var hitvec : Vector3 = hitpt - global_transform.origin
	
	var sintheta : float = (normalvec.cross(hitvec).length()) / (hitvec.length() * normalvec.length())
	
	var torque : Vector3 = hitvec.length() * force * sintheta
	
	#TODO: Apply the stuff to make this happen slower instead of all at once
	rotation += torque
	#var rotated := rotation + torque
	vel += force / 5
	
	#t.interpolate_property(self, "rot", rotation, rotation + torque, 1.0, t.TRANS_CUBIC)
	#t.start()
	
	
	#acc += grav
	#vel += acc
	
	
	
	#if is_on_floor():
	#	vel = Vector3.ZERO
	
	#rotation_degrees = Vector3(0,0,0)
	var in_degrees = Vector3(rad2deg(rotation.x), rad2deg(rotation.y), rad2deg(rotation.z))
	var to_x : float = fmod(in_degrees.x, 90.0)
	if to_x > 45.0:
		to_x = -1 * (90.0 - to_x)
	var to_y : float = fmod(in_degrees.y, 90.0)
	if to_y > 45.0:
		to_y = -1 * (90.0 - to_y)
	var to_z : float = fmod(in_degrees.z, 90.0)
	if to_z > 45.0:
		to_z = -1 * (90.0 - to_z)
	
	
	#TODO: Do the thingy that makes the rotation not happen all at once
	var to_ground : Vector3 = Vector3(deg2rad(to_x), deg2rad(to_y), deg2rad(to_z))
	var grounded := rotation - to_ground
	
	t.interpolate_property(self, "rotation", rotation, grounded, 0.25, t.TRANS_CUBIC)
	t.start()
	
	
	
	"""TODO: YOUR CODE HERE --------------------------------- get pushed around physics all that"""
	print("Hit at: ", hitpt) # where it gets hit (global space)
	print("I am centered at: ", global_transform.origin) # gives you global coordinates for this box
	# translation    gives you local coordinates (relative to parent node)
	# TODO: END YOUR CODE HERE------------------------------------------------------------------------

