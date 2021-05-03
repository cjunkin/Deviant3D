extends PanelContainer

export (NodePath) var original: NodePath

func _ready() -> void:
#	var wasd := PoolStringArray(["ui_up", "ui_right", "ui_left", "ui_down"])
	var ignore := PoolStringArray(["fire", "toggle_debug", "aim"])
	var binding_s := load("res://Scn/UI/Controls/Bind.tscn")
	for action in InputMap.get_actions():
		# Custom controls
		if !action.begins_with("ui") and !(action in ignore):
			add_binding(action, binding_s)
			
#		# WASD keys
#		elif action in wasd:
#			add_binding(action.replace("ui_", ""), action, binding_s)
	set_process_unhandled_key_input(false)

var bindings := {}

func add_binding(bind_name: String, binding_s: Resource) -> void:
	var Buttons := $Controls/Scroll/Buttons
#	var binding := HBoxContainer.new()
	var binding: HBoxContainer = binding_s.instance()
	binding.name = bind_name
	
	var bind_label := binding.get_node("Txt")
	bind_label.text = bind_name.capitalize()
	bind_label.set_h_size_flags(SIZE_EXPAND_FILL)
	bind_label.align = Label.ALIGN_CENTER
	
	var events := binding.get_node("Grid")
	events.name = "grid"
	events.set_h_size_flags(SIZE_EXPAND_FILL)
	events.columns = 2

	for event in InputMap.get_action_list(bind_name):
		if !(event is InputEventJoypadButton):
			var button := Button.new()
			button.text = event.as_text()
			button.set_h_size_flags(SIZE_EXPAND_FILL)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			events.add_child(button)
			if button.connect("pressed", self, "listen_for_rebind", [button]) != OK:
				print("ERROR: check Controls.gd, button couldn't connect to listen_for_rebind")
			bindings[button] = event
			button.name = bind_name
	# TODO: allow adding of optional secondary controls
	Buttons.add_child(binding)
#	binding.add_child(bind_label)
#	binding.add_child(events)

var event_to_be_replaced : InputEventKey
var button_to_rebind: Button
func listen_for_rebind(button) -> void:
	button_to_rebind = button
	event_to_be_replaced = bindings[button]
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process_unhandled_key_input(true)


func rebind(button: Button, event: InputEventKey) -> void:
	var action : String = button.name
	InputMap.action_add_event(action, event)
	InputMap.action_erase_event(action, event_to_be_replaced)
	mouse_filter = MOUSE_FILTER_STOP
	set_process_unhandled_key_input(false)
	button.text = event.as_text()

func _on_Back_pressed() -> void:
	hide()
	if get_node_or_null(original):
		get_node(original).show()

func _unhandled_key_input(event: InputEventKey) -> void:
	# TODO: warn against duplicate keys
	# TODO: be able to clear bindings
	rebind(button_to_rebind, event)
