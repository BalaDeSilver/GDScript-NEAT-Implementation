extends Node

var pop = []
# warning-ignore:unused_class_variable
var best_Agent #The best ever agent
var best_Score : float = 0 #The score of said player
var gen = 0
var innovation_History = []
# warning-ignore:unused_class_variable
var gen_Players = []
var species = []

#Foreshadowing
#var Threads = []
#var mutex = Mutex.new()
#var thread_size = 32

var MASS_EXTINCTION = false

#Constructor
func _init(size):
	for i in range(size):
		pop.append(Globals.Agent.new(4, 4, false)) #Call in new agents with 4 inputs and 4 outputs
		pop[i].brain.Generate_Network()
		pop[i].brain.Mutate(innovation_History)
		add_child(pop[i])

#Every frame, update the alive agents
# warning-ignore:unused_argument
func _process(delta):
	Update_Alive()

#Update all the players who are still alive
func Update_Alive():
	if(!Done()): #If someone is still alive
		for x in pop:
			x.Look() #Get inputs for brain
			x.Think() #Use outputs from NN
			x.Update() #Update the data on the agent
	else:
		Natural_Selection()

#Returns true if all agents are dead
#What have we done...
func Done():
	for x in pop:
		if(!x.dead):
			return false
	return true

#Sets best agent globally and for this gen
func Set_Best_Agent():
	var temp_Best = species[0].actors[0]
	temp_Best.gen = gen
	#If best this gen is better than global best, the set the global best as the bestest best
	if (temp_Best.fitness > best_Score):
		gen_Players.append(temp_Best.Clone())
		#print("Old best: " + best_Score)
		#print("New best: " + temp_Best.score)
		best_Score = temp_Best.fitness
		best_Agent = temp_Best.Clone()

#Separates the population into species based on how similar they are to the leaders of each species in the previous gen
#In contrast with us humans, robots are not racist
func Speciate():
	for s in species: #Empty species
		s.actors.clear()
	
	for x in pop: #For each agent
		var species_Found = false
		for s in species: #For each species
			if (s.Same_Species(x.brain)): #If the player is similar enough to be considered being the same species
				s.Add_To_Species(x) #Add it to the club
				species_Found = true
				break
		if (!species_Found): #If no species was similar enough, then add a new species with this as its champion
			#Maybe they're a little racist...
			species.append(Globals.Species.new(x))

#Calculate the fitness of all the agents
func Calculate_Fitness():
	for x in pop:
		x.Calculate_Fitness()

#Sorts the agents within a species and the species by their fitnesses
#Only the stronk may live
func Sort_Species():
	#Sort the players within all species
	for s in species:
		s.Sort_Species()
	
	#Sort the species by the fitness of its best player
	#Selection sort gang
	#Not knowing how to do Quick sort, but being better than Bubble gang
	var temp = []
	for x in species:
		var maximum = 0
		var max_Index = 0
		for y in range(species.size()):
			if (species[y].best_Fitness > maximum):
				maximum = species[y].best_Fitness
				max_Index = y
		
		temp.append(species[max_Index])
		species.remove(max_Index)
		
	species = temp

#Murders all species which haven't improved in 15 generations
func Kill_Stale_Species():
	var i = 0
	while(i < species.size()): #Fun fact: GDScript doesn't have a proper for implementation, it rather uses the foreach implementation on the for statement
		if(species[i].staleness >= 15):
			Globals.dump.append(species[i])
			species.remove(i) #F
			i -= 1
		i += 1

#Returns the sum of each species average fitness
func Get_Avg_Fitness_Sum():
	var average_Sum = 0
	for s in species:
		average_Sum += s.average_Fitness
	return average_Sum

#Disallows a child for the species that suck too much, then kills them
func Kill_Bad_Species():
	var i = 0
	var average_Sum = Get_Avg_Fitness_Sum()
	while i < species.size():
		if (species[i].average_Fitness / average_Sum * pop.size() < 1): #No child for u
			Globals.dump.append(species[i])
			species.remove(i) #F
			i -= 1
		i += 1

#Kills the bottom half of each species
func Cull_Species():
	for s in species:
		s.Cull() #Kill bottom half
		s.Fitness_Sharing() #Also, while we're at it, let's share our fitnesses, comrades
		s.Set_Average() #Resets averages, because they changed

#If you're feeling sadistic, kill all species, but 5 of them
#Implement this as you wish
func Mass_Extinction():
	# warning-ignore:unused_variable
	for x in range(5, species.size()):
		Globals.dump.append(species[5])
		species.remove(5)
	print("You monster...")

#This function is called when all the agents are ded and a new generation should be generated
# warning-ignore:unused_argument
func Natural_Selection():
	Speciate() #Separate the population into species
	Calculate_Fitness() #Calculate the fitness of each agent and their species
	Sort_Species() #Separate the good from the bad
	if(MASS_EXTINCTION): #If they all succ
		Mass_Extinction() #F
		MASS_EXTINCTION = false
	Cull_Species() #Get rid of the bottom half of each species
	Set_Best_Agent() #Save the best player of this gen, because we cannot save ourselves
	Kill_Stale_Species() #Remove species which haven't improved in a while
	Kill_Bad_Species() #Kill the species which are so bad that they can't even reproduce. Imagine that...
	
	var average_Sum = Get_Avg_Fitness_Sum()
	var children = [] #The Next Generation ®
	
	for x in species: #For each species
		children.append(x.champ.Clone()) #Add champion without any mutation
		var No_Of_Children = floor(x.average_Fitness / average_Sum * pop.size()) - 1 #The number of children this species is allowed -1 because the champion goes in regardless. What a chad
		# warning-ignore:unused_variable
		for y in range(No_Of_Children): #Get the calculated amount of children from this species
			children.append(x.Give_Bebe(innovation_History))
	
	while(children.size() < pop.size()): #If not enough babies, due to the flooring of the number for a whole int
		children.append(species[0].Give_Bebe(innovation_History)) #Get baby from the absolute chad leading the species
	
	for p in pop:
		Globals.dump.append(p) #Remember to manage your memory, kids
		p.get_parent().remove_child(p) #It pays off
	
	pop = children #Set the children as the current population
	gen += 1
	
	for y in pop:
		self.add_child(y)
		y.brain.Generate_Network() #Generate the network for each of teh children
	
	Globals.Dump()#Removes everything that's not in use from the memory
	
	#Reminder: add an option to opt out of the verbose
	print("Generation: ", gen, "; Number of mutations: ", innovation_History.size(), "; Species: ", species.size(), "; ", Globals.count, " agents made it to the target.")
	