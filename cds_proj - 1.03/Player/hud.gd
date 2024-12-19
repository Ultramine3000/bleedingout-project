extends Control

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func update_ui(ammo_count: int) -> void:
	find_child("AmmoCount").text = "%d" % ammo_count
