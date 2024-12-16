extends Button

# Exported variable to select the scene in the Inspector
@export var scene_to_switch_to: PackedScene

func _ready():
	# Connect the button's "pressed" signal using Callable
	self.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if scene_to_switch_to:
		# Switch to the specified scene
		get_tree().change_scene_to_packed(scene_to_switch_to)
	else:
		print("No scene assigned to 'scene_to_switch_to' export variable.")
