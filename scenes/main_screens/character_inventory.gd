class_name Inventory extends Control

# --- Scene References ---
@onready var equipment_panel: PanelContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel
@onready var inventory_panel: PanelContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel
@onready var equipment_vbox: VBoxContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox

@onready var gear_panel: PanelContainer = $VBox_Root/Body/Gear_Panel

@onready var _grid: GridContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemContainer/Grid
@onready var item_scroll_container: ScrollContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var item_container: PanelContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemContainer
@onready var currency_container: PanelContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/CurrencyContainer
@onready var gold_texture: TextureRect = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/CurrencyContainer/MarginContainer/Vbox/HBox/Gold_Texture
@onready var gold_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/CurrencyContainer/MarginContainer/Vbox/HBox/Gold_label

@onready var btn_tab_inventory: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Gear_Tab_Buttons/Btn_Tab_Inventory
@onready var btn_tab_gear: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Gear_Tab_Buttons/Btn_Tab_Gear

@onready var col_left: VBoxContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/HBoxContainer/col_left
@onready var character_model: TextureRect = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/HBoxContainer/character_model
@onready var col_right: VBoxContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/HBoxContainer/col_right

# --- Paper Doll ---
# Draw order: layers added in this order (later = drawn on top)
const PAPER_DOLL_LAYER_ORDER = ["legs", "chest", "shoulder", "head", "gloves", "feet", "belt"]
var _paper_doll_layers: Dictionary = {} # slot_name -> TextureRect

@onready var btn_split_items: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_Split_Items
@onready var btn_split_currency: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_Split_Currency

@onready var btn_all: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_ALL
@onready var btn_gear_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_GearOnly
@onready var btn_consumable_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_ConsumableOnly
@onready var btn_loot_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_LootOnly
@onready var space_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Space_Label
@onready var btn_sort: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Btn_Sort

@onready var ilvl_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/ILVL_Label

# --- Layout / Config ---
@export_group("Grid Settings")
# NOTE: server enforces INVENTORY_MAX_SLOTS = columns * rows (activities_base_config.py).
# Update the server constant if you change these values.
@export var columns: int = 5
@export var rows: int = 6
@export var slot_size: Vector2i = Vector2i(80, 110)
@export var slot_padding: int = 5
 
@export_group("Equipment Settings")
@export var slot_size_eq: Vector2i = Vector2i(76, 76)
@export var slot_padding_eq: int = 10

@export_group("Behavior")
@export var show_stack_count: bool = true
@export var show_tooltips: bool = true

const TOOLTIP_MARGIN = 8.0
const BOTTOM_HUD_HEIGHT: float = 108.0  # BottomHUD ButtonPanel top offset from screen bottom

# --- State ---
var _last_pointer_pos = Vector2.ZERO
var _slots: Array = []          # Array[Dictionary | null] -> [{"id":String, "qty":int}]
var _equipped: Dictionary = {}  # slot_name -> {"id":String, "qty":int}
var _item_defs: Dictionary = {}
var _active_filter: String = "all"
var _bulk_updating: bool = false
var _multi_select_mode: bool = false
var _selected_indices: Array = []
var btn_multi_sell: Button
var btn_sell_all: Button

# UI Cache (slot_name -> {panel, btn, icon})
var _eq_slot_nodes: Dictionary = {} 

# Tooltip State
var _tooltip: LegionTooltip
var _compare_tooltip: LegionTooltip = null
var _tooltip_visible: bool = false
var _tooltip_open_frame: int = -1

var _active_tooltip_source: String = "" # "inventory" or "equipment"
var _active_tooltip_index: int = -1     # Inventory index
var _active_tooltip_slot: String = ""   # Equipment slot name

const SLOT_DISPLAY_NAMES: Dictionary = {
	"head":          "Head",
	"shoulder":      "Shoulder",
	"cloak":         "Back",
	"chest":         "Chest",
	"wrist":         "Wrist",
	"ring_left":     "Ring",
	"trinket_left":  "Trinket",
	"main_hand":     "Main Hand",
	"neck":          "Neck",
	"gloves":        "Gloves",
	"belt":          "Belt",
	"legs":          "Legs",
	"feet":          "Feet",
	"ring_right":    "Ring",
	"trinket_right": "Trinket",
	"off_hand":      "Off Hand",
}

const SLOT_PLACEHOLDER_ICONS: Dictionary = {
	"head":          "head_0",
	"shoulder":      "shoulder_0",
	"cloak":         "cloak_0",
	"chest":         "chest_0",
	"wrist":         "wrist_0",
	"ring_left":     "ring_0",
	"trinket_left":  "trinket_0",
	"main_hand":     "main_hand_0",
	"neck":          "neck_0",
	"gloves":        "gloves_0",
	"belt":          "belt_0",
	"legs":          "legs_0",
	"feet":          "feet_0",
	"ring_right":    "ring_0",
	"trinket_right": "trinket_0",
	"off_hand":      "off_hand_0",
}


func _ready() -> void:
	$VBox_Root.offset_top = Styler.content_top
	$VBox_Root.offset_bottom = Styler.content_bottom

	AccountManager.signal_AccountDataReceived.connect(_on_currency_update)
	AccountManager.signal_InventoryReceived.connect(_on_request_inventory)
	_setup_ui_layout()
	# Defer grid build so container has its final size for adaptive slot calculation
	await get_tree().process_frame
	_build_inventory_grid()
	_build_equipment_ui()
	
	_style_main_interface()

	Styler.style_button(btn_tab_inventory, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_tab_gear, Color.from_rgba8(64,180,255))
	_on_btn_tab_inventory_pressed()  # default: inventory tab
	
	Styler.style_button_small(btn_all, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_gear_only, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_consumable_only, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_loot_only, Color.from_rgba8(255,200,66))
	_set_filter("all")  # apply default active highlight
	Styler.style_button_small(btn_sort, Color.from_rgba8(255,200,66))

	var hbox2 = btn_sort.get_parent()
	btn_multi_sell = Button.new()
	btn_multi_sell.text = "Select"
	Styler.style_button_small(btn_multi_sell, Color.from_rgba8(255, 100, 100))
	btn_multi_sell.pressed.connect(_on_btn_multi_sell_toggled)
	hbox2.add_child(btn_multi_sell)

	btn_sell_all = Button.new()
	btn_sell_all.text = "Sell All (0)"
	btn_sell_all.visible = false
	Styler.style_button_small(btn_sell_all, Color.from_rgba8(220, 50, 50))
	btn_sell_all.pressed.connect(_on_btn_sell_all_pressed)
	hbox2.add_child(btn_sell_all)

	Styler.style_name_label(space_label, Color.from_rgba8(255,215,128))
	
	Styler.style_button_small(btn_split_items, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_split_currency, Color.from_rgba8(255,200,66))
	_set_split_button_active(btn_split_items)  # Items view is default
	Styler.style_name_label(gold_label, Color.from_rgba8(255,215,128))
	
	Styler.style_name_label(ilvl_label, Color.from_rgba8(255,215,128))
	
	_setup_paper_doll()
		
	gold_texture.texture = ItemDB.get_icon("gold_coin")
	gold_label.text = " Gold: {0}".format([str(int(Account.gold))])


func _input(event: InputEvent) -> void:
	if not _tooltip_visible or not _tooltip:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_last_pointer_pos = event.position
		return
	# Skip the same frame the tooltip opened. gui_input (which opens the tooltip)
	# fires AFTER _input for the same event, so any second event batched in the
	# same frame would otherwise close the tooltip before it is ever rendered.
	if Engine.get_process_frames() == _tooltip_open_frame:
		return
	var is_press = (event is InputEventScreenTouch and event.pressed) or \
				   (event is InputEventMouseButton and event.pressed)
	if not is_press:
		return
	if not _tooltip.get_global_rect().has_point(event.position):
		_hide_tooltip()

# --- Public API: Inventory Management ---
func clear_inventory() -> void:
	_slots.resize(columns * rows)
	for i in _slots.size():
		_slots[i] = null
	_refresh_all_inventory_slots()
	_hide_tooltip()

func add_item(item_id: String, qty: int, def: Dictionary = {}) -> int:
	# Returns remaining qty that didn't fit
	if qty <= 0: return 0

	# Cache definition if provided, otherwise generic lookups will fail later
	if not def.is_empty():
		_item_defs[item_id] = def
	else:
		# Fallback if def not provided immediately
		def = _item_defs.get(item_id, {})

	var stackable = def.get("stackable", true)
	var max_stack = int(def.get("max_stack", 99))
	var remaining = qty

	# 1. Stack into existing slots
	if stackable:
		for i in _slots.size():
			if remaining <= 0: break
			var s = _slots[i]
			if s != null and s["id"] == item_id:
				var space = max_stack - int(s["qty"])
				if space > 0:
					var push = min(space, remaining)
					s["qty"] += push
					remaining -= push
					_refresh_inventory_slot_visuals(i)

	# 2. Fill empty slots
	for i in _slots.size():
		if remaining <= 0: break
		if _slots[i] == null:
			# If stackable, push as much as max_stack, else just 1
			var push = min(max_stack, remaining) if stackable else 1
			_slots[i] = {"id": item_id, "qty": push}
			remaining -= push
			_refresh_inventory_slot_visuals(i)

	return remaining

func remove_at(index: int, qty: int) -> Dictionary:
	if index < 0 or index >= _slots.size() or _slots[index] == null:
		return {}

	var s = _slots[index]
	var current_qty = int(s["qty"])
	var take = min(current_qty, max(1, qty))
	
	s["qty"] -= take
	var removed_id = s["id"]
	
	if s["qty"] <= 0:
		_slots[index] = null
		
	_refresh_inventory_slot_visuals(index)
	return {"id": removed_id, "qty": take}


# --- Public API: Equipment ---
func equip(slot_name: String, item_id: String) -> void:
	_equipped[slot_name] = {"id": item_id, "qty": 1}
	_update_equipment_slot_visuals(slot_name)

func unequip(slot_name: String) -> void:
	if _equipped.has(slot_name):
		var id = _equipped[slot_name]["id"]
		_equipped.erase(slot_name)
		_update_equipment_slot_visuals(slot_name)
		emit_signal("unequipped_item", slot_name, id)

func set_equipment(data: Dictionary) -> void:
	# data: slot_name -> {"code": "...", ...}
	_equipped.clear()
	for slot in data:
		var item = data[slot]
		var id = item.get("code", item.get("id", ""))
		if id != "":
			_equipped[slot] = {"id": id, "qty": 1}
			if not _item_defs.has(id):
				_item_defs[id] = item # Cache item data if present
	
	# Refresh all UI
	for slot_name in _eq_slot_nodes:
		_update_equipment_slot_visuals(slot_name)


# --- UI Builders (Internal) ---
func _setup_ui_layout() -> void:
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _build_inventory_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()

	_grid.columns = columns
	_grid.add_theme_constant_override("h_separation", slot_padding)
	_grid.add_theme_constant_override("v_separation", slot_padding)

	# Compute adaptive slot size so the row fills the full panel width
	var available_width = item_container.size.x
	if available_width <= 0:
		available_width = item_container.get_parent().size.x
	var total_padding = slot_padding * (columns - 1)
	var adaptive_size = int(max(32, (available_width - total_padding) / columns))

	_slots.resize(columns * rows)
	for i in range(columns * rows):
		_grid.add_child(_create_inventory_slot_node(i, adaptive_size))

func _create_inventory_slot_node(index: int, adaptive_size: int = 50) -> Control:
	var panel = PanelContainer.new()
	panel.name = "Slot_%d" % index
	panel.custom_minimum_size = Vector2(adaptive_size, adaptive_size)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.1, 0.5) # Dark semi-transparent background
	sb.border_width_bottom = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_color = Color(0.25, 0.25, 0.3) # Default "Empty" border color
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_meta("sb", sb)
	
	var btn = Button.new()
	btn.name = "Btn"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	btn.add_theme_stylebox_override("normal", Styler._get_slot_stylebox(false))
	btn.add_theme_stylebox_override("hover", Styler._get_slot_stylebox(true))
	btn.add_theme_stylebox_override("pressed", Styler._get_slot_stylebox(true))
	# Unified input handler
	btn.gui_input.connect(func(e): _handle_slot_input(e, btn, "inventory", index))
	panel.add_child(btn)
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Add slight margin to icon
	icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -4
	btn.add_child(icon)
	
	var count = Label.new()
	count.name = "Count"
	count.add_theme_font_size_override("font_size", 14)
	count.add_theme_color_override("font_color", Color.WHITE)
	count.add_theme_constant_override("outline_size", 3)
	count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	count.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	count.offset_right  = -3
	count.offset_bottom = -2
	btn.add_child(count)
	
	return panel

func _build_equipment_ui() -> void:
	# Clean existing if needed
	for c in col_left.get_children(): c.queue_free()
	for c in col_right.get_children(): c.queue_free()

	equipment_vbox.add_theme_constant_override("separation", slot_padding)
	col_left.add_theme_constant_override("separation", slot_padding_eq)
	col_right.add_theme_constant_override("separation", slot_padding_eq)
	
	for s in ItemDB.slots_left:
		col_left.add_child(_create_equipment_slot_node(s))
	for s in ItemDB.slots_right:
		col_right.add_child(_create_equipment_slot_node(s))

func _create_equipment_slot_node(slot_name: String) -> Control:
	var wrapper = VBoxContainer.new()
	wrapper.name = slot_name
	wrapper.add_theme_constant_override("separation", 2)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(slot_size_eq)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.4)
	sb.border_width_bottom = 2; sb.border_width_top = 2; sb.border_width_left = 2; sb.border_width_right = 2
	sb.border_color = Color(0.25, 0.25, 0.3)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.gui_input.connect(func(e): _handle_slot_input(e, btn, "equipment", -1, slot_name))
	panel.add_child(btn)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -4
	btn.add_child(icon)

	wrapper.add_child(panel)

	var lbl = Label.new()
	lbl.text = SLOT_DISPLAY_NAMES.get(slot_name, slot_name)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	wrapper.add_child(lbl)

	_eq_slot_nodes[slot_name] = {"panel": panel, "btn": btn, "icon": icon, "label": lbl, "sb": sb}
	_update_equipment_slot_visuals(slot_name)
	return wrapper

func _update_mean_ilvl() -> void:
	if not ilvl_label: return
	
	var total_ilvl: float = 0.0
	
	# Iterate over equipped items
	for slot_name in _equipped:
		var data = _equipped[slot_name]
		var id = data["id"]
		var def = _item_defs.get(id, {})
		
		# Get ilvl, default to 0 if missing
		var ilvl = int(def.get("ilvl", 0))
		
		# Only count items that actually have an ilvl (optional logic)
		if ilvl > 0:
			total_ilvl += ilvl
	
	var mean = 0
	mean = int(round(total_ilvl / 16))
		
	ilvl_label.text = "Average Gear Level: %d" % mean

func _handle_slot_input(event: InputEvent, btn: Control, source: String, index: int = -1, slot_name: String = "") -> void:
	# source: "inventory" or "equipment"
	if event is InputEventScreenTouch and event.pressed:
		_last_pointer_pos = btn.get_global_rect().position + event.position

		# Multi-select mode: toggle selection instead of showing tooltip
		if _multi_select_mode and source == "inventory":
			var s = _slots[index] if index >= 0 and index < _slots.size() else null
			if s != null:
				_toggle_slot_selection(index)
			return

		# Skip tooltip for filtered-out inventory items
		if source == "inventory":
			var s = _slots[index] if index >= 0 and index < _slots.size() else null
			if s == null:
				return
			if _active_filter != "all":
				var def = _item_defs.get(s["id"], {})
				if def.get("category", "") != _active_filter:
					return

		# If tooltip already open for this exact item, toggle off
		if _tooltip_visible and _active_tooltip_source == source:
			if (source == "inventory" and _active_tooltip_index == index) or \
			   (source == "equipment" and _active_tooltip_slot == slot_name):
				_hide_tooltip()
				return

		_show_tooltip(source, index, slot_name)

	elif event is InputEventScreenDrag:
		_last_pointer_pos = btn.get_global_rect().position + event.position

func _show_tooltip(source: String, index: int, slot_name: String) -> void:
	_ensure_tooltip_instance()

	var item_data = {}
	var item_def = {}

	if source == "inventory":
		if index < 0 or index >= _slots.size() or _slots[index] == null:
			_hide_tooltip()
			return

		item_data = _slots[index]
		item_def = _item_defs.get(item_data["id"], {})
		_active_tooltip_index = index

		var compare_def = _get_equipped_def_for_slot(str(item_def.get("slot_type", "")))
		_tooltip.set_data(item_def, item_data.get("qty", 1), source, index, slot_name, compare_def)

		if not compare_def.is_empty():
			_ensure_compare_tooltip()
			_compare_tooltip.set_data(compare_def, 1, "equipment", -1, "", item_def)
			_compare_tooltip.visible = true
		elif _compare_tooltip:
			_compare_tooltip.visible = false

	elif source == "equipment":
		if not _equipped.has(slot_name): return
		item_data = _equipped[slot_name]
		item_def = _item_defs.get(item_data["id"], {})
		_active_tooltip_slot = slot_name
		_tooltip.set_data(item_def, item_data.get("qty", 1), source, index, slot_name)
		if _compare_tooltip:
			_compare_tooltip.visible = false

	else:
		_hide_tooltip()
		return

	_active_tooltip_source = source
	_tooltip_open_frame = Engine.get_process_frames()
	_tooltip_visible = true
	_tooltip.visible = true
	_update_tooltip_position_to_point(_last_pointer_pos)

func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false
	if _compare_tooltip:
		_compare_tooltip.visible = false
	_tooltip_visible = false
	_active_tooltip_index = -1
	_active_tooltip_slot = ""

func _ensure_tooltip_instance() -> void:
	if _tooltip: return
	_tooltip = LegionTooltip.new()
	_tooltip.visible = false
	_tooltip.z_index = 100 # Ensure on top
	add_child(_tooltip)
	SignalManager.signal_UseItem.connect(_on_tooltip_action_use)
	SignalManager.signal_EquipItem.connect(func(_uid, _s): _hide_tooltip())
	SignalManager.signal_UnequipItem.connect(func(_s): _hide_tooltip())
	SignalManager.signal_SellItem.connect(func(_uid): _hide_tooltip())
	SignalManager.signal_DisenchantItem.connect(func(_uid): _hide_tooltip())

func _ensure_compare_tooltip() -> void:
	if _compare_tooltip: return
	_compare_tooltip = LegionTooltip.new()
	_compare_tooltip.visible = false
	_compare_tooltip.z_index = 99
	add_child(_compare_tooltip)

func _get_equipped_def_for_slot(slot_type: String) -> Dictionary:
	var s = slot_type.to_lower()
	if s == "" or s == "none" or s == "null" or s == "<null>" or s == "misc":
		return {}
	var candidates: Array
	if "ring" in s:
		candidates = ["ring_left", "ring_right"]
	elif "trinket" in s:
		candidates = ["trinket_left", "trinket_right"]
	else:
		candidates = [s]
	for candidate in candidates:
		if _equipped.has(candidate):
			var eq_data = _equipped[candidate]
			var def = _item_defs.get(eq_data.get("id", ""), {})
			if not def.is_empty():
				return def
	return {}

func _update_tooltip_position_to_point(global_point: Vector2) -> void:
	if not _tooltip or not _tooltip.visible: return

	var vp_size      = get_viewport().get_visible_rect().size
	var left_limit   = TOOLTIP_MARGIN
	var top_limit    = TOOLTIP_MARGIN
	var right_limit  = vp_size.x - TOOLTIP_MARGIN
	var bottom_limit = vp_size.y - BOTTOM_HUD_HEIGHT - TOOLTIP_MARGIN

	var t_size = _tooltip.size if _tooltip.size.x > 1 else _tooltip.get_combined_minimum_size()

	if _compare_tooltip and _compare_tooltip.visible:
		# --- Joint layout: treat [compare | gap | primary] as one block ---
		var cmp_size = _compare_tooltip.size if _compare_tooltip.size.x > 1 \
						else _compare_tooltip.get_combined_minimum_size()
		var _total_w  = cmp_size.x + TOOLTIP_MARGIN + t_size.x
		var max_h    = maxf(t_size.y, cmp_size.y)

		# Vertical: prefer below touch, flip above if overflow, then clamp
		var y = global_point.y + TOOLTIP_MARGIN
		if y + max_h > bottom_limit:
			y = global_point.y - max_h - TOOLTIP_MARGIN
		y = clamp(y, top_limit, maxf(top_limit, bottom_limit - max_h))

		# Horizontal: place compare to left and primary to right of touch point.
		# Try: primary starts at touch + margin, compare is to its left.
		var primary_x = global_point.x + TOOLTIP_MARGIN
		var compare_x = primary_x - cmp_size.x - TOOLTIP_MARGIN

		# If the block extends past the right edge, shift left so primary fits
		if primary_x + t_size.x > right_limit:
			primary_x = right_limit - t_size.x
			compare_x = primary_x - cmp_size.x - TOOLTIP_MARGIN

		# If compare went off the left edge, shift the whole block right
		if compare_x < left_limit:
			var shift = left_limit - compare_x
			compare_x  += shift
			primary_x  += shift

		# Final safety clamp (handles edge case where total_w > available space)
		compare_x = clamp(compare_x, left_limit, right_limit)
		primary_x = clamp(primary_x, left_limit, right_limit)

		_compare_tooltip.global_position = Vector2(compare_x, y)
		_tooltip.global_position         = Vector2(primary_x, y)
	else:
		# --- Single tooltip layout ---
		var pos = global_point

		# Horizontal: prefer right of touch, flip left if overflow
		if pos.x + t_size.x + TOOLTIP_MARGIN > right_limit:
			pos.x -= t_size.x + TOOLTIP_MARGIN
		else:
			pos.x += TOOLTIP_MARGIN

		# Vertical: prefer below touch, flip above if overflow
		if pos.y + t_size.y + TOOLTIP_MARGIN > bottom_limit:
			pos.y -= t_size.y + TOOLTIP_MARGIN
		else:
			pos.y += TOOLTIP_MARGIN

		pos.x = clamp(pos.x, left_limit, maxf(left_limit, right_limit - t_size.x))
		pos.y = clamp(pos.y, top_limit, maxf(top_limit, bottom_limit - t_size.y))

		_tooltip.global_position = pos


# --- Visual Updates ---
func _style_main_interface() -> void:
	Styler._apply_parchment_style(gear_panel)
	item_scroll_container.get_v_scroll_bar().custom_minimum_size.x = 16
	
	var transparent_sb = StyleBoxFlat.new()
	transparent_sb.bg_color = Color(0,0,0,0)
	transparent_sb.border_width_bottom = 1
	transparent_sb.border_color = Color(0,0,0,0.2)

	equipment_panel.add_theme_stylebox_override("panel", transparent_sb)

	var inv_sb = StyleBoxFlat.new()
	inv_sb.bg_color     = Color(0.06, 0.07, 0.10, 0.75)
	inv_sb.border_color = Color.from_rgba8(255, 200, 66, 55)
	inv_sb.border_width_bottom = 1; inv_sb.border_width_top  = 1
	inv_sb.border_width_left   = 1; inv_sb.border_width_right = 1
	inv_sb.set_corner_radius_all(8)
	inventory_panel.add_theme_stylebox_override("panel", inv_sb)

	var grid_sb = StyleBoxFlat.new()
	grid_sb.bg_color     = Color(0.04, 0.04, 0.07, 0.85)
	grid_sb.border_color = Color(0, 0, 0, 0.3)
	grid_sb.border_width_bottom = 1; grid_sb.border_width_top  = 1
	grid_sb.border_width_left   = 1; grid_sb.border_width_right = 1
	grid_sb.set_corner_radius_all(4)
	item_container.add_theme_stylebox_override("panel", grid_sb)

func _refresh_all_inventory_slots() -> void:
	for i in _grid.get_child_count():
		_refresh_inventory_slot_visuals(i)

func _refresh_inventory_slot_visuals(index: int) -> void:
	if _bulk_updating: return
	if index >= _grid.get_child_count(): return
	var slot_node = _grid.get_child(index)
	var btn = slot_node.get_node("Btn")
	var icon = btn.get_node("Icon")
	var count_lbl = btn.get_node("Count")

	var sb: StyleBoxFlat = slot_node.get_meta("sb") as StyleBoxFlat
	
	var s = _slots[index]
	
	if s == null:
		icon.texture = null
		count_lbl.text = ""
		btn.disabled = true
		slot_node.tooltip_text = ""

		if sb:
			sb.bg_color = Color(0.1, 0.1, 0.1, 0.5)
			sb.border_color = Color(0.25, 0.25, 0.3)
		return
	
	var def = _item_defs.get(s["id"], {})

	# Filter: if category doesn't match, render slot as visually empty
	if _active_filter != "all" and def.get("category", "") != _active_filter:
		icon.texture = null
		count_lbl.text = ""
		btn.disabled = true
		slot_node.tooltip_text = ""
		if sb:
			sb.bg_color = Color(0.1, 0.1, 0.1, 0.5)
			sb.border_color = Color(0.25, 0.25, 0.3)
		return

	var id = s["id"]
	var qty = s["qty"]
	icon.texture = ItemDB.get_item_icon(def["item_icon"], null)
	btn.disabled = false
	count_lbl.text = str(qty) if (show_stack_count and qty > 1) else ""
	
	if sb:
		var q = int(def.get("quality", 1))
		var q_color: Color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])
		# Subtle tint: quality color at ~12% brightness
		sb.bg_color = Color(q_color.r * 0.12, q_color.g * 0.12, q_color.b * 0.12, 0.6)
		sb.border_color = q_color
		# Selection override (takes priority over quality color)
		if index in _selected_indices:
			sb.border_color = Color(1.0, 0.85, 0.0)
			sb.border_width_bottom = 3; sb.border_width_top = 3
			sb.border_width_left  = 3; sb.border_width_right = 3
		else:
			sb.border_width_bottom = 2; sb.border_width_top = 2
			sb.border_width_left  = 2; sb.border_width_right = 2

	# Simple hover tooltip text (fallback)
	if show_tooltips:
		var nm = String(def.get("name", id))
		var ds = String(def.get("descr", ""))
		slot_node.tooltip_text = nm + ("\n" + ds if ds != "" else "")
		#slot_node.tooltip_text = def.get("name", id)

# --- Paper Doll Setup & Update ---
const BASE_BODY_PATH = "res://assets/equipment_overlays/base_body/base_body_female.png"

func _make_paper_doll_layer(layer_name: String, tex: Texture2D = null) -> TextureRect:
	var layer = TextureRect.new()
	layer.name = layer_name
	layer.texture = tex
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	character_model.add_child(layer)
	return layer

func _setup_paper_doll() -> void:
	# Guard against double-setup (e.g., scene re-entry)
	if not _paper_doll_layers.is_empty():
		return

	character_model.texture = null

	# Base body layer (always visible)
	var body_tex = load(BASE_BODY_PATH) as Texture2D
	_make_paper_doll_layer("base_body", body_tex)

	# Equipment overlay layers in draw order (later = on top)
	for slot in PAPER_DOLL_LAYER_ORDER:
		_paper_doll_layers[slot] = _make_paper_doll_layer(slot + "_layer")

func _update_paper_doll_slot(slot_name: String, icon_key: String) -> void:
	if not _paper_doll_layers.has(slot_name):
		return
	var layer = _paper_doll_layers[slot_name]
	if icon_key.is_empty():
		layer.texture = null
	else:
		layer.texture = ItemDB.get_item_overlay(icon_key)

func _update_equipment_slot_visuals(slot_name: String) -> void:
	if not _eq_slot_nodes.has(slot_name): return

	var nodes = _eq_slot_nodes[slot_name]
	var _panel = nodes["panel"]
	var icon  = nodes["icon"]
	var lbl   = nodes.get("label")
	var sb    = nodes.get("sb") as StyleBoxFlat

	if _equipped.has(slot_name):
		var id  = _equipped[slot_name]["id"]
		var def = _item_defs.get(id, {})
		var raw = def.get("item_icon", "")
		var icon_key: String = raw[0] if raw is Array and not raw.is_empty() else str(raw)
		icon.texture  = ItemDB.get_item_icon(icon_key, null)
		icon.modulate = Color.WHITE
		if sb:
			var q = int(def.get("quality", 1))
			sb.border_color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])
		if lbl:
			lbl.add_theme_color_override("font_color", Styler.GOLD_COLOR)
		# Update paper doll overlay
		_update_paper_doll_slot(slot_name, icon_key)
	else:
		var ph_key = SLOT_PLACEHOLDER_ICONS.get(slot_name, "")
		icon.texture  = ItemDB.get_item_icon(ph_key, null) if ph_key != "" else null
		icon.modulate = Color(1, 1, 1, 0.25)
		if sb:
			sb.border_color = Color(0.25, 0.25, 0.3)
		if lbl:
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		# Clear paper doll overlay
		_update_paper_doll_slot(slot_name, "")


# --- Signal Callbacks ---
func _on_request_inventory(server_json) -> void:
	# Suppress per-slot visual refreshes during bulk load; one refresh at the end.
	_bulk_updating = true

	# 1. Clear current
	_equipped.clear()
	_item_defs.clear()

	_slots.resize(columns * rows)
	for i in _slots.size():
		_slots[i] = null

	var data = server_json.data

	# 2. Parse Equipment (server sends "code", we map to "id")
	if data.has("equipment"):
		for item in data.equipment:
			var id = str(item.get("item_uid", ""))
			var slot = item.get("slot", "")
			if id and slot:
				_item_defs[id] = item
				_equipped[slot] = {"id": id, "qty": 1}

	# 3. Parse Inventory
	if data.has("inventory"):
		for item in data.inventory:
			var id = str(item.get("item_uid", ""))
			var qty = int(item.get("qty", 1))
			_item_defs[id] = item
			add_item(id, qty, item)

	# End bulk mode, do a single visual refresh for everything
	_bulk_updating = false
	_update_mean_ilvl()
	_sort_and_compact()
	for slot_name in _eq_slot_nodes:
		_update_equipment_slot_visuals(slot_name)

func _update_space_label() -> void:
	var occupied = 0
	for s in _slots:
		if s != null:
			occupied += 1
	space_label.text = "Space %d / %d" % [occupied, _slots.size()]

func _on_currency_update(_server_json):
	gold_label.text = " Gold: {0}".format([str(int(Account.gold))])

func _on_tooltip_action_use(_item_uid, _qty: int) -> void:
	_hide_tooltip()

# ------------ Control buttons callbacks ----------
func _on_btn_tab_inventory_pressed() -> void:
	inventory_panel.visible = true
	equipment_panel.visible = false
	_set_gear_tab_active(btn_tab_inventory)

func _on_btn_tab_gear_pressed() -> void:
	inventory_panel.visible = false
	equipment_panel.visible = true
	_set_gear_tab_active(btn_tab_gear)

func _set_gear_tab_active(active_btn: Button) -> void:
	for btn in [btn_tab_inventory, btn_tab_gear]:
		var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(64, 180, 255) if btn == active_btn else Color.from_rgba8(60, 60, 70)

func _on_btn_split_items_pressed() -> void:
	item_scroll_container.visible = true
	currency_container.visible = false
	_set_split_button_active(btn_split_items)

func _on_btn_split_currency_pressed() -> void:
	item_scroll_container.visible = false
	currency_container.visible = true
	_set_split_button_active(btn_split_currency)

func _set_split_button_active(active_btn: Button) -> void:
	for btn in [btn_split_items, btn_split_currency]:
		var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(255, 200, 66) if btn == active_btn else Color.from_rgba8(90, 90, 90)

func _on_btn_all_pressed() -> void:
	_set_filter("all")

func _on_btn_gear_only_pressed() -> void:
	_set_filter("equipment")

func _on_btn_consumable_only_pressed() -> void:
	_set_filter("consumable")

func _on_btn_loot_only_pressed() -> void:
	_set_filter("material")

func _set_filter(filter: String) -> void:
	_active_filter = filter
	var filter_btns = {
		"all": btn_all,
		"equipment": btn_gear_only,
		"consumable": btn_consumable_only,
		"material": btn_loot_only,
	}
	for key in filter_btns:
		var btn = filter_btns[key]
		var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(255, 200, 66) if key == filter else Color.from_rgba8(90, 90, 90)
	_sort_and_compact()

func _on_btn_sort_pressed() -> void:
	_sort_and_compact()

func _on_btn_multi_sell_toggled() -> void:
	_multi_select_mode = !_multi_select_mode
	_hide_tooltip()
	if not _multi_select_mode:
		_clear_selection()
		Styler.style_button_small(btn_multi_sell, Color.from_rgba8(255, 100, 100))
		btn_multi_sell.text = "Select"
	else:
		Styler.style_button_small(btn_multi_sell, Color.from_rgba8(255, 200, 66))
		btn_multi_sell.text = "Cancel"

func _toggle_slot_selection(index: int) -> void:
	if index in _selected_indices:
		_selected_indices.erase(index)
	else:
		_selected_indices.append(index)
	_refresh_inventory_slot_visuals(index)
	var n = _selected_indices.size()
	btn_sell_all.visible = n > 0
	btn_sell_all.text = "Sell All (%d)" % n

func _clear_selection() -> void:
	var prev = _selected_indices.duplicate()
	_selected_indices.clear()
	for i in prev:
		_refresh_inventory_slot_visuals(i)
	btn_sell_all.visible = false
	btn_sell_all.text = "Sell All (0)"

func _on_btn_sell_all_pressed() -> void:
	var uids: Array = []
	for i in _selected_indices:
		var s = _slots[i]
		if s != null:
			uids.append(s["id"])
	if uids.is_empty():
		return
	SignalManager.signal_SellItems.emit(uids)
	_multi_select_mode = false
	_clear_selection()
	Styler.style_button_small(btn_multi_sell, Color.from_rgba8(255, 100, 100))
	btn_multi_sell.text = "Select"
	btn_sell_all.visible = false

func _sort_and_compact() -> void:
	# Separate slots into matching (visible) and non-matching, preserving nulls at end
	var matching: Array = []
	var rest: Array = []
	for s in _slots:
		if s == null:
			rest.append(null)
		elif _active_filter == "all" or _item_defs.get(s["id"], {}).get("category", "") == _active_filter:
			matching.append(s)
		else:
			rest.append(s)
	# Sort matching items by quality descending, then by ilvl descending
	matching.sort_custom(func(a, b):
		var def_a = _item_defs.get(a["id"], {})
		var def_b = _item_defs.get(b["id"], {})
		var qa = int(def_a.get("quality") if def_a.get("quality") != null else 0)
		var qb = int(def_b.get("quality") if def_b.get("quality") != null else 0)
		if qa != qb:
			return qa > qb
		var ia = int(def_a.get("ilvl") if def_a.get("ilvl") != null else 0)
		var ib = int(def_b.get("ilvl") if def_b.get("ilvl") != null else 0)
		return ia > ib
	)
	# Rebuild: matching first, rest after, padded to original size
	var combined: Array = matching + rest
	combined.resize(_slots.size())
	_slots = combined
	_refresh_all_inventory_slots()
	_update_space_label()
