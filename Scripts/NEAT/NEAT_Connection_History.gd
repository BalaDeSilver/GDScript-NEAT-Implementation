extends Node

var from_Node
var to_Node
var innovation_Number

var innovation_Numbers = [] #The innovation numbers from the connections of the genome which first had this mutation
#This represents the genome and allows us to test if another genome is the same
#This is before this connection was added

#Constructor
func _init(from : int, to : int, inno : int, innonos : Array):
	#This is never freed from memory throughout the running of the program, so no need to make the references weak
	from_Node = from
	to_Node = to
	innovation_Number = inno
	innovation_Numbers = innonos

#Returns weter the genome matches the original genome and the connection is between the same nodes
func Matches(genome, from, to):
	if (genome.genes.size() == innovation_Numbers.size()): #If the number of connections is different, then the genomes aren't the same
		if (from.number == from_Node and to.number == to_Node):
			#Next, check if all the innovation numbers match from the genome
			for x in genome.genes:
				if (!innovation_Numbers.has(x.innovation_Number)):
					return false
			#If it reached this far, then the innovation numbers match the genes' innovation numbers and the connection is between the same nodes
			#Therefore, it matches
			return true
	return false