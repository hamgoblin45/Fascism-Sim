extends PanelContainer

var inventory_data: InventoryData
var slot_data

@export var item_name: Label
@export var item_descript: RichTextLabel
@export var item_flavor_text: RichTextLabel
@export var trash_button: Button
@export var use_button: Button
@export var split_button: Button

var mouse_on_ui: bool = false

func _ready() -> void:
	#EventBus.select_item.connect(_set_context_menu)
	EventBus.dialogue_started.connect(_set_button_to_give)
	EventBus.dialogue_ended.connect(_set_button_to_use)

func set_context_menu(slot: InventorySlotData):
	if not slot or not slot.item_data:
		hide()
		return
	show()
	slot_data = slot
	print("Setting item context menu in inventory")
	item_name.text = slot_data.item_data.name
	item_descript.text = slot_data.item_data.description
	item_flavor_text.text = slot_data.item_data.flavor_text
	
	if slot_data.item_data.stackable and slot_data.quantity > 1:
		split_button.show()
	if slot_data.item_data.useable:
		use_button.show()
		if GameState.shopping:
			use_button.text = "SELL"
		else:
			_set_button_to_use()


func _clear_out_context_ui():
	slot_data = null
	hide()

func _set_button_to_give():
	use_button.text = "GIVE"

func _set_button_to_use():
	use_button.text = "USE"

func _on_trash_button_pressed() -> void:
	EventBus.removing_item.emit(slot_data)
	_clear_out_context_ui()

func _on_use_button_pressed() -> void:
	match use_button.text:
		"USE":
			EventBus.item_used.emit(slot_data)
		"GIVE":
			EventBus.giving_item.emit(slot_data)
		"SELL":
			EventBus.selling_item.emit(slot_data)

func _on_split_button_pressed() -> void:
	EventBus.open_split_stack_ui.emit(slot_data)
	print("Split button pressed on Context Menu")

func _on_hide_details_button_pressed() -> void:
	_clear_out_context_ui()
