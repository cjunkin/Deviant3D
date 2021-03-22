extends Spatial
class_name Text

onready var label = $Viewport/Label

func SetText(s: String) -> void:
	label.text = s
