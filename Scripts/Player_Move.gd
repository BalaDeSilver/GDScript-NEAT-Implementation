extends "Actor_Move.gd"
#This script moves the player in the same fashion that the Agents move

#The player movement stats
export var Acceleration = 5000
export var Top_Speed = 200
export var Jump_Speed = 600
export var Max_Jump_Time = 0.1
export var Run_Speed = 2

#Replaces the base stats with the stats set on this script
func _ready():
	acceleration = Acceleration
	top_speed = Top_Speed
	jump_speed = Jump_Speed
	MAX_JUMP_TIME = Max_Jump_Time
	run_speed = Run_Speed

#The same thing as the NEAT_Example_Agent script
func apply_force(state):
	if(Input.is_action_pressed("gp_run")): #But it uses inputs instead of a NN
		run_mult = Run_Speed
	else:
		run_mult = 1

	if(Input.is_action_pressed("ui_left")):
		directional_force += DIRECTION.LEFT * run_mult
	
	if(Input.is_action_pressed("ui_right")):
		directional_force += DIRECTION.RIGHT * run_mult
	
	if(Input.is_action_pressed("ui_select") && jump_time < MAX_JUMP_TIME && can_jump):
		directional_force += DIRECTION.UP
		jump_time += state.get_step()
	elif(Input.is_action_just_released("ui_select")):
		can_jump = false
	
	if(grounded):
		can_jump = true
		jump_time = 0
	
	Globals.Current_Position = position

func _on_Ground_Check_body_entered(body):
	var groups = body.get_groups()
	if(!groups.has("Player")):
		grounded = true
func _on_Ground_Check_body_exited(body):
	var groups = body.get_groups()
	if(!groups.has("Player")):
		grounded = false

#Variables that I'll use when I move on with this project
# warning-ignore:unused_argument
func _on_Ceiling_Check_body_entered(body):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_Ceiling_Check_body_exited(body):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_LeftWall_Check_body_entered(body):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_LeftWall_Check_body_exited(body):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_RightWall_Check_body_entered(body):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_RightWall_Check_body_exited(body):
	pass # Replace with function body.
