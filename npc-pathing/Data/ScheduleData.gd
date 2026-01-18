extends Resource
class_name ScheduleData

var current_path: PathData
#var current_routine: Array[PathData]

#@export var test_routine: Array[PathData]

#@export var day_one_routine: Array[PathData]
# But holiday / special routes here
#@export var normal_routine: Array[PathData]

## key: hours as float (0.0 - 23.99), value: PathData
@export var hourly_routine: Dictionary = {}

## Find the next scheduled path based on time
func get_path_for_time(hour: float) -> PathData:
	var best_hour: float = -1.0
	for time in hourly_routine.keys():
		if hour >= time and time > best_hour:
			best_hour = time
	if best_hour != -1.0:
		return hourly_routine[best_hour]
	return null

#
#func set_routine():
	#current_path = null
	#if normal_routine.size() > 0:
		#current_routine = normal_routine
		#print("Setting a normal routine for NPC")
	#else:
		#current_routine = test_routine
#
	##print("%s selected routine %s" % [self, current_routine])
	#_set_path()
#
#func _set_path():
	#if not current_path and current_routine.size() > 0:
		#current_path = current_routine[0]
		#EventBus.setting_path.emit(self, current_path)
		#print("ScheduleData.gd: Setting path to %s" % current_path)
		#return
	#for path in current_routine:
		#if path and current_routine.size() > 1 and current_routine[-1] and path == current_routine[-1]:
			#print("ScheduleData.gd: routine finished")
			#EventBus.finishing_route.emit() # This should either set npc idle or just queue_free them
			#return
		#if path and path == current_path:
			#var path_index = current_routine.find(path)
			#var next_path: PathData = current_routine[path_index + 1]
			#current_path = next_path
			#EventBus.setting_path.emit(self, current_path)
			#print("ScheduleData.gd: updating path to %s" % current_path)
			#return
