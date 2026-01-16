extends CharacterBody3D
class_name NPC

@export var npc_data: NPCData
#@export var dialogue_data: DialogueData
#@export var dialogue_title: String

@onready var dialogue_blurb: Node3D = $DialogueBlurb

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process
var gravity_enabled: bool = true

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var mesh
@onready var npc_mesh: Node3D = $NPCMesh


#@onready var face_mesh: MeshInstance3D = $Mesh/Armature/Skeleton3D/Cube_001

@export var face_smile: Texture2D
@export var face_serious: Texture2D

@onready var head: Node3D = $Head
@onready var dialog_cam_point: Node3D = $DialogCamPoint


@onready var look_at_node: Node3D = $LookAtNode
var looking_at: Node3D
var player_nearby: bool

var interactable: bool = true
#@export var state: String
#@export var speed: float = 10.0

enum {IDLE, WALK, TALK, SIT, WAIT}
var state = IDLE
var prev_state
var anim: AnimationPlayer

#var walk_speed: float = 5.8
#var walk_accel: float = 6.0
#var run_speed: float = 10.0
#var run_accel: float = 15.0

var schedule: ScheduleData

@onready var anim_tree: AnimationTree = $AnimationTree

@export var blend_speed = 2
var walk_blend_value = 0
var prev_walk_blend_value: float
var sit_blend_value = 0

@export var current_path: PathData
var path_follow: PathFollow3D

@onready var proximity_detect_area: Area3D = $ProximityDetectArea

var start_basis
var target_basis
var target_pos: Vector3



func _ready() -> void:
	## sets NPC data from NPC Node (the one on PathFollows), interact/path/dialog signals
	current_path = null
	schedule = null
	
	if npc_data.schedule:
		schedule = npc_data.schedule
		
		schedule.set_routine() # This is a func in the data
		set_path(schedule.current_path)
		
		if npc_data.on_map:
			instance_npc()
			print("%s instancing on current map, instancing based off change_map in NPC.gd" % npc_data.name)
		
		#schedule.setting_path.connect(set_path)
		#schedule.finishing_routine.connect(change_map)
		
		print("%s current path set to %s" % [npc_data.name,current_path])



func _physics_process(delta: float) -> void:
	
	## Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		
		velocity.y -= gravity * delta
		move_and_slide()
		
	## Look at a node if a node is set
	if is_instance_valid(looking_at):
		##look_at_target(looking_at)
		look_at_node.look_at(looking_at.global_position)
		global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.75 * delta)
	
	## Engage with player if within range and waiting for them
	#if npc_data.waiting_for_player and player_nearby:
		#_on_player_nearby_detected()

	#update_anim_tree()
	handle_state(delta)


func instance_npc():
	for child in npc_mesh.get_children():
		child.queue_free()
	if npc_data.on_map:
		print("npc_node.gd: Instancing %s, is on current map" % npc_data.name)
		
		gravity_enabled = true

## -- STATE MACHINE -- ##

# Sets animations (or tries to) based on state. From tutorial. Designed to work with AnimationTree
# Perhaps tracking path progress should be its own func
func handle_state(delta):
	
	match state:
		
		IDLE:
			
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
			
			velocity = Vector3.ZERO
			
			#if npc_data.waiting_for_player and looking_at != Global.player:
				#looking_at = Global.player
		
		WALK:
			#print("I'M WALKIN' HERE!")
			if not get_tree().paused:
				#walk_blend_value = lerpf(walk_blend_value, 1, blend_speed * delta)
				#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
				move_and_slide()
				handle_nav(delta)


## -- NAVIGATION -- ##

func handle_nav(delta: float):
	#print("NPC walking towards %s, currently at %s [approx. %s away]" % [current_path.target_pos, global_position, global_position.distance_to(current_path.target_pos)])
	if current_path:
		if global_position.distance_to(current_path.target_pos) > 1.5:
			
			if not current_path.interactable_while_walking and interactable:
				interactable = false
				#interact_area.interact_text = ""
			
			#nav_agent.target_position = current_path.target_pos
			
			var dir = (current_path.target_pos - global_position).normalized()
			
			look_at_node.look_at(current_path.target_pos) # - Maybe a way to lerp/interpolate this?
			global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 6.0 * delta)
			
			## Walking
			velocity = velocity.lerp(dir * npc_data.walk_speed, npc_data.walk_accel * delta)
			
		else:
			current_path.set_position()
			if current_path:
				nav_agent.target_position = current_path.target_pos
		#finish_path()
	else:
		state = IDLE

func set_path(_path: PathData):
	if _path:
		
		current_path = _path
		
		current_path.set_position()
		current_path.path_finished.connect(finish_path)
		
		if _path.start_pos:
			global_position = _path.start_pos
		
		if _path.start_rot:
			global_rotation.y = _path.start_rot
		
		print("Setting path for %s. Start pos is %s, actual pos is %s" % [npc_data.name,_path.start_pos, position])

func set_next_path(_path: PathData):
	#print("NPC setting next path")
	if _path:
		for path in npc_data.schedule.current_routine:
			if current_path == path:
				if path != npc_data.schedule.current_routine[-1]:
					var path_index = npc_data.schedule.current_routine.find(path)
					if not current_path.wait_for_player:
						state = WALK
					set_path(npc_data.schedule.current_routine[path_index + 1])
					return
				else:
					current_path = null
					if is_instance_valid(anim):
						anim.stop()
					state = "idle"
					state = IDLE
					print("%s finished their routine for the day" % npc_data.name)
					return

## Stops anims, sets states, resets rotation (not entirely sure why I put that there)
func finish_path():
	print("npc.gd: %s stopped walking" % npc_data.name)
	
	state = IDLE
	
	npc_data.waiting_for_player = current_path.wait_for_player
	
	set_next_path(current_path)

## -- INTERACTION -- ##

# Initiated by pressing E on an NPC or entering its detect area while its waiting for player
# Currently just initiates dialogue, may have other uses later (trading, etc)
func interact_with_npc():
	if interactable:
		print("npc.gd: Player interacted with %s" % npc_data.name)


# Sets the rotation of a Node3D (look_at_node) so that the target lerps in the same rotation to mimic looking at a node
func look_at_target(target):
	if target:
		if looking_at != target:
			looking_at = target
			if target == GameState.player:
				looking_at = target.HEAD
		look_at_node.look_at(looking_at.global_position)
	else:
		looking_at = null


#func change_map(next_map: String):
	#npc_data.start_path_time = 0
	#npc_data.current_map = next_map
	#
	#if next_map != "" and next_map != Global.current_map_name:
		#for child in npc_mesh.get_children():
			#child.queue_free()
			#gravity_enabled = false
	#
		#print("%s NPC: Changing map to %s based off change_map in NPC Node" % [npc_data.name, next_map])
	### Instances NPC if they are entering current map
	#if next_map == Global.current_map_name:
		#instance_npc()
		#print("%s entering current map, instancing based off change_map in NPC.gd" % npc_data.name)


#
### Detects if Player is nearby # Set it up to detect other NPCs
#func _on_proximity_detect_area_body_entered(body: Node3D) -> void:
	#if body is Player:
		#
		#player_nearby = true
#
### Detects when Player is no longer nearby
#func _on_proximity_detect_area_body_exited(body: Node3D) -> void:
	#if body is PlayerCharacter:
		#
		#player_nearby = false
#
### Sets paths based on a final anim, worry about this after setting up anim system
#func _on_anim_animation_finished(anim_name: StringName) -> void:
	#if anim_name == current_path.anim:
		#print("Anim finished is named in current path")
	##rotation.y = current_path.end_rotation
		#if current_path.next_map:
			#change_map(current_path.next_map)
		#npc_data.waiting_for_player = current_path.wait_for_player
		#
		#if npc_data.current_dialogue_data:
			#interactable = true
			#interact_area.interact_text = "Press E to talk"
			#
		#set_next_path(current_path)
		##set_next_path(current_path)
