extends Resource
class_name InventoryItemData

@export var name: String = ""
@export var id: String = ""
@export var texture: Texture2D
@export var description: String = ""
@export var flavor_text: String = ""

@export var buy_value: float = 0.0
@export var sell_value: float = 0.0

@export var concealability: float = 0.0 # 0 - 5 w/ 5 most concealable and 0 the least
@export var contraband_level: int = 0 # 0 - Legal, 1 - Frowned Upon, 2 - Prohibited, 3 - Strictly Illegal, etc

#@export var size: int = 0 # 0 - 5 w/ 5 being largest
@export var stackable: bool
@export var max_stack_size: int = 99
@export var useable: bool

@export var equipped_scene: PackedScene # The mesh that is "held" when an item is equipped
