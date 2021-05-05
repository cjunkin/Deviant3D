extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var available = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var currPlayer : Player
func _on_Area_body_entered(body):
	if body.is_in_group(G.PLAYER):
		if available:
			currPlayer = body # Cast
			currPlayer.friction = 0.825 * 0.8695
			print("Friction Increased!")
			$Timer.start()
			$Availability.start()
			available = false
		else:
			print($Availability.get_time_left())


func _on_Timer_timeout():
	currPlayer.friction = 0.825
	print("Friction reset to normal")
	



func _on_Availability_timeout():
	available = true
	#pass # Replace with function body.
