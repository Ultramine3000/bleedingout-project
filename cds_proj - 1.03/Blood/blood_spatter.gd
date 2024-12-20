extends GPUParticles3D
class_name Blood

const LIFESPAN: float = 2.5
var despawn_timer: float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	despawn_timer += delta
	if despawn_timer >= LIFESPAN:
		free()
