extends Control


func _on_Host_button_up() -> void:
	Network.host()

func _on_Join_button_up() -> void:
	Network.join()
