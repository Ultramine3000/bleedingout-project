extends Control

const DEFAULT_RETICLE_COLOR: Color = Color.WHITE

var reticle_color: Color = DEFAULT_RETICLE_COLOR

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _draw() -> void:
	draw_circle(get_parent().get_visible_rect().size / 2.0, 2.0, reticle_color)

func update_ui(ammo_count: int, color: Color = Color.WHITE) -> void:
	var ammo_counter: Label = find_child("AmmoCount")
	if ammo_counter.modulate != color:
		ammo_counter.modulate = color
	ammo_counter.text = "%d" % ammo_count

func recolor_reticle(color: Color) -> void:
	reticle_color = color
	queue_redraw()
