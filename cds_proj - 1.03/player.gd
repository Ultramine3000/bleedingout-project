extends CharacterBody3D
class_name Player

# Exported variables for equipment
@export var equipment_scene_1: PackedScene

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var walk_sound: AudioStreamPlayer3D = $WalkSound
@onready var mesh: MeshInstance3D = $Skeleton3D/PlayerMesh
@onready var equip: Node3D = $Camera3D/Equip

# Constants for movement and control
const SPEED: float = 5.0
const SPRINT_MULTIPLIER: float = 1.5
const JUMP_VELOCITY: float = 6.5
const CONTROLLER_SENSITIVITY: float = 1.25  # Adjust this value for controller sensitivity
const AIR_INERTIA: float = 0.9
const GROUND_FRICTION_DEFAULT: float = 0.005
const BOB_FREQ: float = 2.0
const BOB_AMP_VERTICAL: float = 0.05
const BOB_AMP_HORIZONTAL: float = 0.01
const FOV_DEFAULT: float = 40.0  # Default FOV
const FOV_AIM: float = 20.0      # FOV when aiming
const FOV_TRANSITION_SPEED: float = 5.0  # Speed of FOV transition
const MOVE_INPUTS_SUFFIXES: Dictionary = {
	"FORWARD": "_move_forward",
	"BACKWARD" : "_move_backward",
	"LEFT" : "_move_left",
	"RIGHT" : "_move_right",
}
const LOOK_INPUTS_SUFFIXES: Dictionary = {
	"UP" : "_look_up",
	"DOWN" : "_look_down",
	"LEFT" : "_look_left",
	"RIGHT" : "_look_right",
}

# Head tilt constants
const MAX_TILT_ANGLE: float = 15.0  # Maximum tilt angle in degrees

# Exported variables for equip node bobbing
const EQUIP_BOB_FREQ: float = 2.0  # Frequency of bobbing
@export var equip_bob_intensity: float = 0.0035  # Controls the range of the bobbing motion

# Variables
var id: int = 1
var current_ground_friction: float = GROUND_FRICTION_DEFAULT
var t_bob: float = 0.0
var t_equip_bob: float = 0.0  # Additional variable for equip node bobbing
var is_walking: bool = false
var current_tilt_angle: float = 0.0  # Variable to track the current tilt angle
var camera_init_y: float = 0.0

func _ready() -> void:
	camera_init_y = camera.position.y
	camera.fov = FOV_DEFAULT  # Set default FOV
	_load_equipment()

func _physics_process(delta: float) -> void:
	var camera_move: Vector2 = Input.get_vector(
	  _input_name(LOOK_INPUTS_SUFFIXES["DOWN"]), _input_name(LOOK_INPUTS_SUFFIXES["UP"]),
	  _input_name(LOOK_INPUTS_SUFFIXES["LEFT"]), _input_name(LOOK_INPUTS_SUFFIXES["RIGHT"])
	)
	# Apply right stick input for continuous looking around
	rotate_y(-camera_move.y * CONTROLLER_SENSITIVITY * delta)
	camera.rotate_x(camera_move.x * CONTROLLER_SENSITIVITY * delta)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	# Handle head tilt based on input
	_handle_head_tilt(delta)
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	# Jump logic using "jump" input action
	if Input.is_action_just_pressed(_input_name("_jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Movement logic
	var input_dir: Vector2 = Input.get_vector(
	  _input_name(MOVE_INPUTS_SUFFIXES["LEFT"]), _input_name(MOVE_INPUTS_SUFFIXES["RIGHT"]),
	  _input_name(MOVE_INPUTS_SUFFIXES["FORWARD"]), _input_name(MOVE_INPUTS_SUFFIXES["BACKWARD"])
	)
	var direction: Vector3 = \
	  (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed: float = SPEED
	if Input.is_action_pressed(_input_name("_sprint")):
		current_speed *= SPRINT_MULTIPLIER
	if direction != Vector3.ZERO:
		if is_on_floor():
			is_walking = true
			# Play walk sound if walking
			if not walk_sound.playing:
				walk_sound.play()
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = lerp(velocity.x, direction.x * current_speed, AIR_INERTIA * delta)
			velocity.z = lerp(velocity.z, direction.z * current_speed, AIR_INERTIA * delta)
	elif is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, current_ground_friction / delta)
		velocity.z = lerp(velocity.z, 0.0, current_ground_friction / delta)
	# Stop the footstep sound if the player stops walking
	if is_walking and (direction == Vector3.ZERO):
		walk_sound.stop()
		is_walking = false
	# Head bobbing effect applied locally to the camera based on initial position
	if is_on_floor() and direction != Vector3.ZERO:
		t_bob += delta * velocity.length()
		var bob_offset: Vector3 = _subtle_headbob(t_bob)
		camera.position.y = camera_init_y + bob_offset.y
	else:
		t_bob = 0.0
		camera.position.y = camera_init_y
	# Smoothly transition the FOV
	if Input.is_action_pressed(_input_name("_aim")):
		camera.fov = lerp(camera.fov, FOV_AIM, FOV_TRANSITION_SPEED * delta)
	else:
		camera.fov = lerp(camera.fov, FOV_DEFAULT, FOV_TRANSITION_SPEED * delta)
	# Apply equip node bobbing
	_apply_equip_bob(delta)
	move_and_slide()

func _load_equipment() -> void:
	if not equipment_scene_1:
		print("Warning: Selected equipment scene is null.")
		return
	
	var active_equipment_instance: Node3D = equipment_scene_1.instantiate()
	equip.add_child(active_equipment_instance)
	active_equipment_instance.global_transform = equip.global_transform

func _apply_equip_bob(delta: float) -> void:
	t_equip_bob += delta * EQUIP_BOB_FREQ
	var bob_offset_y: float = sin(t_equip_bob) * equip_bob_intensity * 0.1  # Scale down intensity by 90%
	equip.position.y = bob_offset_y

func _subtle_headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP_VERTICAL
	pos.x = cos(time * BOB_FREQ * 0.5) * BOB_AMP_HORIZONTAL
	return pos

func _handle_head_tilt(delta: float) -> void:
	var target_tilt_angle: float = 0.0
	if Input.is_action_pressed(_input_name("_lean_left")):
		target_tilt_angle = MAX_TILT_ANGLE
	elif Input.is_action_pressed(_input_name("_lean_right")):
		target_tilt_angle = -MAX_TILT_ANGLE

	# Smoothly interpolate the current tilt angle towards the target tilt angle
	current_tilt_angle = lerp(current_tilt_angle, target_tilt_angle, 5.0 * delta)
	camera.rotation.z = deg_to_rad(current_tilt_angle)
	$Skeleton3D.rotation.z = deg_to_rad(current_tilt_angle)

func _input_name(suffix: String) -> String:
	return "p%d%s" % [id, suffix]
