class_name Inventory extends Control

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

@onready var btn_split_items: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_Split_Items
@onready var btn_split_currency: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_Split_Currency

@onready var btn_all: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_ALL
@onready var btn_gear_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_GearOnly
@onready var btn_consumable_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_ConsumableOnly
@onready var btn_loot_only: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/Btn_LootOnly
@onready var space_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Space_Label
@onready var btn_sort: Button = $VBox_Root/Body/Gear_Panel/VBoxContainer/Inventory_Panel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Btn_Sort

@onready var talent_panel: PanelContainer = $VBox_Root/Body/Talents_Panel
@onready var talent_grid: GridContainer = $VBox_Root/Body/Talents_Panel/Margin/VBoxContainer/TalentGrid
@onready var talent_margin: MarginContainer = $VBox_Root/Body/Talents_Panel/Margin
@onready var v_box_container: VBoxContainer = $VBox_Root/Body/Talents_Panel/Margin/VBoxContainer
@onready var title_talents: Label = $VBox_Root/Body/Talents_Panel/Margin/VBoxContainer/Title

@onready var ilvl_label: Label = $VBox_Root/Body/Gear_Panel/VBoxContainer/Equipment_Panel/MarginContainer/equipment_vbox/ILVL_Label

@onready var skill_margin: MarginContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin
@onready var v_box_skills: VBoxContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills
@onready var title_active_skills: Label = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/Header
@onready var active_container: HBoxContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/Active_Container
@onready var h_separator: HSeparator = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/HSeparator
@onready var title_spellbook: Label = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/Header2
@onready var h_box_btn_control: HBoxContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/HBox_btn_control
@onready var btn_skills_mage: Button = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/HBox_btn_control/Btn_skills_mage
@onready var btn_skills_paladin: Button = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/HBox_btn_control/Btn_skills_paladin
@onready var btn_skills_buffs: Button = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/VBox_Skills/HBox_btn_control/Btn_skills_buffs
@onready var spellbook_panel_base: PanelContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base
@onready var paladin_panel: PanelContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base/Paladin_Panel
@onready var mage_panel: PanelContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base/Mage_Panel
@onready var buffs_panel: PanelContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base/Buffs_Panel
@onready var paladin_grid_spellbook: GridContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base/Paladin_Panel/paladin_grid_spellbook
@onready var mage_grid_spellbook: GridContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base/Mage_Panel/mage_grid_spellbook
@onready var buffs_grid_spellbook: GridContainer = $VBox_Root/Body/Skill_Panel/Skill_Margin/VBoxContainer/spellbook_panel_base/Buffs_Panel/buffs_grid_spellbook

# --- Layout / Config ---
@export_group("Grid Settings")
@export var columns: int = 10
@export var rows: int = 10
@export var slot_size: Vector2i = Vector2i(48, 48)
@export var slot_padding: int = 5

@export_group("Equipment Settings")
@export var slot_size_eq: Vector2i = Vector2i(64, 64)
@export var slot_padding_eq: int = 10

@export_group("Behavior")
@export var show_stack_count: bool = true
@export var show_tooltips: bool = true

# --- Data ---
# 5 Slots for active skills. Strings act as IDs pointing to _known_skills.
var _active_slots: Array = [null, null, null, null, null]
var _known_skills: Array = []

const TOOLTIP_MARGIN = 8.0
const BOTTOM_HUD_HEIGHT: float = 108.0  # BottomHUD ButtonPanel top offset from screen bottom

# --- State ---
var _last_pointer_pos = Vector2.ZERO
var _slots: Array = []          # Array[Dictionary | null] -> [{"id":String, "qty":int}]
var _equipped: Dictionary = {}  # slot_name -> {"id":String, "qty":int}
var _item_defs: Dictionary = {}
var _active_filter: String = "all"
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

const TALENT_KEYS = [
	{"k":"thick_skin_lvl",       "n":"Thick Skin",       "exp": "thick_skin_xp"},
	{"k":"brutal_finish_lvl",    "n":"Brutal Finish",    "exp": "brutal_finish_xp"},
	{"k":"guardian_shell_lvl",   "n":"Guardian Shell",   "exp": "guardian_shell_xp"},
	{"k":"evasion_training_lvl", "n":"Evasion Training", "exp": "evasion_training_xp"},
]

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

var PASSIVE_TOTAL_TO_LEVEL = {1: 0}


func _ready() -> void:
	PASSIVE_TOTAL_TO_LEVEL = ServerParams.PASSIVE_TOTAL_TO_LEVEL
	
	AccountManager.signal_AccountDataReceived.connect(_on_currency_update)
	AccountManager.signal_InventoryReceived.connect(_on_request_inventory)
	AccountManager.signal_AccountDataReceived.connect(_update_character_talents_signal)
	
	AccountManager.signal_AllSkillsReceived.connect(_update_game_skills)
	AccountManager.signal_AccountSkillsReceived.connect(_update_skills)
	
	if Account.raw_structures.all_server_skills != null and not Account.raw_structures.all_server_skills.is_empty():
		_update_game_skills(Account.raw_structures.all_server_skills)
		
	if Account.raw_structures.account_skills != null and not Account.raw_structures.account_skills.is_empty():
		_update_skills(Account.raw_structures.account_skills)
	
	_update_character_talents()
	_setup_ui_layout()
	_build_inventory_grid()
	_build_equipment_ui()
	
	_style_main_interface()
	
	var min_btn_size = Vector2(128, 40) # 128px width, 40px height
	btn_gear.custom_minimum_size = min_btn_size
	btn_skills.custom_minimum_size = min_btn_size
	btn_talents.custom_minimum_size = min_btn_size
	
	Styler.style_button(btn_gear, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_skills, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_talents, Color.from_rgba8(64,180,255))

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
	
	var pirat_tex = load("res://assets/background/pirat.png") as Texture2D
	if pirat_tex:
		character_model.texture = pirat_tex
		
	gold_texture.texture = ItemDB.ICONS.get("gold_coin")
	gold_label.text = " Gold: {0}".format([str(int(Account.gold))])
	
	_setup_skill_panel_structure()
	_refresh_skills_ui()
	
	
func _process(_delta: float) -> void:
	if _tooltip_visible:
		_update_tooltip_position_to_point(_last_pointer_pos)

func _input(event: InputEvent) -> void:
	if not _tooltip_visible or not _tooltip:
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
	
	var count := Label.new()
	count.name = "Count"
	count.add_theme_font_size_override("font_size", 10)
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
	var wrapper := VBoxContainer.new()
	wrapper.name = slot_name
	wrapper.add_theme_constant_override("separation", 2)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(slot_size_eq)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.4)
	sb.border_width_bottom = 2; sb.border_width_top = 2; sb.border_width_left = 2; sb.border_width_right = 2
	sb.border_color = Color(0.25, 0.25, 0.3)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.gui_input.connect(func(e): _handle_slot_input(e, btn, "equipment", -1, slot_name))
	panel.add_child(btn)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -4
	btn.add_child(icon)

	wrapper.add_child(panel)

	var lbl := Label.new()
	lbl.text = SLOT_DISPLAY_NAMES.get(slot_name, slot_name)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	wrapper.add_child(lbl)

	_eq_slot_nodes[slot_name] = {"panel": panel, "btn": btn, "icon": icon, "label": lbl}
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
		if _tooltip_visible:
			_update_tooltip_position_to_point(event.position)

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

		var compare_def := _get_equipped_def_for_slot(str(item_def.get("slot_type", "")))
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

func _ensure_compare_tooltip() -> void:
	if _compare_tooltip: return
	_compare_tooltip = LegionTooltip.new()
	_compare_tooltip.visible = false
	_compare_tooltip.z_index = 99
	add_child(_compare_tooltip)

func _get_equipped_def_for_slot(slot_type: String) -> Dictionary:
	var s := slot_type.to_lower()
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

	var vp_size      := get_viewport().get_visible_rect().size
	var left_limit   := TOOLTIP_MARGIN
	var top_limit    := TOOLTIP_MARGIN
	var right_limit  := vp_size.x - TOOLTIP_MARGIN
	var bottom_limit := vp_size.y - BOTTOM_HUD_HEIGHT - TOOLTIP_MARGIN

	var t_size := _tooltip.size if _tooltip.size.x > 1 else _tooltip.get_combined_minimum_size()

	if _compare_tooltip and _compare_tooltip.visible:
		# --- Joint layout: treat [compare | gap | primary] as one block ---
		var cmp_size := _compare_tooltip.size if _compare_tooltip.size.x > 1 \
						else _compare_tooltip.get_combined_minimum_size()
		var total_w  := cmp_size.x + TOOLTIP_MARGIN + t_size.x
		var max_h    := maxf(t_size.y, cmp_size.y)

		# Vertical: prefer below touch, flip above if overflow, then clamp
		var y := global_point.y + TOOLTIP_MARGIN
		if y + max_h > bottom_limit:
			y = global_point.y - max_h - TOOLTIP_MARGIN
		y = clamp(y, top_limit, maxf(top_limit, bottom_limit - max_h))

		# Horizontal: place compare to left and primary to right of touch point.
		# Try: primary starts at touch + margin, compare is to its left.
		var primary_x := global_point.x + TOOLTIP_MARGIN
		var compare_x := primary_x - cmp_size.x - TOOLTIP_MARGIN

		# If the block extends past the right edge, shift left so primary fits
		if primary_x + t_size.x > right_limit:
			primary_x = right_limit - t_size.x
			compare_x = primary_x - cmp_size.x - TOOLTIP_MARGIN

		# If compare went off the left edge, shift the whole block right
		if compare_x < left_limit:
			var shift := left_limit - compare_x
			compare_x  += shift
			primary_x  += shift

		# Final safety clamp (handles edge case where total_w > available space)
		compare_x = clamp(compare_x, left_limit, right_limit)
		primary_x = clamp(primary_x, left_limit, right_limit)

		_compare_tooltip.global_position = Vector2(compare_x, y)
		_tooltip.global_position         = Vector2(primary_x, y)
	else:
		# --- Single tooltip layout ---
		var pos := global_point

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
	Styler._apply_parchment_style(talents_panel)
	item_scroll_container.get_v_scroll_bar().custom_minimum_size.x = 16
	
	var transparent_sb = StyleBoxFlat.new()
	transparent_sb.bg_color = Color(0,0,0,0)
	transparent_sb.border_width_bottom = 1
	transparent_sb.border_color = Color(0,0,0,0.2)

	equipment_panel.add_theme_stylebox_override("panel", transparent_sb)

	var inv_sb := StyleBoxFlat.new()
	inv_sb.bg_color     = Color(0.06, 0.07, 0.10, 0.75)
	inv_sb.border_color = Color.from_rgba8(255, 200, 66, 55)
	inv_sb.border_width_bottom = 1; inv_sb.border_width_top  = 1
	inv_sb.border_width_left   = 1; inv_sb.border_width_right = 1
	inv_sb.set_corner_radius_all(8)
	inventory_panel.add_theme_stylebox_override("panel", inv_sb)

	var grid_sb := StyleBoxFlat.new()
	grid_sb.bg_color     = Color(0.04, 0.04, 0.07, 0.85)
	grid_sb.border_color = Color(0, 0, 0, 0.3)
	grid_sb.border_width_bottom = 1; grid_sb.border_width_top  = 1
	grid_sb.border_width_left   = 1; grid_sb.border_width_right = 1
	grid_sb.set_corner_radius_all(4)
	item_container.add_theme_stylebox_override("panel", grid_sb)
	
	title_talents.text = "Passive Skills"
	title_talents.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_talents.add_theme_font_size_override("font_size", 22)
	title_talents.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1)) # Dark Title

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
	icon.texture = ItemDB.ITEM_ICONS.get(def["item_icon"], null)
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

func _update_equipment_slot_visuals(slot_name: String) -> void:
	if not _eq_slot_nodes.has(slot_name): return

	var nodes = _eq_slot_nodes[slot_name]
	var panel = nodes["panel"]
	var icon  = nodes["icon"]
	var lbl   = nodes.get("label")
	var sb    = panel.get_theme_stylebox("panel") as StyleBoxFlat

	if _equipped.has(slot_name):
		var id  = _equipped[slot_name]["id"]
		var def = _item_defs.get(id, {})
		var raw = def.get("item_icon", "")
		var icon_key: String = raw[0] if raw is Array and not raw.is_empty() else str(raw)
		icon.texture  = ItemDB.ITEM_ICONS.get(icon_key, null)
		icon.modulate = Color.WHITE
		if sb:
			var q = int(def.get("quality", 1))
			sb.border_color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])
		if lbl:
			lbl.add_theme_color_override("font_color", Styler.GOLD_COLOR)
	else:
		var ph_key = SLOT_PLACEHOLDER_ICONS.get(slot_name, "")
		icon.texture  = ItemDB.ITEM_ICONS.get(ph_key, null) if ph_key != "" else null
		icon.modulate = Color(1, 1, 1, 0.25)
		if sb:
			sb.border_color = Color(0.25, 0.25, 0.3)
		if lbl:
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))


# --- Signal Callbacks ---
func _on_request_inventory(server_json) -> void:
	# 1. Clear current
	
	_equipped.clear()
	_item_defs.clear()
	
	clear_inventory()
	for slot_name in _eq_slot_nodes:
		_update_equipment_slot_visuals(slot_name)
		
	var data = server_json.data
	
	# 2. Parse Equipment (server sends "code", we map to "id")
	if data.has("equipment"):
		for item in data.equipment:
			#print(item)
			var id = str(item.get("item_uid", ""))
			var slot = item.get("slot", "")
			if id and slot:
				_item_defs[id] = item
				equip(slot, id)

	# 3. Parse Inventory
	if data.has("inventory"):
		for item in data.inventory:
			#print(item)
			var id = str(item.get("item_uid", ""))
			var qty = int(item.get("qty", 1))
			_item_defs[id] = item
			add_item(id, qty, item)
			
	_update_mean_ilvl()
	_sort_and_compact()

func _update_space_label() -> void:
	var occupied := 0
	for s in _slots:
		if s != null:
			occupied += 1
	space_label.text = "Space %d / %d" % [occupied, _slots.size()]

func _on_currency_update(server_json):
	gold_label.text = " Gold: {0}".format([str(int(Account.gold))])

func _on_tooltip_action_use(_item_uid, _qty: int) -> void:
	_hide_tooltip()

func _update_game_skills(server_json):
	_known_skills = server_json["data"]["all_skills"]

func _update_skills(server_json):
	var skills_data = server_json["data"]["skills"]
	if len(skills_data) > 0:
		for key in skills_data.keys():
			_active_slots[int(skills_data[key]["slot"])] = int(skills_data[key]["skill_id"])

# ==============================================================================
# TALENTS UI
# ==============================================================================
func _update_character_talents() -> void:
	var stats = Account.to_dict()
	set_stats(stats)

func _update_character_talents_signal(dummy) -> void:
	var stats = Account.to_dict()
	set_stats(stats)

func set_stats(d: Dictionary) -> void:
	_clear(talent_grid)

	# Use GOLD color for accent
	var accent_color = Styler.COLOR_GOLD
	
	for entry in TALENT_KEYS:
		var lvl = int(d.get(entry.k, 0))
		var exp = int(d.get(entry.exp, 0))
		var card = _make_mini_card_primary(entry.n, lvl, exp, accent_color)
		talent_grid.add_child(card)

func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _make_mini_card_primary(name: String, lvl: int, exp: int, accent: Color) -> Control:
	# Calculation
	var lvl_key = str(lvl)
	var next_lvl_key = str(lvl + 1)
	var cur_base = PASSIVE_TOTAL_TO_LEVEL.get(lvl_key, 0)
	var next_base = PASSIVE_TOTAL_TO_LEVEL.get(next_lvl_key, cur_base + 100)
	var lvl_current = exp - cur_base
	var lvl_progress = next_base - cur_base
	var frac = 0.0
	if lvl_progress > 0: frac = float(lvl_current) / float(lvl_progress)
	var pct = int(round(frac * 100.0))

	# Card Container (Parchment Compatible Style)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 80)
	panel.tooltip_text = name + "\n(Passive Talent)"
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.06) # Faint Dark Tint
	sb.border_width_left = 1; sb.border_width_top = 1; sb.border_width_right = 1; sb.border_width_bottom = 1
	sb.border_color = Color(0.0, 0.0, 0.0, 0.2)
	sb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", sb)
	
	var main_hbox := HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",5); m.add_theme_constant_override("margin_right",5)
	m.add_theme_constant_override("margin_top",5); m.add_theme_constant_override("margin_bottom",5)
	panel.add_child(m)
	m.add_child(main_hbox)
	
	# Icon
	var icon_box := VBoxContainer.new()
	icon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(icon_box)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Icon Border
	var icon_border = PanelContainer.new()
	var ib_sb = StyleBoxFlat.new()
	ib_sb.bg_color = Color.TRANSPARENT
	ib_sb.border_width_left = 1; ib_sb.border_width_top = 1; ib_sb.border_width_right = 1; ib_sb.border_width_bottom = 1
	ib_sb.border_color = Color(0.1, 0.1, 0.1, 0.8)
	ib_sb.set_corner_radius_all(4)
	icon_border.add_theme_stylebox_override("panel", ib_sb)
	icon_border.add_child(icon)
	icon_box.add_child(icon_border)
	
	var icon_key = {
		"Thick Skin": "thick_skin", "Brutal Finish": "brutal_strike",
		"Guardian Shell": "guardian_shell", "Evasion Training": "evasion_training",
	}
	if ItemDB.ICONS.has(icon_key.get(name)):
		icon.texture = ItemDB.ICONS.get(icon_key.get(name))
	
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 8
	main_hbox.add_child(spacer)
	
	# Text Info
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(vb)
	
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
		
	var n_lbl := Label.new()
	n_lbl.text = name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# FIX: Dark Text for Parchment
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	n_lbl.add_theme_font_size_override("font_size", 14)
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(lvl)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 18)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	hb.add_child(v_lbl)

	# Progress Bar
	var pb := ProgressBar.new()
	pb.min_value = 0; pb.max_value = 100; pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 8)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.2)
	bg_style.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = accent
	fill_style.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("fill", fill_style)
	vb.add_child(pb)

	return panel

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
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(64, 180, 255) if btn == active_btn else Color.from_rgba8(60, 60, 70)

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
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
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
	var filter_btns := {
		"all": btn_all,
		"equipment": btn_gear_only,
		"consumable": btn_consumable_only,
		"material": btn_loot_only,
	}
	for key in filter_btns:
		var btn = filter_btns[key]
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
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


# --------------------------------
# Active skills Block
# --------------------------------
# ==============================================================================
# 1. UI STRUCTURE BUILDER
# ==============================================================================
func _setup_skill_panel_structure() -> void:
	# A. Style the Main Panel (Parchment Look)
	var main_sb = StyleBoxFlat.new()
	main_sb.bg_color = Styler.COLOR_PARCHMENT
	main_sb.border_width_left = 4
	main_sb.border_width_right = 4
	main_sb.border_width_top = 4
	main_sb.border_width_bottom = 4
	main_sb.border_color = Styler.COLOR_BORDER
	main_sb.set_corner_radius_all(4)
	skill_panel.add_theme_stylebox_override("panel", main_sb)

	# B. Vertical Layout
	v_box_skills.add_theme_constant_override("separation", 15)

	# --- SECTION 1: ACTIVE SKILLS ---
	title_active_skills.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_active_skills.add_theme_font_size_override("font_size", 22)
	title_active_skills.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1)) # Dark Title

	# Container for the 5 slots
	active_container.alignment = BoxContainer.ALIGNMENT_CENTER
	active_container.add_theme_constant_override("separation", 15) # Spacing between slots
	
	# Add Visual Separator
	h_separator.modulate = Color(0,0,0, 0.3)

	# --- SECTION 2: SPELLBOOK ---
	title_spellbook.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_spellbook.add_theme_font_size_override("font_size", 22)
	title_spellbook.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1)) # Dark Title
	
	# Grids for skills
	mage_grid_spellbook.columns = 2
	mage_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mage_grid_spellbook.add_theme_constant_override("h_separation", 20)
	mage_grid_spellbook.add_theme_constant_override("v_separation", 10)
	
	paladin_grid_spellbook.columns = 2
	paladin_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paladin_grid_spellbook.add_theme_constant_override("h_separation", 20)
	paladin_grid_spellbook.add_theme_constant_override("v_separation", 10)
	
	buffs_grid_spellbook.columns = 2
	buffs_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buffs_grid_spellbook.add_theme_constant_override("h_separation", 20)
	buffs_grid_spellbook.add_theme_constant_override("v_separation", 10)

# ==============================================================================
# 2. LOGIC & RENDERING
# ==============================================================================
func _refresh_skills_ui() -> void:
	_render_active_bar()
	_render_spellbook_lists()

func _render_active_bar() -> void:
	# Clear old slots
	for c in active_container.get_children():
		c.queue_free()
	
	# Create 5 fixed slots
	for i in range(5):
		var skill_id = _active_slots[i]
		
		# Slot Container
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(96, 96)
		btn.toggle_mode = false
		btn.focus_mode = Control.FOCUS_NONE
		
		# Styling: Gold Border for Active Slots
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0,0,0,0.2)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Styler.COLOR_GOLD
		sb.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

		# Content
		if skill_id != null:
			var skill_instance = {}
			for inst in _known_skills:
				if skill_id == int(inst["skill_id"]):
					skill_instance = inst
				
			btn.icon = ItemDB.ICONS[skill_instance["skill_icon"]]
			btn.expand_icon = true
			
			# Fallback Text
			btn.tooltip_text = skill_instance["name"] + "\n(Click to Unequip)"
		else:
			btn.text = ""
			btn.tooltip_text = "Empty Slot"
		
		# Click Event
		btn.pressed.connect(_on_active_slot_clicked.bind(i))
		active_container.add_child(btn)

func _render_spellbook_lists() -> void:
	for c in mage_grid_spellbook.get_children():
		c.queue_free()
	for c in paladin_grid_spellbook.get_children():
		c.queue_free()
	for c in buffs_grid_spellbook.get_children():
		c.queue_free()
	
	for skill_instance in _known_skills:
		#print(skill_instance)
		
		# Each entry is an HBox (Icon + Name/Desc) like the WoW list view
		var row_btn = Button.new()
		row_btn.custom_minimum_size = Vector2(320, 96) # Wide button
		
		# Style: Transparent or faint background
		var sb_norm = StyleBoxFlat.new()
		sb_norm.bg_color = Color(0,0,0, 0.05)
		sb_norm.set_corner_radius_all(4)
		row_btn.add_theme_stylebox_override("normal", sb_norm)
		
		# Layout inside the button
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Let button catch input
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox.position = Vector2(5, 5) # Slight offset
		row_btn.add_child(hbox)
		
		# 1. Icon Placeholder
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(96, 96)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.texture = ItemDB.ICONS[skill_instance["skill_icon"]]
		
		hbox.add_child(icon_rect)
		
		# 2. Text Info
		var vbox_info = VBoxContainer.new()
		vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox_info)
		
		var lbl_name = Label.new()
		lbl_name.text = skill_instance["name"]
		lbl_name.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		lbl_name.add_theme_font_size_override("font_size", 16)
		vbox_info.add_child(lbl_name)
		
		var lbl_descr = Label.new()
		lbl_descr.text = skill_instance["descr"]
		lbl_descr.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		lbl_descr.add_theme_font_size_override("font_size", 14)
		vbox_info.add_child(lbl_descr)
				
		var expl = " Mana: " + _fmt(skill_instance["mp_cost"]) + " Cast time: " + _fmt(float(skill_instance["cast_time"]) / 10) + "s" + " CD: " + _fmt(float(skill_instance["cooldown"]) / 10) + "s"
		var lbl_mp_cost = Label.new()
		lbl_mp_cost.text = expl
		lbl_mp_cost.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		lbl_mp_cost.add_theme_font_size_override("font_size", 12)
		vbox_info.add_child(lbl_mp_cost)
				
		var effect = _parse_effects(skill_instance)
		var lbl_effect = Label.new()
		lbl_effect.text = effect
		lbl_effect.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		lbl_effect.add_theme_font_size_override("font_size", 12)
		vbox_info.add_child(lbl_effect)

		row_btn.pressed.connect(_on_spellbook_clicked.bind(skill_instance))

		# Add to Grid
		if skill_instance["skill_type"] == "mage":
			mage_grid_spellbook.add_child(row_btn)
		elif skill_instance["skill_type"] == "paladin":
			paladin_grid_spellbook.add_child(row_btn)
		elif skill_instance["skill_type"] == "buff":
			buffs_grid_spellbook.add_child(row_btn)

# ==============================================================================
# 3. INTERACTION
# ==============================================================================
func _on_active_slot_clicked(index: int) -> void:
	# Unequip Logic
	if _active_slots[index] != null:
		_active_slots[index] = null
		SignalManager.signal_UnEquipSkill.emit(index)
		_refresh_skills_ui()

func _on_spellbook_clicked(skill_instance: Dictionary) -> void:
	var skill_id = int(skill_instance["skill_id"])
	if skill_id in _active_slots:
		return
		
	# Find first empty slot
	var idx = _active_slots.find(null)
	if idx != -1:
		_active_slots[idx] = skill_id
		SignalManager.signal_EquipSkill.emit(idx, str(skill_id))
		_refresh_skills_ui()
	else:
		print("No empty slots!")

func _on_btn_skills_mage_pressed() -> void:
	mage_panel.visible = true
	paladin_panel.visible = false
	buffs_panel.visible = false

func _on_btn_skills_paladin_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = true
	buffs_panel.visible = false

func _on_btn_skills_buffs_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = true

func _fmt(v) -> String:
	if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
		var is_whole = is_equal_approx(v, float(int(v)))
		if is_whole:
			return str(int(v))
		else:
			return "%0.1f" % v
	return str(v)
	
func _parse_effects(skill_instance):
	var output = " "
	var keys = skill_instance["effect"].keys()
	if "Physical Attack" in keys:
		var value = (float(skill_instance["effect"]["Physical Attack"]) - 1) * 100
		output += "Physical Attack: +" + _fmt(value) + "% "
	if "Max Health" in keys:
		var value = (float(skill_instance["effect"]["Max Health"]) - 1) * 100
		output += "Max Health: +" + _fmt(value) + "% "
	if "DMG multi" in keys:
		var value = (float(skill_instance["effect"]["DMG multi"]) - 1) * 100
		output += "Damage: +" + _fmt(value) + "% from Magic ATK "
	if "Max Shield" in keys:
		var value = (float(skill_instance["effect"]["Max Shield"]) - 1) * 100
		output += "Max Shield: +" + _fmt(value) + "% "
	if "Recovery HP" in keys:
		var value = float(skill_instance["effect"]["Recovery HP"])
		output += "Recovery HP: +" + _fmt(value) + "HP "
		
	if "apply_each" in keys:
		var value = float(skill_instance["effect"]["apply_each"])
		if value > 0:
			output += "every: " + _fmt(value / 10) + "s "
	if "active_ticks" in keys:
		var value = float(skill_instance["effect"]["active_ticks"])
		if value > 0:
			output += "Active for: " + _fmt(value / 10) + "s "
			
	return output
	
