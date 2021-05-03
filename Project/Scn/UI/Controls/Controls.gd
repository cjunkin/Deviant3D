extends PanelContainer

export (NodePath) var original: NodePath

func _ready() -> void:
	var wasd := PoolStringArray(["ui_up", "ui_right", "ui_left", "ui_down"])
	var ignore := PoolStringArray(["fire", "toggle_debug", "aim"])
	for action in InputMap.get_actions():
		# Custom controls
		if !action.begins_with("ui") and !(action in ignore):
			add_binding(action, action)
			var s: String
			
		# WASD keys
		elif action in wasd:
			add_binding(action.replace("ui_", ""), action)

func add_binding(bind_name: String, full_name: String) -> void:
	bind_name = bind_name.capitalize()
	var Buttons := $Controls/Scroll/Buttons
	var binding := HBoxContainer.new()
	binding.name = full_name
	
	var bind_label := Label.new()
	bind_label.text = bind_name
	bind_label.set_h_size_flags(SIZE_EXPAND_FILL)
	bind_label.align = Label.ALIGN_CENTER
	
	var events := GridContainer.new()
	events.name = "grid"
	events.set_h_size_flags(SIZE_EXPAND_FILL)
	events.columns = 2
	
	for event in InputMap.get_action_list(full_name):
		if !(event is InputEventJoypadButton):
			var button := Button.new()
			button.text = event.as_text()
			button.set_h_size_flags(SIZE_EXPAND_FILL)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			events.add_child(button)
			button.connect("pressed", self, "listen_for_rebind", [button, event])
			button.name = str(event)
		
	Buttons.add_child(binding)
	binding.add_child(bind_label)
	binding.add_child(events)


func listen_for_rebind(button, event) -> void:
	print(button, event, button.name)


func rebind(button, event) -> void:
	var action : String = button.name
	InputMap.action_add_event(action, event)
	InputMap.action_erase_event(action, event)

func _on_Back_pressed() -> void:
	hide()
	if get_node_or_null(original):
		get_node(original).show()

#func _unhandled_key_input(event: InputEventKey) -> void:
#	print(InputMap.get_action_list("fire"))
