extends ParallaxLayer

func _ready():
	pass

func _physics_process(delta):
	if motion_offset < Vector2(127, 127):
		motion_offset += Vector2(.5, .5)
	else:
		motion_offset = Vector2(0, 0)
