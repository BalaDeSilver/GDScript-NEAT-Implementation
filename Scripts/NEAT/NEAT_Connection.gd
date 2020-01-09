extends Node

var from_Node : WeakRef
var to_Node : WeakRef
var weight
var enabled = true
var innovation_Number #Each connection is given an innovation number to compare genomes

#Constructor
func _init(from, to, w, inno):
	#The nodes must be stored in a weak reference to avoid a cyclic reference betheen nodes and connections, avoiding memory leaks
	from_Node = weakref(from)
	to_Node = weakref(to)
	weight = w
	innovation_Number = inno

#Mutates the weight
func Mutate_Weight():
	var rand2 = Globals.RNG.randf()
	if(rand2 < 0.1): #10% of the time, completely change the weight
		weight = Globals.RNG.randf_range(-1, 1)
	else: #Otherwise, just slightly change it
		weight += Globals.RNG.randfn() / 50
		#Keep them within acceptable bounds
		weight = clamp(weight, -1, 1)

#Returns a copy of this connection instance
func Clone(from, to):
	var clone = Globals.Connection.new(from, to, weight, innovation_Number)
	clone.enabled = enabled
	return clone