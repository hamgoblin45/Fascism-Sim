extends Resource
class_name PathData

@export_group("Movement")
@export var start_pos: Vector3
@export var start_rot: float
@export var target_positions: Array[Vector3]
@export var is_looping: bool = false

@export_group("Interaction")
#@export var start_time: float = 0 # What time (in in-game hours) the NPC will start current path
@export var interactable_while_walking: bool = false
@export var wait_for_player: bool = false # Whether NPC starts waiting for player after finishing path
# Might need a var for anims that may play once path is finished
@export var anim_on_arrival: String = ""
# Used to set the line of dialogue that plays AFTER walking
#@export var dialogue_title: String = ""

var current_index: int = 0
var target_pos: Vector3


func get_next_target() -> bool:
	if target_positions.is_empty():
		return false
	
	print("get_next_target run in PathData")
	if current_index < target_positions.size():
		target_pos = target_positions[current_index]
		current_index += 1
		print("Advancing to next target pos: %s" % target_pos)
		return true
	
	elif is_looping:
		print("Looping path")
		current_index = 0
		return get_next_target()
	
	print("No more targets")
	return false

func jump_to_closest_point(current_pos: Vector3):
	var closest_dist = INF
	var closest_index = 0
	for i in range(target_positions.size()):
		var dist = current_pos.distance_to(target_positions[i])
		if dist < closest_dist:
			closest_dist = dist
			closest_index = i
	current_index = closest_index
	target_pos = target_positions[current_index]
	print("Jumping to closest point")

func reset_path():
	print("reset_path run in PathData")
	current_index = 0
	#target_pos = Vector3.ZERO
