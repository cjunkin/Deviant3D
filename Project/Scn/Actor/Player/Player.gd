class_name Player
extends KinematicBody

# Camera mode
var fps := false 
#var cam_views : PoolVector3Array = [Vector3(3.75, 1, 6), Vector3()]

# Sensitivity
var SENS_Y := -.002
var SENS_X := -.002

# Physics
puppetsync var g := true # gravity on/off
puppet var a := Vector3.ZERO # acceleration
var accel := Vector3.ZERO
var vel := Vector3.ZERO
export var grav : float = 64
export var jump : float = grav * .9
export var friction : float = .825
export var speed : float = 4 * friction
const CROUCH_TIME := .05
var newest_normal := Vector3.UP
const AIR_DAMPING := .9985
const DAMP_NEAR_HOOK := .95

# Shooting
puppetsync var b : float = 0.0 # Bendiness of bullet
export var throwable_s: PackedScene

# Grappling
const MAX_GRAPPLE_SPEED := 3
var not_grappling := true
var grapple_pos := Vector3.ZERO
var L_not_grapplin := true
var grapple_pos2 := Vector3.ZERO
const GEAR_MAX_ANGLE := .384 # 22 degrees
const GEAR_REST_ROT := .3

# File Paths
export(String, FILE) var cam_spring_path
export(String, FILE) var flippers_path

# Cached Nodes
#export(NodePath) var flash
onready var CamSpring : SpringArm
onready var Cam : ShakyCam
onready var CamX := $CamX
onready var GrappleSfx := CamX.get_node("GrappleSfx")
onready var MeshHelp := CamX.get_node("MeshHelp")
onready var PMesh := MeshHelp.get_node("PMesh")
onready var Flippers : Array
onready var CamY := CamX.get_node("CamY")
onready var GunHolder := CamY.get_node("GunHolder")
onready var Gun := GunHolder.get_node("Gun")
onready var Muzzle := Gun.get_node("Muzzle")
onready var Sfx := Muzzle.get_node("Sfx")
onready var AnimTree := $AnimTree
# Hooks are first outside scene tree, enter on grapple begin, reparent to collision
var LHook: Hook
var RHook: Hook
onready var FrontCast = Muzzle.get_node("FrontCast") # TODO: Get rid of FrontCast (dont need)
onready var GLine := $Line
onready var LGLine := $Line2
onready var ROF := $ROF
onready var FlipTime := $FlipTime
onready var Hitbox := $Hitbox
onready var tween := $Tween
var LaserSight : CSGCylinder
var RespawnTime : Timer
onready var GearR := $CamX/MeshHelp/GearR
onready var GearL := $CamX/MeshHelp/GearL
onready var GearRMuzzle := GearR.get_node("Muzzle")
onready var GearLMuzzle := GearL.get_node("Muzzle")
#onready var Flash : OmniLight = get_node(flash)
#onready var CamHolder :Spatial = CamY.get_node("CamHolder")

onready var forward : RayCast

func _ready() -> void:
	add_to_group(G.PLAYER)
# THis is to draw the vel, grapple_aim, etc vectors don't need rn
#	DebugOverlay.draw.add_vector(self, "aim", 1, 4, Color(0,1,0, 0.5))
#	DebugOverlay.draw.add_vector(self, "grapple_aim", 1, 4, Color(0,1,1, 0.5))
#	DebugOverlay.draw.add_vector(self, "global_transform:basis:x", 1, 4, Color(1,1,1, 0.5))
	
	# Setup grappling hooks, the name will be used to call the R and L functions 
	# in Game.physics_process when hooks collide
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

	# Setup Forward so that we can aim dead center
	# TODO: Find way to animate camera without using CamHolder 
	var CamHolder :Spatial = CamY.get_node("CamHolder") 
	# CamHolder is needed so walking anims doesn't affect gun rotation
	CamSpring = load(cam_spring_path).instance()
	CamHolder.add_child(CamSpring)
#			Cam = CamSpring.get_node("ViewportContainer/Viewport/Cam")
	forward = CamSpring.get_node("Forward")
	forward.add_exception(self)

	# TODO: implement wall climb (maybe not)
#	Engine.time_scale = .1
	translation = Vector3(7 + rand_range(-2, 2), 17, -14 + rand_range(-2, 2))
	if is_network_master():
		# Regular cam
		if OS.get_name() != "Android" and OS.get_name() != "iOS":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Cam = load("res://Scn/Cam/ShakyCam.tscn").instance()
			CamSpring.add_child(Cam)
			reparent_sound(Sfx)
			reparent_sound(GrappleSfx)
		
		# AR CAM (for mobile)
		else:
			add_child(load("res://Scn/AR/ARVROrigin.tscn").instance())
			Cam = get_node("ARVROrigin")
		
		# Start syncing (every timer.wait_time seconds, it will sync position)
		var timer := Timer.new()
		timer.name = "Sync"
		add_child(timer)
		timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		timer.wait_time = 10
		if timer.connect("timeout", self, "_sync_timeout") != OK:
			print("ERROR: COULDN'T SETUP PERIODIC SYNC")
		timer.start(0)
		
		# Setup Respawn Timer (limits how fast you can respawn)
		RespawnTime = Timer.new()
		RespawnTime.name = "Respawn"
		add_child(RespawnTime)
		RespawnTime.process_mode = Timer.TIMER_PROCESS_PHYSICS
		RespawnTime.one_shot = true
		RespawnTime.wait_time = 8
		
		G.start_game(self)
		
		# Setup Flippers
		var flippers : Spatial = load(flippers_path).instance()
		CamX.add_child(flippers)
		Flippers = flippers.get_children()
		
		# Setup LaserSight
		LaserSight = load("res://Scn/Weaps/LaserSight.tscn").instance()
		LaserSight.visible = true
		Muzzle.add_child(LaserSight)
		
	else:
		set_process_input(false)
		# Request sync from master
		rpc_id(get_network_master(), "req_syn")

func _input(event: InputEvent) -> void:
	# Ground Movement
	a = (
		# Sprinting multiplier
		Input.get_action_strength("sprint") + 1) * speed * (
			# Forward/backwards
			CamX.global_transform.basis.z * (
				Input.get_action_strength("back") - Input.get_action_strength("forward")
				) 
			+ 
			# Right/Left
			CamX.global_transform.basis.x * (
				Input.get_action_strength("right") - Input.get_action_strength("left")
				)
		# Normalize direction
		).normalized()
	
	# If our acceleration has changed, sync the new one
	if a != accel:
		accel = a
		rset("a", a)
	
	# If keypress
	if event is InputEventKey:
		# Switch camera sides
		if event.is_action_pressed("switch_tps"):
			rpc("z")
		
		# Switch between TPS and FPS
		if event.is_action_pressed("switch_view"):
			rpc("y")
			

		# Jumping
		if event.is_action_pressed("jump") and is_on_floor():
			rpc("j") # jump
		
		# Grapple
		if event.is_action_pressed("grapple1"):
			local_grapple(true)
		elif event.is_action_released("grapple1"):
			rpc("R") # release right grapple
			Cam.stress = 0.2
		if event.is_action_pressed("grapple2"):
			local_grapple(false)
		elif event.is_action_released("grapple2"):
			rpc("L")  # release left grapple
			Cam.stress = 0.2

		# Crouching
		if event.is_action_pressed("crouch"):
			rpc("v") # crouch
		elif event.is_action_released("crouch"):
			rpc("u") # uncrouch

		# Reset Gravity
		if event.is_action_pressed("reset_gravity") and FlipTime.is_stopped():
			rpc("t", Vector3.UP, translation) # reset rotation to normal
			toggle_flippers(!G.Flip.pressed)
			G.Flip.pressed = !G.Flip.pressed
			# If we're turning flip off, set wait time
			if !G.Flip.pressed:
				FlipTime.start(5)
				yield(FlipTime, "timeout")
				FlipTime.wait_time = 1
			else:
				FlipTime.start()

		# Reload
		if event.is_action_pressed("reload"):
			AnimTree.set("parameters/Reloading/blend_amount", 1)
			AnimTree.set("parameters/Firing/active", true)

		# Slowdown time, like superhot
		if event.is_action_pressed("slowmo"):
			Engine.time_scale = int(Network.players.size() > 1) * .9 + .1
		elif event.is_action_released("slowmo"):
			Engine.time_scale = 1

		# Accelerate Hook, TODO: sync with multiplayer and only work if grappling
#		if Input.is_action_pressed("sprint"):
#			vel += (grapple_pos - global_transform.origin).normalized() * 3
##			vel -= CamY.global_transform.basis.z
##			vel.y += 1

		# Respawn
		if event.is_action("respawn") and RespawnTime.is_stopped():
			rpc("respawn")
			RespawnTime.start()
		
		# TODO: throw stuff around lmao
#		if event.is_action_pressed("throw"):
#			var proj : RigidBody = throwable_s.instance()
#			proj.rotation = Vector3(randf(), randf(), randf())
#			proj.translation = translation - Muzzle.global_transform.basis.z * (2 + vel.length() / 12)
#			proj.apply_central_impulse(-Muzzle.global_transform.basis.z * 64)
#			get_parent().add_child(proj)

	else:
		# Scroll
		if event is InputEventMouseButton: # and event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				rset("b", b - .025)
			elif event.button_index == BUTTON_WHEEL_DOWN:
				rset("b", b + .025)
		# Look
		if event is InputEventMouseMotion:
			CamX.rotate_y(event.relative.x * SENS_X) # Side to side // (transform.basis.y, 
			CamY.rotation.x = clamp(
				CamY.rotation.x + (event.relative.y * SENS_Y), 
				-PI/2, 
				PI/2
				) # Up down
			
		# This was me playing around with rotation that wrapped around, rather than 
		# capping up/down as 90 degrees and -90 degrees
#			CamY.rotation.x = CamY.rotation.x + (event.relative.y * SENS_Y)
#			if CamY.rotation.x < -PI/2 or CamY.rotation.x > PI/2:
#				SENS_X = -SENS_Y
#				CamY.rotation.x = wrapf(
#					CamY.rotation.x,
#					-PI, 
#					PI
#					) # Up down
#			else:
#				SENS_X = SENS_Y
			rpc_unreliable("A", event.relative)
		
		# Zoom/Aim
		if event.is_action_pressed("aim"):
			tween.interpolate_property(
				Cam, "fov", Cam.fov, int(Cam.fov) % 70 + 35, .25, Tween.TRANS_CUBIC
				)
			tween.start()

var time_elapsed := 0.0
func _physics_process(delta: float) -> void:
	# collision with boxes, don't need anymore since we will be doing custom physics
#	for index in get_slide_count():
#		var collision := get_slide_collision(index)
#		if collision.collider is RigidBody:
#			collision.collider.apply_central_impulse(-collision.normal * .05 * vel.length())

	# If we control this guy
	if is_network_master():
		# Set laser sight alpha
		if Input.is_action_pressed("fire"):
			LaserSight.material.albedo_color.a = .125
		else:
			LaserSight.material.albedo_color.a = .01

		# Set lasersight's length
		if FrontCast.is_colliding():
			LaserSight.height = LaserSight.to_local(FrontCast.get_collision_point()).length()
			LaserSight.translation.z = LaserSight.height / -2
		else:
			LaserSight.height = 256
			LaserSight.translation.z = -128

		# Shooting
		if Input.is_action_pressed("fire") and ROF.is_stopped():
			# TODO: Muzzle flash
			rpc("f") # fire
			Cam.stress = 0.25
			
		else:
			G.game.Reticule.rect_scale = Vector2(ROF.time_left + .2, ROF.time_left + .2) * 5

		# Check flippers for flipping
		for ray in Flippers:
			if ray.is_colliding() and FlipTime.is_stopped():
				var new_normal : Vector3 = ray.get_collision_normal()
				if new_normal.dot(newest_normal) != new_normal.length_squared():
					rpc("t", new_normal, translation)
		
		# Underwater tint
		if Cam.global_transform.origin.y < G.water_level:
			G.game.Water.visible = true
		else:
			G.game.Water.visible = false

	# Point at center
	if forward.is_colliding():
		GunHolder.look_at(forward.get_collision_point(), transform.basis.y)
	else:
		GunHolder.rotation = Vector3.ZERO

	# Grounded
	if is_on_floor():
		# Apply hard friction, unless grappling (then softer friction)
		vel *= friction * int(not_grappling) + DAMP_NEAR_HOOK * int(!not_grappling)
		vel += a
		var vel_speed := a.length()
		
		if vel_speed > 0:
			# animation of gears walking
			GearR.rotation = GearR.rotation.linear_interpolate(
				Vector3(cos(time_elapsed) / 8 + GEAR_REST_ROT, 0, 0), 
				4 * delta
			)
			GearR.translation = Vector3(1.15, sin(time_elapsed) / 16 - .25, 0)
			GearL.rotation = GearL.rotation.linear_interpolate(
				Vector3(sin(time_elapsed) / 8 + GEAR_REST_ROT, 0, 0), 
				4 * delta
			)
			GearL.translation = Vector3(-1.15, sin(time_elapsed) / 16 - .25, 0)
			time_elapsed += delta * accel.length() * 2.5
		else:
			GearR.rotation = GearR.rotation.linear_interpolate(
				Vector3(GEAR_REST_ROT, 0, 0), 
				4 * delta
			)
			GearL.rotation = GearL.rotation.linear_interpolate(
				Vector3(GEAR_REST_ROT, 0, 0), 
				4 * delta
			)
		
		# Walking Anims
		AnimTree.set("parameters/Move/blend_amount", vel_speed)
		AnimTree.set("parameters/SprintFactor/scale", clamp(vel_speed * .3, 1, 1.25))

	# Midair
	else:
		# Reduce grounded movespeed
		vel += .125 * a # TODO: fix massive acceleration if jump while moving
		AnimTree.set("parameters/Move/blend_amount", 0)
		
		GearR.rotation = GearR.rotation.linear_interpolate(
			Vector3(GEAR_REST_ROT, 0, 0), 
			4 * delta
		)
		GearL.rotation = GearL.rotation.linear_interpolate(
			Vector3(GEAR_REST_ROT, 0, 0), 
			4 * delta
		)

	# apply gravity, g is whether gravity is on or off, we turn off gravity if we're grappling
	vel -= int(g) * (int(not_grappling)) * (int(L_not_grapplin)) * grav * delta * transform.basis.y
	# If underwater
	if global_transform.origin.y < G.water_level:
		if Input.is_action_pressed("forward"):
			vel -= CamY.global_transform.basis.z * (int(Input.get_action_strength("sprint")) + 1)
		vel = vel * .95 + Vector3.UP * min(G.water_level - global_transform.origin.y + 1, 1) * grav * delta
		if Input.is_action_pressed("jump"):
			vel += global_transform.basis.y * grav * delta
		

	
	# apply inputs, physics
	vel = move_and_slide(vel, transform.basis.y, false, 4, .75, false)
	# note: using CamY.global_transform.basis.y for line 385
	# instead of transform.basis.y will move it in camera's down
	
	# Orient "up" normal with our newest_normal
	global_transform = global_transform.interpolate_with(
		align_with_y(global_transform, newest_normal), delta * 10
		)


	# Grappling logic
	var air_resistance := 1.0
	var air_resistance2 := 1.0

	# if Right Hook shot
	if GLine.visible:
		grapple_pos = RHook.global_transform.origin
		GearR.global_transform = GearR.global_transform.interpolate_with(
			GearR.global_transform.looking_at(grapple_pos, transform.basis.y), 
			delta * 16
		)
		GearR.rotation.y = clamp(GearR.rotation.y, -GEAR_MAX_ANGLE, GEAR_MAX_ANGLE)
		GLine.points[0] = grapple_pos
		GLine.points[1] = GearRMuzzle.global_transform.origin
	
	# Hook hit
	if !not_grappling:
		var new_grapple_len := (grapple_pos - global_transform.origin).length()
		# normalize grappling vel, and our rest length is 1
		var grapple_vel := (global_transform.origin - grapple_pos) / new_grapple_len * min(
			0, (1 - new_grapple_len)
			) * .25
		# Set max grapple velocity
		if grapple_vel.length_squared() > MAX_GRAPPLE_SPEED * MAX_GRAPPLE_SPEED:
			grapple_vel = grapple_vel.normalized() * MAX_GRAPPLE_SPEED
		vel += grapple_vel
		# If near grappling point, slow down (and get pulled more towards the point)
		var is_near := abs((grapple_pos - global_transform.origin).length_squared()) < 64
		# If near hook, use DAMP_NEAR_HOOK, otherwise use AIR_DAMPING
		air_resistance = DAMP_NEAR_HOOK * int(is_near) + AIR_DAMPING * int(!is_near)

	# if Left Hook shot
	if LGLine.visible:
		grapple_pos2 = LHook.global_transform.origin
		GearL.global_transform = GearL.global_transform.interpolate_with(
			GearL.global_transform.looking_at(grapple_pos2, transform.basis.y), 
			delta * 16
		)
		GearL.rotation.y = clamp(GearL.rotation.y, -GEAR_MAX_ANGLE, GEAR_MAX_ANGLE)
		LGLine.points[0] = grapple_pos2
		LGLine.points[1] = GearLMuzzle.global_transform.origin
	
	# Left Hook hit
	if !L_not_grapplin:
		var new_grapple_len := (grapple_pos2 - global_transform.origin).length()
		var grapple_vel := (global_transform.origin - grapple_pos2) / new_grapple_len * min(0, (
			1 - new_grapple_len)
			) * .25
		# Set max grapple velocity
		if grapple_vel.length_squared() > MAX_GRAPPLE_SPEED * MAX_GRAPPLE_SPEED:
			grapple_vel = grapple_vel.normalized() * MAX_GRAPPLE_SPEED
		vel += grapple_vel
		# If near grappling point, slow down (and get pulled more towards the point)
		var is_near2 := int(abs((grapple_pos2 - global_transform.origin).length_squared()) < 64)
		# If near hook, use DAMP_NEAR_HOOK, otherwise use AIR_DAMPING
		air_resistance2 = DAMP_NEAR_HOOK * int(is_near2) + AIR_DAMPING * int(!is_near2)
	
	# use our computed air_resistance dampings
	vel *= air_resistance*air_resistance2
	
	# Cosmetic, if not hooked, make mesh rotate upright
	if L_not_grapplin and not_grappling:
		MeshHelp.rotation = lerp(MeshHelp.rotation, Vector3.ZERO, 16 * delta)
	# Else rotate mesh towards hook point
	else:
		MeshHelp.global_transform = MeshHelp.global_transform.interpolate_with(
			MeshHelp.global_transform.looking_at(
				(grapple_pos * int(!not_grappling) + grapple_pos2 * int(!L_not_grapplin)) / 2,
				transform.basis.y
				), 
			16 * delta
			)
#	Attempt at rotating camera with mesh, kinda bad: 
#	CamHolder.rotation.z = MeshHelp.rotation.z


# Call only on self so that sounds follow TPS/FPS camera
func reparent_sound(sfx: AudioStreamPlayer3D) -> void:
	sfx.get_parent().remove_child(sfx)
	Cam.add_child(sfx)
	sfx.translation = Vector3.ZERO

# Turn flipping on/off based on ENABLED
func toggle_flippers(enabled: bool) -> void:
	for raycast in Flippers:
		raycast.enabled = enabled

# Activate Grappling Hooks
func hook(hook_name: String) -> void:
	if hook_name == "R":
		GLine.visible = true
		not_grappling = false
		RHook.visible = false
	else:
		LGLine.visible = true
		L_not_grapplin = false
	if is_instance_valid(Cam):
		Cam.stress = 0.28

# =-----------------------------------------------------------=
# Multiplayer Functions (single letters to save network usage)
# =-----------------------------------------------------------=

# Aim
puppet func A(rot: Vector2) -> void:
	CamX.rotate_y(rot.x * SENS_X) # Side to side // (transform.basis.y, 
	CamY.rotation.x = clamp(CamY.rotation.x + (rot.y * SENS_Y), -PI/2, PI/2) # Up down

# Set grapple hook position
puppet func r(trans: Vector3, y: float, cam_help_x: float, v: Vector3) -> void:
	s(trans, y, cam_help_x, v)
	RHook.enabled = true
	RHook.global_transform = FrontCast.global_transform
	G.game.add_child(RHook)
	GLine.visible = true

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
puppet func l(trans: Vector3, y: float, cam_help_x: float, v: Vector3) -> void:
	s(trans, y, cam_help_x, v)
	LHook.enabled = true
	LHook.global_transform = FrontCast.global_transform
	LGLine.visible = true
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

# Fire bullet at current orientation
puppetsync func f() -> void:
	G.game.laser_i = (G.game.laser_i + 1) % G.game.num_lasers
	var p : Projectile = G.game.projectiles[G.game.laser_i]
	G.game.add_child(p)
	p.global_transform = Muzzle.global_transform
	
	# integrate our current velocity accounting for slow mo
	p.translation += vel * Engine.time_scale / 60 
	
	p.monitoring = true
	p.visible = true
	p.rot = b
	p.player = self

#	AnimTree.set("parameters/Firing/active", false)
	AnimTree.set("parameters/Reloading/blend_amount", 0)
	AnimTree.set("parameters/Firing/active", true)

	# Audio
	Sfx.pitch_scale = rand_range(.85, 1.15)
	Sfx.play()

	# Timing
	ROF.start()
	p.timer.start()
#	Flash.visible = true


# Jump
puppetsync func j() -> void:
	vel += jump * transform.basis.y

# Sync position/orientation
puppet func s(trans: Vector3, y: float, x: float, velocity: Vector3, norm := newest_normal) -> void:
	translation = trans
	CamX.rotation.y = y
	CamY.rotation.x = x
	vel = velocity
	newest_normal = norm

# Sync transform (during flip)
puppetsync func t(normal: Vector3, trans: Vector3) -> void:
	translation = trans
	CamY.rotation.x = 0
#	CamX.rotation.y = 0
	newest_normal = normal
#	vel *= .25
	FlipTime.start()

# Uncrouch TODO: tween crouching
puppetsync func u() -> void:
#	Hitbox.shape.height = 1
#	Hitbox.translation.y = 0
#	Hitbox.scale = Vector3(1, 1, 1)
#	PMesh.mesh.mid_height = 1
#	PMesh.translation.y = 0
#	PMesh.scale = Vector3.ONE
	if Cam:
		Cam.get_parent().translation.y = 1.5 * int(!fps) + 1 * int(fps)
	tween.interpolate_property(
		PMesh, "translation:y", PMesh.translation.y, 0, CROUCH_TIME, Tween.TRANS_CUBIC
		)
	tween.interpolate_property(
		PMesh, "scale", PMesh.scale, Vector3.ONE, CROUCH_TIME, Tween.TRANS_CUBIC
		)
	tween.start()

# Crouch TODO: make hitbox also smaller, cam translate down
puppetsync func v() -> void:
#	Hitbox.shape.height = .5
#	Hitbox.translation.y = -.25
#	Hitbox.scale = Vector3(.9, .9, .5)
#	PMesh.mesh.mid_height = .5
#	PMesh.translation.y = -.4
#	PMesh.scale = Vector3(.9, .9, .75)
	if Cam:
		Cam.get_parent().translation.y = 1 * int(!fps) + .5 * int(fps)
	tween.interpolate_property(
		PMesh, "translation:y", PMesh.translation.y, -.4, CROUCH_TIME, Tween.TRANS_CUBIC
		)
	tween.interpolate_property(
		PMesh, "scale", PMesh.scale, Vector3(.9, .9, .75), CROUCH_TIME, Tween.TRANS_CUBIC
		)
	tween.start()

# Switch between FPS and TPS
puppetsync func y() -> void:
	# TODO: reduce to no if/else
	# Switching to TPS
	if fps:
		# previously Vector3(3.75, 1.5, 9)
		# Bring camera to side
		tween.interpolate_property(
			CamSpring, 
			"translation", 
			CamSpring.translation, 
			Vector3(3.5, 1.5, 0), 
			.25, 
			Tween.TRANS_CUBIC
			)
		# Spring length
		tween.interpolate_property(
			CamSpring, 
			"spring_length", 
			CamSpring.spring_length, 
			8, 
			.25, 
			Tween.TRANS_CUBIC
			)
		tween.start()
		PMesh.visible = true
	else:
		# previously Vector3(0, 1, 0)
		# Bring camera into head
		tween.interpolate_property(
			CamSpring, "translation", CamSpring.translation, Vector3(0, 1, -.25), .25, Tween.TRANS_CUBIC
			)
		# Spring length
		tween.interpolate_property(
			CamSpring, "spring_length", CamSpring.spring_length, 0, .25, Tween.TRANS_CUBIC
			)
		tween.start()
		# TODO: hide PMesh
		yield(tween, "tween_all_completed")
		PMesh.visible = false
	fps = !fps

# Shift camera position left/right
puppetsync func z() -> void:
	# This will be our camera position shifted to the other side
	var next : Vector3 = CamSpring.translation
	# Necessary because just multiplying by -1 could result in "convergence" effect
	next.x = -3.5 * sign(next.x) # previously -3.75
	tween.interpolate_property(
		CamSpring, "translation", CamSpring.translation, next, .25, Tween.TRANS_CUBIC
		)
	# Shift the gun as well
	next = GunHolder.translation
	next.x = -.75 * sign(next.x)
	tween.interpolate_property(
		GunHolder, "translation", GunHolder.translation, next, .25, Tween.TRANS_CUBIC
		)
	tween.start()

# Respawn
puppetsync func respawn() -> void:
	translation = Vector3(0, 100, 0)
	vel = Vector3.ZERO
	rotation = Vector3.ZERO
	newest_normal = Vector3.UP
	CamX.rotation.y = 0
	CamY.rotation.x = 0
	L()
	R()



# When other person calls this, send over my info to sync
master func req_syn() -> void:
	rpc("s", translation, CamX.rotation.y, CamY.rotation.x, vel, newest_normal)
	rpc("ss", -SENS_X * 1000)
	rpc("sync_cam", fps, CamSpring.translation, CamSpring.spring_length, GunHolder.translation)

puppet func sync_cam(is_fps_mode, camspring_trans, camspring_length, gun_trans) -> void:
	fps = is_fps_mode
	CamSpring.translation = camspring_trans
	CamSpring.spring_length = camspring_length
	GunHolder.translation = gun_trans

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
func _sync_timeout() -> void:
	rpc("s", translation, CamX.rotation.y, CamY.rotation.x, vel)

# Called when a player quits to main menu
func unregister() -> void:
	G.game.hooks.erase(LHook)
	G.game.hooks.erase(RHook)
	queue_free()

# TODO: Idk why this is causing glitch on web version, for some reason pressing e will activate the q grappling hook
func local_grapple(right: bool) -> void:
	if right and !RHook.is_inside_tree():
		RHook.enabled = true
		RHook.global_transform = FrontCast.global_transform
		GLine.points[1] = global_transform.origin
		GLine.visible = true
		G.game.add_child(RHook)
		rpc("r", translation, CamX.rotation.y, CamY.rotation.x, vel)
	elif !LHook.is_inside_tree():
		LHook.enabled = true
		LHook.global_transform = FrontCast.global_transform
		LGLine.points[1] = global_transform.origin
		LGLine.visible = true
		G.game.add_child(LHook)
		rpc("l", translation, CamX.rotation.y, CamY.rotation.x, vel)

	# Audio
	GrappleSfx.pitch_scale = rand_range(.5, .85)
	GrappleSfx.play()

# For when I add muzzle flash
#func _on_ROF_timeout():
#	Flash.visible = false
