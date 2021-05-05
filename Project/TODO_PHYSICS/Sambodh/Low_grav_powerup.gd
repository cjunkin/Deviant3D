class_name Powerup
extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var currPlayer : Player
func _on_Area_body_entered(body):
	if body.is_in_group(G.PLAYER):
		currPlayer = body # Cast
		currPlayer.grav /= 2
		print("Your Gravity is now cut in half!")
		$Timer.start()
		print("Your Gravity has now reset!")


func _on_Timer_timeout():
	currPlayer.grav *= 2
	print("sdfkl")
	
	pass # Replace with function body.


