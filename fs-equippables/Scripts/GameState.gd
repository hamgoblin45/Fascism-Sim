extends Node

## -- Interface
var ui_open: bool = false
var in_dialogue: bool = false
var shopping: bool = false # Dictates how inventory UI will react, primarily Using an item vs Selling it
var money: float = 100
var pockets_inventory: InventoryData
var active_hotbar_index: int = -1
var equipped_item: InventoryItemData

## -- Player / 3D Controller
var player: CharacterBody3D
var held_item
