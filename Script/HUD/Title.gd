extends Control

var scene_test_world = "res://Scene/Zone/TestWorld0.tscn"


func _ready():
	pass


# Title screen button "Test Zone"
func _on_Test_pressed():
	# Change to the test scene
	get_tree().change_scene(scene_test_world)
