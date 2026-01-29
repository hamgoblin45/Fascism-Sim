extends Node3D

@export var container_inventory: InventoryData
@onready var interactable: Interactable = $Interactable


func _ready():
	interactable.interacted.connect(_interact)

func _interact(type: String, engaged: bool):
	match [type, engaged]:
		["interact", true]:
			print("Player is trying to open a container")
