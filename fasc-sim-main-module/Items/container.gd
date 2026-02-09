extends Node3D

@export var container_inventory: InventoryData
@onready var interactable: Interactable = $Interactable

var open: bool = false

func _ready():
	interactable.interacted.connect(_interact)

func _interact(type: String, engaged: bool):
	match [type, engaged]:
		["interact", true]:
			if !open:
				EventBus.setting_external_inventory.emit(container_inventory)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				GameState.ui_open = true
				open = true
				print("Player is trying to open a container")
				return
			else:
				_close()
				return

func _close():
	EventBus.setting_external_inventory.emit(null)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.ui_open = false
	open = false

func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	if event.is_action_pressed('interact') or event.is_action_pressed("open_interface") or event.is_action_pressed("pause"):
		_close()

func _physics_process(_delta: float) -> void:
	if not open:
		return
	if global_position.distance_to(GameState.player.global_position) > 8.0:
		_close()
	# Distance check, if too far, close inv
