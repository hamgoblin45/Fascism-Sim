extends ObjectiveStepData
class_name ObjectiveStepGatherData
## Step specific to gathering a certain number of items


@export var required_items: Array[String] # Actually make this SlotDatas, with quantities matching required amount


#func _ready():
	#EventBus.item_added_to_inventory.connect(something)
	#EventBus.item_removed_from_inventory.connect(something_else)
