class_name Inventory extends Control

# --- Signals ---
signal SignalEquippedItem(slot_name: String, item_id: String)
signal SignalUnequippedItem(slot_name: String, item_id: String)

# --- Scene References ---
@onready var equipment_panel: PanelContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel
@onready var inventory_panel: PanelContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel
@onready var equipment_vbox: VBoxContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox

@onready var gear_panel: PanelContainer = $VBox_Root/Body/Gear_Panel
@onready var skill_panel: PanelContainer = $VBox_Root/Body/Skill_Panel
@onready var talents_panel: PanelContainer = $VBox_Root/Body/Talents_Panel

@onready var btn_gear: Button = $VBox_Root/Buttons_Container/Btn_Gear
@onready var btn_skills: Button = $VBox_Root/Buttons_Container/Btn_Skills
@onready var btn_talents: Button = $VBox_Root/Buttons_Container/Btn_Talents

@onready var _grid: GridContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/Grid
@onready var col_left: VBoxContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/HBoxContainer/col_left
@onready var character_model: TextureRect = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/HBoxContainer/character_model
@onready var col_right: VBoxContainer = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/HBoxContainer/col_right

@onready var btn_all: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_ALL
@onready var btn_gear_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_GearOnly
@onready var btn_consumable_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_ConsumableOnly
@onready var btn_loot_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_LootOnly
@onready var space_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Space_Label
@onready var gold_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Gold_Label
@onready var diamond_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Diamond_Label
@onready var btn_sort: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Btn_Sort

@onready var talent_panel: PanelContainer = $VBox_Root/Body/Talents_Panel/Talent_Panel
@onready var talent_grid: GridContainer = $VBox_Root/Body/Talents_Panel/Talent_Panel/Margin/TalentGrid

# --- Layout / Config ---
@export_group("Grid Settings")
@export var columns: int = 10
@export var rows: int = 10
@export var slot_size: Vector2i = Vector2i(64, 64)
@export var slot_padding: int = 6

@export_group("Equipment Settings")
@export var slot_size_eq: Vector2i = Vector2i(48, 48)
@export var slot_padding_eq: int = 10

@export_group("Behavior")
@export var show_stack_count: bool = true
@export var show_tooltips: bool = true

const TOOLTIP_MARGIN = 8.0

# --- State ---
var _last_pointer_pos = Vector2.ZERO
var _slots: Array = []          # Array[Dictionary | null] -> [{"id":String, "qty":int}]
var _equipped: Dictionary = {}  # slot_name -> {"id":String, "qty":int}
var _item_defs: Dictionary = {}

# UI Cache (slot_name -> {panel, btn, icon})
var _eq_slot_nodes: Dictionary = {} 

# Tooltip State
var _tooltip: WowTooltip
var _tooltip_visible: bool = false
var _active_tooltip_source: String = "" # "inventory" or "equipment"
var _active_tooltip_index: int = -1     # Inventory index
var _active_tooltip_slot: String = ""   # Equipment slot name

const TALENT_KEYS = [
	{"k":"thick_skin_lvl",       "n":"Thick Skin",       "exp": "thick_skin_xp"},
	{"k":"brutal_finish_lvl",    "n":"Brutal Finish",    "exp": "brutal_finish_xp"},
	{"k":"guardian_shell_lvl",   "n":"Guardian Shell",   "exp": "guardian_shell_xp"},
	{"k":"evasion_training_lvl", "n":"Evasion Training", "exp": "evasion_training_xp"},
]

var PASSIVE_TOTAL_TO_LEVEL = {1: 0}


func _ready() -> void:
	PASSIVE_TOTAL_TO_LEVEL = ServerParams.PASSIVE_TOTAL_TO_LEVEL
		
	AccountManager.signal_InventoryReceived.connect(_on_request_inventory)
	AccountManager.signal_AccountDataReceived.connect(_update_character_talents_signal)
	_update_character_talents()

		
	_setup_ui_layout()
	_build_inventory_grid()
	_build_equipment_ui()
	
	Styler.style_panel(equipment_panel, Styler.COL_PANEL_GRAY, Styler.COL_PANEL_BR)
	Styler.style_panel(inventory_panel, Styler.COL_PANEL_GRAY, Styler.COL_PANEL_BR)
	
	Styler.style_panel(skill_panel, Styler.COL_PANEL_GRAY, Styler.COL_PANEL_BR)
	Styler.style_panel(talents_panel, Styler.COL_PANEL_GRAY, Styler.COL_PANEL_BR)
	
	Styler.style_button(btn_gear, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_skills, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_talents, Color.from_rgba8(64,180,255))
	
	Styler.style_button_small(btn_all, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_gear_only, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_consumable_only, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_loot_only, Color.from_rgba8(255,200,66))
	Styler.style_button_small(btn_sort, Color.from_rgba8(255,200,66))
	Styler.style_name_label(space_label, Color.from_rgba8(255,215,128))
	Styler.style_name_label(gold_label, Color.from_rgba8(255,215,128))
	Styler.style_name_label(diamond_label, Color.from_rgba8(255,215,128))
	
	Styler.style_panel(talent_panel, Styler.COL_PANEL_BG, Styler.COL_PANEL_BR)
	
	var pirat_tex = load("res://assets/background/pirat.png") as Texture2D
	if pirat_tex:
		character_model.texture = pirat_tex

func _process(_delta: float) -> void:
	if _tooltip_visible:
		_update_tooltip_position_to_point(_last_pointer_pos)

func _unhandled_input(event: InputEvent) -> void:
	# Close tooltip on click outside or specific interactions
	if _tooltip_visible:
		if (event is InputEventScreenTouch and event.pressed) or \
		   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
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
	#emit_signal("equipped_item", slot_name, item_id)

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

	_slots.resize(columns * rows)
	for i in range(columns * rows):
		_grid.add_child(_create_inventory_slot_node(i))

func _create_inventory_slot_node(index: int) -> Control:
	var panel = PanelContainer.new()
	panel.name = "Slot_%d" % index
	panel.custom_minimum_size = Vector2(slot_size)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	
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
	
	# Only use the external override if provided, otherwise use our new border style
	panel.add_theme_stylebox_override("panel", sb)
	
	var btn = Button.new()
	btn.name = "Btn"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	#count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	#count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_font_size_override("font_size", 12)
	#count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	#count.position.x -= 20
	#count.position.y -= 20
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
	var panel = PanelContainer.new()
	panel.name = slot_name
	panel.custom_minimum_size = Vector2(slot_size_eq)
	
	# Style
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
	
	_eq_slot_nodes[slot_name] = {"panel": panel, "btn": btn, "icon": icon}
	_update_equipment_slot_visuals(slot_name)
	return panel


# --- Interactions & Tooltips ---
func _handle_slot_input(event: InputEvent, btn: Control, source: String, index: int = -1, slot_name: String = "") -> void:
	# source: "inventory" or "equipment"
	if event is InputEventScreenTouch and event.pressed:
		_last_pointer_pos = btn.get_global_rect().position + event.position
		
		# If tooltip already open for this exact item, toggle off
		if _tooltip_visible and _active_tooltip_source == source:
			if (source == "inventory" and _active_tooltip_index == index) or \
			   (source == "equipment" and _active_tooltip_slot == slot_name):
				_hide_tooltip()
				return
		
		_show_tooltip(source, index, slot_name)

	elif event is InputEventScreenDrag:
		_last_pointer_pos = btn.get_global_rect().position + event.position
		if _tooltip_visible:
			_update_tooltip_position_to_point(event.position)
			
func _show_tooltip(source: String, index: int, slot_name: String) -> void:
	_ensure_tooltip_instance()
	
	var item_data = {}
	var item_def = {}
	
	if source == "inventory":
		if index < 0 or index >= _slots.size() or _slots[index] == null: return
		item_data = _slots[index]
		item_def = _item_defs.get(item_data["id"], {})
		_active_tooltip_index = index
		
	elif source == "equipment":
		if not _equipped.has(slot_name): return
		item_data = _equipped[slot_name]
		item_def = _item_defs.get(item_data["id"], {})
		_active_tooltip_slot = slot_name
	
	if item_def.is_empty() and item_data.has("id"):
		item_def = {"name": item_data["id"], "descr": "Loading..."}

	_tooltip.set_data(item_def, item_data.get("qty", 1))
	
	_active_tooltip_source = source
	_tooltip_visible = true
	_tooltip.visible = true
	_update_tooltip_position_to_point(_last_pointer_pos)

func _hide_tooltip() -> void:
	if _tooltip: _tooltip.visible = false
	_tooltip_visible = false
	_active_tooltip_index = -1
	_active_tooltip_slot = ""
	
func _ensure_tooltip_instance() -> void:
	if _tooltip: return
	_tooltip = WowTooltip.new()
	_tooltip.visible = false
	_tooltip.z_index = 100 # Ensure on top
	add_child(_tooltip)
	SignalManager.signal_UseItem.connect(_on_tooltip_action_use)

func _update_tooltip_position_to_point(global_point: Vector2) -> void:
	if not _tooltip or not _tooltip.visible: return
	
	var vp_size = get_viewport().get_visible_rect().size
	var t_size = _tooltip.get_combined_minimum_size()
	
	var pos = global_point
	# Basic collision logic
	if pos.x + t_size.x + TOOLTIP_MARGIN > vp_size.x:
		pos.x -= (t_size.x + TOOLTIP_MARGIN)
	else:
		pos.x += TOOLTIP_MARGIN
		
	if pos.y + t_size.y + TOOLTIP_MARGIN > vp_size.y:
		pos.y -= (t_size.y + TOOLTIP_MARGIN)
	else:
		pos.y += TOOLTIP_MARGIN
		
	_tooltip.global_position = pos


# --- Visual Updates ---
func _refresh_all_inventory_slots() -> void:
	for i in _grid.get_child_count():
		_refresh_inventory_slot_visuals(i)

func _refresh_inventory_slot_visuals(index: int) -> void:
	if index >= _grid.get_child_count(): return
	var slot_node = _grid.get_child(index)
	var btn = slot_node.get_node("Btn")
	var icon = btn.get_node("Icon")
	var count_lbl = btn.get_node("Count")
	
	var sb: StyleBoxFlat = slot_node.get_theme_stylebox("panel") as StyleBoxFlat
	
	var s = _slots[index]
	
	if s == null:
		icon.texture = null
		count_lbl.text = ""
		btn.disabled = true
		slot_node.tooltip_text = ""
		
		if sb:
			sb.border_color = Color(0.25, 0.25, 0.3)
		return
	
	var def = _item_defs.get(s["id"], {})
	
	var id = s["id"]
	var qty = s["qty"]
	icon.texture = ItemDB.ITEM_ICONS.get(id, null)
	btn.disabled = false
	count_lbl.text = str(qty) if (show_stack_count and qty > 1) else ""
	
	if sb:
		# Default to quality 1 (Common) if not found
		var q = int(def.get("quality", 1))
		# Use your existing QUALITY_COLORS constant
		sb.border_color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])
	
	# Simple hover tooltip text (fallback)
	if show_tooltips:
		var nm = String(def.get("name", id))
		var ds = String(def.get("descr", ""))
		slot_node.tooltip_text = nm + ("\n" + ds if ds != "" else "")
		#slot_node.tooltip_text = def.get("name", id)

func _update_equipment_slot_visuals(slot_name: String) -> void:
	if not _eq_slot_nodes.has(slot_name): return
	
	var nodes = _eq_slot_nodes[slot_name]
	var panel = nodes["panel"]
	var icon = nodes["icon"]
	var sb = panel.get_theme_stylebox("panel") as StyleBoxFlat
	
	if _equipped.has(slot_name):
		var id = _equipped[slot_name]["id"]
		icon.texture = ItemDB.ITEM_ICONS.get(id, null)
		
		# Quality Border Color
		if sb:
			var def = _item_defs.get(id, {})
			var q = int(def.get("quality", 1))
			sb.border_color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])
	else:
		icon.texture = null
		if sb:
			sb.border_color = Color(0.25, 0.25, 0.3)


# --- Signal Callbacks ---
func _on_request_inventory(server_json) -> void:
	# 1. Clear current
	clear_inventory()
	_equipped.clear()
	_item_defs = {}
	
	var data = server_json.data
	
	# 2. Parse Equipment (server sends "code", we map to "id")
	if data.has("equipment"):
		for item in data.equipment:
			#print(item)
			var id = item.get("code", "")
			var slot = item.get("slot", "")
			if id and slot:
				_item_defs[id] = item
				equip(slot, id)

	# 3. Parse Inventory
	if data.has("inventory"):
		for item in data.inventory:
			#print(item)
			var id = item.get("code", "")
			var qty = int(item.get("qty", 1))
			if id:
				add_item(id, qty, item)

func _on_tooltip_action_use(def: Dictionary) -> void:
	if _active_tooltip_source == "inventory" and _active_tooltip_index != -1:
		# Use logic here, e.g., consume item
		# remove_at(_active_tooltip_index, 1)
		pass
	_hide_tooltip()

# ------------ TALENTS ----------
func _update_character_talents() -> void:
	var stats = Account.to_dict()
	set_stats(stats)
	
func _update_character_talents_signal() -> void:
	var stats = Account.to_dict()
	set_stats(stats)
	
func set_stats(d: Dictionary) -> void:
	_clear(talent_grid);

	# Talent cards
	for entry in TALENT_KEYS:
		var lvl = int(d.get(entry.k, 0))
		var exp = int(d.get(entry.exp, 0))
		var card = _make_mini_card_primary(entry.n, lvl, exp, Styler.COL_PRIMARY)
		talent_grid.add_child(card)
		
func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _make_mini_card_primary(name: String, lvl: int, exp: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	
	var lvl_current = exp - PASSIVE_TOTAL_TO_LEVEL[str(lvl)]
	var lvl_progress = PASSIVE_TOTAL_TO_LEVEL[str(lvl + 1)] - PASSIVE_TOTAL_TO_LEVEL[str(lvl)]
	
	var whole = int(lvl)
	var frac  = float(lvl_current) / float(lvl_progress)         # 0.0 .. 1.0
	var pct   = int(round(frac * 100.0))   # 0 .. 100
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 96)
	panel.add_theme_stylebox_override("panel", Styler.card_box())
	panel.tooltip_text = "Passive Talents"
	
	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(main_hbox)
	
	# --- icon position ---
	var icon_box := VBoxContainer.new()
	icon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_box.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(icon_box)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(96, 96)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_key = {
		"Thick Skin"      : "thick_skin",
		"Brutal Finish"   : "brutal_strike",
		"Guardian Shell"  : "guardian_shell",
		"Evasion Training": "evasion_training",
	}
	
	icon.texture = ItemDB.ICONS.get(icon_key.get(name))
	icon_box.add_child(icon)
	
	# --- first line: name + value ---
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(vb)
	
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
		
	var n_lbl := Label.new()
	n_lbl.text = name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(whole)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 24)
	v_lbl.add_theme_color_override("font_color", accent)
	hb.add_child(v_lbl)
#
	## --- second line: fractional progress bar (0..100) ---
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 12)   # height of the bar
	Styler.style_mini_progress(pb, accent)    # style below
	vb.add_child(pb)

	return panel


# ------------ Control buttons callbacks ----------
func _on_btn_gear_pressed() -> void:
	gear_panel.visible = true
	skill_panel.visible = false
	talents_panel.visible = false

func _on_btn_skills_pressed() -> void:
	gear_panel.visible = false
	skill_panel.visible = true
	talents_panel.visible = false

func _on_btn_talents_pressed() -> void:
	gear_panel.visible = false
	skill_panel.visible = false
	talents_panel.visible = true
