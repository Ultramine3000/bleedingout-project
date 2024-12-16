extends Node3D

@export var raycast: RayCast3D
@export var blood_scene: PackedScene

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var camera: Camera3D
var camera_parent: Node

var is_ads = false
var is_running = false
var is_walking = false
var is_reloading = false
var is_meleeing = false
var is_inspecting = false
var lock_animation = false
var is_firing = false

var ammo_count = 30
var max_ammo = 30
var firing_timer = 0.0

var blood_counter = 0

var INPUT_FIRE = ""
var INPUT_RELOAD = ""
var INPUT_MELEE = ""
var INPUT_INSPECT = ""
var INPUT_ADS = ""
var INPUT_RUN = ""
var INPUT_MOVE = []

var blend_times = {
	"idle": 0.01,
	"walking": 0.5,
	"running": 0.5,
	"idle_to_ADS": 0.1,
	"ADS_idle": 0.1,
	"ADS_to_idle": 0.1,
	"full_auto_ADS_fire": 0.0,
	"full_auto_fire": 0.0,
	"reload_empty": 0.0,
	"reload_not_empty": 0.0,
	"melee": 0.0,
	"inspect": 0.5,
	"draw": 0.0
}

var animation_speeds = {
	"idle": 1.0,
	"walking": 1.0,
	"running": 1.2,
	"idle_to_ADS": 1.0,
	"ADS_idle": 1.0,
	"ADS_to_idle": 1.0,
	"full_auto_ADS_fire": 2.0,
	"full_auto_fire": 2.0,
	"reload_empty": 1.0,
	"reload_not_empty": 1.0,
	"melee": 1.0,
	"inspect": 1.0,
	"draw": 1.0
}

const RECOIL_PER_SHOT = 0.01
const RECOIL_RECOVERY_SPEED = 8.0
var recoil_x = 0.0
var recoil_y = 0.0
var weapon_neutral_rot = Vector3()

func _ready():
	var player_id = find_player_id()

	if player_id != "":
		INPUT_FIRE = player_id + "_fire"
		INPUT_RELOAD = player_id + "_reload"
		INPUT_MELEE = player_id + "_melee"
		INPUT_INSPECT = player_id + "_inspect"
		INPUT_ADS = player_id + "_aim"
		INPUT_RUN = player_id + "_sprint"
		INPUT_MOVE = [
			player_id + "_move_forward",
			player_id + "_move_backward",
			player_id + "_move_left",
			player_id + "_move_right"
		]
	else:
		INPUT_FIRE = "default_fire"
		INPUT_RELOAD = "default_reload"
		INPUT_MELEE = "default_melee"
		INPUT_INSPECT = "default_inspect"
		INPUT_ADS = "default_aim"
		INPUT_RUN = "default_sprint"
		INPUT_MOVE = [
			"default_move_forward",
			"default_move_backward",
			"default_move_left",
			"default_move_right"
		]

	camera = find_camera()
	if camera == null:
		print("Error: Camera not found!")
	
	weapon_neutral_rot = self.rotation
	
	await play_draw_animation_on_start()
	play_animation("idle")

func find_player_id() -> String:
	var current = self
	while current:
		if current.name.begins_with("player_"):
			return current.name.replace("player_", "p")
		elif current.name.begins_with("p"):
			return current.name
		current = current.get_parent()
	return ""

func find_camera() -> Camera3D:
	var current = self
	while current:
		if current is Camera3D:
			return current
		current = current.get_parent()
	return null

func _process(delta):
	if lock_animation:
		return
	handle_firing(delta)
	handle_recoil_recovery(delta)
	handle_ads()
	handle_movement()
	handle_actions()

func play_draw_animation_on_start():
	if animation_player and animation_player.has_animation("draw"):
		lock_animation = true
		play_animation("draw")
		await wait_for_animation("draw")
		lock_animation = false
	else:
		print("No draw animation found.")

func handle_firing(delta):
	if Input.is_action_pressed(INPUT_FIRE) and ammo_count > 0:
		is_firing = true
		firing_timer += delta
		if firing_timer >= 0.1:
			firing_timer = 0.0
			ammo_count -= 1
			print("Ammo:", ammo_count)

			play_animation("full_auto_ADS_fire" if is_ads else "full_auto_fire")

			# Vertical recoil
			recoil_x += RECOIL_PER_SHOT
			# Horizontal recoil: random left or right kick
			# Let's say we randomize between -RECOIL_PER_SHOT*0.5 and RECOIL_PER_SHOT*0.5
			recoil_y += randf_range(-RECOIL_PER_SHOT*0.5, RECOIL_PER_SHOT*0.5)

			update_weapon_recoil()

			# Check hit and place blood
			if raycast and raycast.is_colliding():
				var collider = raycast.get_collider()
				if collider is CharacterBody3D and collider.is_in_group("Player"):
					place_blood(collider)
	else:
		if is_firing and (Input.is_action_just_released(INPUT_FIRE) or ammo_count <= 0):
			is_firing = false
			if ammo_count <= 0:
				print("Out of ammo!")
			play_animation("ADS_idle" if is_ads else "idle")

func handle_recoil_recovery(delta):
	if not is_firing:
		recoil_x = lerp(recoil_x, 0.0, RECOIL_RECOVERY_SPEED * delta)
		recoil_y = lerp(recoil_y, 0.0, RECOIL_RECOVERY_SPEED * delta)
	update_weapon_recoil()

func update_weapon_recoil():
	var rot = weapon_neutral_rot
	rot.x += recoil_x    # Kick up
	rot.y += recoil_y    # Kick left/right randomly
	self.rotation = rot

func handle_ads():
	if is_reloading or is_meleeing or is_inspecting or lock_animation:
		return

	if Input.is_action_just_pressed(INPUT_ADS) and not is_ads:
		is_ads = true
		await play_ads_sequence("idle_to_ADS", "ADS_idle")

	if Input.is_action_just_released(INPUT_ADS) and is_ads:
		is_ads = false
		await play_ads_sequence("ADS_to_idle", "idle")

func handle_movement():
	if is_reloading or is_meleeing or is_inspecting or lock_animation or is_firing or is_ads:
		return

	var is_moving = false
	for action in INPUT_MOVE:
		if Input.is_action_pressed(action):
			is_moving = true
			break

	if is_moving:
		if Input.is_action_pressed(INPUT_RUN):
			if not is_running:
				is_running = true
				is_walking = false
				play_animation("running")
		else:
			if not is_walking:
				is_walking = true
				is_running = false
				play_animation("walking")
	else:
		if is_walking or is_running:
			is_walking = false
			is_running = false
			play_animation("idle")

func handle_actions():
	if is_reloading or is_meleeing or is_inspecting or lock_animation:
		return

	if Input.is_action_just_pressed(INPUT_RELOAD):
		await handle_reload()
	elif Input.is_action_just_pressed(INPUT_MELEE):
		await handle_melee()
	elif Input.is_action_just_pressed(INPUT_INSPECT):
		await handle_inspect()

func handle_reload() -> void:
	if lock_animation or is_reloading or is_meleeing or is_inspecting:
		return

	is_reloading = true
	lock_animation = true

	var reload_anim = "reload_empty" if ammo_count == 0 else "reload_not_empty"
	play_animation(reload_anim)
	await wait_for_animation(reload_anim)

	ammo_count = max_ammo
	print("Ammo reloaded:", ammo_count)

	is_reloading = false
	lock_animation = false

func handle_melee() -> void:
	if lock_animation or is_reloading or is_inspecting:
		return

	is_meleeing = true
	play_animation("melee")
	await wait_for_animation("melee")
	is_meleeing = false

func handle_inspect() -> void:
	if lock_animation or is_reloading or is_meleeing:
		return

	is_inspecting = true
	play_animation("inspect")
	await wait_for_animation("inspect")
	is_inspecting = false

func place_blood(player: Node3D):
	if not blood_scene:
		print("Error: blood_scene not assigned!")
		return

	# Manually search for the Head node under the Player node
	var head_node: Node = null
	for child in player.get_children():
		if child.name == "Head":
			head_node = child
			break

	if head_node == null:
		print("Error: Head node not found under player!")
		return

	# Instantiate the blood scene
	var blood_instance = blood_scene.instantiate()
	blood_counter += 1
	blood_instance.name = "blood_spatter_%d" % blood_counter

	# Add blood instance to the Head node
	head_node.add_child(blood_instance)

	# Get collision information
	var collision_point = raycast.get_collision_point()
	var collision_normal = raycast.get_collision_normal()

	# Calculate forward direction based on collision normal
	var forward = Vector3(collision_normal.x, 0, collision_normal.z)
	if forward.length() < 0.01:
		forward = Vector3(1, 0, 0)  # Arbitrary fallback direction
	else:
		forward = forward.normalized()

	# Set position and orientation of the blood spatter
	blood_instance.global_transform.origin = collision_point
	blood_instance.look_at(collision_point + forward, Vector3(0, 1, 0))

	print("Blood spatter placed at", collision_point, "under Head node.")



func play_ads_sequence(start_anim: String, loop_anim: String) -> void:
	lock_animation = true
	play_animation(start_anim)
	await wait_for_animation(start_anim)
	play_animation(loop_anim)
	lock_animation = false

func play_animation(anim_name: String):
	var blend_time = blend_times.get(anim_name, 0.1)
	var speed = animation_speeds.get(anim_name, 1.0)
	if animation_player.current_animation != anim_name or not animation_player.is_playing():
		animation_player.play(anim_name, blend_time)
		animation_player.speed_scale = speed

func wait_for_animation(anim_name: String) -> void:
	while animation_player.is_playing() and animation_player.current_animation == anim_name:
		await get_tree().process_frame
