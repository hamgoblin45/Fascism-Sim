extends Node



func _ready():
	EventBus.change_suspicion.connect(_change_suspicion)
	EventBus.change_resistance.connect(_change_resistance)
	EventBus.change_npc_hope.connect(_change_npc_hope)


func _change_suspicion(change_amt: float):
	GameState.suspicion += change_amt
	EventBus.suspicion_changed.emit(GameState.suspicion)

func _change_resistance(change_amt: float):
	GameState.resistance += change_amt
	EventBus.resistance_changed.emit(GameState.resistance)

func _change_npc_hope(npc: String, change_amt: float):
	for c in GameState.npcs:
		if c.has("id") and c.get("id") == npc:
			print("NPC %s match found in _change_npc_hope() in Manager")
			var new_amount = c.get("hope") + change_amt
			c["hope"] = new_amount
			EventBus.npc_hope_changed.emit(npc, new_amount)
			var output_text = "NPC %s hope changed by %s, new hope value is %s" % [npc, str(change_amt), str(c["hope"])]
			EventBus.output.emit(output_text)
