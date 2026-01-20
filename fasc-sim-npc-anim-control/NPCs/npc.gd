extends CharacterBody3D
class_name NPC

@export var npc_data: NPCData

@export_group("AI Settings")
#@export var flee_distance: flaot = 8.0
#@export var vision_angle: float = 45.0 # Degrees
#@export var recovery_time: float = 4.0

#@onready var npc_mesh: Node3D = $NPCMesh
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var look_at_node: Node3D = $LookAtNode




var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process
var gravity_enabled: bool = true

@onready var head: Node3D = $Head

var looking_at: Node3D
var player_nearby: bool

enum {IDLE, WALK, WAIT, ANIMATING}
var state = IDLE
#var recovery_timer:float = 0.0
var is_interrupted: bool = false
var prev_state
var anim: AnimationPlayer

#@onready var anim_tree: AnimationTree = $AnimationTree

@export_category("Anim Control")
@export var blend_speed = 2
var walk_blend_value = 0
var prev_walk_blend_value: float
var sit_blend_value = 0




#func _ready() -> void:
	#EventBus.npc_play_anim.connect(_play_anim)
	#EventBus.minute_changed.connect(_on_time_updated)
	#_check_schedule(GameState.hour, GameState.minute)


func _physics_process(delta: float) -> void:
	
	## Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		
		velocity.y -= gravity * delta
	
	## Look at a node if a node is set
	if is_instance_valid(looking_at):
		##look_at_target(looking_at)
		look_at_node.look_at(looking_at.global_position)
		global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.75 * delta)

	#update_anim_tree()
	_handle_state(delta)
	move_and_slide()


## -- STATE MACHINE -- ##

# Sets animations (or tries to) based on state. From tutorial. Designed to work with AnimationTree
# Perhaps tracking path progress should be its own func
func _handle_state(_delta):
	match state:
		
		IDLE, ANIMATING:
			
			#walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
			pass
		
		WALK:
			pass


# Sets the rotation of a Node3D (look_at_node) so that the target lerps in the same rotation to mimic looking at a node
func look_at_target(target):
	if target:
		if looking_at != target:
			print("%s is looking at something" % npc_data.name)
			looking_at = target
			if target == GameState.player:
				looking_at = target.HEAD
		look_at_node.look_at(looking_at.global_position)
	else:
		looking_at = null
