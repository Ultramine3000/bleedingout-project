extends Control

# Array to store button references for navigation
var buttons = []
var current_index = 0  # Index of the currently focused button

func _ready():
	# Populate the button array with your buttons
	buttons = [
		$Button,  # Replace with the correct paths to your buttons
		$Button2,
		$Button3
	]
	
	# Ensure the first button is focused
	if buttons.size() > 0:
		buttons[current_index].grab_focus()

func _unhandled_input(event):
	# Detect navigation inputs
	if event.is_action_pressed("ui_down"):
		_navigate(1)  # Move down in the button list
	elif event.is_action_pressed("ui_up"):
		_navigate(-1)  # Move up in the button list
	elif event.is_action_pressed("ui_accept"):
		if buttons.size() > current_index:
			buttons[current_index].emit_signal("pressed")  # Trigger the button's pressed signal

func _navigate(direction):
	# Update the current index
	current_index += direction
	current_index = wrapi(current_index, 0, buttons.size())  # Loop around if out of bounds

	# Focus the new button
	buttons[current_index].grab_focus()
