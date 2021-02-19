class_name Player
extends KinematicBody

var acc := Vector3.DOWN
var vel := Vector3()

export var grav := 64
export var jump := 32
export var friction := .125
export var speed : float = 1000 * friction

#var cam_views : PoolVector3Array = [Vector3(3.75, 1, 6), Vector3()]

onready var CamHelp := $CamHelp
onready var Cam := CamHelp.get_node("Cam")
onready var Muzzle := $CamHelp/Muzzle
onready var TweenN := $Tween

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# acc = player input
	acc = speed * delta * (transform.basis.z * (Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")) + transform.basis.x * (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"))).normalized()
	vel += acc
	
	# apply gravity
	vel += Vector3.DOWN * delta * grav
	
	# friction along x, z (not up/down)
	vel.x = lerp(vel.x, 0, friction)
	vel.z = lerp(vel.z, 0, friction)

	vel = move_and_slide(vel, Vector3.UP, false, 4, .75, false)

	# collision
	for index in get_slide_count():
		var collision := get_slide_collision(index)
		if collision.collider is RigidBody:
			collision.collider.apply_central_impulse(-collision.normal * .05 * vel.length())

	# jumping
	if is_on_floor():
		acc.y = 0
		vel.y = 0
		if Input.get_action_strength("jump"):
			vel.y = jump

	# shooting
	if Input.is_action_just_pressed("fire"):
		Global.game.proj_i = (Global.game.proj_i + 1) % Global.game.num_projectiles
		var p : Projectile = Global.game.projectiles[Global.game.proj_i]
		Global.game.add_child(p)
		p.global_transform = Muzzle.global_transform
		p.monitoring = true
		p.visible = true
	
	if Input.is_action_just_pressed("switch_tps"):
		var next = Cam.translation
		next.x *= -1
		TweenN.interpolate_property(Cam, "translation", Cam.translation, next, .25, Tween.TRANS_CIRC)
		TweenN.start()
#	if Input.is_action_just_pressed("switch_view"):
		

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: # Rotate Camera
		rotate_y(event.relative.x * -.002)
		CamHelp.rotate_x(event.relative.y * -.002)
		CamHelp.rotation.x = clamp(CamHelp.rotation.x, -PI/2, PI/2)
		
