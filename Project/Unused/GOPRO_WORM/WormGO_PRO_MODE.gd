extends Spatial
class_name WormGOPRO

onready var Head := $Head
export (PackedScene) var body_seg_s
const speed := 128
const HALF_RADIUS := 6
const NUM_BODY_SEGS := 64

var cam : SpringArm= load("res://Scn/Actor/ShakyCam.tscn").instance()

func _ready():
	for i in range(NUM_BODY_SEGS):
		var body_seg = body_seg_s.instance()
		body_seg.name = str(i)
		add_child(body_seg)
		
	var i := HALF_RADIUS * -8
	for child in get_children():
		if child != Head and child is KinematicBody:
			child.translation.x = i
		i -= HALF_RADIUS * 8
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	Head.add_child(cam)
	cam.translation = Vector3(28, 1, -36)
	cam.rotation.y = rad2deg(130)
	cam.get_child(0).current = true

func _input(event):
	if event is InputEventMouseMotion:
		Head.rotate_y(event.relative.x * .002) # Side to side // (transform.basis.y, 
#		Head.rotate_x(event.relative.y * -.002)
		Head.rotation.x = clamp(
			Head.rotation.x + (event.relative.y * -.002), 
			-PI/2, 
			PI/2
			) # Up down
		playing = true
	if event.is_action_pressed("ui_cancel"):
		# Pause
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Unpause
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

var playing := false
export (PackedScene) var banana
onready var time := $Timer

func _physics_process(delta):
	if playing:
		$AudioStreamPlayer.play($AudioStreamPlayer.get_playback_position())
		playing = false
		$AudioStreamPlayer.volume_db += delta * 3
		cam.get_child(0).fov -= delta * 3
		if Input.is_action_just_pressed("fire"):
			$AudioStreamPlayer.stream = load("res://Scn/Actor/Enemy/FartMemeSound.wav")
		elif Input.is_action_pressed("fire") and time.is_stopped():
			time.start()
			var ban = banana.instance()
			add_child(ban)
			ban.scale = Vector3.ONE * 36
			ban.rotation = Vector3(randf(), randf(), randf()) - Vector3(.5, .5, .5)
			ban.translation = Head.global_transform.origin + ban.rotation * 64
			
	else:
		$AudioStreamPlayer.play(0)
		$AudioStreamPlayer.volume_db = 0
		cam.get_child(0).fov = 70
#		$AudioStreamPlayer.stop()
	Head.translation -= Head.transform.basis.z * delta * speed
	var prev: Spatial = Head
	for child in get_children():
		if child != Head and (child is KinematicBody):# and prev.global_transform.origin.distance_squared_to(child.global_transform.origin) > 2:
			var look_pt : Vector3 = prev.global_transform.origin + child.global_transform.basis.z * HALF_RADIUS
			child.look_at(look_pt, Vector3.UP)
			child.global_transform.origin = look_pt + child.global_transform.basis.z * HALF_RADIUS
			
			prev = child

func get_class() -> String:
	return "W"
