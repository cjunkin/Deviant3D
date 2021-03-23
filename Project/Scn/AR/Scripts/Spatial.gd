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
