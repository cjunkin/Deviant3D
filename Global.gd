extends Node

const SFX_BUS := 1
const MUSIC_BUS := 2
enum {OFF, LOW, MED, HIGH}

# Graphics
var shadows := HIGH
var glow := HIGH
var bloom := HIGH

# Pause Settings
var sens_changed := false

# Game
var game: Spatial
var hosted := false
var current_player : Player

# Theme
var primary_color := Color("b4d2ff")
var deactivated_color := Color("ff9898")

# GUI nodes
onready var Menu := $Menu
onready var SSlider := Menu.get_node("Menu/Buttons/Sound/SSlider")
onready var MSlider := Menu.get_node("Menu/Buttons/Music/MSlider")
onready var SensSlider := Menu.get_node("Menu/Buttons/Sensitivity/SensSlider")
onready var Flip := Menu.get_node("Menu/Buttons/Flip")

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
			current_player.set_process_input(false)
		# Unpause
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Menu.visible = false
			current_player.set_process_input(true)
			if sens_changed:
				current_player.rpc("ss", -current_player.SENS_X/1000)
				sens_changed = false

	# Fullscreen
	elif event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen


func _on_MSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear2db(value))


func _on_SSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS, linear2db(value))


func _on_Quit_button_up():
	Menu.visible = false
	Network.disconnect_from_server()


func _on_SSlider_mouse_exited():
	SSlider.release_focus()


func _on_MSlider_mouse_exited():
	MSlider.release_focus()

func _on_SensSlider_mouse_exited():
	SensSlider.release_focus()



func _on_CheckBox_toggled(button_pressed: bool):
	for raycast in current_player.CamX.get_children():
		if raycast is RayCast:
			raycast.enabled = button_pressed
	if button_pressed:
		Flip.modulate = G.primary_color
	else:
		Flip.modulate = G.deactivated_color

func _on_SensSlider_value_changed(value: float):
	sens_changed = true
	current_player.ss(value)



