#Extending the Agent, so we can modify it without losing the base script
extends "NEAT/NEAT_Agent.gd"

#Variables specific to this implementation of the agents
var scene
var body
var self_pos = Vector2()
var target_pos = Vector2()
var target_vector = Vector2()
var starting_point = Vector2()
var Ground_Check
var text
var touched = false

#Godot requires you to write the init like this, so it pulls the init from the base class
func _init(inputs, outputs, clone).(inputs, outputs, clone):
	pass

#When ready to go, do your thing
#Adding the scene and children requires being on the scene tree, so this can't be done on init
func _ready():
	scene = Globals.NEAT_Body.instance() #The scene containing a body for the AI
	body = scene.get_node("Body") #The rigidbody2d that this agent will move
	body.connect("integrate_forces", self, "_integrate_forces") #Connecting a custom signal, check the AI script on the Scenes folder
	
	self.add_child(scene) #Adding the scene to the tree, so we can use the get_node function
	
	text = get_node("NEAT/Body/Sprite/Text") #The text you see on each agent
	text.set_bbcode("[center][b]" + str(ID) + "[/b][/center]")
	
	#Creating the checker that tells the Actor_Move script wether the agent is on the ground and can jump or not
	Ground_Check = get_node("NEAT/Body/Ground_Check")
	Ground_Check.connect("body_entered", self, "_on_Ground_Check_body_entered")
	Ground_Check.connect("body_exited", self, "_on_Ground_Check_body_exited")
	
	#Looking now to reset the array, since it looks for a couple of frames before being ready
	#Look()

#Transforms the decision array into actual movement
#See Actor_Move to know what calls this
#[0] = Run
#[1] = Go left
#[2] = Go right
#[3] = Jump
func apply_force(state):
	if(decision[0] != null): #Failsafe because the array wasn't always populated when I was debugging
		if(decision[0] > decision_threshold): #If it decided to run
			run_mult = Run_Speed #Run.
		else: #If it decided not to run
			run_mult = 1 #Don't run
	
		if(decision[1] > decision_threshold): #If it decided to go left
			directional_force += DIRECTION.LEFT * run_mult
		
		if(decision[2] > decision_threshold): #If it decided to go right
			directional_force += DIRECTION.RIGHT * run_mult
		
		if(decision[3] > decision_threshold && jump_time < MAX_JUMP_TIME && can_jump): #If it decided to jump and can jump
			directional_force += DIRECTION.UP
			jump_time += state.get_step() #It can jump for a while, making short hops and high jumps possible
		elif(decision[3] <= decision_threshold): #If it jumped and hasn't on the ground yet, it cannot jump again until it touches the ground
			can_jump = false
		
		if(grounded): #When it touches the ground, it can jump again
			can_jump = true
			jump_time = 0

#Overwrites the Look function to give it meaning
# warning-ignore:unused_argument
func Look():
	#I chose to let them see their position and the player position
	#This is just an example, I don't need to be optimal to exemplify how it works
	self_pos = body.global_position
	target_pos = Globals.Current_Position
	target_vector = target_pos - self_pos #I was using this as the vision, but I decided to change it and keep this as a debug variable
	vision[0] = target_pos.x
	vision[1] = target_pos.y
	vision[2] = self_pos.x
	vision[3] = self_pos.y

#Rewriting the fitness calculation, so it suits my needs
func Calculate_Fitness():
	#Since the score is just the sum of the distance every frame the agent is alive and we want the one who was the lower distance, dividing 1 by the distance gives the agent who stayed closer an exponentially increasing score
	fitness = 1000000 / score
	#I used to award some behaviors, decided to not do that but keep this as an example of how you could tali up a fitness
	#fitness += (starting_point - self_pos).length() * (starting_point - self_pos).length()
	
	if(touched and (target_pos - self_pos).length() > (target_pos - starting_point).length() / 2): #If the agent touched, but got away
		if (fitness > 0): #And its fitness is still positive (it could go negative in past iterations)
			fitness *= -1 #Punish that fucker and put it on the bottom of the list
			
	if(fitness > 0): #If this agent moved torwards the player
		#Reward it with its speed as a multiplier
		fitness *= ((target_pos - starting_point).length() - (target_pos - self_pos).length()) / (lifespan + 1)
	
	unadjusted_Fitness = fitness #Keep things tidy

#Rewriting the Think function because I want the agents to still move even after finishing its objective
# warning-ignore:unused_argument
func Think():
	var d = brain.Feed_Forward(vision)
	decision = d

#You get the point on rewriting functions
# warning-ignore:unused_argument
func Update():
	if(Globals.Timeout): #Mass murder once the Master times out, so we can breed another generation
		dead = true
		return
	
	if(touched and not grounded): #Penalizes jumping after touching the player
		score *= 0.75

	#We skip 1 second of time after spawning, so it has time to enter the tree and set its position
	if(target_vector.length() < 50 and not touched and Globals.NEAT_Timer.time_left < Globals.time - 1):
		Globals.count += 1
		touched = true
		dead = true
		lifespan = 60 - Globals.NEAT_Timer.time_left
	
	if(touched): #If it touched, we freeze the timer on the agent
		text.set_bbcode("[center][b]NEAT_" + str(ID) + "\n" + str(floor(lifespan)) + "s[/b][/center]")
	else: #If it didn't touched, the time ticks down
		text.set_bbcode("[center][b]NEAT_" + str(ID) + "\n" + str(floor(Globals.time - Globals.NEAT_Timer.time_left)) + "s[/b][/center]")
	
	#Adds up the score as a sum of the distance between the agent and the player every update
	score += target_vector.length()
	#Old score system, for example
	#if(!touched):
	#	score += ((target_pos - starting_point).length() - (target_pos - self_pos).length()) / 1000
	#elif(target_vector.length() < 50):
	#	score += ((target_pos - starting_point).length() - (target_pos - self_pos).length()) / 1000 * 2
	#else:
	#	if((target_pos - starting_point).length() > (target_pos - self_pos).length()):
	#		score += ((target_pos - starting_point).length() - (target_pos - self_pos).length()) / 1000 * 0.5
	#	else:
	#		score += ((target_pos - starting_point).length() - (target_pos - self_pos).length()) / 1000

#Checks if the agent is grounded or not, for the Actor_Move script to determine if the agent can jump or not
func _on_Ground_Check_body_entered(body_):
	var groups = body_.get_groups() #The checker is always touching the parent
	if(!groups.has("Enemy")):
		grounded = true
func _on_Ground_Check_body_exited(body_):
	var groups = body_.get_groups()
	if(!groups.has("Enemy")):
		grounded = false

#Variables that I'll use when I move on with this project
# warning-ignore:unused_argument
func _on_Ceiling_Check_body_entered(body_):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_Ceiling_Check_body_exited(body_):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_LeftWall_Check_body_entered(body_):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_LeftWall_Check_body_exited(body_):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_RightWall_Check_body_entered(body_):
	pass # Replace with function body.

# warning-ignore:unused_argument
func _on_RightWall_Check_body_exited(body_):
	pass # Replace with function body.