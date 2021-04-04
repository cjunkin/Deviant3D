class_name Projectile
extends Area

export var speed := 512
onready var timer := $Timer

var player

func _on_Timer_timeout() -> void:
	get_parent().remove_child(self)

