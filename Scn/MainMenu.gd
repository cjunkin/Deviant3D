extends Control

onready var overall_gfx := $Menu/Gfx/Options/Overall/Button
onready var shadows := $Menu/Gfx/Options/shadows/Button
onready var glow := $Menu/Gfx/Options/glow/Button
onready var spinner := $Menu/PlayMargin/Play/Center/Spinner

const STANDARD := PoolStringArray(["Off", "Low", "Medium", "High"])
const BINARY := PoolStringArray(["Off", "On"])
const ALL_GFX_OPTIONS := PoolStringArray(["shadows", "glow"])

func _ready() -> void:
	add_options(overall_gfx, PoolStringArray(["Potato", "Low", "Medium", "High"]))
	add_options(shadows, STANDARD)
	add_options(glow, BINARY)
	setup_graphics_options($Menu/Gfx/Options)


func setup_graphics_options(gfx_control: Control) -> void:
	for child in gfx_control.get_children():
		if child is HBoxContainer:
			var button : OptionButton = child.get_node("Button")
			var setting : String = child.name
			if (button.connect("item_selected", self, "gfx_changed", [setting, button]) != OK):
				print("COULDN'T CONNECT " + setting)
			if setting == "Overall":
				button.select(3)
			else:
				button.select(int(min(G.get(setting), button.get_item_count() - 1)))

func gfx_changed(index: int, setting: String, button: OptionButton) -> void:
	if setting == "Overall":
		for option in ALL_GFX_OPTIONS:
			index = int(min(index, get(option).get_item_count() - 1)) # So that we don't go overbounds
			G.set(option, index)
			get(option).select(index)
	else:
		G.set(setting, int(min(index, button.get_item_count() - 1)))

# Add all strings from OPTIONS as options for BUTTON
func add_options(button: OptionButton, options: PoolStringArray) -> void:
	var i := 0
	for option in options:
		button.add_item(option, i)
		i += 1

func _on_Host_button_up() -> void:
	Network.host()

func _on_Join_button_up() -> void:
	Network.join()
