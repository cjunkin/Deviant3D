extends Control

onready var overall_gfx := $Menu/Gfx/Options/Overall/Button
onready var shadows := $Menu/Gfx/Options/shadow/Button
onready var glow := $Menu/Gfx/Options/glow/Button

const STANDARD := PoolStringArray(["Off", "Low", "Medium", "High"])
const BINARY := PoolStringArray(["Off", "On"])

func _ready() -> void:
	setup_graphics_options($Menu/Gfx/Options)
	add_options(overall_gfx, PoolStringArray(["Potato", "Low", "Medium", "High"]))
	add_options(shadows, STANDARD)
	add_options(glow, BINARY)

func setup_graphics_options(gfx_control: Control) -> void:
	for child in gfx_control.get_children():
		if child is HBoxContainer:
			var button : OptionButton = child.get_node("Button")
			button.connect("item_selected", self, "gfx_changed", [button])

func gfx_changed(index: int, button: OptionButton) -> void:
	var setting: String = button.get_item_text(index)
	print(button.name, setting)
	G.set(setting, index)
	print(G.get(setting))

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
