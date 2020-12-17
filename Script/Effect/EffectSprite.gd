extends AnimatedSprite

var ani_speed = 0.2

func _ready():
	var tw_scale = Tweening.tween_to(self, "scale", Vector2(0, 0), ani_speed)
	tw_scale.easing = Tween.EASE_IN_OUT
	tw_scale.trans = Tween.TRANS_ELASTIC
	
	var tw_rot = Tweening.tween_to(self, "rotation_degrees", 360, ani_speed)
	tw_rot.easing = Tween.EASE_IN_OUT
	tw_rot.trans = Tween.TRANS_QUAD

func _process(delta):
	if scale.x <= 0:
		queue_free()
