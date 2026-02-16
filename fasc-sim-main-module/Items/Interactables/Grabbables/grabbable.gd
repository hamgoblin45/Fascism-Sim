extends RigidBody3D
class_name Grabbable

@export var id: String = ""
@export var slot_data: SlotData

#@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@export var interact_area: Interactable

var original_parent
var current_parent
var held: bool



func _ready():
	_set_pickup()

func _set_pickup():
	#Attach unique meshes and make coll shapes local & adjust for individual items
	# Also set id and interact text/images in the interactable node
	original_parent = get_parent()
	interact_area.interacted.connect(_interact)

func _interact(type: String, engaged: bool):
	match type:
		"click":
			if engaged:
				EventBus.item_grabbed.emit(self)
				held = true
				print("Item grabbed")
			else:
				EventBus.item_dropped.emit()
				held = false
		
		"r_click":
			print("R Click detected on a grabbable")
		
		"interact":
			if slot_data and slot_data.item_data:
				var item_data = ItemData.new()
				item_data = slot_data.item_data
				var qty = slot_data.quantity
				
				EventBus.adding_item.emit(item_data, qty)
				queue_free()
