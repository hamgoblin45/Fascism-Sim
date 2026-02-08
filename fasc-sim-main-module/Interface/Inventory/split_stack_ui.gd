extends PanelContainer

var slot_data: InventorySlotData
var current_inventory: InventoryData

@onready var split_slider: HSlider = $MarginContainer/VBoxContainer/HBoxContainer/SplitSlider
@onready var split_qty: Label = $MarginContainer/VBoxContainer/HBoxContainer/SplitQty

var mouse_on_ui: bool



func _ready() -> void:
	EventBus.open_split_stack_ui.connect(_set_split_ui)


func _set_split_ui(inv: InventoryData, slot: InventorySlotData):
	if not slot.item_data.stackable: return
	await get_tree().create_timer(0.01).timeout
	show()
	current_inventory = inv
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
	var amount = int(split_slider.value)
	
	if amount <= 0 or amount >= slot_data.quantity:
		hide()
		return
	
	var stack_data = InventorySlotData.new()
	stack_data.item_data = slot_data.item_data
	stack_data.quantity = amount
	
	slot_data.quantity -= int(amount)
	
	var idx = current_inventory.slot_datas.find(slot_data)
	
	EventBus.inventory_item_updated.emit(current_inventory, idx)
	
	EventBus.splitting_item_stack.emit(stack_data)
	hide()


func _on_split_slider_value_changed(value: float) -> void:
	split_qty.text = "%s/%s" % [str(snappedi(value,1)), str(slot_data.quantity)]


func _on_mouse_exited() -> void:
	print("Mouse left split UI")
	mouse_on_ui = false


func _on_mouse_entered() -> void:
	print("Mouse on split UI")
	mouse_on_ui = true
