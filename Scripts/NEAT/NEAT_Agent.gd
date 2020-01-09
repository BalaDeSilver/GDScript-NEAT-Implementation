#Can extend any script that moves a character on the screen
#In fact, can extend Node, but this eases the movement for the agents
extends "../Actor_Move.gd"

#Actor_Move variables, change this as it suit your needs
export var Acceleration = 10000
export var Top_Speed = 200
export var Jump_Speed = 600
export var Max_Jump_Time = 0.1
export var Run_Speed = 2

# warning-ignore:unused_class_variable
var ID #ID is for debugging and printing
const decision_threshold = 0.8

var fitness
var brain
var vision = [] #The input array to be fed into the NN
var decision = [] #The output of the NN
# warning-ignore:unused_class_variable
var unadjusted_Fitness
# warning-ignore:unused_class_variable
var lifespan = 0 #How long the player lived for fitness
# warning-ignore:unused_class_variable
var best_Score = 0
var dead #This is the variable that tells an agent finished its objective
# warning-ignore:unused_class_variable
var gen = 0
var score = 0

var genome_Inputs = 2 #The size of the input array
var genome_Outputs = 4 #The size of the output array

#Constructor
func _init(inputs, outputs, clone):
	#Setting inputs and outputs via the constructor to ease handling for the programmer
	genome_Inputs = inputs
	genome_Outputs = outputs
	if(!clone): #Clones and childs shouldn't generate a brain to ease on memory handling
		brain = Globals.Brain.new(genome_Inputs, genome_Outputs, false)
		self.add_child(brain)
	decision.resize(genome_Outputs)
	for x in decision:
		x = 0 #Fills in the output array with values so we can use the += operator
	vision.resize(genome_Inputs)

#Called right after entering the scene tree
func _ready():
	#These variables are only relevant when inside the tree
	acceleration = Acceleration
	top_speed = Top_Speed
	jump_speed = Jump_Speed
	MAX_JUMP_TIME = Max_Jump_Time
	run_speed = Run_Speed

#Returns a clone of this agent
func Clone():
	var clone = Globals.Agent.new(genome_Inputs, genome_Outputs, true)
	clone.brain = brain.Clone()
	clone.add_child(clone.brain)
	clone.fitness = fitness
	clone.brain.Generate_Network()
	return clone

#Virtual function to update the input array
# warning-ignore:unused_argument
func Look():
	pass

#Virtual function to apply the decision, if it doesn't extend a movement script
#Call this inside Update()
# warning-ignore:unused_argument
func Move():
	pass

#Virtual function to determine which agent is better
#By default, fitness equals the score, but this is a virtual function, you are supposed to change it to fit your needs
func Calculate_Fitness():
	fitness = score

#Converts the input of the NN into an output
#Use _integrate_forces, Move() or _physics_process in order to apply the movement in a more stable fashion
# warning-ignore:unused_argument
func Think():
	if(!dead):
		decision = brain.Feed_Forward(vision)
	else:
		for i in decision:
			i = 0

#Virtual function in charge of updating score and any UI related to the NN
# warning-ignore:unused_argument
func Update():
	pass

#Generates a child with a respectful and consensual mating
func Crossover(var player2):
	var child = Globals.Agent.new(genome_Inputs, genome_Outputs, true)
	child.brain = brain.Crossover(player2.brain)
	child.add_child(child.brain)
	child.brain.Generate_Network()
	return child