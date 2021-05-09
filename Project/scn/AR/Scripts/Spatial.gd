extends ARVROrigin

func _ready():
	# Mobile ARVR setup
	var arvr_interface = ARVRServer.find_interface("Native mobile")
	if arvr_interface and arvr_interface.initialize():
		get_viewport().arvr = true

#onready var raycast = $ARVRCamera/RayCast
#onready var text = $ARVRCamera/Viewport/Label
#
#func _physics_process(delta):
#	if raycast.is_colliding():
#		text.text = raycast.get_collider().name
#	else:
#		text.text = "Null"

#	var acc := Input.get_accelerometer()
##	var acc = Input.get_gravity()
##	var acc = Input.get_magnetometer()
#	rotation = Vector3(-acc.y, acc.x, 0) / 20
