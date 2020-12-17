extends Node
class_name Walker

const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

var position = Vector2.ZERO
var direction = Vector2.RIGHT
var borders = Rect2()
var step_history = []
var steps_since_turn = 0

func _init(starting_position, new_borders):
	assert(new_borders.has_point(starting_position))
	position = starting_position
	step_history.append(position)
	borders = new_borders

func walk(steps):
	for step in steps:
		# Never have a hallway more than x steps
		if randf() <= 0.25 or steps_since_turn >= 4:
			change_direction()
		
		if step():
			step_history.append(position)
		else:
			change_direction()
	return step_history
	
func step():
	var target_position = position + direction
	if borders.has_point(target_position):
		steps_since_turn += 1
		position = target_position
		# Okay we were able to take a step
		return true
	else:
		# Can't go outside border
		return false
		
func change_direction():
	steps_since_turn = 0
	# Duplicate the constant
	var directions = DIRECTIONS.duplicate()
	# Removes current direction from list of all possible directions, 
	# so we never go in the same direction we're going in
	directions.erase(direction)
	# Shuffle and grabs first dir in list after 
	directions.shuffle()
	direction = directions.pop_front()
	# Can we move in that direction?
	while not borders.has_point(position + direction):
		# Pick the next direction
		direction = directions.pop_front()

func create_room(position):
	# Random int between 4 and 2
	var size = Vector2(randi() % 4 + 2, randi() % 4 + 2)
	var top_left_corner = (position - size/2).ceil()
	
