extends Control

func _ready():
	# Connect buttons to their respective functions
	$PanelContainer/VBoxContainer/ResumeButton.connect("pressed", Callable(self, "_on_resume_button_pressed"))
	$PanelContainer/VBoxContainer/RestartButton.connect("pressed", Callable(self, "_on_restart_button_pressed"))
	$PanelContainer/VBoxContainer/QuitButton.connect("pressed", Callable(self, "_on_quit_button_pressed"))

func _on_resume_button_pressed():
	# Resume the game
	get_tree().paused = false
	queue_free()  # Close the pause menu
	print("Game resumed")

func _on_restart_button_pressed():
	# Restart the current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.filename
		get_tree().paused = false  # Unpause before reloading
		get_tree().change_scene(scene_path)
		print("Game restarted")

func _on_quit_button_pressed():
	# Quit the game
	print
