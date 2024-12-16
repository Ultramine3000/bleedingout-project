extends GPUParticles3D

func _ready():
	# Set particles to emit upwards
	if process_material and process_material is ParticleProcessMaterial:
		var particle_material = process_material as ParticleProcessMaterial
		particle_material.direction = Vector3.UP  # Pointing upwards

	emitting = true  # Start emitting

	# Timer to stop emitting after 0.25 seconds
	await get_tree().create_timer(0.25).timeout
	emitting = false
