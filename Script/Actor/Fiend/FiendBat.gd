extends KinematicBody2D

enum {
	ATTACK,
	IDLE
}

onready var P = G.player
var attack_inst = null
var state = 0

var follow_point = Vector2()
var motion = Vector2()
var variance = Vector2()

var update_rand = false
var update_rand_reset_time = 8
var update_rand_time = update_rand_reset_time

var stop_timer = null
var stop = false

var in_lag = false
var lag_time = 0

var in_atk = false
var atk_time_max = 90
var atk_time = 0

var atk_target_to = Vector2(100, 100)

func _ready():
	$AtkTarget.position = atk_target_to
	P.my_fiend = self

func _physics_process(delta):
	match state:
		IDLE:
			if P.get_node("Sprite").flip_h:
				$Sprite.flip_h = true
				$AtkTarget.position = atk_target_to * Vector2(-1, 1)
				follow_point = P.global_position + Vector2(26, -98)
			else:
				$Sprite.flip_h = false
				$AtkTarget.position = atk_target_to
				follow_point = P.global_position + Vector2(-26, -98)
			
			# Repeating timer to change variance every x frames
			if update_rand_time <= 0:
				variance = Vector2(rand_range(-3, 3), rand_range(-4, 4))
				update_rand_time = update_rand_reset_time
			else:
				update_rand_time -= 1
			if !stop:
				global_position = lerp(global_position, follow_point + variance, 0.02)
		ATTACK:
			if !stop:
				global_position = lerp(global_position, $AtkTarget.global_position, 0.07)
	
	if lag_time <= 0:
		in_lag = false
		lag_time = 0
	else:
		in_lag = true
		lag_time -= 1
	
	if atk_time <= 0:
		$Sprite.play("Idle")
		state = IDLE
		in_atk = false
		atk_time = 0
	else:
		in_atk = true
		atk_time -= 1

func attack():
	$Sprite.play("Attack")
	state = ATTACK
	in_atk = true
	atk_time = atk_time_max
	attack_inst = G.attack_fiend_bat.instance()
	add_child(attack_inst)

func on_stop_timeout_complete():
	stop = false
