extends Resource
class_name DiscoveryData

@export var item_data: ItemData
@export var record_unit: String
@export var record_value: float

@export var discovery_type: String

var item_data_path: String
var discovery_day: int
var discovery_time: float
var discovery_map: String

var saved_image: Image



func set_discovery(_type: String):
	item_data_path = item_data.resource_path
	discovery_day = GameTime.day
	discovery_time = GameTime.time
	discovery_map = Global.current_map_name
	
	discovery_type = _type
