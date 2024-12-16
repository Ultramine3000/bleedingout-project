extends Node3D

# Declare variables for AnimationPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Input action mappings for player 2
var p2_actions = {
	"p2_move_forward": "RunForward",
	"p2_move_left": "RunLeft",
	"p2_move_right": "RunRight",
	"p2_move_backward": "RunBackward"
}

# Animation speed scales
var animation_speeds = {
	"RunForward": 0.7,
	"RunLeft": 0.7,
	"RunRight": 0.7,
	"RunBackward": 0.7,
	"Idle": 1.0,
	"Stab": 3,
	"Jump": 1.5
}

# Flags to track special animations
var is_stabbing = false
var is_jumping = false

func _physics_process(delta):
	_handle_p2_movement()

# Handles playing animations based on p2 inputs
func _handle_p2_movement():
	# If Stab or Jump animations are playing, do nothing else
	if is_stabbing or is_jumping:
		if not animation_player.is_playing():
			is_stabbing = false
			is_jumping = false  # Reset flags when animations finish
		return

	# Check if melee input is pressed
	if Input.is_action_just_pressed("p2_melee"):
		_play_animation("Stab")
		is_stabbing = true
		return  # Skip other inputs while stabbing

	# Check if jump input is pressed
	if Input.is_action_just_pressed("p2_jump"):
		_play_animation("Jump")
		is_jumping = true
		return  # Skip other inputs while jumping

	# Handle movement animations
	var animation_to_play = ""
	for action in p2_actions.keys():
		if Input.is_action_pressed(action):
			animation_to_play = p2_actions[action]
			break

	# Play the movement animation if it's not already playing
	if animation_to_play != "" and animation_player.current_animation != animation_to_play:
		_play_animation(animation_to_play)
	elif animation_to_play == "" and animation_player.current_animation != "Idle":
		# Play Idle animation when no movement input is detected
		_play_animation("Idle")

# Play an animation with the appropriate speed scale
func _play_animation(animation_name):
	if animation_name in animation_speeds:
		# Use the speed scale when playing the animation
		animation_player.play(animation_name, -1.0, animation_speeds[animation_name])
	else:
		# Default playback speed
		animation_player.play(animation_name, -1.0, 1.0)
