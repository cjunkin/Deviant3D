class_name Deleteme
extends Powerup


func _on_Area_body_entered(body):
	._on_Area_body_entered(body)
	
	if body.is_in_group(G.PLAYER):
		currPlayer = body # Cast
		currPlayer.grav /= 10
		print("SCLJDOFJ")
		
