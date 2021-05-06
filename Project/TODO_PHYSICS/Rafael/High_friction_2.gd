extends Area


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var currPlayer : Player
func _on_Area_body_entered(body):
	if body.is_in_group(G.PLAYER):
#		if monito:
			currPlayer = body # Cast
			currPlayer.friction = 0.825 * 0.8695
			print("Friction Increased!")
			G.game.announce("Friction Increased!")
			$Timer.start()
			$Availability.start()
			monitorable = false
			monitoring = false
			visible = false
			# Remove grappling hooks safely
			for child in get_children():
				if child is Hook:
					remove_child(child)
					child.player.call(child.name)
#		else:
#			print("Not yet available!")
#			print($Availability.get_time_left())


func _on_Timer_timeout():
	if is_instance_valid(currPlayer):
		currPlayer.friction = 0.825
		print("Friction reset to normal")

	



func _on_Availability_timeout():
	monitorable = true
	monitoring = true
	visible = true

