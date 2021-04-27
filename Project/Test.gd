extends Spatial

var cam: Camera
onready var box = $CSGBox
var array := []

# Init, run at start
func _ready():
	cam = $Camera
	

# Run once every frame
func _physics_process(delta: float):
	if Input.is_action_just_released("go_bathroom"):
		print("Hello")
	box.translation.x += delta
#	connect()

func _input(event: InputEvent):
	print(event)
#	if event.is_pressed()



func _on_Area_area_entered(area):
	print(area.name)
