class_name Player
extends KinematicBody

# Camera mode
var fps := false 
#var cam_views : PoolVector3Array = [Vector3(3.75, 1, 6), Vector3()]

# Sensitivity
var SENS_Y := -.002
var SENS_X := -.002

# Physics
remote var a := Vector3.ZERO # acceleration, TODO: optimize networking by only sending inputs
var vel := Vector3.ZERO
export var grav : float= 64 / 60
export var jump : float = grav * 32
export var friction : float = .825
export var speed : float = 4 * friction

# Grappling
const MAX_GRAPPLE_SPEED := 3
var not_grappling := true
var grapple_pos := Vector3.ZERO
var not_grappling2 := true
var grapple_pos2 := Vector3.ZERO

# Cached Nodes
onready var CamSpring : SpringArm
onready var Cam : Camera
onready var PMesh := $PMesh
onready var Top : RayCast = PMesh.get_node("Top")
onready var Forward : RayCast = PMesh.get_node("Forward")
onready var Left : RayCast = PMesh.get_node("Left")
onready var Right : RayCast = PMesh.get_node("Right")
onready var CamHelp := PMesh.get_node("CamHelp")
onready var Gun := CamHelp.get_node("Gun")
onready var Sfx := Gun.get_node("Sfx")
onready var Muzzle := Gun.get_node("Muzzle")
onready var GrappleCast = Muzzle.get_node("GrappleCast")
onready var GLine := $Line
onready var GLine2 := $Line2
onready var sight := $Sight
onready var ROF := $ROF
onready var FlipTime := $FlipTime
onready var Hitbox := $Hitbox
onready var tween := $Tween

func _ready() -> void:
	if is_network_master():
		# Regular cam
		if OS.get_name() != "Android" and OS.get_name() != "iOS":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			CamHelp.add_child(load("res://Scn/Actor/Cam.tscn").instance())
			Cam = CamHelp.get_node("Spring/Cam")
			CamSpring = CamHelp.get_node("Spring")
		# AR CAM
		else:
			add_child(load("res://Scn/AR/ARVROrigin.tscn").instance())
			Cam = get_node("ARVROrigin")
		# Send over sync
		$Sync.start(0)
#		DebugOverlay.draw.add_vector(self, "vel", 1, 4, Color(0,1,0, 0.5))
#		DebugOverlay.draw.add_vector(self, "grapple_aim", 1, 4, Color(0,1,1, 0.5))
#		DebugOverlay.draw.add_vector(self, "global_transform:basis:x", 1, 4, Color(1,1,1, 0.5))
	else:
		set_process_input(false)
		$Sync.queue_free()
		rpc_id(get_network_master(), "req_syn")
	translation = Vector3(7, 17, -14)


func _input(event: InputEvent) -> void:
	# Look
	if event is InputEventMouseMotion: # Rotate Camera
		PMesh.rotate_y(event.relative.x * SENS_X) # Side to side // (transform.basis.y, 
		CamHelp.rotation.x = clamp(CamHelp.rotation.x + (event.relative.y * SENS_Y), -PI/2, PI/2) # Up down
		rpc_unreliable("r", event.relative)
	# Switch camera sides
	if event.is_action_pressed("switch_tps"):
		var next : Vector3 = CamSpring.translation
		next.x = -3.5 * sign(next.x) # previously -3.75
		tween.interpolate_property(CamSpring, "translation", CamSpring.translation, next, .25, Tween.TRANS_CIRC)
		next = Gun.translation
		next.x = -.75 * sign(next.x)
		tween.interpolate_property(Gun, "translation", Gun.translation, next, .25, Tween.TRANS_CIRC)
		tween.start()
	# Switch between TPS and FPS
	if event.is_action_pressed("switch_view"):
		# TODO: reduce to no if/else
		if fps:
#			CamSpring.translation = Vector3(3.5, 1.5, 0) #Vector3(3.75, 1.5, 9)
			tween.interpolate_property(CamSpring, "translation", CamSpring.translation, Vector3(3.5, 1.5, 0), .25, Tween.TRANS_CIRC)
			tween.interpolate_property(CamSpring, "spring_length", CamSpring.spring_length, 8, .25, Tween.TRANS_CIRC)
			tween.start()
#			CamSpring.spring_length = 8
		else:
#			CamSpring.translation = Vector3(0, 1, 0)
			tween.interpolate_property(CamSpring, "translation", CamSpring.translation, Vector3(0, 1, 0), .25, Tween.TRANS_CIRC)
			tween.interpolate_property(CamSpring, "spring_length", CamSpring.spring_length, 0, .25, Tween.TRANS_CIRC)
			tween.start()
#			CamSpring.spring_length = 0
		fps = !fps
	# Zoom
	if event.is_action_pressed("aim"):
		tween.interpolate_property(Cam, "fov", Cam.fov, int(Cam.fov) % 70 + 35, .25, Tween.TRANS_CIRC)
		tween.start()
	# Quit
	elif event.is_action_pressed("ui_cancel"):
		# TODO: reduce to no if/else
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen


func _physics_process(_delta: float) -> void:
	# collision with boxes
	for index in get_slide_count():
		var collision := get_slide_collision(index)
		if collision.collider is RigidBody:
			collision.collider.apply_central_impulse(-collision.normal * .05 * vel.length())

	if is_network_master():
		# Set crosshair
		sight.rect_position.x = 10000
		if GrappleCast.is_colliding():
			sight.rect_position = Cam.unproject_position(GrappleCast.get_collision_point())

		# Shooting
		if Input.is_action_pressed("fire") and ROF.is_stopped():
			# TODO: Muzzle flash
			rpc("f") # fire
			Cam.stress = 0.25

		# Crouching
		if Input.is_action_just_pressed("crouch"):
			rpc("v")
		elif Input.is_action_just_released("crouch"):
			rpc("u")

		# Grapple
		if Input.is_action_just_pressed("grapple1") and GrappleCast.get_collider():
			local_grapple(true)
		elif Input.is_action_just_released("grapple1"):
			rpc("c")
		if Input.is_action_just_pressed("grapple2") and GrappleCast.get_collider():
			local_grapple(false)
		elif Input.is_action_just_released("grapple2"):
			rpc("e")
		# "Run, the game" flipping
		if Top.is_colliding() and FlipTime.is_stopped():
			rpc("st", align_with_y(global_transform, Top.get_collision_normal()))
		elif Forward.is_colliding() and FlipTime.is_stopped():
			rpc("st", align_with_y(global_transform, Forward.get_collision_normal()))
		elif Left.is_colliding() and FlipTime.is_stopped():
			rpc("st", align_with_y(global_transform, Left.get_collision_normal()))
		elif Right.is_colliding() and FlipTime.is_stopped():
			rpc("st", align_with_y(global_transform, Right.get_collision_normal()))

		# Ground Movement
		a = (
			Input.get_action_strength("sprint") + 1) * speed * (
				PMesh.global_transform.basis.z * (
					Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
					) 
				+ 
				PMesh.global_transform.basis.x * (
					Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
					)
			).normalized()
		rset_unreliable("a", a)

	# Grounded
	if is_on_floor():
		# Jumping
		if is_network_master() and Input.get_action_strength("jump"):
			rpc("j") # jump
		# Apply friction on ground
		if not_grappling:
			vel *= friction
		# Apply air resistance
		else:
			vel *= .95
	# Midair
	else:
#		# Accelerate Hook
#		if Input.is_action_pressed("sprint"):
#			vel += (grapple_pos - global_transform.origin).normalized() * 3
##			vel -= CamHelp.global_transform.basis.z
##			vel.y += 1
		# Reduce grounded movespeed
		a *= .125

	# apply gravity, inputs, physics
	vel -= (int(not_grappling)) * (int(not_grappling2)) * transform.basis.y * grav
	vel += a
	vel = move_and_slide(vel, transform.basis.y, false, 4, .75, false)

	# if grappling
	if !not_grappling:
		GLine.points[1] = Muzzle.global_transform.origin
		var new_grapple_len := (grapple_pos - global_transform.origin).length()
		var grapple_vel := (global_transform.origin - grapple_pos) / new_grapple_len * min(0, (1 - new_grapple_len)) * .5
		if grapple_vel.length() > MAX_GRAPPLE_SPEED:
			grapple_vel = grapple_vel.normalized() * MAX_GRAPPLE_SPEED
		vel += grapple_vel
		if abs((grapple_pos - global_transform.origin).length_squared()) < 64:
			vel *= .95
		else:
			vel *= .999
	if !not_grappling2:
		GLine2.points[1] = Muzzle.global_transform.origin
		var new_grapple_len := (grapple_pos2 - global_transform.origin).length()
		var grapple_vel := (global_transform.origin - grapple_pos2) / new_grapple_len * min(0, (1 - new_grapple_len)) * .5
		if grapple_vel.length() > MAX_GRAPPLE_SPEED:
			grapple_vel = grapple_vel.normalized() * MAX_GRAPPLE_SPEED
		vel += grapple_vel
		if abs((grapple_pos2 - global_transform.origin).length_squared()) < 64:
			vel *= .95
		else:
			vel *= .999
	

func local_grapple(right: bool) -> void:

	if right:
		grapple_pos = GrappleCast.get_collision_point()
		GLine.points[0] = grapple_pos
		GLine.points[1] = Muzzle.global_transform.origin
		GLine.visible = true
		not_grappling = false
		rpc("b", translation, PMesh.rotation.y, CamHelp.rotation.x, grapple_pos)
	else:
		grapple_pos2 = GrappleCast.get_collision_point()
		GLine2.points[0] = grapple_pos2
		GLine2.points[1] = Muzzle.global_transform.origin
		GLine2.visible = true
		not_grappling2 = false
		rpc("d", translation, PMesh.rotation.y, CamHelp.rotation.x, grapple_pos2)

# Set grapple hook position
remote func b(trans: Vector3, y: float, cam_help_x: float, pos: Vector3) -> void:
	translation = trans
	PMesh.rotation.y = y
	CamHelp.rotation.x = cam_help_x
	grapple_pos = pos

	GLine.points[0] = pos
	GLine.points[1] = Muzzle.global_transform.origin
	GLine.visible = true
	not_grappling = false

# Stop (no) grappling
remotesync func c() -> void:
	not_grappling = true
	GLine.visible = false

# Set grapple hook position
remote func d(trans: Vector3, y: float, cam_help_x: float, pos: Vector3) -> void:
	translation = trans
	PMesh.rotation.y = y
	CamHelp.rotation.x = cam_help_x
	grapple_pos2 = pos
	GLine2.points[0] = pos
	GLine2.points[1] = Muzzle.global_transform.origin
	not_grappling2 = false
	GLine2.visible = true

# Stop (no) grappling
remotesync func e() -> void:
	not_grappling2 = true
	GLine2.visible = false



# Fire
remotesync func f() -> void:
	G.game.proj_i = (G.game.proj_i + 1) % G.game.num_projectiles
	var p : Projectile = G.game.projectiles[G.game.proj_i]
	G.game.add_child(p)
	p.global_transform = Muzzle.global_transform
	p.monitoring = true
	p.visible = true
	Sfx.pitch_scale = rand_range(.85, 1.15)
	Sfx.play()
	ROF.start()
	p.timer.start()

# Jump
remotesync func j() -> void:
	vel += jump * transform.basis.y

# Aim
remote func r(rot: Vector2) -> void:
	PMesh.rotate_y(rot.x * SENS_X) # Side to side // (transform.basis.y, 
	CamHelp.rotation.x = clamp(CamHelp.rotation.x + (rot.y * SENS_Y), -PI/2, PI/2) # Up down

# Sync transform
remote func s(trans: Vector3, y: float, cam_help_x: float) -> void:
	translation = trans
	PMesh.rotation.y = y
	CamHelp.rotation.x = cam_help_x

# Sync transform (during flip)
remotesync func st(gt: Transform) -> void:
	# BIG TODO: MAKE MORE EFFICIENT BY ONLY SENDING NORMAL
#	global_transform = gt
	tween.interpolate_property(self, "global_transform", global_transform, gt, .25, Tween.TRANS_SINE)
	tween.start()
	FlipTime.start()

# Uncrouch
remotesync func u() -> void:
#	Hitbox.shape.height = 1
#	Hitbox.translation.y = 0
#	Hitbox.scale = Vector3(1, 1, 1)
#	PMesh.mesh.mid_height = 1
	PMesh.translation.y = 0
	PMesh.scale = Vector3(1, 1, 1)

# Crouch
remotesync func v() -> void:
#	Hitbox.shape.height = .5
#	Hitbox.translation.y = -.25
#	Hitbox.scale = Vector3(.9, .9, .5)
#	PMesh.mesh.mid_height = .5
	PMesh.translation.y = -.4
	PMesh.scale = Vector3(.9, .9, .75)

# When other person calls this, send over my info
remote func req_syn() -> void:
	_on_Sync_timeout()


# Return rotated XFORM where its new normal is NEW_Y
func align_with_y(xform: Transform, new_y: Vector3) -> Transform:
	var new_x := -xform.basis.z.cross(new_y)
#	print("\n OLD XFORM")
#	print(xform.basis.x)
#	print(xform.basis.y
#	print(xform.basis.z)
	if new_x != Vector3.ZERO:
		xform.basis.x = new_x
	else:
		xform.basis.z = xform.basis.x.cross(new_y)
	xform.basis.y = new_y
	xform.basis = xform.basis.orthonormalized()
	
#	print("NEW XFORM")
#	print(xform.basis.x)
#	print(xform.basis.y)
#	print(xform.basis.z)
	return xform

# Sync position/aim every X seconds
func _on_Sync_timeout():
	rpc("s", translation, PMesh.rotation.y, CamHelp.rotation.x)
