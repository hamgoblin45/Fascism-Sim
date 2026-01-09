extends Node



signal main_scene_loaded

signal interactable_interacted(id_or_data, interact_type: String, engaged: bool) # Which object, how player is interacting with it, and if engaged or released
