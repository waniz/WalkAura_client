class_name LegionTooltip extends PanelContainer

# --- Visual Config ---
@export var bg_color = Color(0.96, 0.93, 0.85, 1.0) # Beige (Paper color from image)
@export var text_color_dark = Color(0.1, 0.1, 0.1)  # Dark text for beige bgext for beige bg
@export var text_color_green = Color(0.2, 0.7, 0.2) # "Good" stat green
@export var corner_radius = 6
@export var icon_size = Vector2(64, 64)

# --- UI Nodes ---
var _root_vbox: VBoxContainer

# Header
var _lbl_title: Label
var _icon_rect: TextureRect
var _icon_border: PanelContainer
var _lbl_type: Label
var _lbl_ilvl: Label
var _lbl_quality: Label
var _lbl_armor_type: Label

# Body
var _stats_container: VBoxContainer
var _footer_container: VBoxContainer
var _buttons_container: VBoxContainer

# Buttons
var _btn_use: Button
var _btn_equip: Button
var _btn_equip_slot2: Button
var _btn_sell: Button

# Data
var _def: Dictionary = {}
var _source: String = ""
var _slot_name: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 1. Panel Style (Parchment look)
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(corner_radius)
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.2, 0.2, 0.2) # Dark borders top/bottom
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.3)
	add_theme_stylebox_override("panel", sb)

	# 2. Layout Structure
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_root_vbox = VBoxContainer.new()
	_root_vbox.add_theme_constant_override("separation", 6)
	_root_vbox.custom_minimum_size = Vector2(250, 0)
	_root_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(_root_vbox)
	
	# 3. Build Static Layout Nodes
	_setup_header_area()
	_add_visual_separator()
	_setup_body_area()
	_add_visual_separator()
	_setup_footer_area()


func _setup_header_area() -> void:
	# A. Title (Centered)
	_lbl_title = Label.new()
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Safety check for fonts in case Styler isn't ready
	if "GROBOLT_FONT" in Styler:
		_lbl_title.add_theme_font_override("font", Styler.GROBOLT_FONT)
	_lbl_title.add_theme_font_size_override("font_size", 20)
	_lbl_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl_title.add_theme_constant_override("outline_size", 4)
	_root_vbox.add_child(_lbl_title)

	# B. Icon + Meta Data (Side-by-Side HBox)
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	_root_vbox.add_child(header_hbox)

	# Left: Icon
	_icon_border = PanelContainer.new()
	var ib_style = StyleBoxFlat.new()
	ib_style.bg_color = Color.TRANSPARENT
	ib_style.set_border_width_all(2)
	ib_style.border_color = Color.BLACK
	ib_style.set_corner_radius_all(4)
	_icon_border.add_theme_stylebox_override("panel", ib_style)
	
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = icon_size
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_border.add_child(_icon_rect)
	header_hbox.add_child(_icon_border)

	# Right: Metadata VBox
	var meta_vbox = VBoxContainer.new()
	meta_vbox.alignment = BoxContainer.ALIGNMENT_CENTER # Center vertically against icon
	meta_vbox.add_theme_constant_override("separation", 0)
	header_hbox.add_child(meta_vbox)

	_lbl_type = _create_label_simple(text_color_dark)
	_lbl_ilvl = _create_label_simple(text_color_dark)
	_lbl_quality = _create_label_simple(text_color_dark)
	_lbl_armor_type = _create_label_simple(text_color_dark)
	
	meta_vbox.add_child(_lbl_type)
	meta_vbox.add_child(_lbl_ilvl)
	meta_vbox.add_child(_lbl_quality)
	meta_vbox.add_child(_lbl_armor_type)
	
	
func _setup_body_area() -> void:
	# Holds all the stats text
	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 2)
	_stats_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_root_vbox.add_child(_stats_container)


func _setup_footer_area() -> void:
	_footer_container = VBoxContainer.new()
	_root_vbox.add_child(_footer_container)
	
	# Buttons
	_buttons_container = VBoxContainer.new()
	_buttons_container.add_theme_constant_override("separation", 5)
	_buttons_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_root_vbox.add_child(_buttons_container)
	
	# Initialize Buttons (Hidden by default)
	_btn_use = _create_button("Use", Color(0.2, 0.6, 1.0))
	_btn_equip = _create_button("Equip", Color(0.2, 0.8, 0.2))
	_btn_equip_slot2 = _create_button("Equip Slot 2", Color(0.2, 0.8, 0.2))
	_btn_sell = _create_button("Sell", Color(1.0, 0.85, 0.0))
	
# --- Main Data Function ---
func set_data(item_def: Dictionary, qty: int=1, tooltip_source="inventory", slot_index=-1, slot_name="") -> void:
	_def = item_def
	_source = tooltip_source
	_slot_name = slot_name
	
	# 1. Update Header
	var q_idx = int(item_def.get("quality", 1))
	var q_color = Styler.QUALITY_COLORS.get(q_idx, text_color_dark)
	
	_lbl_title.text = item_def.get("name", "Unknown Item")
	_lbl_title.modulate = q_color
	
	# Assumes your item_def has a key "icon" with the full path like "res://icons/sword.png"
	_icon_rect.texture = ItemDB.ITEM_ICONS.get(_def["item_icon"], null)
	
	# Update Icon border color
	var ib_style = _icon_border.get_theme_stylebox("panel")
	ib_style.border_color = q_color
	
	var slot_raw = str(item_def.get("slot_type", "")).capitalize()
	if slot_raw == "" or slot_raw == "None" or slot_raw == "Misc" or slot_raw == "Null" or slot_raw == "<null>":
		_lbl_type.visible = false
	else:
		_lbl_type.text = slot_raw
		_lbl_type.visible = true
	
	# B. Gear Level (Hide if 0)
	var ilvl = _get_safe_int(item_def, "ilvl")
	if ilvl > 0:
		var green_hex = text_color_green.to_html(false)
		_lbl_ilvl.text = "Gear Lv: [color=#%s]%s[/color]" % [green_hex, str(ilvl)]
		_lbl_ilvl.visible = true
	else:
		_lbl_ilvl.visible = false
	
	# Metadata
	_lbl_type.text = str(item_def.get("slot_type", "Misc")).capitalize()
	_lbl_ilvl.text = "Gear Lv: %s" % item_def.get("ilvl", 1)
	
	# Quality Label
	_lbl_quality.text = "Quality: %s" % _get_quality_name(q_idx)
	_lbl_quality.modulate = q_color
	
	# Armor type Label
	var armor_type = item_def.get("armor_type", "null")
	if armor_type == "null" or armor_type == "none" or armor_type == "" or armor_type == "<null>":
		_lbl_armor_type.visible = false
	elif not armor_type:
		_lbl_armor_type.visible = false
	else:
		_lbl_armor_type.text = "Armor type: %s" % armor_type.capitalize()
		_lbl_armor_type.visible = true

	# 2. Rebuild Stats
	_rebuild_stats_section()
	
	# 3. Update Footer & Buttons
	_rebuild_footer(item_def)
	_update_buttons_state()
	
	# Force resize
	custom_minimum_size.y = 0
	await get_tree().process_frame
	size = Vector2.ZERO

func _rebuild_stats_section() -> void:
	# Clear old labels
	for c in _stats_container.get_children():
		c.queue_free()
		
	var base_attrs = _def.get("base_attributes", {})
	var prim_attrs = _def.get("primary_attributes", {})
	var sec_attrs = _def.get("secondary_attributes", {})
	
	# A. "Attribute" Header (Base + Primary)
	if not base_attrs.is_empty() or not prim_attrs.is_empty():
		_add_section_header("Attributes")
		
		# 1. Base Stats (Armor, Block) - Keep Dark/White
		for k in base_attrs:
			_add_stat_row("%s %s" % [base_attrs[k], k.capitalize()], text_color_dark)
		
		for k in prim_attrs:
			# Use color_legendary here instead of text_color_dark
			_add_stat_row("+%s %s" % [prim_attrs[k], k.to_upper()], text_color_green)
	
	# B. "Additional Attributes" Header (Secondary)
	if not sec_attrs.is_empty():
		_add_spacer(8)
		_add_section_header("Additional Attributes")
		
		for k in sec_attrs:
			var val = sec_attrs[k]
			# Example Logic: If val is rating, calculate %, otherwise show raw
			# You can plug your RatingConverter logic here
			var pct_text = ""
			if val is int and val > 0:
				pct_text = " (%.2f%%)" % (float(val)/100.0) # Dummy conversion
			
			var txt = "+%s %s%s" % [val, k.capitalize(), pct_text]
			_add_stat_row(txt, text_color_green, true) # Bold green text

func _rebuild_footer(item_def: Dictionary) -> void:
	for c in _footer_container.get_children():
		c.queue_free()
		
	# Requirements (Level, Class)
	var req_lvl = item_def.get("req_level", 0)
	if req_lvl > 0:
		var l = _create_label_simple(text_color_dark)
		l.text = "Req Lv: %d" % req_lvl
		_footer_container.add_child(l)
		
	# Price
	var price = item_def.get("price", 0)
	if _source == "inventory" and price > 0:
		var l = _create_label_simple(Color(0.8, 0.6, 0.0))
		l.text = "Sell Price: %d Gold" % price
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_footer_container.add_child(l)

# --- Helper Builders ---
func _create_label_simple(color: Color) -> Label:
	var l = Label.new()
	l.add_theme_color_override("font_color", color)
	if "QUADRAT_FONT" in Styler:
		l.add_theme_font_override("font", Styler.QUADRAT_FONT)
	l.add_theme_font_size_override("font_size", 14)
	return l

func _add_section_header(text: String) -> void:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color.BLACK)
	if "GROBOLT_FONT" in Styler:
		l.add_theme_font_override("font", Styler.GROBOLT_FONT)
	l.add_theme_font_size_override("font_size", 16)
	_stats_container.add_child(l)

func _add_stat_row(text: String, color: Color, bold: bool = false) -> void:
	# 1. Create a horizontal row to hold spacer + text
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0) # Tight spacing
	_stats_container.add_child(hbox)
	
	# 2. Add Indentation (The Spacer)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(12, 0) # 12px Left Margin
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)
	
	# 3. Add the Label
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	
	hbox.add_child(l)

func _add_visual_separator() -> void:
	var sep = HSeparator.new()
	sep.modulate = Color(0,0,0, 0.2)
	_root_vbox.add_child(sep)

func _add_spacer(height: int) -> void:
	var c = Control.new()
	c.custom_minimum_size.y = height
	_stats_container.add_child(c)

func _create_button(text: String, color: Color) -> Button:
	var b = Button.new()
	Styler.style_button(b, color)
	b.text = text
	b.visible = false
	b.focus_mode = Control.FOCUS_NONE
	_buttons_container.add_child(b)
	return b

func _update_buttons_state() -> void:
	_btn_use.visible = _can_use()
	_btn_sell.visible = (_source == "inventory")
	_btn_equip_slot2.visible = false # default
	
	if _source == "equipment":
		_btn_equip.text = "Unequip"
		_btn_equip.visible = true
		#_btn_equip.disconnect("pressed", _on_equip_pressed)
		if not _btn_equip.pressed.is_connected(_on_unequip_pressed):
			_btn_equip.pressed.connect(_on_unequip_pressed)
	else:
		_btn_equip.text = "Equip"
		_btn_equip.visible = _can_equip()
		# Check for dual slots (Rings/Trinkets)
		var slot = str(_def.get("slot_type", "")).to_lower()
		if "ring" in slot or "trinket" in slot:
			_btn_equip.text = "Equip (Left)"
			_btn_equip_slot2.text = "Equip (Right)"
			_btn_equip_slot2.visible = true
			
			# Reconnect signals cleanly
			if not _btn_equip.pressed.is_connected(_on_equip_pressed):
				_btn_equip.pressed.connect(_on_equip_pressed)
			if not _btn_equip_slot2.pressed.is_connected(_on_equip_pressed_slot2):
				_btn_equip_slot2.pressed.connect(_on_equip_pressed_slot2)
		else:
			if not _btn_equip.pressed.is_connected(_on_equip_pressed):
				_btn_equip.pressed.connect(_on_equip_pressed)
				
		# add connection for "use" case
		if not _btn_use.pressed.is_connected(_on_use_pressed):
			_btn_use.pressed.connect(_on_use_pressed)
		# add connection for "sell" case
		if not _btn_sell.pressed.is_connected(_on_sell_pressed):
			_btn_sell.pressed.connect(_on_sell_pressed)

func _get_safe_int(data: Dictionary, key: String) -> int:
	var val = data.get(key, 0)
	
	# 1. Handle actual null or missing
	if val == null:
		return 0
		
	# 2. Handle String edge cases
	if val is String:
		var s = val.to_lower()
		if s == "null" or s == "none" or s == "" or s == "<null>":
			return 0
		# Handle "9.0" case (int("9.0") fails, needs int(float("9.0")))
		if "." in s:
			return int(float(s))
			
	# 3. Standard conversion
	return int(val)

# --- Logic Helpers ---
func _get_quality_name(q: int) -> String:
	match q:
		1: return "Common"
		2: return "Uncommon"
		3: return "Rare"
		4: return "Epic"
		5: return "Legendary"
		6: return "MYTHIC"
	return "Common"

func _can_use() -> bool:
	var cat = str(_def.get("category", "")).to_lower()
	return cat in ["consumable", "potion", "food"]

func _can_equip() -> bool:
	var slot = str(_def.get("slot_type", ""))
	return slot in ItemDB.all_slots

# --- Signal Handlers ---
func _on_use_pressed():
	SignalManager.signal_UseItem.emit(_def["item_uid"])
	
func _on_sell_pressed():
	SignalManager.signal_SellItem.emit(_def["item_uid"])

func _on_unequip_pressed(): 
	SignalManager.signal_UnequipItem.emit(_slot_name)

func _on_equip_pressed(): 
	var s = _resolve_slot(false)
	SignalManager.signal_EquipItem.emit(_def["item_uid"], s)

func _on_equip_pressed_slot2(): 
	var s = _resolve_slot(true)
	SignalManager.signal_EquipItem.emit(_def["item_uid"], s)

func _resolve_slot(is_second: bool) -> String:
	var s = str(_def.get("slot_type", ""))
	if "ring" in s: return "ring_right" if is_second else "ring_left"
	if "trinket" in s: return "trinket_right" if is_second else "trinket_left"
	return s
