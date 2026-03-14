class_name WowTooltip extends PanelContainer

@export var bg_color = Color(0.06, 0.06, 0.08, 0.88)  # dark, 88% opacity
@export var border_width = 2
@export var corner_radius = 8

var _title: Label
var _gear_lvl: Label
var _quality_lvl: Label
var _lines: VBoxContainer

var _def: Dictionary = {}
var _qty: int = 0

var _buttons: VBoxContainer
var _btn_use: Button
var _btn_equip: Button
var _btn_equip_slot2: Button
var _source: String
var _slot_index: int
var _slot_name: String
var _price_label: Label
var _btn_sell: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # ignore pointer, don't steal input
	# Panel styling
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_bottom_left = corner_radius
	sb.corner_radius_bottom_right = corner_radius
	sb.corner_radius_top_left = corner_radius
	sb.corner_radius_top_right = corner_radius
	sb.border_width_bottom = border_width
	sb.border_width_left = border_width
	sb.border_width_right = border_width
	sb.border_width_top = border_width
	sb.border_color = Styler.QUALITY_COLORS[1]
	add_theme_stylebox_override("panel", sb)

	# Layout
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.custom_minimum_size = Vector2(128, 0)
	add_child(root)
	
	var margin_main = MarginContainer.new()
	margin_main.add_theme_constant_override("margin_left", 10)
	margin_main.add_theme_constant_override("margin_top", 10)
	margin_main.add_theme_constant_override("margin_bottom", 10)
	margin_main.add_theme_constant_override("margin_rigt", 10)
	root.add_child(margin_main)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", Styler.GROBOLT_FONT)
	_title.add_theme_font_size_override("font_size", 18)
	margin_main.add_child(_title)
	
	_gear_lvl = Label.new()
	_gear_lvl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_gear_lvl.add_theme_font_size_override("font_size", 18)
	root.add_child(_gear_lvl)
	
	_quality_lvl = Label.new()
	_quality_lvl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_quality_lvl.add_theme_font_size_override("font_size", 18)
	root.add_child(_quality_lvl)

	var sep = HSeparator.new()
	root.add_child(sep)

	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 2)
	root.add_child(_lines)
	
	_buttons = VBoxContainer.new()
	root.add_child(_buttons)
	
	#_footer = HBoxContainer.new()
	##_footer.alignment = BoxContainer.ALIGNMENT_BOTTOM
	#add_child(_footer)

	_btn_use = Button.new()
	Styler.style_button(_btn_use,  Color.from_rgba8(64,180,255))
	_btn_use.text = "Use"
	_btn_use.visible = false
	_btn_use.focus_mode = Control.FOCUS_NONE
	_btn_use.pressed.connect(_on_use_pressed)
	_buttons.add_child(_btn_use)

	_btn_equip = Button.new()
	Styler.style_button(_btn_equip,  Color.from_rgba8(64,180,255))
	_btn_equip.text = "Equip"
	_btn_equip.visible = false
	_btn_equip.focus_mode = Control.FOCUS_NONE
	_btn_equip.pressed.connect(_on_equip_pressed)
	_buttons.add_child(_btn_equip)
	
	_btn_equip_slot2 = Button.new()
	Styler.style_button(_btn_equip_slot2,  Color.from_rgba8(64,180,255))
	_btn_equip_slot2.text = "Equip Slot 2"
	_btn_equip_slot2.visible = false
	_btn_equip_slot2.focus_mode = Control.FOCUS_NONE
	_btn_equip_slot2.pressed.connect(_on_equip_pressed_slot2)
	_buttons.add_child(_btn_equip_slot2)
	
	_btn_sell = Button.new()
	Styler.style_button(_btn_sell, Color.from_rgba8(255, 215, 0)) # Gold button
	_btn_sell.text = "Sell"
	_btn_sell.visible = false
	_btn_sell.pressed.connect(_on_sell_pressed)
	_buttons.add_child(_btn_sell)
	
	_price_label = Label.new()
	_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lines.add_child(_price_label)

func set_data(item_def: Dictionary, qty: int=1, tooltip_source="inventory", slot_index=-1, slot_name="") -> void:
	_def = item_def
	_qty = qty
	_source = tooltip_source
	_slot_index = slot_index
	_slot_name = slot_name
	
	var q = int(item_def.get("quality", 1))
	var color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])

	# Title colored by quality
	_title.text = str(item_def.get("name", "Unknown"))
	_title.add_theme_color_override("font_color", color)
	
	# Main info of item
	_gear_lvl.text = "Gear Lvl: {0}".format([str(int(item_def.get("ilvl", "0")))])
	_gear_lvl.text = "Gear Lvl: {0}".format([str(int(item_def.get("ilvl", "0")))])

	# Border color by quality
	var sb: StyleBox = get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		sb.border_color = color

	# Clear previous lines
	for c in _lines.get_children():
		c.free()

	# Attributes
	var attr_label = Label.new()
	attr_label.text = "Attributes:"

	var item_lvl = item_def.get("ilvl", 0)
	var label_ilvl = Label.new()
	label_ilvl.text = "  Item Level: " + str(item_lvl)
	label_ilvl.modulate = Styler.GOLD_COLOR
	_lines.add_child(label_ilvl)

	var base_attrs: Dictionary = item_def.get("base_attributes", {})
	if base_attrs.keys():
		var pa = Label.new()
		_lines.add_child(pa)
		for k in base_attrs.keys():
			_add_stat_line(k, base_attrs[k])

	var primary_attrs: Dictionary = item_def.get("primary_attributes", {})
	if primary_attrs.keys():
		var pa = Label.new()
		pa.text = "Primary Attributes:"
		pa.modulate = Styler.QUALITY_COLORS[2]
		_lines.add_child(pa)
		for k in primary_attrs.keys():
			_add_stat_line(k, primary_attrs[k])

	var secondary_attrs: Dictionary = item_def.get("secondary_attributes", {})
	if secondary_attrs.keys():
		var sa = Label.new()
		sa.text = "Secondary Attributes:"
		sa.modulate = Styler.QUALITY_COLORS[2]
		_lines.add_child(sa)
		for k in secondary_attrs.keys():
			_add_stat_line(k, secondary_attrs[k])
			
	# Item sell info
	var item_gold = item_def.get("price", 1)
	var label_gold = Label.new()
	label_gold.text = "  Item Sell Price: " + str(item_gold)
	label_gold.modulate = Styler.GOLD_COLOR
	_lines.add_child(label_gold)
		
	# Stack count
	if qty > 1:
		var st := Label.new()
		st.text = "Stack: %d" % qty
		st.modulate = Color(0.9, 0.9, 0.9, 0.9)
		_lines.add_child(st)
	
	_btn_use.visible = _can_use(_def)
	_btn_equip.visible = _can_equip(_def)
	_btn_equip_slot2.visible = false # Default to hidden

	if tooltip_source == "equipment":
		# If we are looking at worn items, we just want Unequip
		_btn_equip.text = "Unequip item"
	else:
		# If looking at Inventory
		var slot_type = str(_def.get("slot_type", "")).to_lower()
		
		# Check if this is a dual-slot item (contains "ring" or "trinket")
		if "ring" in slot_type:
			_btn_equip.text = "Equip (Left)"
			_btn_equip_slot2.text = "Equip (Right)"
			_btn_equip_slot2.visible = true
		elif "trinket" in slot_type:
			_btn_equip.text = "Equip (Left)"
			_btn_equip_slot2.text = "Equip (Right)"
			_btn_equip_slot2.visible = true
		else:
			# Standard item
			_btn_equip.text = "Equip item"
			
	size = Vector2.ZERO
	
	# Enable sell button only in inventory
	if tooltip_source == "inventory":
		_btn_sell.visible = true
		_btn_sell.text = "Sell"
	else:
		_btn_sell.visible = false

func _add_stat_line(key, val):
	var h = HBoxContainer.new()
	var lk = Label.new()
	lk.text = "    " + String(key).capitalize() + ":"
	lk.modulate = Color(0.85,0.85,0.95,1)
	var lv = Label.new()
	lv.text = "+" + str(val)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(lk)
	h.add_child(lv)
	_lines.add_child(h)
	
func _can_use(def: Dictionary) -> bool:
	var item_category = str(def.get("category", "")).to_lower()
	if item_category in ["consumable", "potion", "food"]:
		return true
	return false

func _can_equip(def: Dictionary) -> bool:
	if def.has("slot_type"):
		var slot = str(def["slot_type"])
		return str(slot) not in  ["", "<null>", "None", " "]
	return false
	
func _on_use_pressed() -> void:
	if _def.is_empty():
		return
	SignalManager.signal_UseItem.emit(_def["item_uid"], 1)

func _on_equip_pressed() -> void:
	if _def.is_empty():
		return
		
	if _source == "inventory":
		var slot_to_use = _def["slot_type"]
		
		# If it's a ring/trinket, Button 1 forces the Left/First slot
		if "ring" in str(slot_to_use):
			slot_to_use = "ring_left"
		elif "trinket" in str(slot_to_use):
			slot_to_use = "trinket_left"
			
		SignalManager.signal_EquipItem.emit(_def["item_uid"], slot_to_use)
	elif _source == "equipment":
		SignalManager.signal_UnequipItem.emit(_slot_name)
		
func _on_equip_pressed_slot2() -> void:
	if _def.is_empty():
		return
		
	if _source == "inventory":
		var slot_to_use = _def["slot_type"]
		
		# Button 2 forces the Right/Second slot
		if "ring" in str(slot_to_use):
			slot_to_use = "ring_right"
		elif "trinket" in str(slot_to_use):
			slot_to_use = "trinket_right"
			
		SignalManager.signal_EquipItem.emit(_def["item_uid"], slot_to_use)
		
func _on_sell_pressed():
	if _def.is_empty(): return
	# Emit signal to Inventory.gd to handle the network call
	SignalManager.signal_SellItem.emit(_def["item_uid"])
