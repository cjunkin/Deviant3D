extends Node

# Groups
const ENEMY := "EN"
const LASER := "L"
const EXPL := "E"
const WORM_BODY := "WB"

# Paths
const MENU_SCENE := "res://Scn/MainMenu.tscn"
#const GAME_SCENE := "res://Scn/Lvl/Level.tscn"
const GAME_SCENE := "res://Game.tscn"
var TERRAIN_SEED : int

# Settings
const SFX_BUS := 1
const MUSIC_BUS := 2
enum {OFF, LOW, MED, HIGH}

# Graphics
#var shadows := HIGH
#var glow := HIGH
#var bloom := HIGH
var shadows := OFF
var glow := OFF
var bloom := OFF

# Pause Settings
var sens_changed := false
var gravity_changed := false

# Game
var game: Game
var current_player : Player
var combo_msgs : PoolStringArray = [
	"Nice shot!",
	"Wabam!",
	"ReKt",
	"DesTroiD",
	"360 noSCope?"
]

# Theme
var primary_color := Color("b4d2ff")
var deactivated_color := Color("ff9898")

# GUI nodes
export (NodePath) var gravity

onready var Grav := get_node(gravity)
onready var Menu := $Menu
onready var SSlider := Menu.get_node("Center/Menu/Buttons/Sound/SSlider")
onready var MSlider := Menu.get_node("Center/Menu/Buttons/Music/MSlider")
onready var SensSlider := Menu.get_node("Center/Menu/Buttons/Sensitivity/SensSlider")
onready var Flip := Menu.get_node("Center/Menu/Buttons/Flip")
onready var Music := $Music

# Music
var music := load_files("Sfx/Music")

func _ready() -> void:
	Menu.hide()
	set_process_input(false)
	SSlider.value = db2linear(AudioServer.get_bus_volume_db(SFX_BUS))
	MSlider.value = db2linear(AudioServer.get_bus_volume_db(MUSIC_BUS))
	SensSlider.value = 2

	# Sliders should lose focus when mouse exits
	for child in $Menu/Center/Menu/Buttons.get_children():
		if child is HBoxContainer:
			for c in child.get_children():
				if c is Slider:
					c.connect("mouse_exited", self, "mouse_exit", [c])

func _input(event: InputEvent) -> void:
	# Pause
	if event.is_action_pressed("ui_cancel"):
		# TODO: reduce to no if/else
		# Pause
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			current_player.set_process_input(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Menu.visible = true
			get_tree().paused = Network.players.size() <= 1
			current_player.rpc("R")
			current_player.rpc("L")
#			print(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec"))
#			ProjectSettings.set_persisting("gui/timers/tooltip_delay_sec", true)
#			Global.set("gui/timers/tooltip_delay_sec", 0)
#			Global.save()
		# Unpause
		else:
			if sens_changed:
				current_player.rpc("ss", -current_player.SENS_X/1000)
				sens_changed = false
			if gravity_changed:
				current_player.rset("g", current_player.g)
				gravity_changed = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Menu.visible = false
			current_player.set_process_input(true)
			get_tree().paused = false

	# Fullscreen
	elif event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen


func start_game(player: Player) -> void:
	Menu.hide()
	SSlider.value = db2linear(AudioServer.get_bus_volume_db(SFX_BUS))
	MSlider.value = db2linear(AudioServer.get_bus_volume_db(MUSIC_BUS))
	current_player = player
	$Menu/Center/Menu/Buttons/Grav.pressed = current_player.g
	Flip.pressed = true # TODO: Fix hardcode
	set_process_input(true)
	play_music()

func _on_MSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear2db(value))


func _on_SSlider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS, linear2db(value))


func _on_Quit_button_up() -> void:
	get_tree().paused = false
	Menu.visible = false
	set_process_input(false)
	Network.disconnect_from_server()

func mouse_exit(slider: Control) -> void:
	slider.release_focus()


func _on_SensSlider_value_changed(value: float) -> void:
	sens_changed = true
	current_player.ss(value)

# Plays TRACK_NUMBER, or a random track if -1 is passed in
func play_music(track_number: int = -1) -> void:
	if music.size() > 0 and (!Music.playing or track_number != -1):
		randomize()
		Music.stream = music[randi() % music.size()]
		Music.play()

# Load files of extension EXT from DIR and return it as an array of loaded resources
static func load_files(dir: String, ext: String = ".ogg") -> Array:
	var files: Array = []
	var filenames: Array = []
	var file_directory: Directory = Directory.new()
	if file_directory.open(dir) == OK:
		if file_directory.list_dir_begin(true) == OK:

			var file: String = file_directory.get_next()
			while file != "":
				if file.right(file.length() - ext.length()) == ext:
					filenames.append(dir + "/" + file)
	#				filenames.append("preload(\"" + dir + file + "\")")
				file = file_directory.get_next()
			file_directory.list_dir_end()
		else:
			print("ERROR: Couldn't load " + ext + " files!")

#	filenames.sort()
#	print(filenames)
	for file in filenames:
		files.append(load(file))
	return files

# Plays another random track
func _on_Music_finished() -> void:
	play_music()

# Actually changes player's flip
func _on_Flip_toggled(button_pressed: bool) -> void:
	current_player.toggle_flippers(button_pressed)
	if button_pressed:
		Flip.modulate = G.primary_color
	else:
		Flip.modulate = G.deactivated_color

# Actually changes player's gravity
func _on_Grav_toggled(button_pressed: bool) -> void:
	gravity_changed = true
	current_player.g = button_pressed
	if button_pressed:
		Grav.modulate = G.primary_color
	else:
		Grav.modulate = G.deactivated_color

