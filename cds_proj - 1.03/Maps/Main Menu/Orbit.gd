extends Node3D

# Export variables for customization
@export var target_node: NodePath
@export var orbit_radius: float = 5.0
@export var orbit_speed: float = 1.0 # Radians per second
@export var tilt_angle: float = 0.0 # Degrees

# Internal variables
var orbit_angle: float = 0.0 # Current angle in the orbit

func _process(delta: float) -> void:
	if target_node == null:
		return
	
	# Get the target node instance
	var target: Node3D = get_node_or_null(target_node)
	if target == null:
		return
	
	# Increment the orbit angle based on speed and delta time
	orbit_angle += orbit_speed * delta
	orbit_angle = wrapf(orbit_angle, 0, TAU) # Keep angle within [0, 2π]

	# Calculate the new position
	var x = orbit_radius * cos(orbit_angle)
	var z = orbit_radius * sin(orbit_angle)
	var y = tan(deg_to_rad(tilt_angle)) * orbit_radius
	
	# Set the position relative to the target
	global_transform.origin = target.global_transform.origin + Vector3(x, y, z)
	look_at(target.global_transform.origin, Vector3.UP)
