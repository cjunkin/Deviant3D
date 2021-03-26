class_name Player
extends KinematicBody

# Camera mode
var fps := false 
#var cam_views : PoolVector3Array = [Vector3(3.75, 1, 6), Vector3()]

# Sensitivity
var SENS_Y := -.002
var SENS_X := -.002

# Physics
puppet var gravity := true
puppet var a := Vector3.ZERO # acceleration
var accel := Vector3.ZERO
var vel := Vector3.ZERO
export var grav : float= 64 / 60
export var jump : float = grav * 32
export var friction : float = .825
export var speed : float = 4 * friction

# Grappling
const MAX_GRAPPLE_SPEED := 3
var not_grappling := true
var grapple_pos := Vector3.ZERO
var L_not_grapplin := true
var grapple_pos2 := Vector3.ZERO

# File Paths
export(String, FILE) var cam_path
export(String, FILE) var flippers_path


# Cached Nodes
onready var CamSpring : SpringArm
onready var Cam : Camera
onready var CamX := $CamX
onready var PMesh := CamX.get_node("PMesh")
onready var Flippers : Array
onready var CamY := CamX.get_node("CamY")
onready var Gun := CamY.get_node("Gun")
onready var Sfx := Gun.get_node("Sfx")
onready var Muzzle := Gun.get_node("Muzzle")

# Hooks are first outside scene tree, enter on grapple begin, reparent to collision
var LHook: Hook
var RHook: Hook

onready var GrappleCast = Muzzle.get_node("GrappleCast")

onready var GLine := $Line
onready var LGLine := $Line2
onready var sight := $Sight
onready var ROF := $ROF
onready var FlipTime := $FlipTime
onready var Hitbox := $Hitbox
onready var tween := $Tween
onready var GrappleSfx := CamX.get_node("GrappleSfx")

func _ready() -> void:
	var hook_s := load("res://Scn/Projectile/Hook.tscn")
	RHook = hook_s.instance()
	RHook.player = self
	RHook.add_exception(self)
	RHook.name = "R"
	G.game.hooks.append(RHook)
	LHook = hook_s.instance()
	LHook.player = self
	LHook.add_exception(self)
	LHook.name = "L"
	G.game.hooks.append(LHook)

	# TODO: implement wall climb (maybe not)
#	Engine.time_scale = .1
	translation = Vector3(7 + rand_range(-2, 2), 17, -14 + rand_range(-2, 2))
	if is_network_master():
		# Regular cam
		if OS.get_name() != "Android" and OS.get_name() != "iOS":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			CamY.add_child(load(cam_path).instance())
			Cam = CamY.get_node("Spring/Cam")
			CamSpring = CamY.get_node("Spring")
		# AR CAM
		else:
			add_child(load("res://Scn/AR/ARVROrigin.tscn").instance())
			Cam = get_node("ARVROrigin")
		# Start syncing
		var sync_timer := Timer.new()
		add_child(sync_timer)
		sync_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		sync_timer.wait_time = 10
		if sync_timer.connect("timeout", self, "_sync_timeout") != OK:
			print("ERROR: COULDN'T SETUP PERIODIC SYNC")
		sync_timer.start(0)
		
		G.current_player = self
		
		var flippers : Spatial = load(flippers_path).instance()
		CamX.add_child(flippers)
		Flippers = flippers.get_children()
		
#		DebugOverlay.draw.add_vector(self, "vel", 1, 4, Color(0,1,0, 0.5))
#		DebugOverlay.draw.add_vector(self, "grapple_aim", 1, 4, Color(0,1,1, 0.5))
#		DebugOverlay.draw.add_vector(self, "global_transform:basis:x", 1, 4, Color(1,1,1, 0.5))
	else:
		set_process_input(false)
		# Request sync from master
		rpc_id(get_network_master(), "req_syn")



func _input(event: InputEvent) -> void:
	# Ground Movement
	a = (
		Input.get_action_strength("sprint") + 1) * speed * (
			CamX.global_transform.basis.z * (
				Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
				) 
			+ 
			CamX.global_transform.basis.x * (
				Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
				)
		).normalized()
	# If our acceleration has changed, sync the new one
	if a != accel:
		accel = a
		rset("a", a)
	# Look
	if event is InputEventMouseMotion:
		CamX.rotate_y(event.relative.x * SENS_X) # Side to side // (transform.basis.y, 
		CamY.rotation.x = clamp(CamY.rotation.x + (event.relative.y * SENS_Y), -PI/2, PI/2) # Up down
		rpc_unreliable("A", event.relative)
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
	# Jumping
	if event.is_action_pressed("jump") and is_on_floor():
		rpc("j") # jump
	
	# Grapple
	if event.is_action_pressed("grapple1"):
		local_grapple(true)
	elif event.is_action_released("grapple1"):
		rpc("R")
	if event.is_action_pressed("grapple2"):
		local_grapple(false)
	elif event.is_action_released("grapple2"):
		rpc("L")

	# Crouching
	if event.is_action_pressed("crouch"):
		rpc("v") # crouch
	elif event.is_action_released("crouch"):
		rpc("u") # uncrouch

	if event.is_action_pressed("reset_gravity") and FlipTime.is_stopped():
		rpc("st", Vector3.UP) # reset rotation to normal
		toggle_flippers(!G.Flip.pressed)
		G.Flip.pressed = !G.Flip.pressed
		# If we're turning flip off, set wait time
		if !G.Flip.pressed:
			FlipTime.start(5)
			yield(FlipTime, "timeout")
			FlipTime.wait_time = 1
		else:
			FlipTime.start()



#		# Accelerate Hook
#		if Input.is_action_pressed("sprint"):
#			vel += (grapple_pos - global_transform.origin).normalized() * 3
##			vel -= CamY.global_transform.basis.z
##			vel.y += 1

func toggle_flippers(enabled: bool) -> void:
	for raycast in Flippers:
		raycast.enabled = enabled

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

		# "Run, the game" flipping
		for ray in Flippers:
			if ray.is_colliding() and FlipTime.is_stopped():
				rpc("st", ray.get_collision_normal())

	# Grounded
	if is_on_floor():
		# Apply hard friction, unless grappling (then softer friction)
		vel *= friction * int(not_grappling) + .95 * int(!not_grappling)
		vel += a
	# Midair
	else:
		# Reduce grounded movespeed
		vel += .125 * a # BIG TODO: fix massive acceleration if jump while moving

	# apply gravity, inputs, physics
	vel -= int(gravity) * (int(not_grappling)) * (int(L_not_grapplin)) * transform.basis.y * grav
	vel = move_and_slide(vel, transform.basis.y, false, 4, .75, false)


	var air_resistance := 1.0
	var air_resistance2 := 1.0
	# if grappling
	if !not_grappling:
		grapple_pos = RHook.global_transform.origin
		GLine.points[0] = grapple_pos
		GLine.points[1] = GrappleCast.global_transform.origin
		var new_grapple_len := (grapple_pos - global_transform.origin).length()
		var grapple_vel := (global_transform.origin - grapple_pos) / new_grapple_len * min(0, (1 - new_grapple_len)) * .25
		if grapple_vel.length() > MAX_GRAPPLE_SPEED:
			grapple_vel = grapple_vel.normalized() * MAX_GRAPPLE_SPEED
		vel += grapple_vel
		# If near grappling point, slow down (and get pulled more towards the point)
		var is_near := abs((grapple_pos - global_transform.origin).length_squared()) < 64
		air_resistance = .95 * int(is_near) + .999 * int(!is_near)
	if !L_not_grapplin:
		grapple_pos2 = LHook.global_transform.origin
		LGLine.points[0] = grapple_pos2
		LGLine.points[1] = GrappleCast.global_transform.origin
		var new_grapple_len := (grapple_pos2 - global_transform.origin).length()
		var grapple_vel := (global_transform.origin - grapple_pos2) / new_grapple_len * min(0, (1 - new_grapple_len)) * .25
		if grapple_vel.length() > MAX_GRAPPLE_SPEED:
			grapple_vel = grapple_vel.normalized() * MAX_GRAPPLE_SPEED
		vel += grapple_vel
		# If near grappling point, slow down (and get pulled more towards the point)
		var is_near2 := int(abs((grapple_pos2 - global_transform.origin).length_squared()) < 64)
		air_resistance2 = .95 * int(is_near2) + .999 * int(!is_near2)
	vel *= air_resistance*air_resistance2 


func hook(hook_name: String):
	if hook_name == "R":
		GLine.visible = true
		not_grappling = false
		RHook.visible = false
	else:
		LGLine.visible = true
		L_not_grapplin = false

func local_grapple(right: bool) -> void:
	if right:
		RHook.enabled = true
		RHook.global_transform = GrappleCast.global_transform
		GLine.points[1] = Muzzle.global_transform.origin
		G.game.add_child(RHook)
		rpc("r", translation, CamX.rotation.y, CamY.rotation.x, vel)
	else:
		LHook.enabled = true
		LHook.global_transform = GrappleCast.global_transform
		LGLine.points[1] = Muzzle.global_transform.origin
		G.game.add_child(LHook)
		rpc("l", translation, CamX.rotation.y, CamY.rotation.x, vel)

	# Audio
	GrappleSfx.pitch_scale = rand_range(.5, .85)
	GrappleSfx.play()

# Aim
puppet func A(rot: Vector2) -> void:
	CamX.rotate_y(rot.x * SENS_X) # Side to side // (transform.basis.y, 
	CamY.rotation.x = clamp(CamY.rotation.x + (rot.y * SENS_Y), -PI/2, PI/2) # Up down

# Set grapple hook position
puppet func r(trans: Vector3, y: float, cam_help_x: float, vel: Vector3) -> void:
	s(trans, y, cam_help_x, vel)
	RHook.enabled = true
	RHook.global_transform = GrappleCast.global_transform
	GLine.points[1] = Muzzle.global_transform.origin
	G.game.add_child(RHook)

	# Audio
	GrappleSfx.pitch_scale = rand_range(.5, .85)
	GrappleSfx.play()

# Stop (no) grappling
puppetsync func R() -> void:
	if RHook.is_inside_tree():
		RHook.get_parent().remove_child(RHook)
	not_grappling = true
	GLine.visible = false
	RHook.enabled = false
	RHook.visible = true

# Set grapple hook position for 2nd hook
puppet func l(trans: Vector3, y: float, cam_help_x: float, vel: Vector3) -> void:
	s(trans, y, cam_help_x, vel)
	LHook.enabled = true
	LHook.global_transform = GrappleCast.global_transform
	LGLine.points[1] = Muzzle.global_transform.origin
	G.game.add_child(LHook)

	# Audio
	GrappleSfx.pitch_scale = rand_range(.5, .85)
	GrappleSfx.play()

# Stop (no) grappling for 2nd hook
puppetsync func L() -> void:
	if LHook.is_inside_tree():
		LHook.get_parent().remove_child(LHook)
	L_not_grapplin = true
	LGLine.visible = false
	LHook.enabled = false
	LHook.visible = true



# Fire
puppetsync func f() -> void:
	G.game.laser_i = (G.game.laser_i + 1) % G.game.num_lasers
	var p : Projectile = G.game.projectiles[G.game.laser_i]
	G.game.add_child(p)
	p.global_transform = Muzzle.global_transform
	p.monitoring = true
	p.visible = true

	# Audio
	Sfx.pitch_scale = rand_range(.85, 1.15)
	Sfx.play()

	# Timing
	ROF.start()
	p.timer.start()

# Jump
puppetsync func j() -> void:
	vel += jump * transform.basis.y

# Sync position/orientation
puppet func s(trans: Vector3, y: float, cam_help_x: float, velocity: Vector3) -> void:
	translation = trans
	CamX.rotation.y = y
	CamY.rotation.x = cam_help_x
	vel = velocity

# Sync transform (during flip)
puppetsync func st(normal: Vector3) -> void:
	vel *= .25
	tween.interpolate_property(
		self, 
		"global_transform", 
		global_transform, 
		align_with_y(global_transform, normal), 
		.25, 
		Tween.TRANS_CIRC
		)
	tween.start()
	FlipTime.start()

# Transform
puppetsync func t(trans: Transform) -> void:
	transform = trans

# Uncrouch TODO: tween crouching
puppetsync func u() -> void:
#	Hitbox.shape.height = 1
#	Hitbox.translation.y = 0
#	Hitbox.scale = Vector3(1, 1, 1)
#	PMesh.mesh.mid_height = 1
	if Cam:
		Cam.get_parent().translation.y = 1.5 * int(!fps) + 1 * int(fps)
	PMesh.translation.y = 0
	PMesh.scale = Vector3(1, 1, 1)

# Crouch TODO: make hitbox also smaller, cam translate down
puppetsync func v() -> void:
#	Hitbox.shape.height = .5
#	Hitbox.translation.y = -.25
#	Hitbox.scale = Vector3(.9, .9, .5)
#	PMesh.mesh.mid_height = .5
	if Cam:
		Cam.get_parent().translation.y = 1 * int(!fps) + .5 * int(fps)
	PMesh.translation.y = -.4
	PMesh.scale = Vector3(.9, .9, .75)

# When other person calls this, send over my info
master func req_syn() -> void:
	rpc("t", transform)
	rpc("s", translation, CamX.rotation.y, CamY.rotation.x, vel)
	rpc("ss", -SENS_X * 1000)

# Set Sensitivity
puppet func ss(sens: float) -> void:
	SENS_X = -sens/1000
	SENS_Y = -sens/1000

# Return rotated XFORM where its new normal is NEW_Y
func align_with_y(xform: Transform, new_y: Vector3) -> Transform:
	var new_x := -xform.basis.z.cross(new_y)
	if new_x != Vector3.ZERO:
		xform.basis.x = new_x
	else:
		xform.basis.z = xform.basis.x.cross(new_y)
	xform.basis.y = new_y
	xform.basis = xform.basis.orthonormalized()
	return xform

# Sync position/aim every X seconds
func _sync_timeout():
	rpc("s", translation, CamX.rotation.y, CamY.rotation.x, vel)

func unregister() -> void:
	G.game.hooks.erase(LHook)
	G.game.hooks.erase(RHook)
	queue_free()
