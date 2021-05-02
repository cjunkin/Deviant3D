extends VBoxContainer


export (NodePath) var original: NodePath

func _on_Back_pressed():
	print(get_parent().name)
	hide()
	if get_node_or_null(original):
		get_node(original).show()
