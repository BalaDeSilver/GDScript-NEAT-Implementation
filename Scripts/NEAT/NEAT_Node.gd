extends Node

var number : int
var input_Sum : float = 0.0 #Current sum i.e. before activation
var output_Value : float = 0.0 #After activation function is applied
var output_Connections = []
var layer = 0
const e = 2.71828182846 #Fun fact: Godot doesn't have a literal for the euler constant

#Constructor
func _init(no):
	number = no

#Returns a copy of this node
func Clone():
	var clone = Globals.NEAT_Node.new(number)
	clone.layer = layer
	return clone

#Resets the input for the next feed forward
func Reset_In():
	input_Sum = 0

#The superior sigmoid activation function
func Sigmoid(x):
	var y = 1 / (1 + pow(e, -4.9 * x))
	return y

#The node sens its output to the inputs of the nodes it's connected to
func Engage():
	if (layer != 0): #No sigmoid for inputs and bias
		output_Value = Sigmoid(input_Sum)
	
	for x in output_Connections: #For each connection
		if (x.get_ref().enabled): #Dont do shit if not enabled
			x.get_ref().to_Node.get_ref().input_Sum += x.get_ref().weight * output_Value #Add the weighted output to the sum of the inputs of whatever node this node is connected to

#Returns wether this node is connected to the parameter node
#Used when adding a new connection
func Is_Connected_To(node):
	if (node.layer == layer): #Nodes in the same layer cannot be connected
		return false
	
	#You get it
	if (node.layer < layer):
		for x in node.output_Connections:
			if(x.get_ref().to_Node.get_ref() == self):
				return true
	else:
		for x in output_Connections:
			if(x.get_ref().to_Node.get_ref() == node):
				return true
	
	return false
	