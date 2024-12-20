extends Node3D

# Declare variables for AnimationPlayer
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# Input action mappings for player 1
const MOVE_INPUTS_SUFFIXES: Dictionary = {
	"FORWARD" : "_move_forward",
	"BACKWARD" : "_move_backward",
	"LEFT" : "_move_left",
	"RIGHT" : "_move_right",
}

const ANIMATION_NAMES: Dictionary = {
	"FORWARD" : "RunForward",
	"BACKWARD" : "RunBackward",
	"LEFT" : "RunLeft",
	"RIGHT" : "RunRight",
}

# Animation speed scales
const ANIMATION_SPEEDS: Dictionary = {
	"RunForward": 0.7,
	"RunLeft": 0.7,
	"RunRight": 0.7,
	"RunBackward": 0.7,
	"Idle": 1.0,
	"Stab": 3,
	"Jump": 1.5
}

# Flags to track special animations
var is_stabbing: bool = false
var is_jumping: bool = false

func _physics_process(_delta: float) -> void:
	_handle_p1_movement()

# Handles playing animations based on p1 inputs
func _handle_p1_movement() -> void:
	# If Stab or Jump animations are playing, do nothing else
	if is_stabbing or is_jumping:
		if animation_player.is_playing():
			return
		is_stabbing = false
		is_jumping = false  # Reset flags when animations finish

	# Check if melee input is pressed
	if Input.is_action_just_pressed(_input_name("_melee")):
		_play_animation("Stab")
		is_stabbing = true
		return  # Skip other inputs while jumping

	# Check if jump input is pressed
	if Input.is_action_just_pressed(_input_name("_jump")):
		_play_animation("Jump")
		is_jumping = true
		return  # Skip other inputs while jumping

	# Handle movement animations
	var animation_to_play: String = ""
	for key in MOVE_INPUTS_SUFFIXES.keys():
		if Input.is_action_pressed(_input_name(MOVE_INPUTS_SUFFIXES[key])):
			animation_to_play = ANIMATION_NAMES[key]
			break

	# Play the movement animation if it's not already playing
	if animation_to_play != "" and animation_player.current_animation != animation_to_play:
		_play_animation(animation_to_play)
	elif animation_to_play == "" and animation_player.current_animation != "Idle":
		# Play Idle animation when no movement input is detected
		_play_animation("Idle")

# Play an animation with the appropriate speed scale
func _play_animation(animation_name: String) -> void:
	if animation_name in ANIMATION_SPEEDS:
		# Use the speed scale when playing the animation
		animation_player.play(animation_name, -1.0, ANIMATION_SPEEDS[animation_name])
	else:
		# Default playback speed
		animation_player.play(animation_name, -1.0, 1.0)

func _input_name(suffix: String) -> String:
	var player: Player = get_parent()
	return "p%d%s" % [player.id, suffix]
