class_name DisenchantResultView extends Control

# --- Colors (match ActivityProgressView) ---
var COL_PANEL_BG     = Color.from_rgba8(20, 22, 30, 240)
var COL_PANEL_BORDER = Color.from_rgba8(180, 100, 255, 90)
var COL_GOLD         = Color.from_rgba8(255, 215, 128)
var COL_LEVELUP      = Color.from_rgba8(255, 230, 50)
var COL_XP_FILL      = Color.from_rgba8(80, 160, 255)
const COL_XP_TEXT      = Color(0.4, 0.78, 1.0)
const COL_SEPARATOR    = Color(1, 1, 1, 0.08)
const COL_SUBTEXT      = Color(0.65, 0.65, 0.65)
const COL_PURPLE       = Color(0.75, 0.4, 1.0)

# --- Scene References ---
@onready var _panel:        PanelContainer = $PanelContainer
@onready var _title:        Label          = $PanelContainer/VBoxContainer/Title
@onready var _content_vbox: VBoxContainer  = $PanelContainer/VBoxContainer/ContentVBox
@onready var close_button:  Button         = $PanelContainer/VBoxContainer/Close


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	Styler.style_panel(_panel, COL_PANEL_BG, COL_PANEL_BORDER)
	Styler.style_title(_title)
	Styler.style_button(close_button, Styler.GOLD_COLOR)
	Styler.wire_button_anim(close_button)
	_content_vbox.add_theme_constant_override("separation", 12)


# ------------------ Public API ------------------
func apply_result(d: Dictionary) -> void:
	var lvls_gained = int(d.get("levels_gained", 0))
	if lvls_gained > 0:
		_title.text = "Disenchanted!  ·  Level Up!"
	else:
		_title.text = "Disenchanted!"

	for c in _content_vbox.get_children():
		c.queue_free()

	# --- Destroyed item row ---
	var item_name    = str(d.get("item_name", "Item"))
	var item_icon    = str(d.get("item_icon", ""))
	var item_quality = int(d.get("item_quality", 1))
	var item_ilvl    = d.get("item_ilvl", 1)
	var q_color      = Styler.QUALITY_COLORS.get(item_quality, Color.WHITE)

	_content_vbox.add_child(_mk_section_header("Disenchanted"))
	_content_vbox.add_child(_create_item_row(item_icon, item_name, str(item_ilvl), q_color))

	_content_vbox.add_child(_mk_separator())

	# --- Obtained material row ---
	var mat_icon = str(d.get("material_icon", ""))
	var mat_name = str(d.get("material_name", "Material"))
	var mat_qty  = int(d.get("material_qty", 1))

	_content_vbox.add_child(_mk_section_header("Obtained"))
	_content_vbox.add_child(_create_material_row(mat_icon, mat_name, mat_qty))

	_content_vbox.add_child(_mk_separator())

	# --- Enchanting XP section ---
	_content_vbox.add_child(_mk_section_header("Enchanting"))

	var xp_gained    = int(d.get("xp_gained", 0))
	var lvl          = int(d.get("level", 1))
	var lvl_before   = int(d.get("level_before", lvl))
	var xp_into      = int(d.get("xp_into_level", 0))
	var xp_to_next   = d.get("xp_to_next", null)

	var xp_row = _mk_stat_row("", "Experience Gained", "+%d XP" % xp_gained, COL_XP_TEXT)
	_content_vbox.add_child(xp_row)

	if lvls_gained > 0:
		var lvlup_lbl = Label.new()
		lvlup_lbl.text = "⬆  Lv. %d → %d" % [lvl_before, lvl]
		lvlup_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvlup_lbl.add_theme_color_override("font_color", COL_LEVELUP)
		lvlup_lbl.add_theme_font_size_override("font_size", 16)
		if "GROBOLT_FONT" in Styler:
			lvlup_lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
		_content_vbox.add_child(lvlup_lbl)
	else:
		var lvl_lbl = Label.new()
		lvl_lbl.text = "Level %d" % lvl
		lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_name_label(lvl_lbl, COL_GOLD)
		_content_vbox.add_child(lvl_lbl)

	var xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 18)
	xp_bar.min_value = 0
	xp_bar.show_percentage = false
	if xp_to_next:
		xp_bar.max_value = max(1, int(xp_to_next))
		xp_bar.value = clamp(xp_into, 0, xp_bar.max_value)
	else:
		xp_bar.max_value = 100
		xp_bar.value = 100
	Styler.style_mini_progress(xp_bar, COL_XP_FILL)
	_content_vbox.add_child(xp_bar)

	if xp_to_next:
		var xp_sub = Label.new()
		xp_sub.text = "%d / %d XP to next level" % [xp_into, int(xp_to_next)]
		xp_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_sub.add_theme_color_override("font_color", COL_SUBTEXT)
		xp_sub.add_theme_font_size_override("font_size", 11)
		_content_vbox.add_child(xp_sub)


# ------------------ Row Builders ------------------
func _create_item_row(icon_key: String, item_name: String, ilvl: String, q_color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)

	var icon = TextureRect.new()
	icon.texture = ItemDB.get_item_icon(icon_key, null)
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_lbl = Label.new()
	name_lbl.text = item_name
	name_lbl.add_theme_color_override("font_color", q_color)
	name_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(name_lbl)

	var ilvl_lbl = Label.new()
	ilvl_lbl.text = "iLvl %s" % ilvl
	ilvl_lbl.add_theme_color_override("font_color", COL_SUBTEXT)
	ilvl_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(ilvl_lbl)

	return row


func _create_material_row(icon_key: String, mat_name: String, qty: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var icon = TextureRect.new()
	icon.texture = ItemDB.get_item_icon(icon_key, null)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = mat_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(name_lbl, COL_PURPLE)
	row.add_child(name_lbl)

	var qty_lbl = Label.new()
	qty_lbl.text = "×%d" % qty
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(qty_lbl, COL_GOLD)
	row.add_child(qty_lbl)

	return row


func _mk_stat_row(icon_key: String, label_text: String, value_text: String, value_color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	if icon_key != "":
		var icon = TextureRect.new()
		icon.texture = ItemDB.get_icon(icon_key, null)
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	else:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(24, 24)
		row.add_child(spacer)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(lbl, COL_GOLD)
	row.add_child(lbl)

	var val = Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(val, value_color)
	row.add_child(val)

	return row


func _mk_section_header(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Styler.GOLD_COLOR)
	if "GROBOLT_FONT" in Styler:
		lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
	return lbl


func _mk_separator() -> HSeparator:
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", COL_SEPARATOR)
	return sep


func _on_close_pressed() -> void:
	queue_free()
