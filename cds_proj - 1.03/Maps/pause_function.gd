extends Node

@export var ui_scene_path: PackedScene

var ui_instance: Node = null
var is_ui_open: bool = false
var number_of_players: int = 4

@onready var spawn_points: Node3D = $SpawnPoints

func _ready() -> void:
	var player_view_scene: PackedScene = preload("res://Player/Player_View.tscn")
	for p in range(number_of_players):
		var player_view: SubViewportContainer = player_view_scene.instantiate()
		var player: Player = player_view.get_child(0).get_child(0)
		player.id = p + 1
		%GridContainer.add_child(player_view)
		player.global_position = spawn_points.get_child(p).global_position
		player.mesh.set_layer_mask_value(20 - p, true)
		player.camera.set_cull_mask_value(20 - p, false)
		player.camera.set_cull_mask_value(12 - p, true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		spawn_ui()

func spawn_ui() -> void:
	if not ui_instance:
		# Load and add the UI instance to the scene tree
		ui_instance = ui_scene_path.instantiate()
		add_child(ui_instance)
		is_ui_open = true
		get_tree().paused = true  # Pause the game
		print("UI spawned and game paused")
