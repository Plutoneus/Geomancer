extends AnimatedSprite

var ani_speed = 0.2
onready var anim

func _ready():
	frame = 0
	playing = true
	match anim:
		"EffectSmall":
			play("EffectSmall")
			scale = Vector2(1, 1)
			var tw_scale = Tweening.tween_to(self, "scale", Vector2(0, 0), ani_speed)
			tw_scale.easing = Tween.EASE_IN_OUT
			tw_scale.trans = Tween.TRANS_ELASTIC
			
			var tw_rot = Tweening.tween_to(self, "rotation_degrees", 360, ani_speed)
			tw_rot.easing = Tween.EASE_IN_OUT
			tw_rot.trans = Tween.TRANS_QUAD
		"JumpRing":
			play("JumpRing")
			scale = Vector2(0.2, 0.2)

func _process(delta):
	match anim:
		"EffectSmall":
			if scale.x <= 0:
				queue_free()
		"JumpRing":
			pass


func _on_EffectSprite_animation_finished():
	match anim:
		"EffectSmall":
			pass
		"JumpRing":
			queue_free()
