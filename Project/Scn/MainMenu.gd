extends Control

onready var spinner : Control = $All/Margin/Menu/PlayMargin/Play/SpinCenter/Spinner
onready var Menu : Control = $All/Margin
onready var Anim := $Anim
onready var ClickAnim := $ClickAnim
onready var GfxCenter : Control

func _ready() -> void:
#	OS.set_low_processor_usage_mode(true)
	GfxCenter = G.Graphics.get_parent()
	if G.Graphics.connect("graphics_set", self, "_on_Graphics_graphics_set") != OK:
		print("Error: Couldn't connect graphics!")

	# Center background
	var screen : float = get_viewport().size.x
	var bg_img := $BG/Img
	screen /= 1920
	bg_img._set_size(bg_img.rect_size * screen)
	bg_img.rect_position = bg_img.rect_size / -2


func start() -> void:
#	OS.set_low_processor_usage_mode(false)
	$All/Margin/Menu/Status.text = "Connecting..."

func _on_Graphics_button_up() -> void:
	Anim.play("ChooseGfx")
	Menu.hide()
	GfxCenter.show()
	G.Graphics.show()
	G.Menu.show()
	G.GameOptions.hide()

func _on_Host_pressed():
	start()
	Network.host()
#	spinner.show()

func _on_Join_pressed():
	start()
	Network.join()
	spinner.show()

func _on_Graphics_graphics_set() -> void:
	Anim.play_backwards("ChooseGfx")
	Menu.show()








# IGNORE, may be useful later


# NodePaths
#export (NodePath) var overall_path
#export (NodePath) var shadows_path
#export (NodePath) var glow_path
#export (NodePath) var bloom_path
#export (NodePath) var ssao_path
#export (NodePath) var spinner_path
#export (NodePath) var Graphics_path
#export (NodePath) var Menu_path

# Actual Nodes
#onready var overall : OptionButton = get_node(overall_path)
#onready var shadows : OptionButton = get_node(shadows_path)
#onready var glow : OptionButton = get_node(glow_path)
#onready var bloom : OptionButton = get_node(bloom_path)
#onready var ssao : OptionButton = get_node(ssao_path)
#onready var spinner : Control = get_node(spinner_path)
#onready var Graphics : Control = get_node(Graphics_path)
#onready var Menu : Control = get_node(Menu_path)
