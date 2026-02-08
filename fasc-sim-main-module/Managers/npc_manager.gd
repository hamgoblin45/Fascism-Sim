extends Node3D

var npcs = []

## Sets a global var with reference to self for use from other scripts
#func _ready() -> void:
	#instance_nodes()

## Calls instance_node from npc_node.gd
func instance_nodes():
	for npc in npcs:
		npc.instance_npc()

func handle_schedules():
	for npc in npcs:
		if npc.current_path and npc.current_path.start_time > 0 \
		and GameState.time >= npc.current_path.start_time \
		and npc.state != npc.WALK \
		and not npc.npc_data.waiting_for_player:
			print("%s started walking based off handle_schedules in NPC Manager" % npc.npc_data.name)
			#npc.walk_path()
			npc.state = npc.WALK
		## If npc_data's current map changes, queue_free the node and vice versa
		## Maybe also include state / anim control here? 

#
func _on_schedule_check_timer_timeout() -> void:
	#print("Hande Schedule Timer timeout in NPC manager")
	handle_schedules()
