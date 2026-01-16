extends Resource
class_name ScheduleData

var current_path: PathData
var current_routine: Array[PathData]

@export var test_routine: Array[PathData]

@export var day_one_routine: Array[PathData]
# But holiday / special routes here
@export var normal_routine: Array[PathData]

signal setting_path(PathData)
signal finishing_routine(String)



func set_routine():
	current_path = null
	if normal_routine.size() > 0:
		current_routine = normal_routine
		print("Setting a normal routine for NPC")
	else:
		current_routine = test_routine
	
	if GameTime.day <= 1:
		current_routine = day_one_routine
		print("Setting Day 1 routine for NPC")
	
	#print("%s selected routine %s" % [self, current_routine])
	
	
	_set_path()

func _set_path():
	if not current_path and current_routine.size() > 0:
		current_path = current_routine[0]
		setting_path.emit(current_path)
		print("ScheduleData.gd: Setting path to %s" % current_path)
		return
	for path in current_routine:
		if path and current_routine.size() > 1 and current_routine[-1] and path == current_routine[-1]:
			print("ScheduleData.gd: routine finished")
			finishing_routine.emit("") # This should either set npc idle or just queue_free them
			return
		if path and path == current_path:
			var path_index = current_routine.find(path)
			var next_path: PathData = current_routine[path_index + 1]
			current_path = next_path
			setting_path.emit(current_path)
			print("ScheduleData.gd: updating path to %s" % current_path)
			return
