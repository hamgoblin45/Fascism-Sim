extends Node

signal main_scene_loaded

signal end_day # To initiate day transition
signal change_day() # to initiate the change
signal day_changed() # to acknowledge the change and initiate follow-up logic
signal start_day # To load back into the main scene in a full game

signal hour_changed(hour: int)
signal minute_changed(hour: int, minute: int)

signal set_paused(bool)
