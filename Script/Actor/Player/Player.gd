extends KinematicBody2D
# https://coggle.it/diagram/X-y5gPYZr6FG98EF/t/-
# https://coggle.it/diagram/X-y5gPYZr6FG98EF/t/-
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

onready var enemy_frame = $UI/HUD/EnemyFrame

const ACCELERATION = 1200
const MAX_SPEED = 80
const MAX_DASH_SPEED = 190
const DASH_ACCELERATION = 1700
const FRICTION = 0.35
const AIR_RESISTENCE = 0.09
const GRAVITY = 550
const JUMP_FORCE = 198
const MAX_SUPER_METER_VALUE = 100

var max_speed = MAX_SPEED

var state = 0
var health = 500
var my_fiend = null
var super_meter_value = MAX_SUPER_METER_VALUE
var motion = Vector2()
var stored_motion = Vector2()
var jumps = 1

var stop_timer = null
var stop = false

var basic_atk_inst = null

var in_lag = false
var immovable_timer = null
var lag_time = 0
var stall_move = false
var levitation = 1

var dash_length = 66000
var dash_timer = null
var dash_time = 0.45
var point_direction = Vector2()
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

var current_target = null

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
#				else:
#					motion.x += x_input * ACCELERATION/1.2 * delta
#					motion.x = clamp(motion.x, -max_speed/1.2, max_speed/1.2)
				
			elif is_on_floor() and !in_lag:
				$Sprite.play("Idle")
			
			# Apply gravity
			if motion.y > 0:
				motion.y += (GRAVITY/levitation) * delta
			else:
				motion.y += GRAVITY * delta
			
			if in_lag:
				motion.x = lerp(motion.x, 0, AIR_RESISTENCE)
			
			if is_on_floor():
				jumps = 1
				# No direction pressed on ground
				if x_input == 0:
					motion.x = lerp(motion.x, 0, FRICTION)
				
				# Jump is input
				if Input.is_action_just_pressed("ui_jump") and !in_lag:
					initiate_jump()
			elif !in_lag:
				# Jump is input
				if Input.is_action_just_pressed("ui_jump") and jumps > 0:
					initiate_jump()
				
				# Fall animation when falling
				if motion.y > 0:
					$Sprite.play("Fall")
				
				# No direction pressed in air
				if x_input == 0:
					motion.x = lerp(motion.x, 0, AIR_RESISTENCE)
			
			if !is_on_floor():
				# Variable height on jump release
				if Input.is_action_just_released("ui_jump") and motion.y < -JUMP_FORCE/2:
					motion.y = -JUMP_FORCE/2
			
			if Input.is_action_just_pressed("ui_dash"):
				if !in_lag:
					# Not in an atk
					initiate_dash(x_input)
			
		DASH:
			# Move
			if !in_lag:
				max_speed = MAX_DASH_SPEED
				motion.x = clamp(motion.x, -max_speed, max_speed)
				motion.y += (GRAVITY/1.2) * delta
			else:
				motion.x = lerp(motion.x, 0, AIR_RESISTENCE)
				motion.y += (GRAVITY/1.2) * delta
			
			# Jump is input
			if Input.is_action_just_pressed("ui_jump"):
				initiate_jump()
	
	# Apply forces
	if !stop:
		motion = move_and_slide(motion, Vector2.UP)
	else:
		motion = move_and_slide(Vector2(0, 0), Vector2.UP)
	
	if lag_time <= 0:
		in_lag = false
		lag_time = 0
	else:
		in_lag = true
		lag_time -= 1


func _process(delta):
	# Debug-only functions
	debug_controls()
	$UI/HUD/SuperMeter.value = super_meter_value
	if current_target != null:
		enemy_frame.get_node("Base/Portrait").texture = current_target.portrait
		var e_hp_val = (current_target.health / current_target.max_health) * 100.0
		enemy_frame.get_node("Base/HealthBar").value = e_hp_val
	
	# Set the process by which the camera will shake 
	camera_shake_process(0.8)
	
	# Initiate basic attack
	if Input.is_action_just_pressed("ui_attack") and (!in_lag):
		if Input.is_action_pressed("ui_up"):
			use_equipped_attack("up")
	
	if Input.is_action_just_pressed("ui_attack") and (!in_lag):
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
			use_equipped_attack("forward")
	
	if Input.is_action_just_pressed("ui_attack") and (!in_lag) and !is_on_floor():
		if (
			!Input.is_action_pressed("ui_up") and 
			!Input.is_action_pressed("ui_down") and 
			!Input.is_action_pressed("ui_right") and 
			!Input.is_action_pressed("ui_left")
		):
			use_equipped_attack("neutral_aerial")
	
	if Input.is_action_just_pressed("ui_attack") and (!in_lag) and is_on_floor():
		if (
			!Input.is_action_pressed("ui_up") and 
			!Input.is_action_pressed("ui_down") and 
			!Input.is_action_pressed("ui_right") and 
			!Input.is_action_pressed("ui_left")
		):
			use_equipped_attack("neutral_grounded")
	
	if Input.is_action_just_pressed("ui_special") and (!in_lag):
			use_equipped_attack("special")
	
	# Initiate fiend attack
	if Input.is_action_just_pressed("ui_fiend_attack") and (!my_fiend.in_lag):
		my_fiend.attack()


func use_equipped_attack(var direction = ""):
	# Consolidate these
	match direction:
		"up":
			$Sprite.play("AtkBasicUtilt")
			
			basic_atk_inst = G.attack_basic_utilt.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything
			in_lag = true
			lag_time = basic_atk_inst.lag
		
		"neutral_aerial":
			print("neutral_aerial")
			$Sprite.play("AtkBasicSpin")
			
			basic_atk_inst = G.attack_basic_spin.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything
			in_lag = true
			lag_time = basic_atk_inst.lag
		
		"neutral_grounded":
			print("neutral_grounded")
			$Sprite.play("AtkGround")
			
			basic_atk_inst = G.attack_basic_grounded.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything
			in_lag = true
			lag_time = basic_atk_inst.lag
		
		"forward":
			$Sprite.play("AtkBasicPunch")

			basic_atk_inst = G.attack_basic_punch.instance()
			add_child(basic_atk_inst)
			
			# Levitation used in motion.y += section in _physics_process
			if basic_atk_inst.properties["Levitation"] > 1:
				levitation = basic_atk_inst.properties["Levitation"]
			
			# in_lag is when the player cannot do anything
			in_lag = true
			lag_time = basic_atk_inst.lag
			
		"special":
			if super_meter_value >= 25:
				$Sprite.play("AtkBasicPunch") # Inventory Attribute
				
				basic_atk_inst = G.attack_special_fireball.instance() # Inventory Attribute
				# Detached attacks are ones which the player can move after firing.
				# The time before firing is the charge_time, which is based on the move's 
				if basic_atk_inst.properties["Detached"]:
					# Hopefully this property loads by this time
					var atk_sprite = basic_atk_inst.get_node("Sprite")
					atk_sprite.charge_time = basic_atk_inst.properties["Move_Wait_Time"]
					atk_sprite.special = true
					atk_sprite.charge_sprite = "AttackSpecialCharging" 
					atk_sprite.fire_sprite = "AttackSpecialFireball"
					get_parent().add_child(basic_atk_inst)
					basic_atk_inst.global_position = global_position
				else:
					add_child(basic_atk_inst)
				
				# Levitation used in motion.y += section in _physics_process
				if basic_atk_inst.properties["Levitation"] > 1: # Inventory Attribute
					levitation = basic_atk_inst.properties["Levitation"] # Inventory Attribute
				
				# in_lag is when the player cannot do anything
				in_lag = true
				lag_time = basic_atk_inst.lag # Inventory Attribute
				
				update_meter(super_meter_value - 25) # Inventory Attribute?
			
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


func initiate_jump():
	if is_on_floor():
		$Sprite.play("Jump")
		motion.y = -JUMP_FORCE
	elif (jumps > 0):
		$Sprite.play("Jump")
		jumps -= 1
		motion.y = -JUMP_FORCE
		
		# Jump ring effect
		var effect_inst = G.effect_sprite.instance()
		effect_inst.anim = "JumpRing"
		get_parent().add_child(effect_inst)
		effect_inst.global_position = global_position


func update_meter(to):
	var tw_super = Tweening.tween_to(self, "super_meter_value", to, 0.2)
	tw_super.easing = Tween.EASE_IN_OUT
	tw_super.trans = Tween.TRANS_ELASTIC


# Timer timeouts
func on_dash_timeout_complete():
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
	debug_label_0.text = "target: " + str(current_target)
	if current_target != null:
		debug_label_1.text = "count: " + str(current_target.combo_count)
	
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
