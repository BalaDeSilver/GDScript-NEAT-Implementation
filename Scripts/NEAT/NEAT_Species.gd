extends Node

var actors = []
var best_Fitness = 0
var champ
var average_Fitness = 0
var staleness = 0 #How many generations have the species gone without improvements
var rep

#Coefficients for testing compatibility
const excess_Coeff = 1.5
const weight_Diff_Coeff = 1
const compatibility_Threshold = 1.3

#Constructor
func _init(p):
	actors.append(p)
	best_Fitness = p.fitness
	#Since this is the only player on the species, it is also the champion
	rep = p.brain.Clone()
	self.add_child(rep)
	champ = p.Clone()
	self.add_child(champ)

#Returns the number of excess and disjoint genes between 2 input genomes
#i.e. returns the amount of genes that don't match
func Get_Excess_Disjoint(var brain1, var brain2):
	var matching = 0.0
	for x in brain1.genes:
		for y in brain2.genes:
			if(x.innovation_Number == y.innovation_Number):
				matching += 1
				break
	return (brain1.genes.size() + brain2.genes.size() - 2 * (matching))

#Returns the average weight difference between matching genes in the input genomes
func Average_Weight_Diff(var brain1, var brain2):
	if (brain1.genes.size() == 0 or brain2.genes.size() == 0):
		return 0
	
	var matching = 0
	var total_Diff = 0
	for x in brain1.genes:
		for y in brain2.genes:
			if(x.innovation_Number == y.innovation_Number):
				matching += 1
				total_Diff += abs(x.weight - y.weight)
				break
	
	if (matching == 0): #Divide by 0 error
		return 100
	
	return total_Diff / matching

#Returns wether or not the parameter genome is in this species
func Same_Species(var g):
	var compatibility
	var excess_And_Disjoint = Get_Excess_Disjoint(g, rep) #Gets the number of excess and disjoint genes between an agent and the current species rep
	var average_Weight_Diff = Average_Weight_Diff(g, rep) #Gets the average weight difference between matching genes
	
	var large_Genome_Normalizer = 1 #* g.genes.size() - 20
	if (large_Genome_Normalizer < 1):
		large_Genome_Normalizer = 1
	
	compatibility = (excess_Coeff * excess_And_Disjoint / large_Genome_Normalizer) + (weight_Diff_Coeff * average_Weight_Diff) #Compatibility formula
	return (compatibility_Threshold > compatibility)

#Add an agent to the cool kids club
func Add_To_Species(var p):
	actors.append(p)

#Sorts the species by fitness
func Sort_Species():
	#If the species is empty, it gets marked for deletion
	#Debugging is hard, don't blame me
	if (actors.size() == 0):
		staleness = 200
		return
	
	var temp = []
	
	#Selection sort gang
	for i in actors:
		var maximum = 0
		var max_Index = 0
		for y in range(actors.size()):
			if (actors[y].fitness > maximum):
				maximum = actors[y].fitness
				max_Index = y
		
		temp.append(actors[max_Index])
		actors.remove(max_Index)
	
	actors = temp
	
	if(best_Fitness == null):
		best_Fitness = actors[0].fitness
	
	#If new best player
	if (actors[0].fitness > best_Fitness):
		staleness = 0
		best_Fitness = actors[0].fitness
		rep.free()
		champ.free()
		rep = actors[0].brain.Clone()
		champ = actors[0].Clone()
	else: #If no new best player
		staleness += 1

#Simple stuff
func Set_Average():
	var sum = 0
	for x in actors:
		sum += x.fitness
	if(actors.size() != 0):
		average_Fitness = sum / actors.size()

#Select an agent based on its fitness
func Select_Agent():
	var fitness_Sum = 0
	for x in actors:
		fitness_Sum += x.fitness
	
	var rand = Globals.RNG.randf_range(0, fitness_Sum)
	var running_Sum = 0
	
	for x in actors:
		running_Sum += x.fitness
		if(running_Sum > rand):
			return x
	
	#This was here for the Java parser, but I feel like it eases debug
	#You know, if we screw up, there's a backup plan
	return actors[0]

#Gets a well planned baby from the agents in this species
func Give_Bebe(var innovation_History):
	var bebe
	if (Globals.RNG.randf() < 0.25): #25% of the time, there is no crossover and the bebe is just a clone of a random player
		bebe = Select_Agent().Clone()
	else: #75% of the time, there is crossover
		#Grab 2 random parents
		var parent1 = Select_Agent()
		var parent2 = Select_Agent()
		
		#The crossover function expects the highest fitness parent to be the object instance and the lowest as the argument
		if (parent1.fitness < parent2.fitness):
			bebe = parent2.Crossover(parent1)
		else:
			bebe = parent1.Crossover(parent2)
	
	bebe.brain.Mutate(innovation_History) #Mutating the baby brain seems like a good idea that always goes well. Foolproof.
	return bebe

#Thanos snap the species, leaving only the best ones alive
func Cull():
	if (actors.size() > 2):
		var x = ceil(actors.size() / 2)
		while x < actors.size():
			Globals.dump.append(actors[x])
			actors.remove(x)

#I serve the Soviet Union
func Fitness_Sharing():
	for x in actors:
		x.fitness /= actors.size()