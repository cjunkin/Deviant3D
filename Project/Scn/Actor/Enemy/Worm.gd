extends Spatial
class_name Worm

onready var Head := $Head
#export var target_path : NodePath
onready var target : Spatial
export var body_seg_s : PackedScene
const speed := 100
const HALF_RADIUS := 6
const NUM_BODY_SEGS := 48
func _ready():
	for i in range(NUM_BODY_SEGS):
		var body_seg := body_seg_s.instance()
		body_seg.name = str(i)
#		body_seg.radius = HALF_RADIUS * 2
		add_child(body_seg)
		
	var i := HALF_RADIUS * -8
	for child in get_children():
		if child != Head:
			child.translation.x = i
		i -= HALF_RADIUS * 8
	set_physics_process(false)


func set_target(t: Spatial):
	target = t
	set_physics_process(true)

func _physics_process(delta):
	Head.translation -= Head.transform.basis.z * delta * speed
	Head.look_at(target.global_transform.origin, Vector3.UP)
	var ang : float = Head.global_transform.basis.z.angle_to(target.global_transform.basis.z)
	var T=Head.global_transform.looking_at(target.global_transform.origin, Vector3.UP)
	if ang == 0:
		ang = delta
	else:
		ang = delta / ang * 4
	
	Head.global_transform.basis.y=lerp(Head.global_transform.basis.y, T.basis.y, ang)
	Head.global_transform.basis.x=lerp(Head.global_transform.basis.x, T.basis.x, ang)
	Head.global_transform.basis.z=lerp(Head.global_transform.basis.z, T.basis.z, ang)
	Head.scale = Vector3.ONE


#	Head.global_transform = Head.global_transform.basis.slerp(
#		Head.global_transform.looking_at(target.global_transform.origin, Vector3.UP).basis,
#		.1
#	)

	var prev: Spatial = Head
	for child in get_children():
		if child != Head and !(child is SpringArm):# and prev.global_transform.origin.distance_squared_to(child.global_transform.origin) > 2:
			var look_pt : Vector3 = prev.global_transform.origin + child.global_transform.basis.z * HALF_RADIUS
			child.look_at(look_pt, Vector3.UP)
			child.global_transform.origin = look_pt + child.global_transform.basis.z * HALF_RADIUS
			prev = child

func get_class() -> String:
	return "W"
