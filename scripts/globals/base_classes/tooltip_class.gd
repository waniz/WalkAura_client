class_name WowTooltip extends PanelContainer

@export var bg_color = Color(0.06, 0.06, 0.08, 0.88)  # dark, 88% opacity
@export var border_width = 2
@export var corner_radius = 8

var _title: Label
var _lines: VBoxContainer

var _def: Dictionary = {}
var _qty: int = 0

var _footer: HBoxContainer
var _buttons: VBoxContainer
var _btn_use: Button
var _btn_equip: Button

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
	root.custom_minimum_size = Vector2(220, 0)
	add_child(root)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	root.add_child(_title)

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

func set_data(item_def: Dictionary, qty: int=1) -> void:
	_def = item_def
	_qty = qty
	
	# item_def expected keys: name, descr, quality:int, attrs:Dictionary
	var q = int(item_def.get("quality", 1))
	var color = Styler.QUALITY_COLORS.get(q, Styler.QUALITY_COLORS[1])

	# Title colored by quality
	_title.text = String(item_def.get("name", "Unknown"))
	_title.add_theme_color_override("font_color", color)

	# Border color by quality
	var sb: StyleBox = get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		sb.border_color = color

	# Clear previous lines
	for c in _lines.get_children():
		c.queue_free()

	# Description (faded)
	var descr = String(item_def.get("descr", ""))
	if descr != "":
		var d = Label.new()
		d.text = descr
		d.modulate = color
		#d.modulate = Color(1,1,1,0.9)
		_lines.add_child(d)

	# Attributes (key: value)
	var attrs: Dictionary = item_def.get("attrs", {})
	for k in attrs.keys():
		var h = HBoxContainer.new()
		var lk = Label.new()
		lk.text = String(k).capitalize() + ":"
		lk.modulate = Color(0.85,0.85,0.95,1)
		var lv = Label.new()
		lv.text = str(attrs[k])
		lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(lk)
		h.add_child(lv)
		_lines.add_child(h)

	# Stack count
	if qty > 1:
		var st := Label.new()
		st.text = "Stack: %d" % qty
		st.modulate = Color(0.9, 0.9, 0.9, 0.9)
		_lines.add_child(st)
		
	_btn_use.visible = _can_use(_def)
	_btn_equip.visible = _can_equip(_def)

func _can_use(def: Dictionary) -> bool:
	var item_class := str(def.get("itemClass", "")).to_lower()
	var sub_class := str(def.get("itemSubClass", "")).to_lower()
	if item_class == "consumable":
		return true
	if "potion" in sub_class or "food" in sub_class:
		return true

	var attrs = def.get("attrs", {})
	if typeof(attrs) == TYPE_DICTIONARY:
		if attrs.has("HP") or attrs.has("MP"):
			return true

	return false


func _can_equip(def: Dictionary) -> bool:
	if def.has("slot"):
		var slot := str(def["slot_type"])
		return slot != ""
	return false
	
func _on_use_pressed() -> void:
	if _def.is_empty():
		return
	SignalManager.signal_UseItem.emit(_def["name"])

func _on_equip_pressed() -> void:
	if _def.is_empty():
		return
	SignalManager.signal_EquipItem.emit(_def["name"])
