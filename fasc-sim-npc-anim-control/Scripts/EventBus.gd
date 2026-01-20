extends Node


signal npc_set_state(npc: NPCData, state: String) #IDLE,WALK, TALK, RUN, SIT, etc
signal npc_play_anim(npc: NPCData, anim: String)
