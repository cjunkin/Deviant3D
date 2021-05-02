extends MarginContainer

signal graphics_set

onready var overall : OptionButton = $Panel/Buttons/Options/Overall/Button
onready var shadows : OptionButton = $Panel/Buttons/Options/shadows/Button
onready var glow : OptionButton = $Panel/Buttons/Options/glow/Button
onready var bloom : OptionButton = $Panel/Buttons/Options/bloom/Button
onready var ssao : OptionButton = $Panel/Buttons/Options/ssao/Button

# Setting constants
const STANDARD := PoolStringArray(["Off", "Low", "Medium", "High"])
const BINARY := PoolStringArray(["Off", "On"])
const ALL_GFX_OPTIONS := PoolStringArray(["shadows", "glow", "bloom", "ssao"]) # TODO: more graphics settings

func _ready() -> void:
	# Add options
	add_options_to_button(overall, PoolStringArray(["Potato", "Low", "Medium", "High"]))
	add_options_to_button(shadows, STANDARD)
	add_options_to_button(glow, BINARY)
	add_options_to_button(bloom, BINARY)
	add_options_to_button(ssao, STANDARD)

	# Setup signals
	setup_graphics_options_signals($Panel/Buttons/Options, "gfx_changed")


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
				update_overall_ui()
			# Set other defaults
			else:
				set_setting(setting, G.get(setting))



# Sets SETTING in G to INDEX (off, low, med, high), corrects overbounds INDEX
func set_setting(setting: String, index: int) -> void:
	# Bounds correction
	index = int(min(index, get(setting).get_item_count() - 1))
	# Set global variable
	G.set(setting, index)
	# Visual update
	get(setting).select(index)

# Sets overall's text to "custom" unless we match a preset
func update_overall_ui() -> void:
	var first : int = G.get(ALL_GFX_OPTIONS[0])
	var all_match := true
	for option in ALL_GFX_OPTIONS:
		if first != G.get(option):
			all_match = false
			break
	if all_match:
		overall.select(first)
	else:
		overall.text = "Custom"

# Add all strings from OPTIONS as options for BUTTON
func add_options_to_button(button: OptionButton, options: PoolStringArray) -> void:
	var i := 0
	for option in options:
		button.add_item(option, i)
		i += 1

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
	if is_instance_valid(G.game):
		print(setting)
		G.game.get_node("Env")._ready()

func _on_DoneButton_pressed():
	emit_signal("graphics_set")
