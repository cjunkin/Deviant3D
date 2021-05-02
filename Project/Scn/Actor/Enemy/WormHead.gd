extends KinematicBody


func _ready() -> void:
	add_to_group(G.ENEMY)

func dmg(_pos: Vector3, amt := 1) -> void:
	rpc("d")

remotesync func d() -> void:
	get_parent().get_parent().remove_child(get_parent())
