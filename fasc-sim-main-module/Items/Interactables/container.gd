extends Node3D

@export var container_inventory: InventoryData
@export var concealment_score: float = 0.5
@onready var interactable: Interactable = $Interactable

var is_open: bool = false

func _ready():
	interactable.interacted.connect(_on_interacted)

func _on_interacted(type: String, engaged: bool):
	# We only care about the initial press of the Interact key
	if type == "interact" and engaged:
		_toggle_container()

func _toggle_container():
	if is_open:
		_close()
	else:
		_open()

func _open():
	is_open = true
	print("Opening container")
	
	# Switch Input Mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.ui_open = true
	
	# Send data to Inventory Manager/UI
	EventBus.setting_external_inventory.emit(container_inventory)
	EventBus.force_ui_open.emit(true) # Ensures Manager knows UI is open

func _close():
	is_open = false
	
	# Reset Input Mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.ui_open = false
	
	# Clear external inventory
	EventBus.setting_external_inventory.emit(null)
	EventBus.force_ui_open.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open: return
	
	# Close if interact, inventory toggle, or escape is pressed
	if event.is_action_pressed("interact") or event.is_action_pressed("open_interface") or event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if is_open:
		var dist = global_position.distance_to(GameState.player.global_position)
		if dist > 3.0: # 3.0 meters is usually a good reach distance
			_close()
