extends Node

var game: Spatial
var hosted := false


const SFX_BUS := 1
const MUSIC_BUS := 2
enum {OFF, LOW, MED, HIGH}

onready var Menu := $Menu
onready var SSlider := $Menu/Panel/Buttons/Sound/SSlider
onready var MSlider := $Menu/Panel/Buttons/Music/MSlider
onready var SensSlider := $Menu/Panel/Buttons/Sensitivity/SensSlider
var current_player : Player

var shadows := HIGH
var glow := HIGH
#var lighting := OFF
#var glow := OFF

func _ready() -> void:
	$Menu.hide()
	set_process_input(false)
	SSlider.value = db2linear(AudioServer.get_bus_volume_db(SFX_BUS))
	MSlider.value = db2linear(AudioServer.get_bus_volume_db(MUSIC_BUS))
	SensSlider.value = 2

func _input(event: InputEvent) -> void:
	# Pause
	if event.is_action_pressed("ui_cancel"):
		# TODO: reduce to no if/else
		# Pause
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Menu.visible = true
#			if current_player:
			current_player.set_process_input(false)
		# Unpause
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Menu.visible = false
#			if current_player:
			current_player.set_process_input(true)
	# Fullscreen
	elif event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen



func _on_MSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear2db(value))


func _on_SSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS, linear2db(value))


func _on_Quit_button_up():
	get_tree().quit()


func _on_SSlider_mouse_exited():
	SSlider.release_focus()


func _on_MSlider_mouse_exited():
	MSlider.release_focus()


func _on_CheckBox_toggled(button_pressed: bool):
	for raycast in current_player.PMesh.get_children():
		if raycast is RayCast:
			raycast.enabled = button_pressed

func _on_SensSlider_value_changed(value: float):
	current_player.ss(value)
	current_player.rpc("ss", value)

func _on_SensSlider_mouse_exited():
	SensSlider.release_focus()
