extends Node

var game: Spatial
var hosted := false

enum {OFF, LOW, MED, HIGH}

onready var blur := $Blur
var current_player : Player

var shadows := HIGH
var glow := HIGH
#var lighting := OFF
#var glow := OFF

func _ready() -> void:
	set_process_input(false)

func _input(event: InputEvent) -> void:
	# Pause
	if event.is_action_pressed("ui_cancel"):
		# TODO: reduce to no if/else
		# Pause
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			blur.visible = true
			current_player.set_process_input(false)
		# Unpause
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			blur.visible = false
			current_player.set_process_input(true)
	# Fullscreen
	elif event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
