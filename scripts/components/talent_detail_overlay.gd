extends PanelContainer
# Talent tooltip — persistent structure like LegionTooltip.
# All nodes created once in _ready(). show_talent() only updates text/visibility.

signal allocate_pressed(talent_id: String)
signal dismissed()

const BG_COLOR = Color(0.96, 0.93, 0.85, 1.0)
const TEXT_DARK = Color(0.1, 0.1, 0.1)
const TEXT_MID = Color(0.35, 0.35, 0.35)
const TEXT_GREEN = Color(0.2, 0.6, 0.2)
const TEXT_GOLD = Color(0.6, 0.4, 0.0)
const TEXT_GRAY = Color(0.5, 0.5, 0.5)
const TOOLTIP_MARGIN = 8.0

var _talent_id: String = ""
var _tap_global_pos: Vector2 = Vector2.ZERO
var _panel_rect: Rect2 = Rect2()

# Persistent UI nodes
var _root_vbox: VBoxContainer
var _lbl_title: Label
var _icon_rect: TextureRect
var _lbl_type: Label
var _lbl_rank: Label
var _tier_dots: Array = []
var _lbl_bonus: Label
var _lbl_t1_desc: Label
var _lbl_t2_header: Label
var _lbl_t2_desc: Label
var _lbl_t3_header: Label
var _lbl_t3_desc: Label
var _synergy_container: VBoxContainer
var _btn_allocate: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	z_index = 100

	var sb = StyleBoxFlat.new()
	sb.bg_color = BG_COLOR
	sb.set_corner_radius_all(6)
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.2, 0.2, 0.2)
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.3)
	add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_root_vbox = VBoxContainer.new()
	_root_vbox.add_theme_constant_override("separation", 6)
	_root_vbox.custom_minimum_size = Vector2(300, 0)
	_root_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(_root_vbox)

	# Title
	_lbl_title = Label.new()
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if "GROBOLT_FONT" in Styler:
		_lbl_title.add_theme_font_override("font", Styler.GROBOLT_FONT)
	_lbl_title.add_theme_font_size_override("font_size", 20)
	_lbl_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl_title.add_theme_constant_override("outline_size", 4)
	_root_vbox.add_child(_lbl_title)

	# Header: icon + info
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_root_vbox.add_child(header)

	var icon_border = PanelContainer.new()
	var ib_style = StyleBoxFlat.new()
	ib_style.bg_color = Color.TRANSPARENT
	ib_style.set_border_width_all(2)
	ib_style.border_color = Color(0.3, 0.3, 0.3)
	ib_style.set_corner_radius_all(4)
	icon_border.add_theme_stylebox_override("panel", ib_style)
	header.add_child(icon_border)

	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(64, 64)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_border.add_child(_icon_rect)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)

	_lbl_type = Label.new()
	_lbl_type.add_theme_font_size_override("font_size", 14)
	_lbl_type.add_theme_color_override("font_color", TEXT_MID)
	info_vbox.add_child(_lbl_type)

	var level_row = HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	info_vbox.add_child(level_row)

	_lbl_rank = Label.new()
	_lbl_rank.add_theme_font_size_override("font_size", 16)
	level_row.add_child(_lbl_rank)

	var dots_box = HBoxContainer.new()
	dots_box.add_theme_constant_override("separation", 4)
	level_row.add_child(dots_box)
	for i in range(3):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = Color(0.3, 0.3, 0.3, 0.5)
		dots_box.add_child(dot)
		_tier_dots.append(dot)

	_lbl_bonus = Label.new()
	_lbl_bonus.add_theme_font_size_override("font_size", 14)
	_lbl_bonus.add_theme_color_override("font_color", TEXT_GREEN)
	info_vbox.add_child(_lbl_bonus)

	_add_sep()

	# T1
	_lbl_t1_desc = _make_label(14)
	_root_vbox.add_child(_lbl_t1_desc)
	_add_sep()

	# T2
	_lbl_t2_header = _make_label(13)
	_root_vbox.add_child(_lbl_t2_header)
	_lbl_t2_desc = _make_label(14)
	_root_vbox.add_child(_lbl_t2_desc)
	_add_sep()

	# T3
	_lbl_t3_header = _make_label(13)
	_root_vbox.add_child(_lbl_t3_header)
	_lbl_t3_desc = _make_label(14)
	_root_vbox.add_child(_lbl_t3_desc)

	# Synergies
	_add_sep()
	_synergy_container = VBoxContainer.new()
	_synergy_container.add_theme_constant_override("separation", 4)
	_root_vbox.add_child(_synergy_container)

	# Button
	_add_sep()
	_btn_allocate = Button.new()
	Styler.style_button(_btn_allocate, Color(0.2, 0.6, 1.0))
	_btn_allocate.focus_mode = Control.FOCUS_NONE
	_btn_allocate.pressed.connect(func(): allocate_pressed.emit(_talent_id))
	_root_vbox.add_child(_btn_allocate)


func _make_label(font_size: int) -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl


func _add_sep() -> void:
	var sep = HSeparator.new()
	sep.modulate = Color(0, 0, 0, 0.2)
	_root_vbox.add_child(sep)


func show_talent(talent_id: String, data: Dictionary, synergies: Array,
		all_talents: Dictionary, _config_by_id: Dictionary) -> void:
	_talent_id = talent_id

	var allocated = int(data.get("allocated", 0))
	var tier = int(data.get("tier", 1))
	var per_level = float(data.get("per_level", 0))
	var cost_next = int(data.get("cost_next_rank", 1))
	var unspent = int(data.get("_unspent", 0))

	# Update persistent nodes — no add/remove
	_lbl_title.text = str(data.get("name", talent_id))
	_lbl_type.text = str(data.get("type", "")).replace("_", " ").capitalize()
	_lbl_rank.text = "Rank %d / 50" % allocated

	if allocated >= 50:
		_lbl_rank.add_theme_color_override("font_color", TEXT_GOLD)
	elif allocated > 0:
		_lbl_rank.add_theme_color_override("font_color", TEXT_GREEN)
	else:
		_lbl_rank.add_theme_color_override("font_color", TEXT_GRAY)

	for i in range(3):
		_tier_dots[i].color = Color("#FFC842") if i < tier else Color(0.3, 0.3, 0.3, 0.5)

	if allocated > 0:
		_lbl_bonus.text = "Current: +%.1f%%" % (allocated * per_level * 100.0)
		_lbl_bonus.visible = true
	else:
		_lbl_bonus.visible = false

	var icon_path = "res://assets/general_icons/passive_talents/%s.png" % talent_id
	if ResourceLoader.exists(icon_path):
		_icon_rect.texture = load(icon_path)

	# Tiers
	_lbl_t1_desc.text = str(data.get("tier1_desc", ""))
	_lbl_t1_desc.add_theme_color_override("font_color", TEXT_DARK)

	if tier >= 2:
		_lbl_t2_header.text = "Tier 2 (rank 16) — Active"
		_lbl_t2_header.add_theme_color_override("font_color", TEXT_GREEN)
		_lbl_t2_desc.add_theme_color_override("font_color", TEXT_DARK)
	else:
		_lbl_t2_header.text = "Tier 2 (rank 16) — %d ranks away" % max(16 - allocated, 0)
		_lbl_t2_header.add_theme_color_override("font_color", TEXT_GOLD)
		_lbl_t2_desc.add_theme_color_override("font_color", TEXT_GRAY)
	_lbl_t2_desc.text = str(data.get("tier2_desc", ""))

	if tier >= 3:
		_lbl_t3_header.text = "Tier 3 (rank 31) — Active"
		_lbl_t3_header.add_theme_color_override("font_color", TEXT_GREEN)
		_lbl_t3_desc.add_theme_color_override("font_color", TEXT_DARK)
	else:
		_lbl_t3_header.text = "Tier 3 (rank 31) — %d ranks away" % max(31 - allocated, 0)
		_lbl_t3_header.add_theme_color_override("font_color", TEXT_GOLD)
		_lbl_t3_desc.add_theme_color_override("font_color", TEXT_GRAY)
	_lbl_t3_desc.text = str(data.get("tier3_desc", ""))

	# Synergies — only this container recreates children (small, fast)
	for child in _synergy_container.get_children():
		_synergy_container.remove_child(child)
		child.free()
	for syn in synergies:
		var tlist = syn.get("talents", [])
		var t1 = str(tlist[0]) if tlist.size() > 0 else ""
		var t2 = str(tlist[1]) if tlist.size() > 1 else ""
		if t1 != talent_id and t2 != talent_id:
			continue
		var partner_id = t2 if t1 == talent_id else t1
		var partner_name = str(all_talents.get(partner_id, {}).get("name", partner_id))
		var partner_rank = int(all_talents.get(partner_id, {}).get("allocated", 0))
		var syn_name = str(syn.get("name", ""))
		var syn_effect = str(syn.get("bonus_desc", syn.get("effect", syn.get("description", ""))))
		var both_active = allocated >= 16 and partner_rank >= 16
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 14)
		if both_active:
			lbl.text = "%s + %s: %s" % [syn_name, partner_name, syn_effect]
			lbl.add_theme_color_override("font_color", TEXT_GREEN)
		else:
			var remaining = max(16 - allocated, 0) + max(16 - partner_rank, 0)
			lbl.text = "%s (w/ %s) — %d ranks" % [syn_name, partner_name, remaining]
			lbl.add_theme_color_override("font_color", TEXT_GRAY)
		_synergy_container.add_child(lbl)

	# Button
	if allocated >= 50:
		_btn_allocate.text = "Max Rank"
		_btn_allocate.disabled = true
	elif unspent < cost_next:
		_btn_allocate.text = "Need %d Points" % cost_next
		_btn_allocate.disabled = true
	else:
		_btn_allocate.text = "Add Point"
		_btn_allocate.disabled = false

	# Force resize — same as LegionTooltip
	# Force resize — same as LegionTooltip (works because no autowrap labels)
	custom_minimum_size.y = 0
	await get_tree().process_frame
	size = Vector2.ZERO

	visible = true
	_position_tooltip()


func _position_tooltip() -> void:
	var t_size = size if size.x > 1 else get_combined_minimum_size()
	var left_limit = _panel_rect.position.x + TOOLTIP_MARGIN
	var top_limit = _panel_rect.position.y + TOOLTIP_MARGIN
	var right_limit = _panel_rect.position.x + _panel_rect.size.x - TOOLTIP_MARGIN
	var bottom_limit = _panel_rect.position.y + _panel_rect.size.y - TOOLTIP_MARGIN

	var pos = _tap_global_pos
	if pos.x + t_size.x + TOOLTIP_MARGIN > right_limit:
		pos.x -= t_size.x + TOOLTIP_MARGIN
	else:
		pos.x += TOOLTIP_MARGIN
	if pos.y + t_size.y + TOOLTIP_MARGIN > bottom_limit:
		pos.y -= t_size.y + TOOLTIP_MARGIN
	else:
		pos.y += TOOLTIP_MARGIN

	pos.x = clamp(pos.x, left_limit, max(left_limit, right_limit - t_size.x))
	pos.y = clamp(pos.y, top_limit, max(top_limit, bottom_limit - t_size.y))
	global_position = pos


func switch_talent(talent_id: String, data: Dictionary, synergies: Array,
		all_talents: Dictionary, config_by_id: Dictionary) -> void:
	show_talent(talent_id, data, synergies, all_talents, config_by_id)


func hide_overlay() -> void:
	visible = false
