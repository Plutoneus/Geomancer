extends Node

# Put a bunch of fucking palettes here

# Put a bunch of fucking attacks here, USE LOOPS

var player = null
var pick = null
var previous_number = ""
var hit_mult = 0

var attack_basic_utilt = load("res://Scene/Actor/Player/Attack/Starter/AttackBasicUtilt.tscn")
var attack_basic_spin = load("res://Scene/Actor/Player/Attack/Starter/AttackBasicSpin.tscn")
var attack_basic_punch = load("res://Scene/Actor/Player/Attack/Starter/AttackBasicPunch.tscn")


var attack_fiend_bat = load("res://Scene/Actor/Fiend/Bat/AttackFiendBat.tscn")

# Deprecate this
#var attack_basic_utilt = load("res://Scene/Actor/Player/Attack/AttackBasicUtilt.tscn")
var attack_basic_multijab = load("res://Scene/Actor/Player/Attack/AttackBasicMultiJab.tscn")
var attack_special_inward_spike = load("res://Scene/Actor/Player/Attack/AttackSpecialInwardSpike.tscn")
var effect_sprite = load("res://Scene/Effect/EffectSprite.tscn")

var shake_magnitude = 0
var shake = false

var ghost_scene = load("res://Scene/Effect/Ghost.tscn")
var numbers_scene = load("res://Scene/Effect/Numbers.tscn")

var null_clear = false


func _ready():
	pass


func _process(delta):
	if Input.is_action_just_pressed("ui_reset"):
		get_tree().reload_current_scene()

# -------------------------- Global functions ----------------------

# The function requires a caller, which will be assigned the timer object variable anyway
func timer_create(var caller, var timer_name, var time, var prefix):
	timer_name = Timer.new()
	timer_name.set_one_shot(true)
	timer_name.set_wait_time(time)
	timer_name.connect("timeout", caller, "on_%s_timeout_complete" % prefix)
	timer_name.pause_mode = PAUSE_MODE_STOP
	add_child(timer_name)
	return timer_name


func screen_shake(var mag):
	var mags = [-mag, mag]
	shake_magnitude = mags[randi() % 2]
	shake = true


func set_font(font):
	font.font_data.antialiased = false
	font.use_filter = true
	font.use_filter = false
