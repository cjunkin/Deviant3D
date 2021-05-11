extends KinematicBody

const EXTENTS := 512
var flipped := false
var dist_traveled : float = 0
const SPEED := 32

export (NodePath) var patrol_path
#var patrol_points: PoolVector3Array
#var patrol_index := 0

# FIXME: Sync multiplayer starting position, 
# FIXME: Stop moving when paused

func _ready() -> void:
	set_network_master(get_tree().get_root().get_network_master())
	if !is_network_master():
		yield(Network, "game_start")
		rpc("req_syn")
#	if patrol_path:
#		var path: Path = get_node(patrol_path)
#		patrol_points = path.curve.get_baked_points()
##		print(patrol_points)

master func req_syn() -> void:
	rpc("t", translation.x, dist_traveled, flipped)

puppet func t(transl: float, dt : float, fl: bool) -> void:
	translation.x = transl
	dist_traveled = dt
	flipped = fl

func _physics_process(delta: float) -> void:
	translation.x += delta * (int(flipped) * 2 - 1) * SPEED
	dist_traveled += delta * SPEED
	if dist_traveled > EXTENTS:
		flipped = !flipped
		dist_traveled = 0

#	var target = patrol_points[patrol_index]
#	if translation.distance_to(target) < 1:
#		print(target)
##		print("TRANS ", translation)
#
#		patrol_index = (patrol_index + 1) % patrol_points.size()
#		target = patrol_points[patrol_index]
#	translation += (target - translation).normalized() * SPEED * delta
