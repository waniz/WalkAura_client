class_name ActivityProgressView extends Control

var _card_box_ref: Callable = Callable() # call to get StyleBox for panel
var _item_name_resolver: Callable = Callable() # (id:String)->String

@onready var _panel: PanelContainer = $PanelContainer
@onready var _title: Label = $PanelContainer/VBoxContainer/Title
@onready var close_button: Button = $PanelContainer/VBoxContainer/Close

@onready var _grid: GridContainer = $PanelContainer/VBoxContainer/ContentScroll/GridContainer

@onready var _steps_label: Label = $PanelContainer/VBoxContainer/ContentScroll/GridContainer/stepsLabel
@onready var _xp_label: Label = $PanelContainer/VBoxContainer/ContentScroll/GridContainer/xpLabel
@onready var _xp_bar: ProgressBar = $PanelContainer/VBoxContainer/ContentScroll/GridContainer/ProgressBar
@onready var loot_title: Label = $PanelContainer/VBoxContainer/ContentScroll/GridContainer/LootTitle
@onready var _loot_list: VBoxContainer = $PanelContainer/VBoxContainer/ContentScroll/GridContainer/LootList

@onready var root: VBoxContainer = $PanelContainer/VBoxContainer
var _equipment_list: VBoxContainer
var icon_mapper: Dictionary

var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)
var bg_color = Color.from_rgba8(28, 30, 40, 255)
var border_color = Color.from_rgba8(255, 255, 255, 30)


func _ready() -> void:
	_build_ui()
	
	# Create the equipment container dynamically since it might not exist in scene
	_equipment_list = VBoxContainer.new()
	_equipment_list.name = "EquipmentList"
	_equipment_list.add_theme_constant_override("separation", 6)
	
	# Add it to the main grid, right after the loot list
	_grid.add_child(_equipment_list)
	
	Styler.style_panel(_panel, COL_PANEL_BG, COL_PANEL_BR)
	Styler.style_title(_title)
	Styler.style_title(loot_title)
	Styler.style_button(close_button, Color.from_rgba8(255,200,66))
	Styler.wire_button_anim(close_button)
	Styler.style_name_label(_steps_label, Color.from_rgba8(255, 215, 128))
	Styler.style_name_label(_xp_label, Color.from_rgba8(255, 215, 128))
	Styler.style_bar(_xp_bar, bg_color, border_color)


func set_card_box(card_box_callable: Callable) -> void:
	_card_box_ref = card_box_callable
	if is_instance_valid(_panel) and _card_box_ref.is_valid():
		var sb = _card_box_ref.call()
		if typeof(sb) == TYPE_OBJECT:
			_panel.add_theme_stylebox_override("panel", sb)


func set_item_name_resolver(resolver: Callable) -> void:
	_item_name_resolver = resolver
	
# ------------------ Public API ------------------
func apply_activity_progress(d: Dictionary) -> void:
	var activities_completed: int = int(d.get("activities_completed", 0))
	var steps_in: int = int(d.get("steps_in", 0))
	var xp_gained: int = int(d.get("xp_gained", 0))
	var lvl: int = int(d.get("level", 1))
	var lvl_prev: int = int(d.get("level_before", lvl))
	var lvls_gained: int = int(d.get("levels_gained", 0))
	var xp_into: int = int(d.get("xp_into_level", 0))
	var xp_to_next = d.get("xp_to_next", null)
	var req_skill: int = int(d.get("req_skill", 1))

	# Loot Data
	var resource_counts = d.get("loot_counts", {}) # Standard resources (Wood, Ore)
	var equipment_blueprints = d.get("new_items", []) # New Gear
	icon_mapper = d.get("mapping", [])
	
	# Title / header
	var title = "Activity Progress"
	if d.has("locked") and d["locked"]:
		title += " — Locked: requires %d" % req_skill
	elif lvls_gained > 0:
		title += " — Level Up x%d!" % lvls_gained
	_title.text = title
	
	# Steps progress
	_steps_label.text = "Progress: (+%d steps, %d activities finishes)" % [steps_in, activities_completed]
	
	# XP progress
	if xp_to_next:
		_xp_bar.max_value = max(1, int(xp_to_next))
		_xp_bar.value = clamp(xp_into, 0, _xp_bar.max_value)
	else:
		_xp_bar.value = 100
		_xp_bar.max_value = 100

	_xp_label.text = "Activity Level %d (%d -> %d) XP: +%d" % [lvl, lvl_prev, lvl, xp_gained]
	
	loot_title.text = "Loot:"

	# Render Both Lists
	_render_loot(resource_counts)
	_render_equipment(equipment_blueprints)

# ------------------ UI building ------------------
func _build_ui() -> void:
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_panel.name = "Card"
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if _card_box_ref.is_valid():
		var sb = _card_box_ref.call()
		if typeof(sb) == TYPE_OBJECT:
			_panel.add_theme_stylebox_override("panel", sb)

	root.name = "Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)

	_title.text = "Activity Progress"
	_title.add_theme_font_size_override("font_size", 18)

	# Stats Grid settings
	_grid.columns = 1
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 6)

	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.min_value = 0; _xp_bar.max_value = 100; _xp_bar.value = 0
	_xp_bar.tooltip_text = "XP into current level"
	
	# Spacers/Layout
	# Check if spacer exists to avoid duplicate adding if scene is static
	# _grid.add_child(_mk_spacer()) 

	loot_title.text = "Loot"
	loot_title.add_theme_font_size_override("font_size", 16)

	_loot_list.add_theme_constant_override("separation", 6)
	
func _mk_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l

func _mk_spacer() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(1, 1)
	return c
	
# ------------------ Loot rendering ------------------
func _render_loot(summary) -> void:
	for c in _loot_list.get_children():
		c.queue_free()

	if summary == null:
		return

	for key in summary.keys():
		var qty = int(summary[key])
		var icon_key = icon_mapper.get(key, key)
		var row = _create_loot_row(icon_key, "x%d" % qty)
		_loot_list.add_child(row)

func _render_equipment(items: Array) -> void:
	# Clear previous items
	for c in _equipment_list.get_children():
		c.queue_free()
		
	if items.is_empty():
		return

	# Header
	var eq_header = Label.new()
	eq_header.text = "New Equipment"
	eq_header.add_theme_font_size_override("font_size", 16)
	eq_header.add_theme_color_override("font_color", Color(1, 0.84, 0.0)) # Gold
	_equipment_list.add_child(eq_header)

	for item_data in items:
		# 1. Extract Icon
		var icon_key = "chest_closed" 
		var item_quality = int(item_data.get("quality", 1))
		
		if item_data.has("item_icon"):
			var raw_icon = item_data["item_icon"]
			# Safety check: Handle Python lists ["icon"] vs Strings "icon"
			if raw_icon is Array and not raw_icon.is_empty():
				icon_key = str(raw_icon[0])
			elif raw_icon is String:
				icon_key = raw_icon

		# 2. Extract Name and Level
		# Try to use the real name if available, otherwise fallback to "Unidentified"
		var ilvl = item_data.get("ilvl", item_data.get("monster_level", 1))
		var display_name = item_data.get("name", "Unidentified Item (Lvl %d)" % ilvl)

		# 3. Create the Row
		# We pass the icon_key directly to our helper
		var row = _create_loot_row(icon_key, "New!", Color(1, 0.8, 0.2))
		
		# 4. Update the Name Label
		# _create_loot_row auto-capitalizes the icon name, so we overwrite it with the real name
		var name_lbl = row.get_child(1) as Label
		name_lbl.add_theme_color_override("font_color", Styler.QUALITY_COLORS[item_quality])
		name_lbl.text = display_name
		
		_equipment_list.add_child(row)

# Shared helper to create a visual row (Icon + Name + Right Text)
func _create_loot_row(icon_key: String, right_text: String, right_color = null) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	
	# Icon
	var icon = TextureRect.new()
	var tex: Texture2D = ItemDB.ITEM_ICONS.get(icon_key, ItemDB.ITEM_ICONS.get("default_bag"))
	icon.texture = tex
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	# Name Label
	var left := Label.new()
	left.text = icon_key.capitalize().replace("_", " ")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(left)

	# Quantity/Status Label
	var right := Label.new()
	right.text = right_text
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if right_color:
		right.add_theme_color_override("font_color", right_color)
	row.add_child(right)
	
	return row


func _on_close_pressed() -> void:
	queue_free()
