class_name ActivityProgressView extends Control

# --- Colors ---
var COL_PANEL_BG     := Color.from_rgba8(20, 22, 30, 240)
var COL_PANEL_BORDER := Color.from_rgba8(255, 200, 66, 90)
var COL_GOLD         := Color.from_rgba8(255, 215, 128)
var COL_LEVELUP      := Color.from_rgba8(255, 230, 50)
var COL_XP_FILL      := Color.from_rgba8(80, 160, 255)
const COL_XP_TEXT      := Color(0.4, 0.78, 1.0)
const COL_SEPARATOR    := Color(1, 1, 1, 0.08)
const COL_SUBTEXT      := Color(0.65, 0.65, 0.65)

# --- Scene References ---
@onready var _panel:        PanelContainer = $PanelContainer
@onready var _title:        Label          = $PanelContainer/VBoxContainer/Title
@onready var _content_vbox: VBoxContainer  = $PanelContainer/VBoxContainer/ContentScroll/ContentVBox
@onready var close_button:  Button         = $PanelContainer/VBoxContainer/Close

# --- State ---
var _stats_vbox:  VBoxContainer
var _loot_vbox:   VBoxContainer
var _equip_vbox:  VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	Styler.style_panel(_panel, COL_PANEL_BG, COL_PANEL_BORDER)
	Styler.style_title(_title)
	Styler.style_button(close_button, Styler.GOLD_COLOR)
	Styler.wire_button_anim(close_button)

	_content_vbox.add_theme_constant_override("separation", 12)

	_stats_vbox = VBoxContainer.new()
	_stats_vbox.add_theme_constant_override("separation", 8)
	_content_vbox.add_child(_stats_vbox)

	_content_vbox.add_child(_mk_separator())

	_loot_vbox = VBoxContainer.new()
	_loot_vbox.add_theme_constant_override("separation", 6)
	_content_vbox.add_child(_loot_vbox)

	_equip_vbox = VBoxContainer.new()
	_equip_vbox.add_theme_constant_override("separation", 6)
	_content_vbox.add_child(_equip_vbox)


# ------------------ Public API ------------------
func apply_activity_progress(d: Dictionary) -> void:
	var lvls_gained := int(d.get("levels_gained", 0))
	var req_skill   := int(d.get("req_skill", 1))

	if d.get("locked", false):
		_title.text = "Activity — Locked  (Req. Lv. %d)" % req_skill
	elif lvls_gained > 0:
		_title.text = "Activity Complete  ·  Level Up!"
	else:
		_title.text = "Activity Complete"

	_render_stats(d)
	_render_loot(d.get("loot_counts", {}), d.get("mapping", {}))
	_render_equipment(d.get("new_items", []))


# ------------------ Stats Section ------------------
func _render_stats(d: Dictionary) -> void:
	for c in _stats_vbox.get_children():
		c.queue_free()

	var steps_in            := int(d.get("steps_in", 0))
	var activities_completed := int(d.get("activities_completed", 0))
	var xp_gained           := int(d.get("xp_gained", 0))
	var lvl                 := int(d.get("level", 1))
	var lvl_prev            := int(d.get("level_before", lvl))
	var lvls_gained         := int(d.get("levels_gained", 0))
	var xp_into             := int(d.get("xp_into_level", 0))
	var xp_to_next                   = d.get("xp_to_next", null)

	# Steps row
	_stats_vbox.add_child(
		_mk_stat_row("steps", "Steps Used", "+%d" % steps_in, COL_GOLD))

	# Activities row
	_stats_vbox.add_child(
		_mk_stat_row("", "Activities Completed", "×%d" % activities_completed, COL_GOLD))

	# XP row
	_stats_vbox.add_child(
		_mk_stat_row("", "Experience Gained", "+%d XP" % xp_gained, COL_XP_TEXT))

	# Level row
	if lvls_gained > 0:
		var lvlup_lbl := Label.new()
		lvlup_lbl.text = "⬆  Lv. %d → %d" % [lvl_prev, lvl]
		lvlup_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvlup_lbl.add_theme_color_override("font_color", COL_LEVELUP)
		lvlup_lbl.add_theme_font_size_override("font_size", 16)
		if "GROBOLT_FONT" in Styler:
			lvlup_lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
		_stats_vbox.add_child(lvlup_lbl)
	else:
		var lvl_lbl := Label.new()
		lvl_lbl.text = "Level %d" % lvl
		lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_name_label(lvl_lbl, COL_GOLD)
		_stats_vbox.add_child(lvl_lbl)

	# XP progress bar
	var xp_bar := ProgressBar.new()
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
	_stats_vbox.add_child(xp_bar)

	# XP sub-text
	if xp_to_next:
		var xp_sub := Label.new()
		xp_sub.text = "%d / %d XP to next level" % [xp_into, int(xp_to_next)]
		xp_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_sub.add_theme_color_override("font_color", COL_SUBTEXT)
		xp_sub.add_theme_font_size_override("font_size", 11)
		_stats_vbox.add_child(xp_sub)


# ------------------ Loot Section ------------------
func _render_loot(summary: Dictionary, mapper: Dictionary) -> void:
	for c in _loot_vbox.get_children():
		c.queue_free()

	if summary.is_empty():
		return

	_loot_vbox.add_child(_mk_section_header("Resources"))

	for key in summary.keys():
		var qty      := int(summary[key])
		var icon_key := str(mapper.get(key, key))
		var row      := _create_loot_row(icon_key, _format_resource_name(icon_key), "×%d" % qty)
		_loot_vbox.add_child(row)


# ------------------ Equipment Section ------------------
func _render_equipment(items: Array) -> void:
	for c in _equip_vbox.get_children():
		c.queue_free()

	if items.is_empty():
		return

	_equip_vbox.add_child(_mk_section_header("New Equipment"))

	for item_data in items:
		var icon_key      = _extract_icon_key(item_data)
		var item_quality  = int(item_data.get("quality", 1))
		var ilvl          = item_data.get("ilvl", item_data.get("monster_level", 1))
		var display_name  = str(item_data.get("name", "Unknown Item"))
		var quality_name  = _get_quality_name(item_quality)
		var quality_color = Styler.QUALITY_COLORS.get(item_quality, Styler.QUALITY_COLORS[1])

		_equip_vbox.add_child(
			_create_equip_row(icon_key, display_name, quality_name, ilvl, quality_color))


# ------------------ Row Builders ------------------
func _mk_stat_row(icon_key: String, label_text: String, value_text: String, value_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	if icon_key != "":
		var icon := TextureRect.new()
		icon.texture = ItemDB.get_icon(icon_key, null)
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(24, 24)
		row.add_child(spacer)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(lbl, COL_GOLD)
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(val, value_color)
	row.add_child(val)

	return row


func _create_loot_row(icon_key: String, display_name: String, qty_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.texture = ItemDB.get_item_icon(icon_key, ItemDB.get_item_icon("default_bag"))
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(name_lbl, Color.WHITE)
	row.add_child(name_lbl)

	var qty_lbl := Label.new()
	qty_lbl.text = qty_text
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Styler.style_name_label(qty_lbl, COL_GOLD)
	row.add_child(qty_lbl)

	return row


func _create_equip_row(icon_key: String, item_name: String, quality_name: String, ilvl, quality_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.texture = ItemDB.get_item_icon(icon_key, ItemDB.get_item_icon("default_bag"))
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = item_name
	name_lbl.add_theme_color_override("font_color", quality_color)
	name_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "%s  ·  iLvl %s" % [quality_name, str(ilvl)]
	sub_lbl.add_theme_color_override("font_color", COL_SUBTEXT)
	sub_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(sub_lbl)

	return row


# ------------------ Helpers ------------------
func _mk_section_header(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Styler.GOLD_COLOR)
	if "GROBOLT_FONT" in Styler:
		lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
	return lbl


func _mk_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", COL_SEPARATOR)
	return sep


func _format_resource_name(s: String) -> String:
	var result := PackedStringArray()
	for w in s.split("_"):
		result.append(w.capitalize())
	return " ".join(result)


func _extract_icon_key(item_data: Dictionary) -> String:
	var raw = item_data.get("item_icon", "")
	if raw is Array and not raw.is_empty():
		return str(raw[0])
	if raw is String and raw != "":
		return raw
	return "chest_0"


func _get_quality_name(q: int) -> String:
	match q:
		0: return "Poor"
		1: return "Common"
		2: return "Uncommon"
		3: return "Rare"
		4: return "Epic"
		5: return "Legendary"
		6: return "Mythic"
	return "Common"


func _on_close_pressed() -> void:
	queue_free()
