extends Camera


func _physics_process(delta):
#	var acc := Input.get_accelerometer()
#	var acc = Input.get_gravity()
	var acc = Input.get_magnetometer()
	rotation = Vector3(-acc.y, acc.x, 0) / 20
