extends Node



signal main_scene_loaded

signal looking_at_interactable(Interactable, bool) # Interact icon, text, goes here
signal item_interacted(id_or_data, interact_type: String, engaged: bool) # Which object, how player is interacting with it, and if engaged or released
signal item_dropped(body, speed: float) # also handles throwing
signal item_grabbed(body)
