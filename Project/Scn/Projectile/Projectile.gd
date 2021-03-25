class_name Projectile
extends Area

export var speed := 256
onready var timer := $Timer

func _on_Timer_timeout() -> void:
	get_parent().remove_child(self)

