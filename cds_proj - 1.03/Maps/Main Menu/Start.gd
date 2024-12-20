extends Button
class_name MainMenuButton

const DEFAULT_SIZE: Vector2 = Vector2(192.0, 40.0)

# Exported variable to select the scene in the Inspector
@export var scene_to_switch_to: PackedScene = null

static func create_new(custom_text: String, next_scene: PackedScene, \
	  custom_size: Vector2 = DEFAULT_SIZE) -> MainMenuButton:
	var button: MainMenuButton = preload("res://Maps/Main Menu/main_menu_button.tscn").instantiate()
	button.size = custom_size
	button.text = custom_text
	button.scene_to_switch_to = next_scene
	return button

func _ready() -> void:
	pass

func switch_scenes() -> void:
	if not scene_to_switch_to:
		print("No scene assigned to 'scene_to_switch_to' export variable.")
		return
	
	# Switch to the specified scene
	get_tree().change_scene_to_packed(scene_to_switch_to)
