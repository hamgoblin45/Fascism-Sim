extends Node

# References to Actors
@export var officer_major_npc: NPC
@export var officer_grunt_1: NPC # Searcher
@export var officer_grunt_2: NPC # Back door guard
@export var fugitive_npc: NPC
@export var merchant_npc: NPC

# Locations
@export var spawn_marker: Node3D
@export var door_marker: Node3D
@export var back_door_marker: Node3D
@export var side_yard_marker: Node3D # NEW: The corner they must walk around
@export var leave_marker: Node3D

var current_visitor: NPC = null
var raid_party_arrived_count: int = 0

func _ready() -> void:
	EventBus.visitor_arrived.connect(_on_visitor_arrived)
	EventBus.door_opened_for_visitor.connect(_on_door_opened)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.visitor_leave_requested.connect(_send_npc_away)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_visit_officer"): 
		start_raid_arrival() # Updated to call the squad logic
	elif event.is_action_pressed("debug_visit_fugitive"): 
		start_visit(fugitive_npc)
	elif event.is_action_pressed("debug_visit_merchant"): 
		start_visit(merchant_npc)

# --- SOLO VISITOR LOGIC ---

func start_visit(npc: NPC) -> void:
	if current_visitor != null: return
	if not spawn_marker or not door_marker: return

	print("VisitorManager: Starting visit for %s" % npc.npc_data.name)
	current_visitor = npc
	
	npc.global_position = spawn_marker.global_position
	npc.show()
	npc.process_mode = Node.PROCESS_MODE_INHERIT
	var points: Array[Vector3] = []
	points.append(door_marker.global_position)
	
	var path = _create_visit_path(spawn_marker.global_position, points)
	npc.set_override_path(path)

# --- RAID PARTY LOGIC ---

func start_raid_arrival() -> void:
	if current_visitor != null: return
	print("VisitorManager: DISPATCHING RAID SQUAD")
	
	raid_party_arrived_count = 0
	current_visitor = officer_major_npc
	
	# 1. Spawn Everyone
	var squad = [officer_major_npc, officer_grunt_1, officer_grunt_2]
	var offset = Vector3(0,0,0)
	
	for member in squad:
		if member:
			member.global_position = spawn_marker.global_position + offset
			member.show()
			member.process_mode = Node.PROCESS_MODE_INHERIT
			offset += Vector3(1, 0, 1)

	# 2. Assign Paths
	# Major -> Front Door
	var major_path = _create_visit_path(officer_major_npc.global_position, [door_marker.global_position])
	officer_major_npc.set_override_path(major_path)
	
	# Grunt 1 -> Front Door Side
	var grunt1_pos = door_marker.global_position + (door_marker.basis.x * 1.5) + (door_marker.basis.z * 1.0)
	var grunt1_path = _create_visit_path(officer_grunt_1.global_position, [grunt1_pos])
	officer_grunt_1.set_override_path(grunt1_path)
	
	# Grunt 2 -> Side Yard -> Back Door
	if back_door_marker:
		var points: Array[Vector3] = []
		
		# If we defined a corner waypoint, go there first
		if side_yard_marker:
			points.append(side_yard_marker.global_position)
			
		points.append(back_door_marker.global_position)
		
		var grunt2_path = _create_visit_path(officer_grunt_2.global_position, points)
		officer_grunt_2.set_override_path(grunt2_path)

# --- UTILS ---

func _create_visit_path(start: Vector3, target_points: Array[Vector3]) -> PathData:
	var new_path = PathData.new()
	new_path.start_pos = start
	new_path.points = target_points # Assign the list of points
	new_path.wait_for_player = true 
	new_path.anim_on_arrival = "Idle"
	return new_path

# --- ARRIVAL HANDLING ---

func _on_visitor_arrived(npc: NPC) -> void:
	# If it's a Raid Member
	if npc == officer_major_npc or npc == officer_grunt_1:
		raid_party_arrived_count += 1
		npc.look_at_target(door_marker) # Face door
		
		# Wait for both front-door officers to arrive
		if raid_party_arrived_count >= 2:
			print("VisitorManager: Raid Party in position. Starting Sequence.")
			EventBus.raid_starting.emit()
			# We don't despawn them or send them away yet, RaidSequence takes control now
	
	elif npc == officer_grunt_2:
		print("VisitorManager: Backup positioned at back door.")
		npc.look_at_target(back_door_marker) # Face back door

	elif npc == current_visitor:
		# Normal Visitor
		print("VisitorManager: %s has arrived." % npc.npc_data.name)
		npc.spawn_bark("Knock knock!")
		npc.look_at_target(GameState.player)
		npc.interactable = true 


func _on_door_opened() -> void:
	if current_visitor and is_instance_valid(current_visitor):
		GameState.talking_to = current_visitor
		# Determine which timeline to play
		var timeline = "default_visitor"
		
		if current_visitor == fugitive_npc:
			timeline = "fugitive_at_door"
		elif current_visitor == merchant_npc:
			timeline = "merchant_at_door"
			
		print("VisitorManager: Door opened, starting dialogue: ", timeline)
		DialogueManager.start_dialogue(timeline, current_visitor.npc_data.name)

# ... (Keep _on_dialogue_ended, _handle_post_visit_logic, etc. from previous response) ...
func _on_dialogue_ended() -> void:
	if GameState.shopping:
		print("VisitorManager: Dialogue ended, but shopping active. Keeping visitor.")
		return

	if current_visitor and not GameState.raid_in_progress:
		_handle_post_visit_logic(current_visitor)

func _handle_post_visit_logic(npc: NPC) -> void:
	if npc == fugitive_npc:
		if GameState.world_flags.get("accepted_fugitive", true):
			_convert_to_guest(npc)
			current_visitor = null
			return

	print("VisitorManager: Visit complete. NPC leaving.")
	_send_npc_away()

func _send_npc_away() -> void:
	if not current_visitor or not is_instance_valid(current_visitor):
		return
	var npc = current_visitor
	var points: Array[Vector3] = []
	points.append(leave_marker.global_position)
	var path = _create_visit_path(npc.global_position, points)
	npc.set_override_path(path)
	await get_tree().create_timer(10.0).timeout
	npc.release_from_override() 
	current_visitor = null

func _convert_to_guest(npc: NPC) -> void:
	print("VisitorManager: Convert to guest run")
	# Release them from their door-waiting override path
	npc.release_from_override()
	GuestManager.make_guest(npc)
