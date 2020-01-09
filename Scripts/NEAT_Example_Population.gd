#Start by extending the Population script
extends "res://Scripts/NEAT/NEAT_Population.gd"

#Limits on where to spawn agents
var limit_left = 0
var limit_right = 0

#Appending the ID debug variable set to the constructor
func _init(size).(size):
	for i in range(size):
		pop[i].ID = i

#Once it entered the tree, it can safely place in the agents
func _ready():
	var tree = get_tree() #Gets a reference to the tree
	var tilemaps = tree.get_nodes_in_group("tilemap") #Get everything within the group tilemap
	for tilemap in tilemaps: #For each stuff in that array
		if(tilemap is TileMap): #Grab the tilemap
			var used = tilemap.get_used_rect()
			#Grab the size of the tilemap
			limit_left = min(used.position.x * tilemap.cell_size.x, limit_left) / 2 + 32
			limit_right = max(used.end.x * tilemap.cell_size.x, limit_right) / 2 - 32
			break
	
	for i in pop: #Distribute the agents in random positions
		var pos = Vector2(0, 0)
		pos.x = Globals.RNG.randf_range(limit_left, limit_right)
		while((pos - Globals.Current_Position).length() < 1000): #But they have to be at least 1000 units away from the player
			pos.x = Globals.RNG.randf_range(limit_left, limit_right)
		i.position = pos
		i.starting_point = i.position #Crucial point on getting the score right

#Appends a bit of logic to the natural selection code
# warning-ignore:unused_argument
func Natural_Selection():
	.Natural_Selection() #Call the base function first, sice we need that to evolve
	Globals.count = 0 #Restore the count of how many agents got to the point
	for i in pop: #Reshuffles the position of every agent
		var pos = Vector2(0, 0)
		pos.x = Globals.RNG.randf_range(limit_left, limit_right)
		while((pos - Globals.Current_Position).length() < 1000): #You get it
			pos.x = Globals.RNG.randf_range(limit_left, limit_right)
		i.ID = pop.find(i) #Sice the agents got flushed, reset their ID
		i.position = pos
		i.starting_point = i.position
		i.dead = false #Heroes never die
	
	#Restart the timer
	Globals.NEAT_Timer.start(Globals.time)
	Globals.Timeout = false