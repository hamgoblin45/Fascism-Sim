extends PanelContainer
class_name SlotUI

var parent_inventory: InventoryData
@export var slot_data: SlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity

@onready var selected_panel: Panel = %SelectedPanel
@onready var equip_highlight: Panel = %EquipHighlight
@onready var search_overlay: ColorRect = %SearchOverlay

@onready var hotbar_number: Label = %HotbarNumber
var slot_index: int = 0

var activated: bool = true
var tween: Tween

enum SearchState {NONE, PENDING, SEARCHING, CLEARED}
var current_search_state = SearchState.NONE


func _ready() -> void:
	EventBus.inventory_item_updated.connect(_on_item_updated)
	EventBus.select_item.connect(_select_item)
	EventBus.hotbar_index_changed.connect(_on_equipped_changed)
	#Hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	EventBus.shopping.connect(_check_if_sellable)
	EventBus.shop_closed.connect(_on_shop_closed)
	SearchManager.search_step_started.connect(_on_search_step)
	SearchManager.search_finished.connect(_on_search_finished)

func set_slot_data(new_slot_data: SlotData):
	slot_data = new_slot_data
	if !slot_data or !slot_data.item_data:
		print("InventorySlotUI: set_slot_data: setting empty slot")
		return
	
	print("InventorySlotUI: set_slot_data: DATA: %s, ITEM: %s" % [slot_data, slot_data.item_data.name])
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	tooltip_text = slot_data.item_data.name
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()
	
	if parent_inventory == GameState.pockets_inventory:
		equip_highlight.visible = (get_index() == GameState.active_hotbar_index)

func _select_item(data: SlotData):
	# Show if panel being selected, hide if not
	#print("InventorySlotUI: select_item: selecting %s" % data)
	selected_panel.visible = (data == slot_data and data != null)
	

func _on_item_updated(inv_data: InventoryData, index: int):
	# Only updates if slot is actually changed
	if inv_data == parent_inventory and index == get_index():
		selected_panel.hide()
		
		var new_data = parent_inventory.slot_datas[index]
		if new_data == null or new_data.quantity <= 0:
			clear_slot_data(null)
		else:
			print("InventorySlotUI: _on_item_updated running...")
			set_slot_data(new_data)
			_update_visuals()

func _update_visuals():
	print("UPDATING VISUALS")
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()
	

func _on_mouse_entered():
	# Shows a subtle highlight on hover
	if !selected_panel.visible:
		modulate = Color(1.2, 1.2, 1.2) # Slightly brighten

func _on_mouse_exited():
	modulate = Color(1,1,1) # Reset to normal

## -- Remove from slot
func clear_visuals():
	selected_panel.hide()
	item_texture.hide()
	quantity.hide()
	tooltip_text = ""
	

func clear_slot_data(_slot: SlotData):
	print("InventorySlotUI: clearing slot data")
	slot_data = null
	item_texture.texture = null
	clear_visuals()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and activated:
		# Shift click
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "shift_click")
				print("InventorySlotUI: Shift Slot clicked")
			else:
				EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "click")
				print("InventorySlotUI: Slot clicked")
			return
		
			
		if event.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "r_click")
			print("InventorySlotUI: Slot right-clicked")

func _on_equipped_changed(active_index: int):
	if parent_inventory == GameState.pockets_inventory:
		var is_active = (get_index() == active_index)
		equip_highlight.visible = is_active
		
		_animate_selection(is_active)
		
	else:
		equip_highlight.hide()
		#equip_highlight.visible = (data == slot_data and data != null)

func _animate_selection(is_active: bool):
	if tween:
		tween.kill()
	tween = create_tween()
	
	var target_scale = Vector2(1.15,1.15) if is_active else Vector2(1.0, 1.0)
	
	tween.set_trans(tween.TRANS_BACK) # Give it a lil bounce, ya know what I'm sayin'?
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", target_scale, 0.2)

func _check_if_sellable(legal: bool):
	if not slot_data or not slot_data.item_data:
		return
	if legal and slot_data.item_data.contraband_level > 1 \
	or not legal and slot_data.item_data.contraband_level <= 1:
		activated = false
		item_texture.modulate = Color.BLACK
		tooltip_text = "Merchant won't buy this"
	else:
		activated = true
		item_texture.modulate = Color.WHITE
		tooltip_text = slot_data.item_data.name

func _on_shop_closed():
	if not slot_data or not slot_data.item_data:
		return
		# Reset deactivate parameters set when an item isn't sellable
	activated = true
	item_texture.modulate = Color(1,1,1) # Reset to normal
	tooltip_text = slot_data.item_data.name

func _on_search_step(search_inv: InventoryData, index: int, duration: float):
	if search_inv != parent_inventory:
		return
	if index == get_index():
		_set_search_visual(SearchState.SEARCHING, duration)
	elif index < get_index() and SearchManager.is_searching:
		_set_search_visual(SearchState.PENDING)
	elif index > get_index():
		_set_search_visual(SearchState.CLEARED)

func _set_search_visual(state: SearchState, duration: float = 0.0):
	current_search_state = state
	search_overlay.show()
	
	if tween and tween.is_valid():
		tween.kill()
	
	match state:
		SearchState.PENDING:
			search_overlay.color = Color(0,0,0, 0.2) # Dim unsearched slots
			search_overlay.scale = Vector2(1,1)
			
		SearchState.SEARCHING:
			search_overlay.color = Color(1, 0.3, 0.3, 0.5) # Red Highlight for active slots
			search_overlay.scale = Vector2(0,1)
			
			tween = create_tween()
			
			tween.tween_property(search_overlay, "scale:x", 1.0, duration)
			
			# Automatically turn green if time runs out
			tween.tween_callback(func(): search_overlay.color = Color(0.3,1,0.3,0.2))
		
		SearchState.CLEARED:
			search_overlay.color = Color(0.3,1,0.3,0.2) # Green tint if cleared
			search_overlay.scale = Vector2(1,1)
		
		SearchState.NONE:
			search_overlay.hide()

func _on_search_finished(_caught, _item, _qty):
	_set_search_visual(SearchState.NONE)
