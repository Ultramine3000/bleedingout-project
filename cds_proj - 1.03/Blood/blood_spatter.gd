extends Node3D

func _process(_delta: float) -> void:
	# Match the rotation of the parent node
	if get_parent() != null:
		rotation = get_parent().rotation
