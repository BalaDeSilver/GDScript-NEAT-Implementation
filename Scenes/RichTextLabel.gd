extends RichTextLabel

#How the duck do I make this show up on the screen????

# warning-ignore:unused_argument
func _process(delta):
	set_bbcode("Time remaining: " + "%1.3f" % Globals.NEAT_Timer.time_left + "\nReached: " + "%1d" % Globals.count)