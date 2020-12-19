extends AnimatedSprite

var charge_time = 0
var special = false
var charge_sprite = "AttackSpecialCharging"
var fire_sprite = "AttackSpecialFireball"

func _ready():
	if special:
		# Attack's "Move_Wait_Time" is in frames; on release changes sprite
		charge_time *= 60
		play(charge_sprite)


func _physics_process(delta):
	if special:
		charge_time -= 1
		if charge_time <= 0:
			play(fire_sprite)
