extends Control

# Array to store button references for navigation
var buttons: Array[MainMenuButton] = []
var current_index: int = 0  # Index of the currently focused button

func _ready() -> void:
	position = get_viewport_rect().size / 2.0
	
	# Populate the button array with your buttons
	buttons.append_array(
		[
			MainMenuButton.create_new("Start", preload("res://Maps/DebugMap.tscn")),
			MainMenuButton.create_new("Options", null),
			MainMenuButton.create_new("Exit", null),
		]
	)
	
	_initialize_buttons()

func _unhandled_input(event: InputEvent) -> void:
	# Detect navigation inputs
	if event.is_action_pressed("ui_down"):
		_increment_current_index()
	elif event.is_action_pressed("ui_up"):
		_decrement_current_index()
	elif event.is_action_pressed("ui_accept"):
		if not ((0 <= current_index) and (current_index <= buttons.size() - 1)):
			return
		buttons[current_index].switch_scenes()

func _increment_current_index() -> void:
	current_index += 1
	if current_index >= buttons.size():
		current_index = 0
	buttons[current_index].grab_focus()

func _decrement_current_index() -> void:
	current_index -= 1
	if current_index < 0:
		current_index = buttons.size() - 1
	buttons[current_index].grab_focus()

func _initialize_buttons() -> void:
	var initial_children: Array[Node] = get_children()
	
	# Add the MainMenuButtons in the _ready func as children of the MainMenu node 
	for button in buttons:
		add_child(button)
	
	# Append buttons that were already children of the arrays list
	for child in initial_children:
		if child is MainMenuButton:
			buttons.append(child)
		elif child is Button:
			print("DEBUG: Use MainMenuButton instead of Button for MainMenu.")
	
	# Offset their y position based on their index
	var y_offset: float = 64.0
	for button in buttons.slice(1):
		button.position.y += y_offset
		y_offset += 64.0
	
	# Ensure the first button is focused
	if buttons.size() > 0:
		buttons[current_index].grab_focus()
