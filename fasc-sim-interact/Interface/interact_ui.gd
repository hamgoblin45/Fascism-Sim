extends PanelContainer

@onready var interact_icon: TextureRect = %InteractIcon
@onready var interact_label: RichTextLabel = %InteractLabel


func _ready() -> void:
	EventBus.looking_at_interactable.connect(_set_interact_ui)

func _set_interact_ui(interactle: Interactable, looking: bool):
	if not looking:
		if visible:
			hide()
		return
	
	show()
	interact_icon.texture = interactle.interact_icon
	interact_label.text = "[center]"+ interactle.interact_text
