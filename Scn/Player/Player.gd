class_name Player
extends KinematicBody

remote var a := Vector3.ZERO # acceleration
var vel := Vector3.ZERO

export var grav := 64
export var jump := 32
export var friction := .125
export var speed : float = 1000 * friction

#var cam_views : PoolVector3Array = [Vector3(3.75, 1, 6), Vector3()]

onready var CamHelp := $CamHelp
onready var Cam : Camera = CamHelp.get_node_or_null("Cam")
onready var Muzzle := $CamHelp/Gun/Muzzle
onready var Gun := $CamHelp/Gun
onready var TweenN := $Tween
onready var Sfx := $CamHelp/Gun/Sfx
onready var Firetime := $Firetime

onready var PMesh := $CSGMesh
onready var Hitbox := $Hitbox

func _ready() -> void:
	if is_network_master():
		if OS.get_name() != "Android" and OS.get_name() != "iOS":
			# Regular cam
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			CamHelp.add_child(load("res://Scn/Actor/Cam.tscn").instance())
			Cam = CamHelp.get_node("Cam")
		else:
			# AR CAM
			add_child(load("res://Scn/AR/ARVROrigin.tscn").instance())
			Cam = get_node("ARVROrigin")
		# Send over sync
		$Sync.start(0)
	else:
		set_process_input(false)
		$Sync.queue_free()
		rpc_id(get_network_master(), "req_syn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: # Rotate Camera
		rotate_y(event.relative.x * -.002)
		CamHelp.rotate_x(event.relative.y * -.002)
		CamHelp.rotation.x = clamp(CamHelp.rotation.x, -PI/2, PI/2)
		rpc_unreliable("r", event.relative)

func _physics_process(delta: float) -> void:
	if is_network_master():
		# Zoom
		if Input.is_action_just_pressed("aim"):
			TweenN.interpolate_property(Cam, "fov", Cam.fov, int(Cam.fov) % 70 + 35, .25, Tween.TRANS_CIRC)
			TweenN.start()
		
		# Switch camera sides
		if Input.is_action_just_pressed("switch_tps"):
			var next : Vector3 = Cam.translation
			next.x *= -1
			TweenN.interpolate_property(Cam, "translation", Cam.translation, next, .25, Tween.TRANS_CIRC)
			next = Gun.translation
			next.x *= -1
			TweenN.interpolate_property(Gun, "translation", Gun.translation, next, .25, Tween.TRANS_CIRC)
			TweenN.start()
		#	if Input.is_action_just_pressed("switch_view"):
		
		# Quit
		if Input.is_action_just_pressed("ui_cancel"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# Movement
		a = (Input.get_action_strength("sprint") + 1) * speed * delta * (transform.basis.z * (Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")) + transform.basis.x * (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"))).normalized()
#		var new_acc := (Input.get_action_strength("sprint") + 1) * speed * delta * (transform.basis.z * (Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")) + transform.basis.x * (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"))).normalized()
#		if new_acc != a:
#			rset_unreliable("a", new_acc)
#			a = new_acc
		rset_unreliable("a", a)
		
		# Shooting
		if Input.is_action_pressed("fire") and Firetime.is_stopped():
			rpc("f") # fire
			Cam.stress = 0.25
#		else:
#			$CamHelp/Gun/Muzzle/OmniLight.visible = false
		
		# Crouching
		if Input.is_action_just_pressed("crouch"):
			rpc("c")
		elif Input.is_action_just_released("crouch"):
			rpc("u")

	vel += a
	
	# apply gravity
	vel += Vector3.DOWN * delta * grav
	
	# friction along x, z (not up/down)
	vel.x = lerp(vel.x, 0, friction)
	vel.z = lerp(vel.z, 0, friction)

	vel = move_and_slide(vel, Vector3.UP, false, 4, .75, false)

	# collision with boxes
	for index in get_slide_count():
		var collision := get_slide_collision(index)
		if collision.collider is RigidBody:
			collision.collider.apply_central_impulse(-collision.normal * .05 * vel.length())

	# jumping
	if is_on_floor():
		a.y = 0
		vel.y = 0
		if is_network_master() and Input.get_action_strength("jump"):
			rpc("j") # jump

func _on_Sync_timeout():
	rpc("syn", translation, rotation.y, CamHelp.rotation.x)

# Fire
remotesync func f() -> void:
	Global.game.proj_i = (Global.game.proj_i + 1) % Global.game.num_projectiles
	var p : Projectile = Global.game.projectiles[Global.game.proj_i]
	Global.game.add_child(p)
	p.global_transform = Muzzle.global_transform
	p.monitoring = true
	p.visible = true
	Sfx.pitch_scale = rand_range(.85, 1.15)
	Sfx.play()
	Firetime.start()
#	$CamHelp/Gun/Muzzle/OmniLight.visible = true

# Crouch
remotesync func c() -> void:
	PMesh.mesh.mid_height = .5
	PMesh.translation.y = -.25
	PMesh.scale = Vector3(.9, .9, .9)
	Hitbox.shape.height = .5
	Hitbox.translation.y = -.25
	Hitbox.scale = Vector3(.9, .9, .9)

# Uncrouch
remotesync func u() -> void:
	PMesh.mesh.mid_height = 1
	PMesh.translation.y = 0
	PMesh.scale = Vector3(1, 1, 1)
	Hitbox.shape.height = 1
	Hitbox.translation.y = 0
	Hitbox.scale = Vector3(1, 1, 1)

# Jump
remotesync func j() -> void:
	vel.y = jump

# Aim
remote func r(rot: Vector2) -> void:
	rotate_y(rot.x * -.002)
	CamHelp.rotate_x(rot.y * -.002)
	CamHelp.rotation.x = clamp(CamHelp.rotation.x, -PI/2, PI/2)

# Sync transform
remote func syn(trans: Vector3, y: float, cam_help_x: float) -> void:
	translation = trans
	rotation.y = y
	CamHelp.rotation.x = cam_help_x

# When other person calls this, send over my info
remote func req_syn() -> void:
	_on_Sync_timeout()

