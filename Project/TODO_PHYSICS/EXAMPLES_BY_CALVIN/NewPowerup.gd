class_name Deleteme
extends Powerup # ctrl click me to see base class


func _on_Area_body_entered(body):
	._on_Area_body_entered(body) # Calls the parent's method
	
	# Here we want it to do some extra stuff on top of what the parent does
	if body.is_in_group(G.PLAYER):
		currPlayer = body # Cast
		currPlayer.grav /= 10
		print("NewPowerup.gd")
		
