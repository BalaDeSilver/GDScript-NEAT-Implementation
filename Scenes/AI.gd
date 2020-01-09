extends RigidBody2D

var body_server #Random name

signal integrate_forces(state)
#This entire script is to attach this signal and pass the state to hook the integrate forces
#Without this, there is no connection between the NEAT rigidbody and the actual onscreen rigidbody
func _integrate_forces(state):
	body_server = state
	emit_signal("integrate_forces", state)