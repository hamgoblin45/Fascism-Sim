extends PanelContainer

var slot_data: InventorySlotData

@onready var split_slider: HSlider = %SplitSlider
@onready var split_qty: Label = %SplitQty

var mouse_on_ui: bool



func _ready() -> void:
	EventBus.open_split_stack_ui.connect(_set_split_ui)


func _set_split_ui(slot: InventorySlotData):
	show()
	slot_data = slot
	split_qty.text = "%s/%s" % [str(split_slider.value), str(slot.quantity)]
	split_slider.max_value = slot.quantity
	split_slider.value = 0

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_pressed() \
	and event is InputEventMouseButton and not mouse_on_ui \
	or Input.is_action_just_pressed("back"):
		hide()

func _on_split_button_pressed() -> void:
	EventBus.splitting_item_stack.emit(slot_data, split_slider.value)
	hide()


func _on_split_slider_value_changed(value: float) -> void:
	split_qty.text = "%s/%s" % [str(value), str(slot_data.quantity)]


func _on_mouse_exited() -> void:
	mouse_on_ui = false


func _on_mouse_entered() -> void:
	mouse_on_ui = true
