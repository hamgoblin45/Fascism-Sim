extends PanelContainer

@onready var interact_label: RichTextLabel = %InteractLabel
@onready var interact_icon: TextureRect = %InteractIcon

func _ready() -> void:
	hide()
	EventBus.looking_at_interactable.connect(_set_interact_ui)

func _set_interact_ui(interactable: Interactable, looking: bool):
	# Update check: Also check is_queued_for_deletion
	if not looking or not is_instance_valid(interactable) or interactable.is_queued_for_deletion():
		hide()
		return
	
	show()
	if interactable.interact_icon:
		interact_icon.texture = interactable.interact_icon
		interact_icon.show()
	else:
		interact_icon.hide()
		
	interact_label.text = "[center]" + interactable.interact_text
