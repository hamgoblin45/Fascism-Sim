extends Node

#Testing signals
signal output(text: String)


signal change_suspicion(change_amount: float)
signal suspicion_changed(new_value: float)

signal change_resistance(change_amount: float)
signal resistance_changed(new_value: float)

signal change_npc_hope(npc_id: String, change_amount: float)
signal npc_hope_changed(npc_id: String, new_value: float)
