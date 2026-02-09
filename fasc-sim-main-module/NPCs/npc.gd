extends CharacterBody3D
class_name NPC

@export var npc_data: NPCData

@export_group("AI Settings")
#@export var flee_distance: flaot = 8.0
#@export var vision_angle: float = 45.0 # Degrees
#@export var recovery_time: float = 4.0

#@onready var npc_mesh: Node3D = $NPCMesh
@onready var look_at_node: Node3D = $LookAtNode

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process
var gravity_enabled: bool = true

@onready var interact_area: Interactable = $Interactable
var interactable: bool = true

@export_category("Anim Control")
var anim: AnimationPlayer
@export var blend_speed = 2
var walk_blend_value = 0
var prev_walk_blend_value: float
var sit_blend_value = 0
# Looking at stuff
@onready var head: Node3D = $Head
var looking_at: Node3D
var player_nearby: bool
## --- STATES
enum {IDLE, WALK, WAIT, ANIMATING}
var state = IDLE
#var recovery_timer:float = 0.0
var is_interrupted: bool = false
var prev_state

## -- PATHING
var last_schedule_check: float = -1.0 #Based on time, full numbers being hours
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var proximity_detect_area: Area3D = $ProximityDetectArea
var start_basis
var target_basis
var target_pos: Vector3



func _ready() -> void:
	EventBus.minute_changed.connect(_on_time_updated)
	EventBus.world_changed.connect(_on_world_changed)
	_check_schedule(GameState.hour, GameState.minute)
	EventBus.item_interacted.connect(_on_interact)


func _physics_process(delta: float) -> void:
	
	## Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		
		velocity.y -= gravity * delta
	
	## Look at a node if a node is set
	if is_instance_valid(looking_at):
		##look_at_target(looking_at)
		look_at_node.look_at(looking_at.global_position)
		global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.75 * delta)
	
	#_check_for_interrupt(delta)
	## Engage with player if within range and waiting for them
	#if npc_data.waiting_for_player and player_nearby:
		#_on_player_nearby_detected()

	#update_anim_tree()
	_handle_state(delta)
	move_and_slide()


func instance_npc():
	#for child in npc_mesh.get_children():
		#child.queue_free()
	if npc_data.on_map:
		print("npc_node.gd: Instancing %s, is on current map" % npc_data.name)
		
		gravity_enabled = true

func _on_interact(object: Interactable, interact_type: String, engaged: bool):
	if object.id != interact_area.id: return
	match interact_type:
		"interact":
			DialogueManager.start_dialogue()

## -- SCHEDULE / PATHING ------------
func _on_world_changed(flag_name: String, value: bool):
	# When the world changes, have it check schedule to see if it should react
	print("NPC %s reacting to world change: %s" % [npc_data.name, flag_name])
	# This can be used to play specif anims based on the flag. For example:
	#if flag_name == "alarm_sounded" and value == true:
		#state = ANIMATING
		#anim.play("panic")
		#await anim.animation_finished # This would have it play the animation, THEN update pathing
	
	npc_data.schedule.current_path = null
	_check_schedule(GameState.hour, GameState.minute)

func _on_time_updated(h: int, m: int):
	if not is_interrupted:
		_check_schedule(h, m)

func _check_schedule(h: int, m: int):
	if not npc_data.schedule:
		return
	#print("_check_schedule run in npc.gd")
	var new_path = npc_data.schedule.get_path_for_time(h, m)
	
	if new_path and new_path != npc_data.schedule.current_path:
		print("selecting a new path in _check_schedule in npc.gd")
		npc_data.schedule.current_path = new_path
		new_path.reset_path()
		_start_walking()
		#set_path(new_path)

#func _check_for_interrupt(delta: float):
	#var dist = global_position.distance_to(GameState.player.global_position)
	#var can_see = _can_see_player(dist)
	#
	#if can_see and dist < confront_distance:
		#if state != CONFRONT:
			#state = CONFRONT
			#is_interrupted = true
		#recovery_timer = recovery_time
	#elif is_interrupted:
		#recovery_timer -= delta
		#if recovery_timer <= 0:
			#_resume_routine()

#func _can_see_player(dist: float) -> bool:
	#if dist > aggro_distance: return false
	#var dir_to_player = global_position.direction_to(GameState.player.global_position)
	#var forward = -global_transform.basis.z # Typical Godot forward
	#var angle = rad_to_deg(forward.angle_to(dir_to_player))
	#return angle < vision_angle

func _resume_routine():
	is_interrupted = false
	var path = npc_data.schedule.get_path_for_time(GameState.hour, GameState.minute)
	if path:
		npc_data.schedule.current_path = path
		path.jump_to_closest_point(global_position)
		state = WALK

func set_path(path: PathData):
	if path.get_next_target(): # Get the first position
		print("set_path() run in NPC.gd, state set to WALK")
		state = WALK
		if path.start_pos != Vector3.ZERO:
			global_position = path.start_pos
	else:
		print("set_path() run in NPC.gd, state set to IDLE")
		state = IDLE


## -- STATE MACHINE -- ##

# Sets animations (or tries to) based on state. From tutorial. Designed to work with AnimationTree
# Perhaps tracking path progress should be its own func
func _handle_state(delta):
	match state:
		
		IDLE, ANIMATING:
			
			#walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
			
			velocity.x = move_toward(velocity.x, 0, npc_data.walk_accel * delta)
			velocity.z = move_toward(velocity.z, 0, npc_data.walk_accel * delta)
			
			#if npc_data.waiting_for_player and looking_at != Global.player:
				#looking_at = Global.player
		
		WALK:
			if not get_tree().paused:
				#walk_blend_value = lerpf(walk_blend_value, 1, blend_speed * delta)
				#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
				handle_nav(delta)


## -- NAVIGATION -- ##
func handle_nav(delta: float):
	#print("Handling Nav")
	var path = npc_data.schedule.current_path
	if not path: return
	
	# Checks if npc has reached target point
	if global_position.distance_to(path.target_pos) < 0.6:
		if not path.get_next_target():
			_finish_path()
			return
	
	# Calculate movement
	var dir = global_position.direction_to(path.target_pos)
	_move_and_rotate(dir, npc_data.walk_speed, delta)


func _move_and_rotate(dir: Vector3, speed: float, delta: float):
	velocity.x = lerp(velocity.x, dir.x * speed, npc_data.walk_accel * delta)
	velocity.z = lerp(velocity.z, dir.z * speed, npc_data.walk_accel * delta)
	# Rotation
	look_at_node.look_at(global_position + dir)
	global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 6.0 * delta)

func _start_walking():
	if npc_data.schedule.current_path.get_next_target():
		state = WALK

func _finish_path():
	var path = npc_data.schedule.current_path
	print("%s reached end of path" % npc_data.name)
	
	if path.anim_on_arrival != "":
		state = ANIMATING
		#Once setting up anims:
		anim.play(path.anim_on_arrival)
	else:
		state = IDLE
	
	interactable = true
	npc_data.waiting_for_player = path.wait_for_player
	EventBus.path_finished.emit(npc_data, path)

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
			print("%s is looking at something" % npc_data.name)
			looking_at = target
			if target == GameState.player:
				looking_at = target.HEAD
		look_at_node.look_at(looking_at.global_position)
	else:
		looking_at = null


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
