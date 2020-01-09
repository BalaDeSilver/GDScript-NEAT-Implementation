extends Node2D

#The number of agents to be spawned
const SPAWN_NUMBER = 128 #-------------------------------------------------------
# warning-ignore:unused_class_variable
var NEAT_next_connection_no : int = 1000 #The next connection number the algorithm will make
# warning-ignore:unused_class_variable
var Current_Position = Vector2() #The position of the player
var NEAT_Pop #If you ever need to debug the population, this is the variable to look for in the inspector
#More than one population can exist at the same time, be creative!

#Oreloads every aspect of the 
# warning-ignore:unused_class_variable
var Agent = preload("NEAT_Example_Agent.gd")
var Pop = preload("NEAT_Example_Population.gd")
# warning-ignore:unused_class_variable
var Brain = preload("NEAT/NEAT_Genome.gd")
# warning-ignore:unused_class_variable
var NEAT_Body = preload("../Scenes/NEAT_Agent.tscn")
# warning-ignore:unused_class_variable
var NEAT_Node = preload("NEAT/NEAT_Node.gd")
# warning-ignore:unused_class_variable
var Connection = preload("NEAT/NEAT_Connection.gd")
# warning-ignore:unused_class_variable
var Connection_History = preload("NEAT/NEAT_Connection_History.gd")
# warning-ignore:unused_class_variable
var Species = preload("NEAT/NEAT_Species.gd")

var RNG = RandomNumberGenerator.new() #RNG stands for Realy Not Good
var NEAT_Timer = Timer.new() #The timer node
var Timeout = false #If it has timed out
var time = 60 #The time the actors have to reach the target
# warning-ignore:unused_class_variable
var count = 0 #How many actors got to the point

#The ranch. It's for stuff we don't need anymore and want to free from memory
var dump : Array = []

#The signal to the timer
func _on_Timer_timeout():
	Timeout = true

#Once entering the tree, kickstarts the process
func _ready():
	RNG.randomize() #Sets a random seed for the RNG
	NEAT_Timer.connect("timeout", self, "_on_Timer_timeout") #Links the timeout signal
	NEAT_Timer.set_one_shot(true) #It should only run once, then wait for the ok to run again
	add_child(NEAT_Timer) #The timer only works if it is inside the tree
	NEAT_Pop = Pop.new(SPAWN_NUMBER) #Spawns the agents
	self.add_child(NEAT_Pop) #Sets the child to make everyhing else possible
	NEAT_Timer.start(time) #Clock's ticking
	print("Loaded ", SPAWN_NUMBER, " agents.")

#Frees any resource sent to the dump
func Dump():
	while dump.size() > 0:
		if is_instance_valid(dump[0]): #I might have gotten overzealous and sent some stuff to the dump twice
			dump[0].free() #BEGONE
		dump.remove(0) #Cleans the array so it is nice and tidy