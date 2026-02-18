extends CharacterBody3D
class_name NPC

@export var npc_data: NPCData

@export_group("AI Settings")
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_enabled: bool = true
var interactable: bool = true

@onready var interact_area: Interactable = $Interactable
@onready var look_at_node: Node3D = $LookAtNode
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var bark_anchor: Node3D = $BarkAnchor

@export_group("Vision Settings")
@export var vision_range: float = 10.0
@export var vision_angle: float = 60.0
@onready var vision_ray: RayCast3D = %VisionRay

# Animation
var anim: AnimationPlayer
@onready var head: Node3D = $Head
var looking_at: Node3D

# State Machine
enum {IDLE, WALK, WAIT, ANIMATING, FOLLOWING, COMMAND_MOVE}
var state = IDLE
var prev_state

# Pathing & Overrides
var is_under_command: bool = false 
var override_path_active: bool = false 
var dynamic_target_pos: Vector3 = Vector3.ZERO
var active_path: PathData = null # Local reference for current movement

const BARK_BUBBLE = preload("uid://cxosfcljv24w3")

signal destination_reached

func _ready() -> void:
	EventBus.minute_changed.connect(_on_time_updated)
	EventBus.world_changed.connect(_on_world_changed)
	EventBus.item_interacted.connect(_on_interact)
	EventBus.follow_player.connect(follow_player)
	
	await get_tree().process_frame 
	_check_schedule(GameState.hour, GameState.minute)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor() and gravity_enabled:
		velocity.y -= gravity * delta
	
	# Look At
	if is_instance_valid(looking_at):
		look_at_node.look_at(looking_at.global_position)
		global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.1)

	_handle_state(delta)
	move_and_slide()

# --- PATHING & SCHEDULES ---

func _on_time_updated(h: int, m: int):
	if not is_under_command and not override_path_active:
		_check_schedule(h, m)

func _check_schedule(h: int, m: int):
	if not npc_data or not npc_data.schedule: return
	
	var new_path = npc_data.schedule.get_path_for_time(h, m)
	# Compare against our local active_path
	if new_path and new_path != active_path:
		print("NPC %s: Schedule updated, new path found." % npc_data.name)
		active_path = new_path
		active_path.reset_path()
		set_path(active_path)

func set_path(path: PathData):
	active_path = path
	
	if path and path.get_next_target():
		state = WALK
		if path.start_pos != Vector3.ZERO:
			global_position = path.start_pos
	else:
		state = IDLE

# NEW: Dynamic Visit Path
func set_override_path(path: PathData):
	print("NPC %s: Starting Override Path (Visitor Mode)" % npc_data.name)
	override_path_active = true
	interactable = false 
	
	# FIX: Assign to local variable, ignoring schedule entirely
	active_path = path
	active_path.reset_path()
	
	# Manually trigger start
	state = WALK
	
func release_from_override():
	override_path_active = false
	active_path = null 
	interactable = true
	_check_schedule(GameState.hour, GameState.minute) 
	print("NPC %s released from override, resuming schedule." % npc_data.name)

func _finish_path():
	print("%s reached end of path." % npc_data.name)
	
	if active_path and active_path.anim_on_arrival != "":
		state = ANIMATING
		# anim.play(active_path.anim_on_arrival)
	else:
		state = IDLE
	
	interactable = true
	if active_path:
		npc_data.waiting_for_player = active_path.wait_for_player
	
	if override_path_active:
		print("NPC %s: Override Path Complete." % npc_data.name)
		EventBus.visitor_arrived.emit(self)
	
	EventBus.path_finished.emit(npc_data, active_path)

# --- MOVEMENT LOGIC ---

func _handle_state(delta):
	match state:
		IDLE, ANIMATING:
			velocity.x = move_toward(velocity.x, 0, 2.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 2.0 * delta)
		
		WALK:
			if not get_tree().paused:
				_handle_schedule_nav(delta)
		
		COMMAND_MOVE:
			_handle_dynamic_nav(delta)

func _handle_schedule_nav(delta: float):
	# Use local active_path variable
	if not active_path: 
		state = IDLE
		return
		
	var current_target = active_path.get_current_target()
	if current_target == Vector3.ZERO: 
		_finish_path()
		return

	if global_position.distance_to(current_target) < 1.0:
		if not active_path.advance_to_next():
			_finish_path()
			return
	
	_move_and_rotate(global_position.direction_to(current_target), 9.0, delta)

func _handle_dynamic_nav(delta: float):
	if global_position.distance_to(dynamic_target_pos) < 1.0:
		state = IDLE
		destination_reached.emit()
		return
	
	# Simple direct movement for command mode
	var dir = global_position.direction_to(dynamic_target_pos)
	_move_and_rotate(dir, 9.0, delta)

func _move_and_rotate(dir: Vector3, speed: float, delta: float):
	velocity.x = lerp(velocity.x, dir.x * speed, 15.0 * delta)
	velocity.z = lerp(velocity.z, dir.z * speed, 15.0 * delta)
	look_at_node.look_at(global_position + dir)
	global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 5.0 * delta)

# --- COMMANDS ---

func command_move_to(target: Vector3):
	is_under_command = true
	dynamic_target_pos = target
	state = COMMAND_MOVE

func command_stop():
	is_under_command = false
	state = IDLE
	velocity = Vector3.ZERO

# --- VISION (RESTORED) ---

func look_at_target(target):
	looking_at = target

func _can_see_target(target_node: Node3D) -> bool:
	if not is_instance_valid(target_node): return false
	
	var _target_pos = target_node.global_position
	if target_node is NPC: 
		_target_pos.y += 2.2 # Look up at head
	
	# Distance Check
	if global_position.distance_to(_target_pos) > vision_range:
		return false
	
	# Angle Check
	var dir = global_position.direction_to(_target_pos)
	var fwd = -global_transform.basis.z
	var angle_dot = fwd.dot(dir)
	var angle_threshold = cos(deg_to_rad(vision_angle))
	
	if angle_dot < angle_threshold:
		return false
	
	# Raycast Check
	if not vision_ray: return false
	
	vision_ray.enabled = true
	vision_ray.target_position = vision_ray.to_local(_target_pos)
	vision_ray.force_raycast_update()
	
	var can_see = false
	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		if collider == target_node or collider.get_parent() == target_node:
			can_see = true
	
	vision_ray.enabled = false
	return can_see

# --- INTERACTION & EVENTS ---

func _on_world_changed(flag_name: String, value: bool):
	if npc_data and npc_data.schedule:
		npc_data.schedule.current_path = null
		_check_schedule(GameState.hour, GameState.minute)

func _on_interact(object: Interactable, interact_type: String, engaged: bool):
	if object != interact_area or not engaged: return
	if interact_type == "interact":
		_handle_interaction()

func _handle_interaction():
	if npc_data.bark_only:
		_play_context_bark()
	else:
		_start_context_dialogue()

func _start_context_dialogue():
	if not interactable: return
	GameState.talking_to = null
	var timeline_to_play = npc_data.default_timeline
	for flag in npc_data.condition_timelines.keys():
		if GameState.world_flags.get(flag, false) == true:
			timeline_to_play = npc_data.condition_timelines[flag]
			break
	if timeline_to_play != "":
		DialogueManager.start_dialogue(timeline_to_play, npc_data.name)
		GameState.talking_to = self
	else:
		_play_context_bark()

func _play_context_bark():
	var bark_lines = npc_data.conditional_barks.get("default", [])
	if bark_lines.is_empty(): return
	spawn_bark(bark_lines.pick_random())

func spawn_bark(text: String):
	var bubble = BARK_BUBBLE.instantiate()
	get_tree().root.add_child(bubble)
	bubble.global_position = bark_anchor.global_position
	bubble.setup(text, Color.WHITE)

func follow_player(follow_npc: NPC, follow: bool):
	if follow_npc != self: return
	if follow:
		prev_state = state
		state = FOLLOWING
		GameState.leading_npc = self
	else:
		state = prev_state
		GameState.leading_npc = null
