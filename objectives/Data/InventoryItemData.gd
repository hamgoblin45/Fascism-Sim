extends Resource
class_name InventoryItemData

@export var name: String = ""
@export var id: String = ""
@export var texture: Texture2D
@export var description: String = ""
@export var flavor_text: String = ""

@export var stackable: bool
@export var max_stack_size: int = 99
@export var useable: bool
