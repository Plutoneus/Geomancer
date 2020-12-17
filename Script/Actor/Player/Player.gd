extends KinematicBody2D

enum {
	MOVE, 
	BASIC_ATK,
	DASH
}

onready var debug_label_0 = $UI/HUD/VBoxContainer/DebugLabel0
onready var debug_label_1 = $UI/HUD/VBoxContainer/DebugLabel1
onready var debug_label_2 = $UI/HUD/VBoxContainer/DebugLabel2
onready var debug_label_3 = $UI/HUD/VBoxContainer/DebugLabel3
onready var debug_label_4 = $UI/HUD/VBoxContainer/DebugLabel4
onready var debug_label_5 = $UI/HUD/VBoxContainer/DebugLabel5
onready var debug_label_6 = $UI/HUD/VBoxContainer/DebugLabel6

const ACCELERATION = 1200
const MAX_SPEED = 80
const MAX_DASH_SPEED = 190
const DASH_ACCELERATION = 1700
const FRICTION = 0.35
const AIR_RESISTENCE = 0.09
const GRAVITY = 550
const JUMP_FORCE = 198

var max_speed = MAX_SPEED

var state = 0
var my_fiend = null
var motion = Vector2()
var stored_motion = Vector2()

var stop_timer = null
var stop = false

var basic_atk_inst = null

var in_lag = false
var immovable_timer = null
var lag_time = 0
var stall_move = false
var levitation = 1

var cancelable = false
var cancelable_time = 0

var dash_length = 66000
var dash_timer = null
var dash_time = 0.45
var point_direction = Vector2()
var dash_queued = false
var prev_x_input = 0

# Trails
var ghost_timer = null
var ghost_time = 0.08
var ghost_colors = {
	"blue" : Color(0.452941, 0.637255, 0.923529)*1.5,
	"red" : Color(0.957031, 0.334353, 0.190659)*1.5,
}
var ghost_color = ghost_colors["blue"]

var current_max_speed = MAX_SPEED
var current_accel = ACCELERATION

# Camera
var tw_z = Vector2(1, 1)


func _ready():
	G.player = self
	
	ghost_timer = G.timer_create(self, ghost_timer, ghost_time, "ghost_timer")
	ghost_timer.start()


func _physics_process(delta):
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	point_direction = Vector2(x_input, y_input)
	match state:
		MOVE:
			max_speed = lerp(max_speed, MAX_SPEED, 0.08)
			# Move
			if x_input != 0:
				if is_on_floor() and !in_lag:
					$Sprite.play("Walk")
				
				if !in_lag:
					motion.x += x_input * ACCELERATION * delta
					motion.x = clamp(motion.x, -max_speed, max_speed)
					$Sprite.flip_h = x_input < 0
				else:
					motion.x += x_input * ACCELERATION/1.2 * delta
					motion.x = clamp(motion.x, -max_speed/1.2, max_speed/1.2)
				
			elif is_on_floor() and !in_lag:
				$Sprite.play("Idle")
			
			# Apply gravity
			if motion.y > 0:
				motion.y += (GRAVITY/levitation) * delta
			else:
				motion.y += GRAVITY * delta
			
			if is_on_floor():
				# No direction pressed on ground
				if x_input == 0:
					motion.x = lerp(motion.x, 0, FRICTION)
				
				# Jump is input
				if Input.is_action_just_pressed("ui_jump") and !in_lag:
					$Sprite.play("Jump")
					motion.y = -JUMP_FORCE
			elif !in_lag:
				# Variable height on jump release
				if Input.is_action_just_released("ui_jump") and motion.y < -JUMP_FORCE/2:
					motion.y = -JUMP_FORCE/2
				
				# Fall animation when falling
				if motion.y > 0:
					$Sprite.play("Fall")
				
				# No direction pressed in air
				if x_input == 0:
					motion.x = lerp(motion.x, 0, AIR_RESISTENCE)
					
			if (cancelable or (!in_lag and !stop)) and Input.is_action_just_pressed("ui_dash"):
				if cancelable and stop:
					dash_queued = true
					basic_atk_inst.kill()
				else:
					initiate_dash(x_input)
			
		DASH:
			# Move
			max_speed = MAX_DASH_SPEED
			motion.x = clamp(motion.x, -max_speed, max_speed)
			motion.y += (GRAVITY/1.2) * delta
			
			# Jump is input
			if Input.is_action_just_pressed("ui_jump") and is_on_floor():
				$Sprite.play("Jump")
				motion.y = -JUMP_FORCE
	
	# Apply forces
	if !stop:
		motion = move_and_slide(motion, Vector2.UP)
	else:
		motion = move_and_slide(Vector2(0, 0), Vector2.UP)
	
	# Continuous frame timers
	if cancelable_time <= 0:
		cancelable = false
		cancelable_time = 0
	else:
		cancelable = true
		cancelable_time -= 1
	
	if lag_time <= 0:
		in_lag = false
		lag_time = 0
	else:
		in_lag = true
		lag_time -= 1


func _process(delta):
	# Debug-only functions
	debug_controls()
	
	# Set the process by which the camera will shake 
	camera_shake_process(0.8)
	
	# Initiate basic attack
	if Input.is_action_just_pressed("ui_attack") and (!in_lag):
		if Input.is_action_pressed("ui_up"):
			use_equipped_attack("up")
	
	if Input.is_action_just_pressed("ui_attack") and (!in_lag):
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
			use_equipped_attack("forward")
	
	if Input.is_action_just_pressed("ui_attack") and (!in_lag):
		if (
			!Input.is_action_pressed("ui_up") and 
			!Input.is_action_pressed("ui_down") and 
			!Input.is_action_pressed("ui_right") and 
			!Input.is_action_pressed("ui_left")
		):
			use_equipped_attack("neutral")
	
	# Initiate fiend attack
	if Input.is_action_just_pressed("ui_fiend_attack") and (!my_fiend.in_lag):
		my_fiend.attack()


func use_equipped_attack(var direction = ""):
	match direction:
		"up":
			$Sprite.play("AtkBasicUtilt")
			
			cancelable = false
			basic_atk_inst = G.attack_basic_utilt.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything, always longer than cancelable
			in_lag = true
			lag_time = basic_atk_inst.lag
			
			# cancelable is when the player can do something other than regular movement or the same move 
			# to escape the lag of a move and destroy the move early
		
		"neutral":
			$Sprite.play("AtkBasicSpin")
			
			cancelable = false
			basic_atk_inst = G.attack_basic_spin.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything, always longer than cancelable
			in_lag = true
			lag_time = basic_atk_inst.lag
			
			# cancelable is when the player can do something other than regular movement or the same move 
			# to escape the lag of a move and destroy the move early
		
		"forward":
			$Sprite.play("AtkBasicPunch")
			
			cancelable = false
			basic_atk_inst = G.attack_basic_punch.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything, always longer than cancelable
			in_lag = true
			lag_time = basic_atk_inst.lag
			
			# cancelable is when the player can do something other than regular movement or the same move 
			# to escape the lag of a move and destroy the move early
			
	# Flip whole node accordingly
	if $Sprite.flip_h:
		basic_atk_inst.scale = Vector2(-1, 1)


# What happens as a mock camera "process" to settle camera down if shake is true
func camera_shake_process(settle):
	$Camera.set_offset(Vector2(G.shake_magnitude, 0))
	if G.shake:
		G.shake_magnitude *= -settle
		if round($Camera.get_offset().x) == 0:
			G.shake = false
			$Camera.set_offset(Vector2(0, 0))


func initiate_dash(x_in):
	# Change state change sprite
	state = DASH
	$Sprite.play("Dash")
	
	# Timer to determine escape to MOVE
	dash_timer = G.timer_create(self, dash_timer, dash_time, "dash")
	dash_timer.start()
	
	# Determine speed/direction
	motion.x = x_in * MAX_DASH_SPEED # No * delta, happens once
	ghost_color = ghost_colors["blue"]


# Timer timeouts
func on_dash_timeout_complete():
	dash_queued = false
	state = MOVE


func on_stop_timeout_complete():
	stop = false
	motion = stored_motion


func on_ghost_timer_timeout_complete():
	if state == DASH or abs(motion.x) > 150:
		var this_ghost = G.ghost_scene.instance()
		# Give the ghost a parent
		get_parent().add_child(this_ghost)
		this_ghost.set_global_position(position)
		this_ghost.texture = $Sprite.frames.get_frame($Sprite.animation, $Sprite.get_frame())
		if $Sprite.flip_h:
			this_ghost.flip_h = true
	
	# Infinitely repeat this timer
	ghost_timer.start()


func debug_controls():
	# Debug Labels
	debug_label_0.text = "cancelable: " + str(cancelable)
	debug_label_1.text = "in_lag: " + str(in_lag)
	debug_label_2.text = "motion: " + str(motion)
	debug_label_3.text = "point_direction: " + str(point_direction)
	debug_label_4.text = "stop: " + str(stop)
	debug_label_5.text = "cancelable_time: " + str(cancelable_time)
	debug_label_6.text = "lag_time: " + str(lag_time)
	
	if Input.is_action_just_pressed("ui_db_1"):
		tw_z = Tweening.tween_to($Camera, "zoom", Vector2(1, 1), .3)
		tw_z.easing = Tween.EASE_IN_OUT
		tw_z.trans = Tween.TRANS_SINE
	
	if Input.is_action_just_pressed("ui_db_2"):
		tw_z = Tweening.tween_to($Camera, "zoom", Vector2(1.5, 1.5), .3)
		tw_z.easing = Tween.EASE_IN_OUT
		tw_z.trans = Tween.TRANS_SINE
	
	if Input.is_action_just_pressed("ui_db_3"):
		tw_z = Tweening.tween_to($Camera, "zoom", Vector2(.5, .5), .3)
		tw_z.easing = Tween.EASE_IN_OUT
		tw_z.trans = Tween.TRANS_SINE
