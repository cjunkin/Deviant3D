extends Control

onready var overall_gfx := $Graphics/Buttons/Options/Overall/Button
onready var shadows := $Graphics/Buttons/Options/shadows/Button
onready var glow := $Graphics/Buttons/Options/glow/Button
onready var bloom := $Graphics/Buttons/Options/bloom/Button
onready var spinner := $Menu/PlayMargin/Play/SpinCenter/Spinner
onready var Graphics := $Graphics
onready var Menu := $Menu
onready var Anim := $Anim

const STANDARD := PoolStringArray(["Off", "Low", "Medium", "High"])
const BINARY := PoolStringArray(["Off", "On"])
const ALL_GFX_OPTIONS := PoolStringArray(["shadows", "glow", "bloom"]) # TODO: more graphics settings
# TODO: minimal theme, where graphics settings are opened in separate panel

func _ready() -> void:
	OS.set_low_processor_usage_mode(true)
	# Add options
	add_options(overall_gfx, PoolStringArray(["Potato", "Low", "Medium", "High"]))
	add_options(shadows, STANDARD)
	add_options(glow, BINARY)
	add_options(bloom, BINARY)
	# Setup signals
	setup_graphics_options_signals($Graphics/Buttons/Options, "gfx_changed")


# Connects all OptionButtons under parent GFX_CONTROL to FUNCTION_NAME
# (Note: OptionButtons must be children of an HBoxContainer under GFX_CONTROL)
func setup_graphics_options_signals(gfx_control: Control, function_name: String) -> void:
	for child in gfx_control.get_children():
		# Specific to this game
		if child is HBoxContainer:
			var button : OptionButton = child.get_node("Button")
			var setting : String = child.name
			# Connect signal
			if (button.connect("item_selected", self, function_name, [setting]) != OK): # , button
				print("ERROR: COULDN'T CONNECT " + setting)
			# Default overall is high
			if setting == "Overall":
				button.select(3)
			# Set other defaults
			else:
				set_setting(setting, G.get(setting))

# If setup_graphics_options_signals connects BUTTON to this, sets SETTING
# anytime the BUTTON's option is changed.
func gfx_changed(index: int, setting: String) -> void: #, button: OptionButton
	# Overall setting
	if setting == "Overall":
		for option in ALL_GFX_OPTIONS: 
			set_setting(option, index)
	# Custom setting overall
	elif index == 4:
		return
	# Specific setting
	else:
		set_setting(setting, index)
		overall_gfx.text = "Custom"

# Sets SETTING in G to INDEX (off, low, med, high), corrects overbounds INDEX
func set_setting(setting: String, index: int) -> void:
	# Bounds correction
	index = int(min(index, get(setting).get_item_count() - 1))
	# Set global variable
	G.set(setting, index)
	# Visual update
	get(setting).select(index)

# Add all strings from OPTIONS as options for BUTTON
func add_options(button: OptionButton, options: PoolStringArray) -> void:
	var i := 0
	for option in options:
		button.add_item(option, i)
		i += 1

func _on_Host_button_up() -> void:
	OS.set_low_processor_usage_mode(false)
	G.set_process_input(true)
	Network.host()

func _on_Join_button_up() -> void:
	OS.set_low_processor_usage_mode(false)
	G.set_process_input(true)
	Network.join()


func _on_Graphics_button_up():
	Menu.hide()
	Graphics.show()
	Anim.play("ChooseGfx")


func _on_Button_button_up():
	Menu.show()
	Graphics.hide()
	Anim.play_backwards("ChooseGfx")


