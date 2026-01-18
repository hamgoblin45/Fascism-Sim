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
@export var dialogue_title: String = ""
#@export var next_map: String
#@export var end_rotation: float

var current_index: int = 0
var target_pos: Vector3


func get_next_target() -> bool:
	if target_positions.is_empty():
		return false
	
	if current_index < target_positions.size():
		target_pos = target_positions[current_index]
		current_index += 1
		return true
	
	elif is_looping:
		current_index = 0
		return get_next_target()
	
	return false

func reset_path():
	current_index = 0
	target_pos = Vector3.ZERO


#
#func set_position():
	#if not target_pos and target_positions.size() > 0:
		#target_pos = target_positions[0]
		#print("PathData.gd: Setting target pos to %s" % target_pos)
		#return
	#for pos in target_positions:
		#if pos and target_positions[-1] and pos == target_positions[-1]:
			#EventBus.path_finished.emit(self)
			#print("PathData.gd: all target positions reached")
			#return
		#if pos and pos == target_pos:
			#var pos_index = target_positions.find(pos)
			#var next_pos = target_positions[pos_index + 1]
			#target_pos = next_pos
			#print("ScheduleData.gd: updating pos to %s" % target_pos)
			#return
