extends PanelContainer

var slot_data

@onready var item_name: Label = %ItemName
@onready var item_descript: RichTextLabel = %ItemDescript
@onready var item_flavor_text: RichTextLabel = %ItemFlavorText
@onready var trash_button: Button = %TrashButton
@onready var use_button: Button = %UseButton
@onready var split_button: Button = %SplitButton

var mouse_on_ui: bool = false

func _ready() -> void:
	EventBus.open_item_context_menu.connect(_set_context_menu)

func _set_context_menu(slot: InventorySlotData):
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
	
	global_position = Vector2(get_global_mouse_position().x - 200, get_global_mouse_position().y - 180)

func _physics_process(_delta: float) -> void:
	if !visible: return
	if Input.is_action_just_pressed("click") and not mouse_on_ui \
	or Input.is_action_just_pressed("back"):
		hide()

func _on_trash_button_pressed() -> void:
	EventBus.removing_item_from_inventory.emit(slot_data)
	slot_data = null
	hide()



func _on_use_button_pressed() -> void:
	pass # Replace with function body.


func _on_split_button_pressed() -> void:
	EventBus.open_split_stack_ui.emit(slot_data)


func _on_mouse_entered() -> void:
	print("Mouse on Context Menu")
	mouse_on_ui = true


func _on_mouse_exited() -> void:
	print("Mouse left Context Menu")
	mouse_on_ui = false
