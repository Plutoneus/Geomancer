extends KinematicBody2D

const GRAVITY = 600
const FRICTION = 0.25
const AIR_RESISTENCE = 0.08

var my_body = null
var blood = 99999999
var stun_time = 0
var current_delta = 0

var motion = Vector2(0, 0)
var damage_influence = Vector2(0, 0)
var player_stored_motion = Vector2(0, 0)

var stop = false
var stop_timer = null
var stop_time = 0

var has_cleared = false


func _ready():
	pass


func _physics_process(delta):
	current_delta = delta
	if get_parent().is_in_group("EnemyBasic"): # or other enemy groups
		# EITHER YOUR BODY IS THE SANDBAG ITSELF OR THE BODY IS YOUR PARENT
		my_body = get_parent()
		my_body.extra_motion = my_body.move_and_slide(my_body.extra_motion)
		
	# Apply gravity
	if !stop:
		motion.y += GRAVITY * delta
	
	if is_on_floor() and !stop:
		motion.x = lerp(motion.x, 0, FRICTION)
		if motion.y > 50 and stun_time > 0:
			print("bounce")
			motion.y *= -1
	elif !stop:
		motion.x = lerp(motion.x, 0, AIR_RESISTENCE)
	
	if is_on_wall() and !stop and (abs(motion.x) > 5) and stun_time > 0:
		print("reverse")
		motion.x *= -1
	
	motion = move_and_slide(motion, Vector2.UP)
	
	# Time in hitstun
	if stun_time > 0:
		$Sprite.play("Hit")
		stun_time -= 1
	else:
		stun_time = 0
		$Sprite.play("Not Hit")


func hit(atk):
	# YOU CAN JUST PASS IN THE AREA, YOU KNOW?
	
	# Status effects, "properties"
#	if body != null:
#		if body.has[g.effect[32]]:
		# This shit happens/changes parameters
	
	# Shake the screen
	G.screen_shake(round(atk.properties["Strength"]/15))
	
	# Hit effect (now halfway between player and self)
	var effect_inst = G.effect_sprite.instance()
	effect_inst.anim = "EffectSmall"
	get_parent().add_child(effect_inst)
	effect_inst.global_position = global_position/2 + atk.global_position/2
	
	# Stop the body's current motion
	#my_body.extra_motion = Vector2(0, 0)
	motion.x = motion.x / 2
	motion.y = motion.y / 4
	
	# Add variance
	atk.force.x += rand_range(-90, 90)
	atk.force.y += rand_range(-15, 15)
	
	# Body is an enemy's health
	blood -= atk.properties["Strength"]
	# Stun is a parameter that is always decremented when < 0
	stun_time = atk.hitstun
	
	damage_influence = atk.force
	# Numbers!!!
	var numbers_inst = G.numbers_scene.instance()
	
	# A timer used to determine hitlag length, resolves in on_stop_timeout_complete() in each n
	if atk.user["Player"]:
		var P = G.player
		
		if atk.properties["Facing"]:
			if P.get_node("Sprite").flip_h:
				damage_influence.x *= -1
		
		P.stop = true
		P.stored_motion = P.motion
		P.stop_timer = G.timer_create(P, stop_timer, atk.hitstop, "stop")
		P.stop_timer.start()
		numbers_inst.type["Normal"] = true
		
	elif atk.user["Fiend"]:
		# Possible that this will only be for bat or certain scenarios. change according
		var F = atk.get_parent()
		
		if atk.properties["Facing"]:
			if F.get_node("Sprite").flip_h:
				damage_influence.x *= -1
		
		F.in_lag = true
		F.lag_time = atk.lag
		F.atk_time = 0
		F.stop = true
		F.stop_timer = G.timer_create(F, stop_timer, atk.hitstop, "stop")
		F.stop_timer.start()
		atk.queue_free()
		numbers_inst.type["Fiend"] = true
	
	# SFX
	if atk.type["Ender"]:
		S.get_node("HitStrong").pitch_scale = rand_range(0.95, 1.05)
		S.get_node("HitStrong").play()
		
		var tw_z = Tweening.tween_to(G.player.get_node("Camera"), "zoom", Vector2(.9, .9), .1)
		tw_z.easing = Tween.EASE_IN_OUT
		tw_z.trans = Tween.TRANS_SINE
		
	elif atk.type["Filler"] or atk.type["Starter"]:
		S.get_node("HitBasic").pitch_scale = rand_range(0.95, 1.05)
		S.get_node("HitBasic").play()
	
	numbers_inst.damage = atk.properties["Strength"]
	get_parent().add_child(numbers_inst)
	var x_range = rand_range(-32, 32)
	var y_range = rand_range(-64, -48)
	numbers_inst.global_position = global_position
	numbers_inst.destination = global_position + Vector2(x_range, y_range)
	
	stop = true
	stop_timer = G.timer_create(self, stop_timer, atk.hitstop, "stop")
	stop_timer.start()
	motion = Vector2(0, 0)


func _on_Collider_area_entered(area):
	# Get attack data from attack and send it to _hit()
	if area.is_in_group("Attack") and !stop:
		# TODO delete all parameters other than area, since you can just reference its vars
		hit(area)
		area.on_hit()


func on_stop_timeout_complete():
	var tw_z = Tweening.tween_to(G.player.get_node("Camera"), "zoom", Vector2(1, 1), .2)
	tw_z.easing = Tween.EASE_IN_OUT
	tw_z.trans = Tween.TRANS_SINE
	
	stop = false
	# Motion to apply after stop_time is over
	motion += damage_influence
