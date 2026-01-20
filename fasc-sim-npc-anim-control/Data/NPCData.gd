extends Resource
class_name NPCData

@export var name: String
@export var id: String

var waiting_for_player: bool

@export var walk_speed: float = 15.0
@export var walk_accel: float = 15.0
@export var run_speed: float = 20.0
@export var run_accel: float = 30.0
