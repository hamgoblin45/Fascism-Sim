extends Resource
class_name NPCData

@export var name: String

@export var on_map: bool = true
@export var schedule: ScheduleData
#var start_path_time: float

var waiting_for_player: bool

@export var walk_speed: float = 5.0
@export var walk_accel: float = 5.0
@export var run_speed: float = 10.0
@export var run_accel: float = 15.0
