extends Sprite

func _ready():
	var ghost_color = G.player.ghost_color
	$AlphaTween.interpolate_property(
		self, 
		"modulate", 
		ghost_color, 
		Color(1, 1, 1, 0.0), 
		0.5, 
		Tween.TRANS_QUAD, 
		Tween.EASE_OUT
	)
	$AlphaTween.start()

func _on_Tween_tween_completed(object, key):
	queue_free()
