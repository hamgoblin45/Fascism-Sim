extends CharacterBody3D
class_name NPC

@export var npc_data: NPCData

@export_group("AI Settings")
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var look_at_node: Node3D = $LookAtNode

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process
var gravity_enabled: bool = true

@onready var head: Node3D = $Head

var looking_at: Node3D
var player_nearby: bool

#enum {IDLE, WALK, TALK, WAIT, ANIMATING}
var state: String = "IDLE"
var is_interrupted: bool = false


@export_category("Anim Control")
var anim: AnimationPlayer
@export var blend_speed = 2
@onready var anim_tree: AnimationTree = $AnimationTree

var action_map = {
	"TakeItem": 0
}

var walk_blend_value = 0
var prev_walk_blend_value: float
var sit_blend_value = 0




func _ready() -> void:
	_instance_npc_mesh()
	EventBus.npc_play_anim.connect(_play_anim)
	EventBus.npc_set_state.connect(_set_state)

func _instance_npc_mesh():
	if npc_data and npc_data.mesh:
		var mesh = npc_data.mesh.instantiate()
		add_child(mesh)
		
		var found_anim: AnimationPlayer = null
		for child in mesh.get_children():
			if child is AnimationPlayer:
				found_anim = child
				break
		
		if found_anim:
			anim = found_anim
			anim_tree.anim_player = anim.get_path()
			anim_tree.active = true
			_set_blend_tree()

func _physics_process(delta: float) -> void:
	
	## Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		
		velocity.y -= gravity * delta
	
	## Look at a node if a node is set
	if is_instance_valid(looking_at):
		##look_at_target(looking_at)
		look_at_node.look_at(looking_at.global_position)
		global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.75 * delta)

	
	_handle_state(delta)
	move_and_slide()

func _play_anim(npc: NPCData, anim_name: String):
	if npc.id != npc_data.id:
		return
	
	if action_map.has(anim_name):
		var action_index = action_map[anim_name]
		anim_tree.set("parameters/ActionSelector/current_state", action_index)
		anim_tree.set("parameters/ActionOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		print("NPC %s fired action %s at index %d" % [npc_data.name, anim_name, action_index])
	else:
		push_error("NPC %s: Animation '%s' not found" % [npc_data.name, anim_name])
	#if not anim.has_animation(anim_name):
		#push_error("NPC %s: Animation '%s' not found" % [npc_data.name, anim_name])
		#return
	
	#var anim_path = "parameters/ActionOneShot/ActionAnimation/animation"
	#anim_tree.set(anim_path, anim_name)
	#
	#anim_tree.set("parameters/ActionOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#print("NPC %s playing anim %s" % [npc_data.name, anim_name])

func _set_blend_tree():
	anim_tree.anim_player = anim.get_path()
	anim_tree.active = true # Makes sure tree is running
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
	print("NPC %s setting state to %s" % [npc_data.name, new_state])
	#prev_state = state
	state = new_state

# Sets animations (or tries to) based on state. From a tutorial. Designed to work with AnimationTree
func _handle_state(delta):
	
	match state:
		"IDLE":
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
		
		"WALK":
			walk_blend_value = lerpf(walk_blend_value, 1, blend_speed * delta)
			#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
		"TALK":
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			velocity.x = move_toward(velocity.x, 0, npc_data.walk_accel * delta)
			velocity.z = move_toward(velocity.z, 0, npc_data.walk_accel * delta)
		"ANIMATING":
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
	
	_update_anim_tree()


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
	print("NPC %s finished playing anim %s, animating set to false" % [npc_data.name, _anim_name])
	#animating = false
