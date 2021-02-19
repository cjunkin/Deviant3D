extends Spatial
class_name Text

onready var label = $Viewport/Control/Label

func SetText(s: String) -> void:
	label.text = s
