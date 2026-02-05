extends Node3D

@export var container_inventory: InventoryData
@onready var interactable: Interactable = $Interactable

var open: bool = false

func _ready():
	interactable.interacted.connect(_interact)

func _interact(type: String, engaged: bool):
	match [type, engaged]:
		["interact", true]:
			open = true
			EventBus.setting_external_inventory.emit(container_inventory)
			print("Player is trying to open a container")

func _physics_process(delta: float) -> void:
	if not open:
		return
	# Distance check, if too far, close inv
