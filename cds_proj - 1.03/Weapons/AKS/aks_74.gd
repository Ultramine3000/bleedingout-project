extends Node3D

@export var blood_scene: PackedScene
@export var bullethole_scene: PackedScene

@onready var raycast: RayCast3D = $RayCast3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var holder: Player = null

var is_ads: bool = false
var is_running: bool = false
var is_walking: bool = false
var is_reloading: bool = false
var is_meleeing: bool = false
var is_inspecting: bool = false
var is_firing: bool = false
var should_lock_animation: bool = false

var firing_timer: float = 0.0
var max_ammo: int = 30
var ammo_count: int = max_ammo

var blood_counter: int = 0

const FIRE_INPUT_SUFFIX: String = "_fire"
const RELOAD_INPUT_SUFFIX: String = "_reload"
const MELEE_INPUT_SUFFIX: String = "_melee"
const INSPECT_INPUT_SUFFIX: String = "_inspect"
const ADS_INPUT_SUFFIX: String = "_aim"
const RUN_INPUT_SUFFIX: String = "_sprint"
const MOVE_INPUTS_SUFFIX: Dictionary = {
	"FORWARD" : "_move_forward",
	"BACKWARD" : "_move_backward",
	"LEFT" : "_move_left",
	"RIGHT" : "_move_right",
}

const BLEND_TIMES: Dictionary = {
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

const ANIMATION_SPEEDS: Dictionary = {
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

const RECOIL_PER_SHOT: float = 0.01
const RECOIL_RECOVERY_SPEED: float = 8.0
var recoil_x: float = 0.0
var recoil_y: float = 0.0
var weapon_neutral_rot: Vector3 = Vector3.ZERO

func _ready() -> void:
	holder = get_parent().get_parent().get_parent()
	for mesh in find_child("Skeleton3D").get_children():
		mesh.set_layer_mask_value(13 - holder.id, true)
	holder.update_hud_ui(ammo_count)
	await _play_draw_animation_on_start()
	_play_animation("idle")

func _physics_process(delta: float) -> void:
	if should_lock_animation:
		return
	_handle_firing(delta)
	_handle_recoil_recovery(delta)
	_handle_ads()
	_handle_movement()
	_handle_actions()

func get_ammo_count() -> int:
	return ammo_count

func _decrement_ammo_count() -> void:
	ammo_count -= 1
	holder.update_hud_ui(ammo_count, Color.WHITE if ammo_count > 0 else Color.RED)

func _reset_ammo_count() -> void:
	ammo_count = max_ammo
	holder.update_hud_ui(ammo_count, Color.WHITE)

func _play_draw_animation_on_start() -> void:
	if (not animation_player) or (not animation_player.has_animation("draw")):
		return
	should_lock_animation = true
	_play_animation("draw")
	await _wait_for_animation("draw")
	should_lock_animation = false

func _handle_firing(delta: float) -> void:
	if Input.is_action_pressed(_input_name(FIRE_INPUT_SUFFIX)) and ammo_count > 0:
		is_firing = true
		firing_timer += delta
		if firing_timer >= 0.1:
			firing_timer = 0.0
			_decrement_ammo_count()
			_play_animation("full_auto_ADS_fire" if is_ads else "full_auto_fire")
			# Vertical recoil
			recoil_x += RECOIL_PER_SHOT
			# Horizontal recoil: random left or right kick
			# Let's say we randomize between -RECOIL_PER_SHOT*0.5 and RECOIL_PER_SHOT*0.5
			recoil_y += randf_range(-RECOIL_PER_SHOT * 0.5, RECOIL_PER_SHOT * 0.5)
			update_weapon_recoil()
			# Check hit and place blood
			if raycast.is_colliding():
				var collider: Node3D = raycast.get_collider()
				if collider is Player:
					_place_decal(blood_scene, collider, raycast.get_collision_point())
				elif (collider is StaticBody3D) or (collider is GeometryInstance3D):
					_place_decal(bullethole_scene, collider, raycast.get_collision_point())
	else:
		if is_firing and \
		  (Input.is_action_just_released(_input_name(FIRE_INPUT_SUFFIX)) or \
		  ammo_count <= 0):
			is_firing = false
			if ammo_count <= 0:
				print("Out of ammo!")
			_play_animation("ADS_idle" if is_ads else "idle")

func _handle_recoil_recovery(delta: float) -> void:
	if not is_firing:
		recoil_x = lerp(recoil_x, 0.0, RECOIL_RECOVERY_SPEED * delta)
		recoil_y = lerp(recoil_y, 0.0, RECOIL_RECOVERY_SPEED * delta)
	update_weapon_recoil()

func update_weapon_recoil() -> void:
	var rot = weapon_neutral_rot
	rot.x += recoil_x    # Kick up
	rot.y += recoil_y    # Kick left/right randomly
	self.rotation = rot

func _handle_ads() -> void:
	if is_reloading or is_meleeing or is_inspecting or should_lock_animation:
		return
	if Input.is_action_just_pressed(_input_name(ADS_INPUT_SUFFIX)) and not is_ads:
		is_ads = true
		await _play_ads_sequence("idle_to_ADS", "ADS_idle")
	if Input.is_action_just_released(_input_name(ADS_INPUT_SUFFIX)) and is_ads:
		is_ads = false
		await _play_ads_sequence("ADS_to_idle", "idle")

func _handle_movement() -> void:
	if is_reloading or is_meleeing or is_inspecting or \
	  should_lock_animation or is_firing or is_ads:
		return
	var is_moving = false
	for suffix in MOVE_INPUTS_SUFFIX.values():
		if Input.is_action_pressed(_input_name(suffix)):
			is_moving = true
			break
	if is_moving:
		if Input.is_action_pressed(_input_name(RUN_INPUT_SUFFIX)):
			if not is_running:
				is_running = true
				is_walking = false
				_play_animation("running")
		else:
			if not is_walking:
				is_walking = true
				is_running = false
				_play_animation("walking")
	else:
		if is_walking or is_running:
			is_walking = false
			is_running = false
			_play_animation("idle")

func _handle_actions() -> void:
	if is_reloading or is_meleeing or is_inspecting or should_lock_animation:
		return
	if Input.is_action_just_pressed(_input_name(RELOAD_INPUT_SUFFIX)):
		await _handle_reload()
	elif Input.is_action_just_pressed(_input_name(MELEE_INPUT_SUFFIX)):
		await _handle_melee()
	elif Input.is_action_just_pressed(_input_name(INSPECT_INPUT_SUFFIX)):
		await _handle_inspect()

func _handle_reload() -> void:
	if should_lock_animation or is_reloading or is_meleeing or is_inspecting:
		return
	is_reloading = true
	should_lock_animation = true
	var reload_anim = "reload_empty" if ammo_count == 0 else "reload_not_empty"
	_play_animation(reload_anim)
	await _wait_for_animation(reload_anim)
	_reset_ammo_count()
	is_reloading = false
	should_lock_animation = false

func _handle_melee() -> void:
	if should_lock_animation or is_reloading or is_inspecting:
		return
	is_meleeing = true
	_play_animation("melee")
	await _wait_for_animation("melee")
	is_meleeing = false

func _handle_inspect() -> void:
	if should_lock_animation or is_reloading or is_meleeing:
		return
	is_inspecting = true
	_play_animation("inspect")
	await _wait_for_animation("inspect")
	is_inspecting = false

func _place_decal(decal_scene: PackedScene, target: Node3D, collision_point: Vector3) -> void:
	var decal: Node3D = decal_scene.instantiate()
	if not (decal is Blood or decal is BulletHole):
		return
	target.add_child(decal)
	decal.global_position = collision_point
	if not raycast.get_collision_normal() == Vector3.UP:
		decal.look_at(collision_point + raycast.get_collision_normal())

func _play_ads_sequence(start_anim: String, loop_anim: String) -> void:
	should_lock_animation = true
	_play_animation(start_anim)
	await _wait_for_animation(start_anim)
	_play_animation(loop_anim)
	should_lock_animation = false

func _play_animation(anim_name: String) -> void:
	var blend_time = BLEND_TIMES.get(anim_name, 0.1)
	var speed = ANIMATION_SPEEDS.get(anim_name, 1.0)
	if animation_player.current_animation != anim_name or not animation_player.is_playing():
		animation_player.play(anim_name, blend_time)
		animation_player.speed_scale = speed

func _wait_for_animation(anim_name: String) -> void:
	while animation_player.is_playing() and animation_player.current_animation == anim_name:
		await get_tree().process_frame

func _input_name(suffix: String) -> String:
	var player: Player = get_parent().get_parent().get_parent()
	return "p%d%s" % [player.id, suffix]
