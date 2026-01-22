extends Node


var suspicion: float = 20.0
var resistance: float = 10.0


var npcs: Array[Dictionary] = [{
	"id": "test_npc",
	"hope": 0.0 # NPC hope will be used to impact dialogue and the NPC's helpfulness, but also impacts the Resistance each day
}]
