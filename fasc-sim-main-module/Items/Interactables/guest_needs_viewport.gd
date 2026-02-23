extends SubViewport

@onready var name_label = $VBoxContainer/GuestName
@onready var hunger_bar = $VBoxContainer/HungerBar
@onready var stress_bar = $VBoxContainer/StressBar

func update_needs(guest_name: String, hunger: float, stress: float):
	name_label.text = guest_name
	hunger_bar.value = hunger
	stress_bar.value = stress
