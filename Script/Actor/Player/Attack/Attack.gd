extends Area2D

# Instructions: 
# INHERITED BY: Giant AttacksData Master Node2D with children
#	INHERITED BY: [AttacksOwner] named Fiend or Player 
#			(in which the fiend can have the data the says whether or not it can learn this attack)
#		INHERITED BY: [AttacksType] named the Attack's Type
#
# Note: What I'm thinking is this could've been a function if there weren't so many properties,
# But also I'm integrating the use of the Inspector
#
# V = Visible; N = iNvisible
# Make a node with data such as: 
# These will be defined by placement/editor things:
#	export var coordinate_data = Vector2()
#	export (PackedScene) var hitbox_data
#	export (PackedScene) var animation # (Always playing (cc button or whatever))
#
#V	Attack's user (Player, Fiend)


var moving = false
var move_time = 0


export var user = {
	"Player" : false,
	"Fiend" : false,
	"Enemy" : false
}

#V	Attack's Control (Where it can be mapped: Up, Forward, Down, Moon Up Forward Down)
export var control = {
	"Up" : false, # X/Square
	"Forward" : false, # X/Square
	"Down" : false, # X/Square
	"Neutral" : false, # X/Square
	"Special" : false, # B/Circle
	"Super" : false, # L2 + R2
	"Null" : false, # For enemies?
}

#V	Attack's Type (Starter, Filler, Ender, Special, Ultra)
export var type = {
	"Starter" : false, 
	"Filler" : false, 
	"Ender" : false, 
	"Special" : false, 
	"Super" : false
}
#N	Attack's Hitstop

# These properties are separate since they won't be upgraded in any way
export var hitstop = 0.0
#N	Attack's Hitstun
export var hitstun = 0.0

#N	Attack's overall time before user is actionable
export var lag = 0.0

export var motion = Vector2(0, 0)

#V	Attack's Property (Can have a mix of them?? Effect magnitude/effect level):
export var properties = {
	"Force" : 0, # General knockback power
	"Strength" : 0, # General attack power
	"Levitation" : 0, # Amount of levitation granted
	"Imbued Beast" : 0, # Amount of beast power in the attack
	"Curse Seal" : 0, # Uhhhhhh Curse
	"Base_Meter_Gain" : 0, # Meter gain before combo squish
	"Facing" : false, # Motion of enemy to be determined by flip_h of sprite
	"Detached" : false, # Projectile property
	"Move_Wait_Time" : 0,
	"Destroy_On_Hit" : false,
}

#N	Attack's Direction (with magnitude of property["Force"])
export var force = Vector2(0, 0)
#	
#	Note: These can all be exports of a node that you can save in the inspector,
#	but you also need to instantiate them in the global script
#	Note: How can you call nodes' signals without having them setup

#	All this will be filled out, attached to a node in AttackData, and the
#	player will create each individual attack scene, modified by their own stats/buffs
#	Enemy will react in their internal sandbag, taking data from the area (filled out
#	in this inspector) to affect them differently


func _ready():
	# Play sprite
	$Sprite.playing = true
	# Apply a force magnitude to the exported force
	force *= properties["Force"]
	# Convert to a frame value
	hitstop /= 60
	print(properties)
	# Set move time
	if properties["Detached"]:
		move_time = properties["Move_Wait_Time"]
	# Set facing vector
	if properties["Facing"] and user["Player"]:
		if G.player.get_node("Sprite").flip_h:
			print("flipping")
			motion *= -1


func _process(delta):
	if !G.player.stop:
		$Sprite.speed_scale = 1.0
		$Anim.playback_speed = 1.0
	else:
		$Sprite.speed_scale = 0
		$Anim.playback_speed = 0


func _physics_process(delta):
	if move_time <= 0:
		moving = true
	else:
		moving = false
		move_time -= 1
	
	if moving:
		position += motion
	elif properties["Detached"]:
		position = G.player.global_position

# Extend this to destroy on contact with tile + breakable stuff
func on_hit():
	if properties["Destroy_On_Hit"]:
		kill()


func _on_Anim_animation_finished(anim_name):
	if !properties["Destroy_On_Hit"]:
		kill()


func kill():
	queue_free()
	if user["Player"] and !user["Fiend"] and !user["Enemy"] and !properties["Detached"]:
		G.player.levitation = 1
		G.player.basic_atk_inst = null
