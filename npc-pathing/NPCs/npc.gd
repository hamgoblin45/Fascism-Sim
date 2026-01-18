extends CharacterBody3D
class_name NPC

@export var npc_data: NPCData

@onready var npc_mesh: Node3D = $NPCMesh
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var look_at_node: Node3D = $LookAtNode

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process
var gravity_enabled: bool = true

var interactable: bool = true
var last_schedule_check: float = -1.0 #Based on time, full numbers being hours

@onready var head: Node3D = $Head

var looking_at: Node3D
var player_nearby: bool

enum {IDLE, WALK, WAIT, ANIMATING}
var state = IDLE
var prev_state
var anim: AnimationPlayer

#@onready var anim_tree: AnimationTree = $AnimationTree

@export_category("Anim Control")
@export var blend_speed = 2
var walk_blend_value = 0
var prev_walk_blend_value: float
var sit_blend_value = 0

var path_follow: PathFollow3D

@onready var proximity_detect_area: Area3D = $ProximityDetectArea

var start_basis
var target_basis
var target_pos: Vector3



func _ready() -> void:
	EventBus.minute_changed.connect(_on_time_updated)
	_check_schedule(GameState.hour)
	#if npc_data.schedule:
		#
		#npc_data.schedule.set_routine()
		#set_path(npc_data.schedule.current_path)
		#
		#if npc_data.on_map:
			#instance_npc()
			#print("%s instancing on current map, instancing based off change_map in NPC.gd" % npc_data.name)
		#
		##schedule.setting_path.connect(set_path)
		##schedule.finishing_routine.connect(change_map)
		#
		#print("%s current path set to %s" % [npc_data.name,npc_data.schedule.current_path])
		#state = WALK



func _physics_process(delta: float) -> void:
	
	## Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		
		velocity.y -= gravity * delta
		
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
	move_and_slide()


func instance_npc():
	#for child in npc_mesh.get_children():
		#child.queue_free()
	if npc_data.on_map:
		print("npc_node.gd: Instancing %s, is on current map" % npc_data.name)
		
		gravity_enabled = true

func _on_time_updated(hour: float, _minute: int):
	if hour != last_schedule_check:
		last_schedule_check = hour
		_check_schedule(hour)

func _check_schedule(hour: float):
	if not npc_data.schedule:
		return
	var new_path = npc_data.schedule.get_path_for_time(hour)
	
	if new_path and new_path != npc_data.schedule.current_path:
		npc_data.schedule.current_path = new_path
		new_path.reset_path()
		set_path(new_path)

func set_path(path: PathData):
	if path.get_next_target(): # Get the first position
		state = WALK
		if path.start_pos != Vector3.ZERO:
			global_position = path.start_pos
	else:
		state = IDLE


## -- STATE MACHINE -- ##

# Sets animations (or tries to) based on state. From tutorial. Designed to work with AnimationTree
# Perhaps tracking path progress should be its own func
func handle_state(delta):
	
	match state:
		
		IDLE, ANIMATING:
			
			#walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
			
			velocity.x = move_toward(velocity.x, 0, npc_data.walk_accel * delta)
			velocity.z = move_toward(velocity.z, 0, npc_data.walk_accel * delta)
			
			#if npc_data.waiting_for_player and looking_at != Global.player:
				#looking_at = Global.player
		
		WALK:
			#print("I'M WALKIN' HERE!")
			if not get_tree().paused:
				#walk_blend_value = lerpf(walk_blend_value, 1, blend_speed * delta)
				#sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
				handle_nav(delta)
				move_and_slide()


## -- NAVIGATION -- ##

func handle_nav(delta: float):
	var path = npc_data.schedule.current_path
	if not path: return
	
	# Checks if npc has reached target point
	if global_position.distance_to(path.target_pos) < 0.5:
		if not path.get_next_target():
			_finish_path()
			return
	
	# Calculate movement
	var dir = (path.target_pos - global_position).normalized()
	velocity.x = lerp(velocity.x, dir.x * npc_data.walk_speed, npc_data.walk_accel * delta)
	velocity.z = lerp(velocity.z, dir.z * npc_data.walk_speed, npc_data.walk_accel * delta)
	
	# Rotation
	look_at_node.look_at(path.target_pos)
	global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 6.0 * delta)

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

#func handle_nav(delta: float):
	##print("NPC walking towards %s, currently at %s [approx. %s away]" % [current_path.target_pos, global_position, global_position.distance_to(current_path.target_pos)])
	#if npc_data.schedule.current_path:
		#var current_path = npc_data.schedule.current_path
		#if global_position.distance_to(current_path.target_pos) > 1.5:
			#
			#if not current_path.interactable_while_walking and interactable:
				#interactable = false
				##interact_area.interact_text = ""
			#
			##nav_agent.target_position = current_path.target_pos
			#
			#var dir = (current_path.target_pos - global_position).normalized()
			#
			#look_at_node.look_at(current_path.target_pos) # - Maybe a way to lerp/interpolate this?
			#global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 6.0 * delta)
			#
			### Walking
			#velocity = velocity.lerp(dir * npc_data.walk_speed, npc_data.walk_accel * delta)
			#
		#else:
			#current_path.set_position()
			#if current_path:
				#nav_agent.target_position = current_path.target_pos
		##finish_path()
	#else:
		#state = IDLE
#
#func set_path(_path: PathData):
	#if _path:
		#_path.set_position()
		#EventBus.path_finished.connect(_finish_path)
		#
		#if _path.start_pos:
			#global_position = _path.start_pos
		#
		#if _path.start_rot:
			#global_rotation.y = _path.start_rot
		#
		#print("Setting path for %s. Start pos is %s, actual pos is %s" % [npc_data.name,_path.start_pos, position])

func set_next_path(_path: PathData):
	#print("NPC setting next path")
	if _path:
		var current_path = npc_data.schedule.current_path
		for path in npc_data.schedule.current_routine:
			if current_path == path:
				if path != npc_data.schedule.current_routine[-1]:
					var path_index = npc_data.schedule.current_routine.find(path)
					if not current_path.wait_for_player:
						state = WALK
					set_path(npc_data.schedule.current_routine[path_index + 1])
					return
				else:
					if is_instance_valid(anim):
						anim.stop()
					state = "idle"
					state = IDLE
					print("%s finished their routine for the day" % npc_data.name)
					return

## Stops anims, sets states, resets rotation (not entirely sure why I put that there)
#func _finish_path(_npc: NPCData, _path: PathData):
	#print("npc.gd: %s stopped walking" % npc_data.name)
	#if _npc != npc_data:
		#return
	#state = IDLE
	#
	#npc_data.waiting_for_player = npc_data.schedule.current_path.wait_for_player
	#
	#set_next_path(npc_data.schedule.current_path)

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
