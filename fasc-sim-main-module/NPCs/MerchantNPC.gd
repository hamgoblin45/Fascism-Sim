extends NPC
class_name MerchantNPC

@export var is_legal_merchant: bool = false

func _ready():
	super._ready()
	# Optional: Override default interaction to open shop directly 
	# OR handle via Dialogue signal (preferred for your system)

# Hook this function to a Dialogic Signal event called "open_shop"
func open_shop():
	print("MerchantNPC: Opening shop interface.")
	EventBus.shopping.emit(is_legal_merchant)

func _on_interact(object, type, engaged):
	# If we are the visitor at the door, standard interaction applies.
	# Once inside (or if at the door), dialogue can trigger the shop.
	super._on_interact(object, type, engaged)
