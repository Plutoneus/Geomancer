extends Node2D

export var destination = Vector2()
var c_from = Color(0.964706, 0.964706, 0.74902)
var c_to = Color(0.792157, 0.396078, 0.494118)

var shrink_timer = null
var shrink_time = 0.8

var free_timer = null
var free_time = 0.6

var full_time = shrink_time + free_time

var damage = 0

var type = {
	"Normal" : false, # Normal moves (Light Yellow)
	"Special" : false, # Special hits (Blue)
	"Super" : false, # Super hits (Orange)
	"Fiend" : false # Fiend moves (Red)
}

func _ready():
	if type["Normal"]:
		c_from = Color(0.964706, 0.964706, 0.74902)
		c_to = Color(0.615686, 0.752941, 0.521569)
	elif type["Special"]:
		c_from = Color(0.552941, 0.737255, 0.823529)
		c_to = Color(0.223529, 0.831373, 0.72549)
	elif type["Super"]:
		c_from = Color(0.929412, 0.764706, 0.552941)
		c_to = Color(0.960784, 0.882353, 0.478431)
	elif type["Fiend"]:
		c_from = Color(0.792157, 0.396078, 0.494118)
		c_to = Color(0.47451, 0.278431, 0.396078)
	
	
	
	$Label.set("custom_colors/font_color", c_from)
	
#	if $Label.text == G.previous_number:
#		G.hit_mult += 1
#	else:
#		G.hit_mult = 0
#	G.previous_number = str(damage)
#	if G.hit_mult > 0:
#		$Label.text = str(damage) + "x" + str(G.hit_mult)
#	else:
	$Label.text = str(damage)
	
	# Modulate
	var tw_alpha = Tweening.tween_to($Label, "modulate", Color(1, 1, 1, 0), full_time)
	tw_alpha.easing = Tween.EASE_IN_OUT
	tw_alpha.trans = Tween.TRANS_LINEAR
	
	# Color
	var tw_color = Tweening.tween_to($Label, "custom_colors/font_color", c_to, full_time)
	tw_color.easing = Tween.EASE_OUT
	tw_color.trans = Tween.TRANS_QUAD
	
	# Scale up
	var tw_scale = Tweening.tween_to(self, "scale", Vector2(1, 1), .4)
	tw_scale.easing = Tween.EASE_IN_OUT
	tw_scale.trans = Tween.TRANS_ELASTIC
	
	shrink_timer = G.timer_create(self, shrink_timer, shrink_time, "shrink_timer")
	shrink_timer.start()
	
func _process(delta):
	position = lerp(position, destination, 0.2)


func on_shrink_timer_timeout_complete():
	# Scale down
	var tw_scale = Tweening.tween_to(self, "scale", Vector2(0, 0), .2)
	tw_scale.easing = Tween.EASE_IN_OUT
	tw_scale.trans = Tween.TRANS_SINE
	
	free_timer = G.timer_create(self, free_timer, free_time, "free_timer")
	free_timer.start()


func on_free_timer_timeout_complete():
	queue_free()
