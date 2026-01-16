extends Node3D

## NPC DATAS
#const AMY_DATA = preload("res://Characters/Amy/amy_npc_data.tres")
#const EDD_DATA = preload("res://Characters/Edd/edd_npc_data.tres")
#const GREG_DATA = preload("res://Characters/Greg/greg_npc_data.tres")
##const HEATHER_DATA = preload()
#const TEDDY_DATA = preload("res://Characters/Teddy/teddy_npc_data.tres")
#const ZEB_DATA = preload("res://Characters/Zeb/zeb_npc_data.tres")
@export var emails: Array[EmailData]
## NPC SCENES

## NPC NODES
@onready var amy_npc: NPC = $AmyNPC
@onready var edd_npc: NPC = $EddNPC
@onready var teddy_npc: NPC = $TeddyNPC
@onready var zeb_npc: NPC = $ZebNPC
@onready var greg_npc: NPC = $GregNPC
@onready var heather_npc: NPC = $HeatherNPC
@onready var hiro_npc: NPC = $HiroNPC
@onready var yancy_npc: NPC = $YancyNPC
@onready var vivian_npc: NPC = $VivianNPC


var npcs = []

## Sets a global var with reference to self for use from other scripts
func _ready() -> void:
	Global.npc_manager = self
	npcs = [teddy_npc, amy_npc, edd_npc, zeb_npc, greg_npc, heather_npc, hiro_npc, yancy_npc, vivian_npc]
	instance_nodes()

## Calls instance_node from npc_node.gd
func instance_nodes():
	for npc in npcs:
		npc.instance_npc()

func handle_schedules():
	for npc in npcs:
		if npc.current_path and npc.current_path.start_time > 0 \
		and GameTime.time >= npc.current_path.start_time \
		and npc.state != npc.WALK \
		and not npc.npc_data.waiting_for_player:
			print("%s started walking based off handle_schedules in NPC Manager" % npc.npc_data.name)
			#npc.walk_path()
			npc.state = npc.WALK
		## If npc_data's current map changes, queue_free the node and vice versa
		## Maybe also include state / anim control here? 

#func handle_npc_dialogue():
	#for npc in npcs:
		#npc.npc_data.select_dialogue()

func handle_text_messages():
	for npc in npcs:
		var npc_already_has_thread: bool
		
		for thread in Player.text_message_threads:
			
			if npc.npc_data == thread.npc_data:
				npc_already_has_thread = true
				#print("NPC %s data matches that of a thread in Player.text_message_threads" % npc.npc_data.name)
				check_existing_thread_for_messages_to_send(npc.npc_data, thread)
					
		if npc.npc_data.all_texts.size() > 0 and not npc_already_has_thread:
			
			check_if_new_thread_needed(npc.npc_data)
			

func check_existing_thread_for_messages_to_send(npc_data: NPCData, thread: TextThreadData) -> bool:
	for text_data in npc_data.all_texts:
		if not thread.text_messages.has(text_data):
			#print("Text doesn't already have message")
			if text_data.req_current_objective:
				if Objectives.current_objectives.has(text_data.req_current_objective):
					# - also check opinion reqs and time if they exist, then only send if they don't or they are met
					# - do this for every "elif" below
					print("Player has req objective, sending text")
					Player.receive_text_message(npc_data, text_data)
					return true
					
			elif text_data.req_completed_objective:
				if Objectives.completed_objectives.has(text_data.req_completed_objective):
					# - Check everything here
					print("Player has complete objective, sending text")
					Player.receive_text_message(npc_data, text_data)
					return true
			
			elif text_data.opinion_min and npc_data.opinion >= text_data.opinion_min\
			or text_data.opinion_max and npc_data.opinion <= text_data.opinion_max:
				# - check against time here
				print("Player has req opinion, sending text")
				Player.receive_text_message(npc_data, text_data)
				return true
				
			
			# - Time based
			elif text_data.send_time and text_data.send_day == GameTime.day and text_data.send_time <= GameTime.time:
				print("Time met,sending text")
				Player.receive_text_message(npc_data, text_data)
				return true
	return false

func check_if_new_thread_needed(npc_data: NPCData) -> bool:
	for text_data in npc_data.all_texts:
		if text_data.req_current_objective:
			if Objectives.current_objectives.has(text_data.req_current_objective):
				print("Player has req objective, creating new thread and sending text")
				create_new_text_thread(npc_data, text_data)
				return true
		
		elif text_data.req_completed_objective:
			if Objectives.completed_objectives.has(text_data.req_completed_objective):
				print("Player has complete objective, creating thread and sending text")
				create_new_text_thread(npc_data, text_data)
				return true
				
		elif text_data.opinion_min and npc_data.opinion >= text_data.opinion_min\
		or text_data.opinion_max and npc_data.opinion <= text_data.opinion_max:
			print("Player has req opinion, creating thread and sending text")
			create_new_text_thread(npc_data, text_data)
			return true
			
		
		elif text_data.send_time and text_data.send_day == GameTime.day and text_data.send_time <= GameTime.time:
			print("Time met, creating thread and sending text")
			create_new_text_thread(npc_data, text_data)
			return true
			
	return false

func create_new_text_thread(npc_data: NPCData, text_data: TextMessageData):
	var new_thread = TextThreadData.new()
	new_thread.npc_data = npc_data
	new_thread.npc_name = npc_data.name
	#new_thread.text_messages.append(text_data)
	Player.text_message_threads.append(new_thread)
	Player.receive_text_message(npc_data, text_data)
	return

func handle_emails():
	for email in emails:
		if Player.received_emails.has(email):
			return
		
		if email.send_time and email.send_day == GameTime.day and email.send_time <= GameTime.time:
			Player.receive_email(email)
			print("sending email %s" % email)
#
func _on_schedule_check_timer_timeout() -> void:
	#print("Hande Schedule Timer timeout in NPC manager")
	handle_schedules()
	#handle_npc_dialogue()
	handle_text_messages()
	handle_emails()
