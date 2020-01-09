extends RigidBody2D

#Variables to use in movement
var acceleration = 10000
var top_speed = 200
var jump_speed = 400
# warning-ignore:unused_class_variable
var MAX_JUMP_TIME = 0.1
# warning-ignore:unused_class_variable
var run_speed = 2
# warning-ignore:unused_class_variable
var run_mult = 1

var grounded = false
# warning-ignore:unused_class_variable
var can_jump = false
# warning-ignore:unused_class_variable
var jump_time = 0

var directional_force = Vector2()
const DIRECTION = { #The 4 possible directions and 0
	ZERO = Vector2(0, 0),
	LEFT = Vector2(-1, 0),
	RIGHT = Vector2(1, 0),
	UP = Vector2(0, -1),
	DOWN = Vector2(0, 1)
}

#
func _integrate_forces(state):
	var final_force = Vector2()
	directional_force = DIRECTION.ZERO
	
	#Gets the force applied from an AI or the player
	apply_force(state)
	
	#Modifying the force to apply it
	final_force = state.get_linear_velocity() + (directional_force * acceleration)
	
	#Clamping the force to be applied, so it respects the max speed
	final_force.x = clamp(final_force.x, -top_speed * run_mult, top_speed * run_mult)
	final_force.y = clamp(final_force.y, -jump_speed, jump_speed)
	
	#Applies the force
	state.linear_velocity = final_force

# warning-ignore:unused_argument
func apply_force(state): #Virtual function, use extended method
	pass