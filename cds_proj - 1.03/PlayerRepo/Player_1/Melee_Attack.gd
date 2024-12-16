extends Node3D

# Export variables
@export var raycast: RayCast3D
@export var blood_scene: PackedScene

# References
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Flag to track if blood has been placed during the current animation
var blood_placed = false

# Counter for dynamically naming blood nodes
var blood_counter = 0

func _physics_process(delta):
	# Check if the current animation is "Swipe_1"
	if animation_player.current_animation == "Swipe_1":
		# Check if a blood node has already been added
		if not blood_placed:
			# Check if the raycast exists and is colliding with anything
			if raycast and raycast.is_colliding():
				var collider = raycast.get_collider()

				# Check if the collider is a CharacterBody3D and part of the "Player" group
				if collider is CharacterBody3D and collider.is_in_group("Player"):
					place_blood(collider)
					blood_placed = true  # Set the flag to true after placing blood

	# Reset the flag when the animation changes or ends
	if animation_player.current_animation != "Swipe_1":
		blood_placed = false

func place_blood(player: Node3D):
	if blood_scene:
		# Instantiate the blood node
		var blood_instance = blood_scene.instantiate()

		# Dynamically assign a unique name to the blood node
		blood_counter += 1
		blood_instance.name = "blood_spatter" + str(blood_counter)

		# Navigate to the "Health" node as a child of the "Head" node
		var health_node = player.get_node("Head/Health")
		if health_node:
			# Add the blood node as a child of the Health node
			health_node.add_child(blood_instance)
			
			# Position the blood effect at the collision point
			var collision_point = raycast.get_collision_point()
			blood_instance.global_transform.origin = collision_point
			
			# Make the blood instance face the attacking player
			var attacker_position = global_transform.origin
			var direction = (attacker_position - collision_point).normalized()
			
			# Adjust the blood instance's orientation to face the attacker
			blood_instance.look_at(attacker_position)
	else:
		print("Error: Blood scene not assigned.")
