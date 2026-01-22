extends Node

signal main_scene_loaded

signal change_stat(stat: String, change_value: float)
signal stat_changed(stat: String)
signal player_died

## -- TIME
signal end_day # To initiate day transition
signal change_day() # to initiate the change
signal day_changed() # to acknowledge the change and initiate follow-up logic
signal start_day # To load back into the main scene in a full game

signal hour_changed(hour: int)
signal minute_changed(hour: int, minute: int)

signal set_paused(bool)
