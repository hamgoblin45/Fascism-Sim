extends Node

signal main_scene_loaded

signal change_day(new_day: int) # to initiate the change
signal day_changed(new_day: int) # to acknowledge the change and initiate follow-up logic

signal hour_changed(hour: int)
signal minute_changed(hour: int, minute: int)

signal set_paused(bool)
