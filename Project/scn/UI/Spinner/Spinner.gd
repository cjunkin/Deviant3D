extends TextureRect


func _physics_process(delta: float) -> void:
	rect_rotation += 350 * delta
