extends PanelContainer

var slot_data: InventorySlotData

@onready var split_slider: HSlider = %SplitSlider
@onready var split_qty: Label = %SplitQty

var mouse_on_ui: bool



func _ready() -> void:
	EventBus.open_split_stack_ui.connect(_set_split_ui)


func _set_split_ui(slot: InventorySlotData):
	if not slot.item_data.stackable: return
	await get_tree().create_timer(0.01).timeout
	show()
	global_position = Vector2(get_global_mouse_position().x - 150, get_global_mouse_position().y - 90)
	slot_data = slot
	split_qty.text = "%s/%s" % [str(snappedi(split_slider.value,1)), str(slot.quantity)]
	split_slider.max_value = slot.quantity
	split_slider.value = 0

func _physics_process(_delta: float) -> void:
	if !visible: return
	if Input.is_action_just_pressed("click") and not mouse_on_ui \
	or Input.is_action_just_pressed("back"):
		print("Click while split ui is visible and mouse off panel, hiding")
		hide()

func _on_split_button_pressed() -> void:
	EventBus.splitting_item_stack.emit(slot_data, split_slider.value)
	hide()


func _on_split_slider_value_changed(value: float) -> void:
	split_qty.text = "%s/%s" % [str(snappedi(value,1)), str(slot_data.quantity)]


func _on_mouse_exited() -> void:
	print("Mouse left split UI")
	mouse_on_ui = false


func _on_mouse_entered() -> void:
	print("Mouse on split UI")
	mouse_on_ui = true
