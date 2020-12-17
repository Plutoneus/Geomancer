extends Node2D

var borders = Rect2(1, 1, 38, 21)
var steps = 500

func _ready():
	randomize()
	generate_level()

func generate_level():
	var walker = Walker.new(Vector2(19, 11), borders)
	# Walk for 500 steps
	var map = walker.walk(steps)
	walker.queue_free()
	for location in map:
		# Sets tile based on vector (location), erases tile (-1)
		$TileMap.set_cellv(location, -1)
	# Start and end
	$TileMap.update_bitmask_region(borders.position, borders.end)
