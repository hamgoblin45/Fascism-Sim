extends Resource
class_name NPCData

@export var name: String

@export var on_map: bool = true
var current_path: PathData
@export var schedule: ScheduleData
#var start_path_time: float

@export var waiting_for_player: bool

@export var walk_speed: float = 5.0
@export var walk_accel: float = 5.0
@export var run_speed: float = 10.0
@export var run_accel: float = 15.0



func set_route():
	if schedule:
		print("Setting routine via NPCData's set_route() func")
		schedule.set_routine()
