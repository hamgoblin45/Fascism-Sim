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

@onready var interact_area: Interactable = $InteractArea
@onready var proximity_detect_area: Area3D = $ProximityDetectArea

var start_basis
var target_basis
var target_pos: Vector3

signal finished_path(Curve3D)
signal stopped_talking()



func _ready() -> void:
	## sets NPC data from NPC Node (the one on PathFollows), interact/path/dialog signals
	current_path = null
	schedule = null
	interact_area.interacted.connect(interact_with_npc)
	npc_data.update_dialogue.connect(update_dialogue)
	
	set_global_npc()
	
	npc_data.select_dialogue()
	if npc_data.schedule:
		schedule = npc_data.schedule
		
		schedule.set_routine() # This is a func in the data
		set_path(schedule.current_path)
		
		if schedule.current_path:
			var map = schedule.current_path.start_map
			npc_data.current_map = schedule.current_path.start_map
		
			if map != "" and map != Global.current_map_name:
				for child in npc_mesh.get_children():
					child.queue_free()
					gravity_enabled = false
			
				print("%s NPC: Spawning on %s based off schedule/path data in NPC Node" % [npc_data.name, map])
			## Instances NPC if they are entering current map
			if map == Global.current_map_name:
				instance_npc()
				print("%s instancing on current map, instancing based off change_map in NPC.gd" % npc_data.name)
		
		schedule.setting_path.connect(set_path)
		schedule.finishing_routine.connect(change_map)
		
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
	if npc_data.waiting_for_player and player_nearby and not Global.in_dialogue:
		interact_with_npc()

	update_anim_tree()
	handle_state(delta)


## -- SET NPC -- ##

func set_global_npc():
#for node in get_children():
	#if node is NPC:
	match npc_data.name:
		"Teddy":
			Global.teddy_node = self
			#print("Setting Global teddy node")
		"Zeb":
			Global.zeb_node = self
		"Amy":
			Global.amy_node = self
		"Edd":
			Global.edd_node = self
		"Greg":
			Global.greg_node = self
		"Heather":
			Global.heather_node = self
		"Hiro":
			Global.hiro_node = self
		"Yancy":
			Global.yancy_node = self
		"Vivian":
			Global.vivian_node = self

func instance_npc():
	for child in npc_mesh.get_children():
		child.queue_free()
	if npc_data.current_map == Global.current_map_name:
		
		
		
		print("npc_node.gd: Instancing %s, is on current map" % npc_data.name)
		
		if npc_data.mesh:
			var new_mesh = npc_data.mesh.instantiate()
			npc_data.instance = new_mesh
		
			npc_mesh.add_child(new_mesh)
			mesh = new_mesh
			
		else:
			print("Generic mesh set for %s" % npc_data.name)
			var generic_mesh = preload("res://Characters/blank_npc_model.glb").instantiate()
			npc_mesh.add_child(generic_mesh)
			mesh = generic_mesh
		
		
		if npc_data.current_dialogue_data:
			interact_area.interact_text = "Press E to talk"
		
		set_anim_player()
		
		anim_tree.anim_player = anim.get_path()
		
		gravity_enabled = true

func set_anim_player():
	for child in mesh.get_children(true):
		if child is AnimationPlayer:
			
			anim = child
			anim.animation_finished.connect(_on_anim_animation_finished)
			print("anim set: child")
			return
		for _child in child.get_children(true):
			if child is AnimationPlayer:
			
				anim = child
				anim.animation_finished.connect(_on_anim_animation_finished)
				print("anim set: _child")
				return
			for c in _child.get_children(true):
				if c is AnimationPlayer:
				
					anim = c
					anim.animation_finished.connect(_on_anim_animation_finished)
					print("anim set: c")
					return
	print("NO ANIM PLAYER SET, something went wrong")

## -- STATE MACHINE -- ##

# Sets new anims and blends them; from tutorial. Add more lines for each unique blend
func update_anim_tree():
	if walk_blend_value != prev_walk_blend_value:
		anim_tree["parameters/walk/blend_amount"] = walk_blend_value
		prev_walk_blend_value = walk_blend_value

# Sets animations (or tries to) based on state. From tutorial. Designed to work with AnimationTree
# Perhaps tracking path progress should be its own func
func handle_state(delta):
	
	match state:
		
		IDLE:
			
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)
			sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
			
			velocity = Vector3.ZERO
			
			if npc_data.waiting_for_player and looking_at != Global.player:
				looking_at = Global.player
				#look_at_target(Global.player)
		
		WALK:
			#print("I'M WALKIN' HERE!")
			if not get_tree().paused:
				walk_blend_value = lerpf(walk_blend_value, 1, blend_speed * delta)
				sit_blend_value = lerpf(sit_blend_value, 0, blend_speed * delta)
				
				move_and_slide()
				handle_nav(delta)
		
		TALK:
			#if not looking_at:
				#look_at_target(Global.player)
			if not anim.is_playing():
				anim.play("Talk1")
			#global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 0.75 * delta)
		
		SIT:
			sit_blend_value = lerpf(sit_blend_value, 1, blend_speed * delta)
			walk_blend_value = lerpf(walk_blend_value, 0, blend_speed * delta)

# Used by self_made state machine (func set_state) but also used to play one-off anims
func play_anim(anim_name: String):
	anim.stop()
	if anim.has_animation(anim_name):
		anim.play(anim_name)
	else:
		print("%s does not have animation named '%s'" % [npc_data.name, anim_name])

## -- NAVIGATION -- ##

func handle_nav(delta: float):
	#print("NPC walking towards %s, currently at %s [approx. %s away]" % [current_path.target_pos, global_position, global_position.distance_to(current_path.target_pos)])
	if current_path:
		if global_position.distance_to(current_path.target_pos) > 1.5:
			
			if not current_path.interactable_while_walking and interactable:
				interactable = false
				interact_area.interact_text = ""
			
			#nav_agent.target_position = current_path.target_pos
			
			var dir = (current_path.target_pos - global_position).normalized()
			
			look_at_node.look_at(current_path.target_pos) # - Maybe a way to lerp/interpolate this?
			global_rotation.y = lerp_angle(global_rotation.y, look_at_node.global_rotation.y, 6.0 * delta)
			
			velocity = velocity.lerp(dir * Settings.npc_walk_speed, Settings.npc_walk_accel * delta)
			
		else:
			#print("SHOULD BE SETTING NEXT POSITION IN PATH")
			
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
	
	if is_instance_valid(anim):
		anim.stop()
		if current_path.anim:
			play_anim(current_path.anim)
			return
	
	
	#rotation.y = current_path.end_rotation
	if current_path.next_map:
		change_map(current_path.next_map)
	npc_data.waiting_for_player = current_path.wait_for_player
	
	if npc_data.current_dialogue_data:
		interactable = true
		interact_area.interact_text = "Press E to talk"
	
	
		
	set_next_path(current_path)
	
	
	#schedule._set_path()
	


## -- INTERACTION -- ##

# Initiated by pressing E on an NPC or entering its detect area while its waiting for player
# Currently just initiates dialogue, may have other uses later (trading, etc)
func interact_with_npc():
	if interactable:
		print("npc.gd: Player interacted with %s" % npc_data.name)
		
		## Talk to NPC
		#if npc_data.current_dialogue_data:
			#handle_dialogue(npc_data.current_dialogue_data.selected_title.title)
		if npc_data.current_dialogue_data:
			handle_dialogue(npc_data.current_dialogue_data)
			
			

func handle_dialogue(dialogue_data: DialogueData):
	state = TALK
	
	Global.player.HEADBOB_ANIMATION.stop()
	
	#Global.ui_open = true
	
	## Create a generic blurb that shows up, sets talking state, and then goes away and resets to whatever it was before
	if dialogue_data is GenericDialogueData:
		print("Dialog is generic, showing simple blurb")
		if dialogue_data.line_options.size() > 0:
			dialogue_data.line = dialogue_data.line_options.pick_random()
		dialogue_blurb.show_text(npc_data.current_dialogue_data.line)
	
	else:
		var sheet_id = dialogue_data.sheet_id
		## Transfer global vars to the dialog for use via MadTalk
		MadTalkGlobals.set_variable("player_name", Player.player_name)
		MadTalkGlobals.set_variable("player_hp", Player.health)
		MadTalkGlobals.set_variable("player_energy", Player.energy)
		MadTalkGlobals.set_variable("money", Player.money)
		
		MadTalkGlobals.set_variable("crafting_lvl", Player.crafting_lvl)
		MadTalkGlobals.set_variable("cooking_lvl", Player.cooking_lvl)
		MadTalkGlobals.set_variable("nature_lvl", Player.nature_lvl)
		MadTalkGlobals.set_variable("charisma_lvl", Player.charisma_lvl)
		MadTalkGlobals.set_variable("stamina_lvl", Player.stamina_lvl)
		MadTalkGlobals.set_variable("survival_lvl", Player.survival_lvl)
		MadTalkGlobals.set_variable("mining_lvl", Player.mining_lvl)
		MadTalkGlobals.set_variable("logging_lvl", Player.logging_lvl)
		MadTalkGlobals.set_variable("gardening_lvl", Player.gardening_lvl)
		MadTalkGlobals.set_variable("fishing_lvl", Player.fishing_lvl)
		
		MadTalkGlobals.set_variable("npc_opinion", npc_data.opinion)
		if Player.equipped_item:
			MadTalkGlobals.set_variable("equipped_item", Player.equipped_item.name)
		
		MadTalkGlobals.set_variable("day", GameTime.day)
		MadTalkGlobals.set_variable("time", GameTime.time)
		MadTalkGlobals.set_variable("weekday", GameTime.weekday)
		MadTalkGlobals.set_variable("weather", GameTime.weather)
		
		# Might need something to check Player's items if that's ever relevant but that's a later problem
		
		## Set all necessary vars to control UI, camera, and pause
		Global.in_dialogue = true
		Global.speaking_to = self
		Player.looking_at = self
		Global.main_viewport.day_night_cycle.timer.stop()
		Global.ui.handle_mouse_mode()
		#Global.player.footsteps_audio.stop()
		get_tree().paused = true
		
		if dialogue_data.selected_sequence:
			Global.dialogue.start_dialog(sheet_id, dialogue_data.selected_sequence.id)
		else:
			Global.dialogue.start_dialog(sheet_id)
		

## If no dialogue data but has dialogue_blurb, does that
	#Global.main_viewport.ui.pause_game()


# Sets the rotation of a Node3D (look_at_node) so that the target lerps in the same rotation to mimic looking at a node
func look_at_target(target):
	if target:
		if looking_at != target:
			looking_at = target
			if target == Global.player:
				looking_at = target.HEAD
		look_at_node.look_at(looking_at.global_position)
	else:
		looking_at = null


## Changes facial expression; only works if they have a seperate face mesh in their model; will cause crash otherwise
#func change_expression(expression: String):
	#match expression:
		#"smile":
			#face_mesh.mesh.surface_set_material(0, preload("res://Characters/Teddy/test_expression_smile.tres"))
		#"serious":
			#face_mesh.mesh.surface_set_material(0, preload("res://Characters/Teddy/test_expression_serious.tres"))

## Resets dialogue-based vars and stops looking at current target
func stop_talking():
	print("npc.gd: %s stopped talking" % self)
	get_tree().paused = false
	if state != WALK:
		state = IDLE
	anim.stop()
	look_at_node.global_rotation.y = 0
	global_rotation.y = 0
	looking_at = null
	Player.looking_at = null
	Global.in_dialogue = false
	Global.speaking_to = null
	Global.ui.handle_mouse_mode()
	
	#Starts time after Mayor's Tour
	if GameTime.day > 1 or Objectives.completed_objectives.has(load("res://Player/Objectives/000_welcome_tour.tres")):
		Global.main_viewport.day_night_cycle.timer.start()
		
	if npc_data.current_dialogue_data.selected_sequence and npc_data.current_dialogue_data.selected_sequence.walk_after_talk:
		state = WALK
	
	#Global.dialogue._on_mad_talk_dialog_finished.disconnect(stop_talking)
	stopped_talking.emit()
	npc_data.current_dialogue_data.set_dialogue()
	npc_data.waiting_for_player = false
	
	
	

# Checks if this node's current dialogue_data matches that of the character_data's, then sets it if not
# Either way, sets the next dialogue line. Usually called by finishing a path or from another dialogue line.
# Will also be set based on Time and conditions in the future
func update_dialogue(new_line: String):
	print("npc.gd: %s's dialogue updated to new line: %s" % [self, npc_data.next_dialogue_title])
	#if dialogue_data != npc_data.dialogue_data:
		#dialogue_data = npc_data.dialogue_data
	#dialogue_title = new_line
	#npc_data.next_dialogue_title = new_line

func change_map(next_map: String):
	npc_data.start_path_time = 0
	npc_data.current_map = next_map
	
	if next_map != "" and next_map != Global.current_map_name:
		for child in npc_mesh.get_children():
			child.queue_free()
			gravity_enabled = false
	
		print("%s NPC: Changing map to %s based off change_map in NPC Node" % [npc_data.name, next_map])
	## Instances NPC if they are entering current map
	if next_map == Global.current_map_name:
		instance_npc()
		print("%s entering current map, instancing based off change_map in NPC.gd" % npc_data.name)


#func remove_npc():
	#if Global.looking_at == self:
		#Global.looking_at = null
	#look_at_target(null)
	#looking_at = null
	#
	#await get_tree().create_timer(0.2).timeout
	#
	#queue_free()











## Detects if Player is nearby
func _on_proximity_detect_area_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		
		player_nearby = true

## Detects when Player is no longer nearby
func _on_proximity_detect_area_body_exited(body: Node3D) -> void:
	if body is PlayerCharacter:
		
		player_nearby = false


func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == current_path.anim:
		print("Anim finished is named in current path")
	#rotation.y = current_path.end_rotation
		if current_path.next_map:
			change_map(current_path.next_map)
		npc_data.waiting_for_player = current_path.wait_for_player
		
		if npc_data.current_dialogue_data:
			interactable = true
			interact_area.interact_text = "Press E to talk"
			
		set_next_path(current_path)
		#set_next_path(current_path)
