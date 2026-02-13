extends NPC
class_name GuestNPC

var is_inside_house: bool = false
var is_hidden: bool = false
var current_hiding_spot: HidingSpot = null

func hide_in_spot(spot: HidingSpot):
	is_hidden = true
	current_hiding_spot = spot
	hide()
	collision_layer = 0
	state = IDLE # Maybe add a "Hiding" state later that can do things that might risk detection; e.g. coughing

func exit_hiding():
	is_hidden = false
	current_hiding_spot = null
	show()
	collision_layer = 1

func _on_clue_timer_timeout():
	var GUEST_CLUE = preload("uid://bkoe4a2utnp6l")
	
	if is_inside_house and not is_hidden:
		var clue = GUEST_CLUE.instantiate()
		get_parent().add_child(clue)
		clue.global_position = global_position # Drops clue at feet
		# Add logic to randomize what kinda clue mesh it is; maybe even juist in the clue itself
