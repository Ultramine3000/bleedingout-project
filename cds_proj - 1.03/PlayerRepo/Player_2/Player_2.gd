extends CharacterBody3D

# Constants for movement and control
const SPEED = 5.0
const SPRINT_MULTIPLIER = 1.5
const JUMP_VELOCITY = 6.5
const CONTROLLER_SENSITIVITY = 1.25  # Adjust this value for controller sensitivity
const AIR_INERTIA = 0.9
const GROUND_FRICTION_DEFAULT = 0.005
const BOB_FREQ = 2.0
const BOB_AMP_VERTICAL = 0.05
const BOB_AMP_HORIZONTAL = 0.01
const FOV_DEFAULT = 40.0  # Default FOV
const FOV_AIM = 20.0      # FOV when aiming
const FOV_TRANSITION_SPEED = 5.0  # Speed of FOV transition

# Head tilt constants
const MAX_TILT_ANGLE = 15.0  # Maximum tilt angle in degrees

# Exported variables for equip node bobbing
@export var equip_bob_intensity: float = 0.0035  # Controls the range of the bobbing motion
const EQUIP_BOB_FREQ = 2.0  # Frequency of bobbing

# Variables
var gravity = Vector3(0, -9.8, 0)
var current_ground_friction = GROUND_FRICTION_DEFAULT
var t_bob = 0.0
var t_equip_bob = 0.0  # Additional variable for equip node bobbing
var camera_start_position = Vector3()
var is_walking = false
var is_aiming = false
var equip_start_position = Vector3()  # For equip node bobbing
var current_tilt_angle = 0.0  # Variable to track the current tilt angle

# Exported variables for equipment
@export var equipment_scene_1: PackedScene

# Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var walk_sound: AudioStreamPlayer3D = $WalkSound

func _ready():
	camera_start_position = camera.transform.origin  # Store the initial camera position
	camera.fov = FOV_DEFAULT  # Set default FOV
	load_equipment()

	# Store initial position for equip node
	var equip_node = get_node_or_null("Head/Camera3D/Equip")
	if equip_node:
		equip_start_position = equip_node.transform.origin

func load_equipment():
	if equipment_scene_1:
		var equip_node = get_node_or_null("Head/Camera3D/Equip")
		if equip_node:
			var active_equipment_instance = equipment_scene_1.instantiate()
			equip_node.add_child(active_equipment_instance)
			active_equipment_instance.global_transform = equip_node.global_transform
		else:
			print("Error: 'Equip' node not found at path 'Head/Camera3D/Equip'.")
	else:
		print("Warning: Selected equipment scene is null.")

func _physics_process(delta: float) -> void:
	# Handle right-stick input for looking around
	var look_horizontal = 0.0
	var look_vertical = 0.0

	if Input.is_action_pressed("p2_look_right"):
		look_horizontal -= 1.0  # Invert direction for natural feel
	if Input.is_action_pressed("p2_look_left"):
		look_horizontal += 1.0  # Invert direction for natural feel
	if Input.is_action_pressed("p2_look_up"):
		look_vertical += 1.0  # Invert direction for natural feel
	if Input.is_action_pressed("p2_look_down"):
		look_vertical -= 1.0  # Invert direction for natural feel

	# Apply right stick input for continuous looking around
	head.rotate_y(look_horizontal * CONTROLLER_SENSITIVITY * delta)
	camera.rotate_x(look_vertical * CONTROLLER_SENSITIVITY * delta)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

	# Handle head tilt based on input
	_handle_head_tilt(delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity.y * delta

	# Jump logic using "jump" input action
	if Input.is_action_just_pressed("p2_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement logic
	var current_speed = SPEED
	if Input.is_action_pressed("p2_sprint"):
		current_speed *= SPRINT_MULTIPLIER

	var input_dir = Input.get_vector("p2_move_left", "p2_move_right", "p2_move_forward", "p2_move_backward")
	var direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		if is_on_floor():
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed

			# Play walk sound if walking
			if not walk_sound.playing:
				walk_sound.play()
			is_walking = true
		else:
			velocity.x = lerp(velocity.x, direction.x * current_speed, AIR_INERTIA * delta)
			velocity.z = lerp(velocity.z, direction.z * current_speed, AIR_INERTIA * delta)
	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, current_ground_friction / delta)
			velocity.z = lerp(velocity.z, 0.0, current_ground_friction / delta)

	# Stop the footstep sound if the player stops walking
	if is_walking and direction == Vector3.ZERO:
		walk_sound.stop()
		is_walking = false

	# Head bobbing effect applied locally to the camera based on initial position
	if is_on_floor() and direction != Vector3.ZERO:
		t_bob += delta * velocity.length()
		var bob_offset = _subtle_headbob(t_bob)
		camera.transform.origin = camera_start_position + Vector3(0, bob_offset.y, 0)
	else:
		t_bob = 0.0
		camera.transform.origin = camera_start_position

	# FOV handling based on aim input
	if Input.is_action_pressed("p2_aim"):
		is_aiming = true
	else:
		is_aiming = false

	# Smoothly transition the FOV
	if is_aiming:
		camera.fov = lerp(camera.fov, FOV_AIM, FOV_TRANSITION_SPEED * delta)
	else:
		camera.fov = lerp(camera.fov, FOV_DEFAULT, FOV_TRANSITION_SPEED * delta)

	# Apply equip node bobbing
	_apply_equip_bob(delta)

	move_and_slide()

func _apply_equip_bob(delta: float):
	t_equip_bob += delta * EQUIP_BOB_FREQ
	var bob_offset_y = sin(t_equip_bob) * equip_bob_intensity * 0.1  # Scale down intensity by 90%
	var equip_node = get_node_or_null("Head/Camera3D/Equip")
	if equip_node:
		equip_node.transform.origin.y = equip_start_position.y + bob_offset_y

func _subtle_headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP_VERTICAL
	pos.x = cos(time * BOB_FREQ * 0.5) * BOB_AMP_HORIZONTAL
	return pos

func _handle_head_tilt(delta: float):
	var target_tilt_angle = 0.0
	if Input.is_action_pressed("p2_lean_left"):
		target_tilt_angle = MAX_TILT_ANGLE
	elif Input.is_action_pressed("p2_lean_right"):
		target_tilt_angle = -MAX_TILT_ANGLE

	# Smoothly interpolate the current tilt angle towards the target tilt angle
	current_tilt_angle = lerp(current_tilt_angle, target_tilt_angle, 5.0 * delta)
	head.rotation = Vector3(head.rotation.x, head.rotation.y, deg_to_rad(current_tilt_angle))
