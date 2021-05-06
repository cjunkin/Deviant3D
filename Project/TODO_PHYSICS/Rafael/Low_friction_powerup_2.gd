class_name LowFrictionPower
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
		currPlayer = body # Cast
		currPlayer.friction = 0.825 * 1.15
		print("Friction Reduced!")
		G.game.announce("Friction Reduced!")
		$Timer.start()
		$Availability.start()
		visible = false
		# Remove grappling hooks safely
		for child in get_children():
			if child is Hook:
				remove_child(child)
				child.player.call(child.name)
		monitorable = false
		monitoring = false
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

