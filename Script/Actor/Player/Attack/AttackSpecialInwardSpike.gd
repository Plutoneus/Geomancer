extends Area2D

export var atk_damage = 100
export var atk_stun = 0.99
export var atk_motion = Vector2(-500, -250)
export var immo_time = 0.8
export var canc_time = 0.2 # deprecated

var contact_found = false

func _ready():
	if G.player.get_node("Sprite").flip_h:
		atk_motion = Vector2(500, -250)
	$Sprite.playing = true


func _process(delta):
	if !G.player.stop:
		$Sprite.speed_scale = 1.0
		$AnimationPlayer.playback_speed = 1.0
	else:
		$Sprite.speed_scale = 0
		$AnimationPlayer.playback_speed = 0


func _on_AnimationPlayer_animation_finished(anim_name):
	kill()


func kill():
	queue_free()
	G.null_clear = true


func _on_AttackBasicUtilt_body_entered(body):
	pass # Replace with function body.


func contact_found():
	contact_found = true
