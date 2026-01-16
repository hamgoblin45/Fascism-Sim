extends Resource
class_name PathData

#@export var curve: Curve3D # Each individual path
@export var start_map: String
@export var start_pos: Vector3
@export var start_rot: float
var target_pos: Vector3
@export var target_positions: Array[Vector3]
@export var start_time: float = 0 # What time (in in-game hours) the NPC will start current path
@export var interactable_while_walking: bool = false
@export var wait_for_player: bool = false # Whether NPC starts waiting for player after finishing path
# Might need a var for anims that may play once path is finished
@export var anim: String = ""
# Used to set the line of dialogue that plays AFTER walking
@export var dialogue_title: String = ""
@export var next_map: String
@export var end_rotation: float

signal path_finished()
#@export var next_map: String = ""



func set_position():
	if not target_pos and target_positions.size() > 0:
		target_pos = target_positions[0]
		print("PathData.gd: Setting target pos to %s" % target_pos)
		return
	for pos in target_positions:
		if pos and target_positions[-1] and pos == target_positions[-1]:
			path_finished.emit()
			print("PathData.gd: all target positions reached")
			return
		if pos and pos == target_pos:
			var pos_index = target_positions.find(pos)
			var next_pos = target_positions[pos_index + 1]
			target_pos = next_pos
			print("ScheduleData.gd: updating pos to %s" % target_pos)
			return
