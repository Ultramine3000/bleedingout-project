extends Node

@export var ui_scene_path: PackedScene

var ui_instance: Node = null
var is_ui_open: bool = false

func _unhandled_input(event):
	if event.is_action_pressed("pause_menu"):
			spawn_ui()

func spawn_ui():
	if not ui_instance:
		# Load and add the UI instance to the scene tree
		ui_instance = ui_scene_path.instantiate()
		add_child(ui_instance)
		is_ui_open = true
		get_tree().paused = true  # Pause the game
		print("UI spawned and game paused")
