extends AnimatedSprite

var charge_time = 0
var special
var charge_sprite = "AttackSpecialCharging"
var fire_sprite = "AttackSpecialFireball"

func _ready():
	if special:
		# Make (amount of frames) play at (charge speed)
		# charge_time/60 * 47 sprite fps
		var charge_frames = get_sprite_frames().get_frame_count("AttackSpecialCharge")
		var charge_speed = charge_frames / (charge_time/60.0)
		var sf = get_sprite_frames()
		sf.set_animation_speed("AttackSpecialCharge", charge_speed)
		
		print("charge_time/60.0: ", charge_time/60.0)
		print("Charge frames: ", charge_frames)
		print("Charge anim speed: ", get_sprite_frames().get_animation_speed("AttackSpecialCharge"))
		play(charge_sprite)


func _physics_process(delta):
	if special:
		charge_time -= 1
		if charge_time <= 0:
			play(fire_sprite)
