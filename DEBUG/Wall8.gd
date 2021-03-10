extends CSGBox


func _physics_process(_delta):
	translation += (-global_transform.origin.cross(global_transform.basis.x)).normalized() * .1
