class_name Powerup
extends Area

#onready var Availability: Timer = $Availability
#get_node("Availability")


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
		currPlayer.grav /= 2
		print("Your Gravity is now cut in half!")
		G.game.announce("Your Gravity is now cut in half!")
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
		currPlayer.grav *= 2
		print("Your Gravity has now reset!")





func _on_Availability_timeout():
	monitorable = true
	monitoring = true
	visible = true

