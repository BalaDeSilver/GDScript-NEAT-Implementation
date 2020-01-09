extends Node

var genes = [] #A list of references to connections, which represents the Neural Network
var nodes = []
var inputs
var outputs
var layers = 2
var next_Node = 0
var bias_Node
var outs
var network = [] #A list of the nodes in the order that they need to be considered in the NN

#Constructor
func _init(inp, out, clone):
	#Set imput and output numbers
	inputs = inp
	outputs = out
	
	if(!clone): #Clones don't get filled with data. Instead, they are given the data of their parent
		var local_Next_Connection_Number = 0
		#Create input nodes
		for x in range(inputs):
			nodes.append(Globals.NEAT_Node.new(x))
			next_Node += 1
			nodes[x].layer = 0
			#Adding as a child of the node eases the job while cleaning memory to avoid leaks
			self.add_child(nodes[x])
		#Create output nodes
		for x in range(outputs):
			nodes.append(Globals.NEAT_Node.new(x + inputs))
			next_Node += 1
			nodes[x + inputs].layer = 1
			self.add_child(nodes[x + inputs])
		
		nodes.append(Globals.NEAT_Node.new(next_Node)) #Bias node
		self.add_child(nodes[next_Node])
		bias_Node = next_Node
		next_Node += 1
		nodes[bias_Node].layer = 0
		
		#Connect inputs to all outputs 
		for i in range(inp):
			#Add the bare minimum amout of connections to the array with random weights and unique innovation numbers
			for j in range(outputs):
				genes.append(Globals.Connection.new(nodes[i], nodes[inputs + j], Globals.RNG.randf_range(-1, 1), local_Next_Connection_Number))
				#self.add_child(genes[i + j])
				local_Next_Connection_Number += 1
		#Connect the bias
		for i in range(outputs):
			genes.append(Globals.Connection.new(nodes[bias_Node], nodes[inputs + i], Globals.RNG.randf_range(-1, 1), local_Next_Connection_Number))
			#self.add_child(genes[i])
			local_Next_Connection_Number += 1
		#I lost track of how to add the genes as children of the agent as they are created, so I did this
		for i in genes:
			self.add_child(i)

#Returns the node with a matching number
#Sometimes, nodes will not be in order
func Get_Node(num):
	for i in nodes:
		if(i.number == num):
			return i
	return null

#Adds the connections' references between the nodes, so they can access each other during feed forward
func Connect_Nodes():
	for x in nodes:#Clear the connections
		x.output_Connections.clear()
	
	for x in genes:#For each connection
		x.from_Node.get_ref().output_Connections.append(weakref(x))#Add a reference to it to the node

#Feeding in the input values into the NN and returning the output array
func Feed_Forward(input_Values):
	#Set the outputs of the input nodes
	for x in range(inputs):
		nodes[x].output_Value = input_Values[x]
	nodes[bias_Node].output_Value = 1.0 #Output of bias is always 1
	
	for x in network: #For each node in the network, engage it
		x.Engage() #See Node class to understand what this does
	
	#The outputs are nodes[inputs] to nodes[inputs + outputs - 1]
	outs = []
	outs.resize(outputs)
	for x in range(outputs):
		outs[x] = nodes[inputs + x].output_Value
	
	for n in nodes: #Reset all nodes for the next feed forward
		n.Reset_In()
	
	return outs

#Sets up the NN as a list of nodes in the right order to be engaged
func Generate_Network():
	Connect_Nodes()
	network = []
	#For each layer, add the node in that layer, since layers cannot connect to themselves, there is no need to order the nodes within a layer.
	for i in range(layers): #For each layer
		for j in nodes: #For each node
			if(j.layer == i): #If that node is in that layer
				network.append(j)

#Returns wether the network is fully connected or not
func Fully_Connected():
	var max_connections = 0
	
	var nodes_in_layers = [] #Array which stored the amount of nodes in each layer

	#Populate array with 0s to ease the code
	# warning-ignore:unused_variable
	for x in range(layers):
		nodes_in_layers.append(0)
	
	#Populate array
	for x in nodes:
		nodes_in_layers[x.layer] += 1
	
	#For each layer, the maximum amount of connections is the number in this layer * the number of nodes in front of it
	#So let's add the max for each layer together and then we will get the maximum amount of connections in the network
	for x in range(layers - 1):
		var nodes_in_front = 0
		for y in range(x + 1, layers): #For each layer in front of this layer
			nodes_in_front += nodes_in_layers[y] #Add up the nodes
		
		max_connections += nodes_in_layers[x] * nodes_in_front
	
	if (max_connections == genes.size()): #If the number of conenctions is equal to the max number of connections possible, then it is full
		return true
		
	return false

#Returns wether or not the randomly gennerated connections aren't good
func Random_Connection_Nodes_Are_Shit(rand1, rand2):
	if(nodes[rand1].layer == nodes[rand2].layer):
		return true
	if(nodes[rand1].Is_Connected_To(nodes[rand2])):
		return true
	
	return false

#Returns the innovation number for the new mutation
#If this mutation has never been seen before, then it will be given a new unique innovation number
#If this mutation matches a previous mutation, then it will be given the same innovation number as the previous one
func Get_Innovation_Number(innovation_history, from, to):
	var isnew = true
	var connection_innovation_number = Globals.NEAT_next_connection_no
	for x in innovation_history: #For each previous mutation
		if(x.Matches(self, from, to)): #If mutation found
			isnew = false #It's not a new mutation
			connection_innovation_number = x.innovation_Number #Set the innovation number as the innovation number of the match
			break
	
	if(isnew): #If the mutation is new, then create an array with numbers representing the current state of the genome
		var innovation_numbers = []
		for x in genes: #Set the innovation numbers
			innovation_numbers.append(x.innovation_Number)
		
		#Then add this mutation to the innovation history
		innovation_history.append(Globals.Connection_History.new(from.number, to.number, connection_innovation_number, innovation_numbers))
		Globals.NEAT_next_connection_no += 1
	
	return connection_innovation_number

#Adds a connection between 2 nodes which aren't currently connected
func Add_Connection(innovation_history):
	#Cannot add a connection to a fully connected network
	if(Fully_Connected()):
		return
	
	#Get random nodes
	var random_node_01 = Globals.RNG.randi_range(0, nodes.size() - 1)
	var random_node_02 = Globals.RNG.randi_range(0, nodes.size() - 1)
	while (Random_Connection_Nodes_Are_Shit(random_node_01, random_node_02)):
		#Get new ones until they are not shit
		random_node_01 = Globals.RNG.randi_range(0, nodes.size() - 1)
		random_node_02 = Globals.RNG.randi_range(0, nodes.size() - 1)
	
	var temp
	if(nodes[random_node_01].layer > nodes[random_node_02].layer): #If the first random node is after the second, do the ole' switcharoo
		temp = random_node_02
		random_node_02 = random_node_01
		random_node_01 = temp
	
	#Get the innovation number of the connection
	#This will be a new number if no identical genome has mutated the same way
	var connection_innovation_number = Get_Innovation_Number(innovation_history, nodes[random_node_01], nodes[random_node_02])
	#Add the connection with a random array
	
	genes.append(Globals.Connection.new(nodes[random_node_01], nodes[random_node_02], Globals.RNG.randf_range(-1, 1), connection_innovation_number))
	self.add_child(genes.back()) #Setting the newly added node as a child of this genome, so it's easier to clean the memory
	Connect_Nodes()

#Mutate the NN by adding a new node
#It does this by picking a random connection and disabling it, then 2 new connections are added:
#One between the input node of the disabled connection and the new node
#And the other between the new node and the output of the disabled connection
func Add_Node(innovation_history):
	#Failsafe if no genes are present
	if(genes.size() == 0):
		Add_Connection(innovation_history)
		return
	#Pick a random connection to create a new node between
	var random_connection = Globals.RNG.randi_range(0, genes.size() - 1)
	while (genes[random_connection].from_Node == nodes[bias_Node]): #Don't disconnect the bias
		random_connection = Globals.RNG.randi_range(0, genes.size() - 1)
	
	genes[random_connection].enabled = false #Disable it
	
	var new_node_no = next_Node
	nodes.append(Globals.NEAT_Node.new(new_node_no))
	self.add_child(nodes[new_node_no])
	next_Node += 1
	#Add a new connection to the new node, with a weight of 1
	var connection_innovation_number = Get_Innovation_Number(innovation_history, genes[random_connection].from_Node.get_ref(), Get_Node(new_node_no))
	genes.append(Globals.Connection.new(genes[random_connection].from_Node.get_ref(), Get_Node(new_node_no), 1, connection_innovation_number))
	self.add_child(genes.back())
	
	connection_innovation_number = Get_Innovation_Number(innovation_history, Get_Node(new_node_no), genes[random_connection].to_Node.get_ref())
	#Add a new connection from the new node with a weight equal to that of the disabled connection
	genes.append(Globals.Connection.new(Get_Node(new_node_no), genes[random_connection].to_Node.get_ref(), genes[random_connection].weight, connection_innovation_number))
	self.add_child(genes.back())
	Get_Node(new_node_no).layer = genes[random_connection].from_Node.get_ref().layer + 1
	
	connection_innovation_number = Get_Innovation_Number(innovation_history, Get_Node(bias_Node), Get_Node(new_node_no))
	#Connect the bias to the new node with a weight of 0
	genes.append(Globals.Connection.new(Get_Node(bias_Node), Get_Node(new_node_no), 0, connection_innovation_number))
	self.add_child(genes.back())
	
	#If the layer of the new node is equal to the layer of the node in the output connection, then a new layer should be created
	#More accurately, the layer numbers of all layers equal to or greater than this new node need to be incremented
	if(Get_Node(new_node_no).layer == genes[random_connection].to_Node.get_ref().layer):
		for x in range(nodes.size() - 1): #Don't include this newest node
			if (nodes[x].layer >= Get_Node(new_node_no).layer):
				nodes[x].layer += 1
		layers += 1
	
	Connect_Nodes()

#Mutates the genome
func Mutate(innovation_history):
	if (genes.size() == 0):
		Add_Connection(innovation_history)
	
	var rand = Globals.RNG.randf()
	if (rand < 0.8): #80% of the time, mutate weights
		for x in genes:
			x.Mutate_Weight()
	
	rand = Globals.RNG.randf()
	if (rand < 0.08): #8% of the time, add a new connection
		Add_Connection(innovation_history)
	
	rand = Globals.RNG.randf()
	if (rand < 0.02): #2% of the time, add a new node
		Add_Node(innovation_history)

#Returns the number of a gene matching the input innovation number in the input genome
func Matching_Gene(parent2, innovation_number):
	var x = 0
	while x < min(genes.size(), parent2.genes.size()):
		if(parent2.genes[x].innovation_Number == innovation_number):
			return x
		x += 1
	return -1 #No matching gene found

#Returns a clone of this genome
func Clone():
	var clone = Globals.Brain.new(inputs, outputs, true)
	
	for x in nodes: #Copy nodes
		clone.nodes.append(x.Clone())
		clone.add_child(clone.nodes.back())
		
	#Copy all the connections so that they connect the cone's new ones
	
	for x in genes: #Copy genes
		clone.genes.append(x.Clone(clone.Get_Node(x.from_Node.get_ref().number), clone.Get_Node(x.to_Node.get_ref().number)))
		clone.add_child(clone.genes.back())
	
	clone.layers = layers
	clone.next_Node = next_Node
	clone.bias_Node = bias_Node
	clone.Connect_Nodes()
	
	return clone

#Called when this genome is better than the other parent, to give bebe
func Crossover(parent2):
	var child = Globals.Brain.new(inputs, outputs, true)
	child.genes.clear()
	child.nodes.clear()
	child.layers = layers
	child.next_Node = next_Node
	child.bias_Node = bias_Node
	
	var child_Genes = [] #List of genes to be inherrited from the parents
	var is_Enabled = []
	#All inherrited genes
	for x in range(genes.size()):
		var set_Enabled = true #Is this node in the child going to be enabled
		
		var parent_2_gene = Matching_Gene(parent2, genes[x].innovation_Number)
		if (parent_2_gene != -1): #If the genes match
			if (!genes[x].enabled or !parent2.genes[parent_2_gene].enabled): #If either of the matching genes are disabled
				if (Globals.RNG.randf() < 0.75): #75% of the time, disable the child's gene
					set_Enabled = false
			
			var rand = Globals.RNG.randf()
			if (rand < 0.5): #r/fiftyfifty
				#Get genes from this mofo
				child_Genes.append(genes[x])
			else:
				#Get genes from the other parent
				child_Genes.append(parent2.genes[x])
		else: #Disjoint or excess gene
			child_Genes.append(genes[x])
			set_Enabled = genes[x].enabled
		
		is_Enabled.append(set_Enabled)
	
	#Since all excess and disjoint genes are inherrited from the more fit parent (this genome) the child's strutcture is no different from this parent | With the exception of dormant connections being enabled, but this doesn't affect nodes
	#So all the nodes can be inherrited from this parent
	for x in nodes:
		child.nodes.append(x.Clone())
		child.add_child(child.nodes.back())
	
	#Clone all teh connections so that they connect the child's new nodes
	for x in range(child_Genes.size()):
		child.genes.append(child_Genes[x].Clone(child.Get_Node(child_Genes[x].from_Node.get_ref().number), child.Get_Node(child_Genes[x].to_Node.get_ref().number)))
		child.genes[x].enabled = is_Enabled[x]
		child.add_child(child.genes.back())
	
	child.Connect_Nodes()
	return child
