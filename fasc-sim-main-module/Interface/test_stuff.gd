extends Control


func _on_start_raid_pressed() -> void:
	EventBus.raid_starting.emit()
