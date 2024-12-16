extends GPUParticles3D

func _ready():
	# Ensure particles do not rotate or align to velocity
	set_particles_to_face_up()

func set_particles_to_face_up():
	# Disable velocity alignment
	process_material.set("params/align_to_velocity", false)
	# Reset rotation and angular velocity
	process_material.set("params/angle", 0)
	process_material.set("params/angular_velocity", 0)
