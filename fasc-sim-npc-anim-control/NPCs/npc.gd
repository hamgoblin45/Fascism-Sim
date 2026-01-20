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

#enum {IDLE, WALK, TALK, WAIT, ANIMATING}
var state: String = "IDLE"
#var recovery_timer:float = 0.0
var is_interrupted: bool = false
var prev_state

#@onready var anim_tree: AnimationTree = $AnimationTree

@export_category("Anim Control")
var anim: AnimationPlayer
var animating: bool = false
@export var blend_speed = 2
@onready var anim_tree: AnimationTree = $AnimationTree

var walk_blend_value = 0
var prev_walk_blend_value: float
var sit_blend_value = 0




func _ready() -> void:
	_instance_npc_mesh()
	EventBus.npc_play_anim.connect(_play_anim)
	EventBus.npc_set_state.connect(_set_state)
	#EventBus.minute_changed.connect(_on_time_updated)
	#_check_schedule(GameState.hour, GameState.minute)

func _instance_npc_mesh():
	if npc_data:
		if npc_data.mesh:
			var mesh = npc_data.mesh.instantiate()
			add_child(mesh)
			
			for child in mesh.get_children():
				if child is AnimationPlayer:
					anim = child
					# Set up AnimTree
					_set_blend_tree()
					
					anim.animation_finished.connect(_on_anim_finished)
					return

func _physics_process(delta: float) -> void:
	
	## Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		
		velocity.y -= gravity * delta
	
	## Look at a node if a node is set
	if is_instance_valid(looking_at):
		##look_at_target(looking_at)
		look_at_node.look_at(looking_at.global_position)
		global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.75 * delta)

	_update_anim_tree()
	_handle_state(delta)
	move_and_slide()


func _play_anim(npc: NPCData, anim_name: String):
	if npc.id != npc_data.id:
		return
	if not anim.has_animation(anim_name):
		push_error("Attempting to play anim %s on NPC %s but no such anim name exists" % [anim_name, npc_data.name])
	anim.stop()
	anim.play(anim_name)
	animating = true

func _set_blend_tree():
	anim_tree.anim_player = anim.get_path()
	var tree_root: AnimationNodeBlendTree = anim_tree.tree_root
	
	# Set Idle node anim
	var idle_node: AnimationNodeAnimation = tree_root.get_node("AnimIdle")
	if idle_node:
		idle_node.animation = npc_data.idle_anims.pick_random()
		print("_set_blend_tree run in npc.gd; %s's IdleWalk animation set to %s" % [npc_data.name, idle_node.animation])
	else:
		print("Idle Anim node not found in blend tree!")
		
	# Set Walk node anim
	var walk_node: AnimationNodeAnimation = tree_root.get_node("AnimWalk")
	if walk_node:
		walk_node.animation = npc_data.walk_anims.pick_random()
		print("_set_blend_tree run in npc.gd; %s's AnimWalk animation set to %s" % [npc_data.name, walk_node.animation])
	else:
		print("Walk Anim node not found in blend tree!")

func _update_anim_tree():
	anim_tree["parameters/Walk/blend_amount"] = walk_blend_value


## -- STATE MACHINE -- ##
func _set_state(npc: NPCData, new_state: String):
	if npc.id != npc_data.id or new_state == state:
		return
	print("Setting state in NPC")
	#prev_state = state
	state = new_state


# Sets animations (or tries to) based on state. From tutorial. Designed to work with AnimationTree
# Perhaps tracking path progress should be its own func
func _handle_state(delta):
	match state:
		
		"IDLE":
			#if anim.is_playing() and npc_data.idle_anims.has(anim.current_animation) or animating:
				#return
			#else:
				#var selected_anim = npc_data.idle_anims.pick_random()
				#anim.play(selected_anim)
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
		
		"WALK":
			walk_blend_value = lerpf(walk_blend_value, 1, blend_speed * delta)
			#if anim.is_playing() and npc_data.walk_anims.has(anim.current_animation) or animating:
				#return
			#else:
				#var selected_anim = npc_data.walk_anims.pick_random()
				#anim.play(selected_anim)



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

func _on_anim_finished(_anim_name: String):
	animating = false
