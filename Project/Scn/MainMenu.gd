extends Control

export (NodePath) var overall_path
export (NodePath) var shadows_path
export (NodePath) var glow_path
export (NodePath) var bloom_path
export (NodePath) var spinner_path
export (NodePath) var Graphics_path
export (NodePath) var Menu_path

onready var overall : OptionButton = get_node(overall_path)
onready var shadows : OptionButton = get_node(shadows_path)
onready var glow : OptionButton = get_node(glow_path)
onready var bloom : OptionButton = get_node(bloom_path)
onready var spinner : Control = get_node(spinner_path)
onready var Graphics : Control = get_node(Graphics_path)
onready var Menu : Control = get_node(Menu_path)
onready var Anim := $Anim
onready var ClickAnim := $ClickAnim


const STANDARD := PoolStringArray(["Off", "Low", "Medium", "High"])
const BINARY := PoolStringArray(["Off", "On"])
const ALL_GFX_OPTIONS := PoolStringArray(["shadows", "glow", "bloom"]) # TODO: more graphics settings

func _ready() -> void:
#	OS.set_low_processor_usage_mode(true)

	# Add options
	add_options(overall, PoolStringArray(["Potato", "Low", "Medium", "High"]))
	add_options(shadows, STANDARD)
	add_options(glow, BINARY)
	add_options(bloom, BINARY)

	# Setup signals
	setup_graphics_options_signals($All/Margin/Center/Graphics/Buttons/Options, "gfx_changed")

	var screen : float = get_viewport().size.x
	var bg_img := $BG/Img
	screen /= 1920
	bg_img._set_size(bg_img.rect_size * screen)
	bg_img.rect_position = bg_img.rect_size / -2
	


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
				button.select(2)
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
		overall.text = "Custom"

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
	start()
	Network.host()

func _on_Join_button_up() -> void:
	start()
	Network.join()

func start():
#	OS.set_low_processor_usage_mode(false)
	G.set_process_input(true)
	G.play_music()

func _on_Graphics_button_up():
	Anim.play("ChooseGfx")
	Menu.hide()
	Graphics.show()


func _on_DoneButton_button_up():
	Anim.play_backwards("ChooseGfx")
	Menu.show()
	Graphics.hide()

