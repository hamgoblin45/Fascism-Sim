extends Resource
class_name RouteData

@export var paths: Array[PathData]
var current_path: PathData

@export var next_map: String

#signal path_finished(Curve3D, float, bool, String)
signal path_updated(PathData)
signal route_finished(String)



func _set_path():
	if not current_path and paths.size() > 0:
		current_path = paths[0]
		path_updated.emit(current_path)
		print("RouteData.gd: Setting path to %s" % current_path)
		return
	for p in paths:
		if p and paths[-1] and p == paths[-1]:
			print("RouteData.gd: route finished")
			route_finished.emit(next_map)
			return
		if p and p == current_path:
			var path_index = paths.find(p)
			var next_path: PathData = paths[path_index + 1]
			current_path = next_path
			path_updated.emit(current_path)
			print("RouteData.gd: updating path to %s" % current_path)
			return
		
	
func path_finished(path: PathData):
	print("Current path finished")

	
