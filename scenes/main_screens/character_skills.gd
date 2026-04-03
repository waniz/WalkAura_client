extends Control

# Talent config loaded from server
var talent_config: Array = []    # set from ServerParams on login
var talent_data: Dictionary = {} # current talent allocations/ranks from server
var synergy_config: Array = []   # synergy definitions from server

var PASSIVE_TOTAL_TO_LEVEL = {1: 0}
var _active_slots: Array = [null, null, null, null, null]
var _known_skills: Array = []

# --- Node refs (set in _build_ui) ---
var skill_panel: PanelContainer
var talents_panel: PanelContainer
var btn_tab_skills: Button
var btn_tab_talents: Button
var v_box_skills: VBoxContainer
var title_active_skills: Label
var active_container: HBoxContainer
var h_separator: HSeparator
var title_spellbook: Label
var h_box_btn_control: HBoxContainer
var btn_skills_mage: Button
var btn_skills_paladin: Button
var btn_skills_buffs: Button
var spellbook_panel_base: PanelContainer
var mage_panel: PanelContainer
var paladin_panel: PanelContainer
var buffs_panel: PanelContainer
var btn_skills_blood: Button
var blood_panel: PanelContainer
var blood_grid_spellbook: GridContainer
var btn_skills_dark: Button
var dark_panel: PanelContainer
var dark_grid_spellbook: GridContainer
var btn_skills_arcane: Button
var arcane_panel: PanelContainer
var arcane_grid_spellbook: GridContainer
var mage_grid_spellbook: HBoxContainer
var paladin_grid_spellbook: GridContainer
var buffs_grid_spellbook: GridContainer
var talent_list: VBoxContainer
var _talent_header_points_label: Label
var _talent_header_streak_label: Label
var _talent_bottom_used_label: Label
var _talent_hint_label: Label
var _talent_empty_label: Label
var _current_filter: String = "all"
var _filter_buttons: Dictionary = {}
var _allocate_debounce: Dictionary = {}  # talent_id -> timestamp


func _ready() -> void:
	PASSIVE_TOTAL_TO_LEVEL = ServerParams.PASSIVE_TOTAL_TO_LEVEL
	_build_ui()

	AccountManager.signal_AllSkillsReceived.connect(_update_game_skills)
	AccountManager.signal_AccountSkillsReceived.connect(_update_skills)

	AccountManager.signal_TalentsConfigReceived.connect(_on_talents_config)
	AccountManager.signal_TalentsDataReceived.connect(_on_talents_data)

	if Account.raw_structures.all_server_skills != null and not Account.raw_structures.all_server_skills.is_empty():
		_update_game_skills(Account.raw_structures.all_server_skills)

	if Account.raw_structures.account_skills != null and not Account.raw_structures.account_skills.is_empty():
		_update_skills(Account.raw_structures.account_skills)

	_setup_skill_panel_structure()
	_refresh_skills_ui()
	_refresh_talents()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox_root = VBoxContainer.new()
	vbox_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	vbox_root.offset_left = Styler.CONTENT_MARGIN_H
	vbox_root.offset_top = Styler.content_top
	vbox_root.offset_right = -Styler.CONTENT_MARGIN_H
	vbox_root.offset_bottom = Styler.content_bottom
	add_child(vbox_root)

	# --- Tab Buttons ---
	var tab_hbox = HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 4)
	vbox_root.add_child(tab_hbox)

	btn_tab_skills = Button.new()
	btn_tab_skills.text = "Skills"
	btn_tab_skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_hbox.add_child(btn_tab_skills)

	btn_tab_talents = Button.new()
	btn_tab_talents.text = "Talents"
	btn_tab_talents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_hbox.add_child(btn_tab_talents)

	# --- Body ---
	var body = PanelContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_root.add_child(body)

	# --- Skill Panel ---
	skill_panel = PanelContainer.new()
	skill_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(skill_panel)

	var skill_margin = MarginContainer.new()
	skill_margin.add_theme_constant_override("margin_left", 10)
	skill_margin.add_theme_constant_override("margin_top", 10)
	skill_margin.add_theme_constant_override("margin_right", 10)
	skill_margin.add_theme_constant_override("margin_bottom", 10)
	skill_panel.add_child(skill_margin)

	var skill_vbox_outer = VBoxContainer.new()
	skill_margin.add_child(skill_vbox_outer)

	v_box_skills = VBoxContainer.new()
	skill_vbox_outer.add_child(v_box_skills)

	title_active_skills = Label.new()
	title_active_skills.text = "Active Skills"
	v_box_skills.add_child(title_active_skills)

	active_container = HBoxContainer.new()
	v_box_skills.add_child(active_container)

	h_separator = HSeparator.new()
	v_box_skills.add_child(h_separator)

	title_spellbook = Label.new()
	title_spellbook.text = "Spellbook"
	v_box_skills.add_child(title_spellbook)

	h_box_btn_control = HBoxContainer.new()
	v_box_skills.add_child(h_box_btn_control)

	btn_skills_mage = Button.new()
	btn_skills_mage.text = "Mage"
	h_box_btn_control.add_child(btn_skills_mage)

	btn_skills_paladin = Button.new()
	btn_skills_paladin.text = "Paladin"
	h_box_btn_control.add_child(btn_skills_paladin)

	btn_skills_buffs = Button.new()
	btn_skills_buffs.text = "Utility"
	h_box_btn_control.add_child(btn_skills_buffs)

	btn_skills_blood = Button.new()
	btn_skills_blood.text = "Blood"
	h_box_btn_control.add_child(btn_skills_blood)

	btn_skills_dark = Button.new()
	btn_skills_dark.text = "Dark"
	h_box_btn_control.add_child(btn_skills_dark)

	btn_skills_arcane = Button.new()
	btn_skills_arcane.text = "Arcane"
	h_box_btn_control.add_child(btn_skills_arcane)

	for btn in [btn_skills_mage, btn_skills_paladin, btn_skills_buffs, btn_skills_blood, btn_skills_dark, btn_skills_arcane]:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skill_vbox_outer.add_child(scroll_container)

	spellbook_panel_base = PanelContainer.new()
	spellbook_panel_base.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spellbook_panel_base.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spellbook_panel_base.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	scroll_container.add_child(spellbook_panel_base)

	mage_panel = PanelContainer.new()
	mage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mage_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(mage_panel)

	mage_grid_spellbook = HBoxContainer.new()
	mage_grid_spellbook.alignment = BoxContainer.ALIGNMENT_BEGIN
	mage_panel.add_child(mage_grid_spellbook)

	paladin_panel = PanelContainer.new()
	paladin_panel.visible = false
	paladin_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paladin_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(paladin_panel)

	paladin_grid_spellbook = GridContainer.new()
	paladin_panel.add_child(paladin_grid_spellbook)

	buffs_panel = PanelContainer.new()
	buffs_panel.visible = false
	buffs_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(buffs_panel)

	buffs_grid_spellbook = GridContainer.new()
	buffs_panel.add_child(buffs_grid_spellbook)

	blood_panel = PanelContainer.new()
	blood_panel.visible = false
	blood_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blood_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(blood_panel)

	blood_grid_spellbook = GridContainer.new()
	blood_panel.add_child(blood_grid_spellbook)

	dark_panel = PanelContainer.new()
	dark_panel.visible = false
	dark_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dark_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(dark_panel)

	dark_grid_spellbook = GridContainer.new()
	dark_panel.add_child(dark_grid_spellbook)

	arcane_panel = PanelContainer.new()
	arcane_panel.visible = false
	arcane_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arcane_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(arcane_panel)

	arcane_grid_spellbook = GridContainer.new()
	arcane_panel.add_child(arcane_grid_spellbook)

	# --- Talents Panel ---
	talents_panel = PanelContainer.new()
	talents_panel.visible = false
	talents_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(talents_panel)

	var talent_margin = MarginContainer.new()
	talent_margin.add_theme_constant_override("margin_left", 10)
	talent_margin.add_theme_constant_override("margin_top", 10)
	talent_margin.add_theme_constant_override("margin_right", 10)
	talent_margin.add_theme_constant_override("margin_bottom", 10)
	talents_panel.add_child(talent_margin)

	var talent_outer_vbox = VBoxContainer.new()
	talent_outer_vbox.add_theme_constant_override("separation", 8)
	talent_margin.add_child(talent_outer_vbox)

	# --- Header HBox ---
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	talent_outer_vbox.add_child(header_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "Talents"
	title_lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_lbl.add_theme_font_size_override("font_size", Styler.FONT_SECTION)
	title_lbl.add_theme_color_override("font_color", Color.BLACK)
	header_hbox.add_child(title_lbl)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(header_spacer)

	_talent_header_streak_label = Label.new()
	_talent_header_streak_label.text = ""
	_talent_header_streak_label.visible = false
	_talent_header_streak_label.add_theme_font_size_override("font_size", Styler.FONT_SMALL)
	_talent_header_streak_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	header_hbox.add_child(_talent_header_streak_label)

	# Points badge (red pill)
	var points_badge = PanelContainer.new()
	var pts_sb = StyleBoxFlat.new()
	pts_sb.bg_color = Color(0.91, 0.27, 0.38)
	pts_sb.set_corner_radius_all(12)
	pts_sb.content_margin_left = 10
	pts_sb.content_margin_right = 10
	pts_sb.content_margin_top = 2
	pts_sb.content_margin_bottom = 2
	points_badge.add_theme_stylebox_override("panel", pts_sb)
	header_hbox.add_child(points_badge)

	_talent_header_points_label = Label.new()
	_talent_header_points_label.text = "0 pts"
	_talent_header_points_label.add_theme_font_size_override("font_size", Styler.FONT_SMALL)
	_talent_header_points_label.add_theme_color_override("font_color", Color.WHITE)
	points_badge.add_child(_talent_header_points_label)

	# --- Filter tabs HBox ---
	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 4)
	talent_outer_vbox.add_child(filter_hbox)

	var filter_names = ["My Build", "All", "Offense", "Defense", "Magic", "Cross"]
	var filter_keys = ["my_build", "all", "offense", "defense", "magic", "cross"]
	for i in range(filter_names.size()):
		var fbtn = Button.new()
		fbtn.text = filter_names[i]
		fbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fbtn.custom_minimum_size.y = 32
		var fkey = filter_keys[i]
		_filter_buttons[fkey] = fbtn
		fbtn.pressed.connect(_on_filter_pressed.bind(fkey))
		filter_hbox.add_child(fbtn)
		# Style filter buttons
		var fb_base = Color(0.16, 0.16, 0.24) if fkey != "all" else Color(0.25, 0.25, 0.38)
		Styler.style_button_small(fbtn, fb_base)
		fbtn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

	# --- Empty state label (hidden by default) ---
	_talent_empty_label = Label.new()
	_talent_empty_label.text = "Walk to earn talent points!"
	_talent_empty_label.visible = false
	_talent_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talent_empty_label.add_theme_font_size_override("font_size", Styler.FONT_BODY)
	_talent_empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	talent_outer_vbox.add_child(_talent_empty_label)

	# --- Hint label (hidden by default) ---
	_talent_hint_label = Label.new()
	_talent_hint_label.text = "Tap + to invest your first talent point!"
	_talent_hint_label.visible = false
	_talent_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talent_hint_label.add_theme_font_size_override("font_size", Styler.FONT_BODY)
	_talent_hint_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.21))
	talent_outer_vbox.add_child(_talent_hint_label)

	# --- ScrollContainer with talent list ---
	var talent_scroll = ScrollContainer.new()
	talent_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	talent_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talent_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	talent_outer_vbox.add_child(talent_scroll)

	talent_list = VBoxContainer.new()
	talent_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talent_list.add_theme_constant_override("separation", 6)
	talent_scroll.add_child(talent_list)

	# --- Bottom HBox ---
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 8)
	talent_outer_vbox.add_child(bottom_hbox)

	_talent_bottom_used_label = Label.new()
	_talent_bottom_used_label.text = "0 / 100 used"
	_talent_bottom_used_label.add_theme_font_size_override("font_size", Styler.FONT_SMALL)
	_talent_bottom_used_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	bottom_hbox.add_child(_talent_bottom_used_label)

	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(bottom_spacer)

	var respec_btn = Button.new()
	respec_btn.text = "Respec"
	respec_btn.custom_minimum_size = Vector2(80, 36)
	Styler.style_button_small(respec_btn, Color(0.7, 0.23, 0.23))
	respec_btn.add_theme_color_override("font_color", Color.WHITE)
	respec_btn.pressed.connect(_on_respec_pressed)
	bottom_hbox.add_child(respec_btn)

	# --- Style ---
	Styler.style_button(btn_tab_skills, Color.from_rgba8(64, 180, 255))
	Styler.style_button(btn_tab_talents, Color.from_rgba8(64, 180, 255))
	_set_skills_tab_active(btn_tab_skills)

	# Parchment theme for talents panel (matches profile/skills panels)
	var talents_sb = StyleBoxFlat.new()
	talents_sb.bg_color = Styler.COLOR_PARCHMENT
	talents_sb.set_corner_radius_all(4)
	talents_sb.border_width_left = 4
	talents_sb.border_width_right = 4
	talents_sb.border_width_top = 4
	talents_sb.border_width_bottom = 4
	talents_sb.border_color = Styler.COLOR_BORDER
	talents_sb.shadow_size = 4
	talents_sb.shadow_color = Color(0, 0, 0, 0.3)
	talents_panel.add_theme_stylebox_override("panel", talents_sb)

	# --- Connect ---
	btn_tab_skills.pressed.connect(_on_btn_tab_skills_pressed)
	btn_tab_talents.pressed.connect(_on_btn_tab_talents_pressed)
	btn_skills_mage.pressed.connect(_on_btn_skills_mage_pressed)
	btn_skills_paladin.pressed.connect(_on_btn_skills_paladin_pressed)
	btn_skills_buffs.pressed.connect(_on_btn_skills_buffs_pressed)
	btn_skills_blood.pressed.connect(_on_btn_skills_blood_pressed)
	btn_skills_dark.pressed.connect(_on_btn_skills_dark_pressed)
	btn_skills_arcane.pressed.connect(_on_btn_skills_arcane_pressed)

	# Blood button gets crimson color to stand out
	Styler.style_button(btn_skills_blood, Styler.COL_BLOOD)
	Styler.style_button(btn_skills_dark, Styler.COL_DARK)
	Styler.style_button(btn_skills_arcane, Styler.COL_ARCANE)
	# Mage button gets a fire/frost blended color
	Styler.style_button(btn_skills_mage, Styler.COL_FIRE.lerp(Styler.COL_FROST, 0.5))
	Styler.style_button(btn_skills_paladin, Styler.COL_HOLY)
	Styler.style_button(btn_skills_buffs, Styler.COL_UTILITY)


func _on_btn_tab_skills_pressed() -> void:
	skill_panel.visible = true
	talents_panel.visible = false
	_set_skills_tab_active(btn_tab_skills)


func _on_btn_tab_talents_pressed() -> void:
	skill_panel.visible = false
	talents_panel.visible = true
	_set_skills_tab_active(btn_tab_talents)


func _set_skills_tab_active(active_btn: Button) -> void:
	for btn in [btn_tab_skills, btn_tab_talents]:
		var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(64, 180, 255) if btn == active_btn else Color.from_rgba8(60, 60, 70)


# ==============================================================================
# DATA CALLBACKS
# ==============================================================================
func _update_game_skills(server_json) -> void:
	_known_skills = server_json["data"]["all_skills"]


func _update_skills(server_json) -> void:
	var skills_data = server_json["data"]["skills"]
	if len(skills_data) > 0:
		for key in skills_data.keys():
			_active_slots[int(skills_data[key]["slot"])] = int(skills_data[key]["skill_id"])


func _refresh_talents() -> void:
	_clear(talent_list)

	var total_allocated: int = talent_data.get("total_allocated", 0)
	var unspent: int = talent_data.get("unspent", 0)
	var max_points: int = talent_data.get("max_allocated", 100)
	var streak: int = talent_data.get("walking_streak", 0)
	var allocations: Dictionary = talent_data.get("talents", {})

	# Update header badges
	_talent_header_points_label.text = str(unspent) + " pts"
	if streak > 0:
		_talent_header_streak_label.text = str(streak) + "-day streak"
		_talent_header_streak_label.visible = true
	else:
		_talent_header_streak_label.visible = false

	# Update bottom used label
	_talent_bottom_used_label.text = str(total_allocated) + " / " + str(max_points) + " used"

	# Empty state
	if unspent == 0 and total_allocated == 0:
		_talent_empty_label.visible = true
		_talent_hint_label.visible = false
	elif total_allocated == 0 and unspent > 0:
		_talent_empty_label.visible = false
		_talent_hint_label.visible = true
	else:
		_talent_empty_label.visible = false
		_talent_hint_label.visible = false

	# Build talent cards
	for talent_info in talent_config:
		var talent_id: String = talent_info.get("id", "")
		var alloc_info: Dictionary = allocations.get(talent_id, {})
		var allocated: int = alloc_info.get("allocated", 0)
		var effective: int = alloc_info.get("effective", allocated)
		var tier: int = alloc_info.get("tier", 0)
		var talent_type: String = talent_info.get("type", "")

		# Filter: My Build — skip unallocated
		if _current_filter == "my_build" and allocated == 0:
			continue

		# Filter: type-based
		if _current_filter == "offense" and talent_type != "offense":
			continue
		if _current_filter == "defense" and talent_type != "defense":
			continue
		if _current_filter == "magic" and not talent_type.begins_with("magic_"):
			continue
		if _current_filter == "cross" and talent_type != "cross_system":
			continue

		var card = _make_talent_card(talent_info, allocated, effective, tier)

		talent_list.add_child(card)


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _get_talent_type_color(talent_type: String) -> Color:
	match talent_type:
		"offense":
			return Color(0.91, 0.27, 0.38)
		"defense":
			return Color(0.29, 0.62, 1.0)
		"magic_fire":
			return Styler.COL_FIRE
		"magic_frost":
			return Styler.COL_FROST
		"magic_holy":
			return Styler.COL_HOLY
		"magic_dark":
			return Styler.COL_DARK
		"magic_arcane":
			return Styler.COL_ARCANE
		"utility":
			return Color(0.48, 0.72, 1.0)
		"cross_system":
			return Color(0.65, 1.0, 0.21)
		_:
			return Color(0.6, 0.6, 0.7)


func _make_talent_card(info: Dictionary, allocated: int, effective: int, tier: int) -> Control:
	var talent_id: String = info.get("id", "")
	var talent_name: String = info.get("name", "Unknown")
	var talent_type: String = info.get("type", "")
	var max_rank: int = info.get("max_rank", 50)
	var icon_key: String = info.get("icon", "")
	var synergies: Array = info.get("synergies", [])
	var per_level: float = info.get("per_level", 0.0)
	var tier1_desc: String = info.get("tier1_desc", "")
	var tier2_desc: String = info.get("tier2_desc", "")
	var tier3_desc: String = info.get("tier3_desc", "")
	var accent = _get_talent_type_color(talent_type)

	# Build tooltip
	var tip = talent_name + " [" + talent_type.replace("_", " ") + "]\n"
	if effective > 0:
		var current_value = effective * per_level * 100.0
		tip += "Current: +" + ("%.1f" % current_value) + "%%\n"
	tip += "\nTier 1: " + tier1_desc
	tip += "\nTier 2 (rank 16): " + tier2_desc
	tip += "\nTier 3 (rank 31): " + tier3_desc
	if tier >= 2:
		tip += "\n\nTier 2 ACTIVE"
	if tier >= 3:
		tip += " | Tier 3 ACTIVE"

	# Card panel
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.102, 0.102, 0.243)  # #1a1a3e
	card_sb.border_color = Color(0.165, 0.165, 0.369)  # #2a2a5e
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", card_sb)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	# Main HBox
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 8)
	margin.add_child(main_hbox)

	# --- Icon with element-colored border ---
	var icon_border = PanelContainer.new()
	icon_border.custom_minimum_size = Vector2(72, 72)
	var ib_sb = StyleBoxFlat.new()
	ib_sb.bg_color = Color.TRANSPARENT
	ib_sb.set_border_width_all(2)
	ib_sb.border_color = accent
	ib_sb.set_corner_radius_all(6)
	icon_border.add_theme_stylebox_override("panel", ib_sb)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(68, 68)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_key != "" and ItemDB.has_icon(icon_key):
		icon_rect.texture = ItemDB.get_icon(icon_key)
	icon_border.add_child(icon_rect)
	main_hbox.add_child(icon_border)

	# --- Info VBox ---
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	main_hbox.add_child(info_vbox)

	# Name + Rank row
	var name_row = HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = talent_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	name_row.add_child(name_lbl)

	var rank_lbl = Label.new()
	rank_lbl.text = str(effective) + "/" + str(max_rank)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank_lbl.add_theme_font_size_override("font_size", Styler.FONT_SMALL + 1)
	rank_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	name_row.add_child(rank_lbl)

	# Tier dots
	var tier_row = HBoxContainer.new()
	tier_row.add_theme_constant_override("separation", 4)
	info_vbox.add_child(tier_row)
	for t in range(3):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		if t < tier:
			dot.color = accent
		else:
			dot.color = Color(0.3, 0.3, 0.4)
		tier_row.add_child(dot)

	# Progress bar
	var pct: float = 0.0
	if max_rank > 0:
		pct = float(effective) / float(max_rank) * 100.0
	var pb = ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 4)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.25)
	bg_style.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = accent
	fill_style.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("fill", fill_style)
	info_vbox.add_child(pb)

	# Tier descriptions
	var desc_color = Color(0.55, 0.55, 0.65)
	var active_color = Color(0.65, 1.0, 0.21)
	var t1_lbl = Label.new()
	t1_lbl.text = tier1_desc
	t1_lbl.add_theme_font_size_override("font_size", Styler.FONT_CAPTION + 1)
	t1_lbl.add_theme_color_override("font_color", active_color if tier >= 1 and effective > 0 else desc_color)
	t1_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(t1_lbl)
	if effective > 0:
		var current_value = effective * per_level * 100.0
		var val_lbl = Label.new()
		val_lbl.text = "Current: +" + ("%.1f" % current_value) + "%"
		val_lbl.add_theme_font_size_override("font_size", Styler.FONT_CAPTION + 1)
		val_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
		info_vbox.add_child(val_lbl)

	# Synergy badges
	if not synergies.is_empty():
		var syn_row = HBoxContainer.new()
		syn_row.add_theme_constant_override("separation", 4)
		info_vbox.add_child(syn_row)

		for syn_id in synergies:
			var syn_info = _get_synergy_info(syn_id)
			var syn_name: String = syn_info.get("name", str(syn_id))
			var syn_active: bool = syn_info.get("active", false)

			var syn_badge = PanelContainer.new()
			var syn_sb = StyleBoxFlat.new()
			syn_sb.set_corner_radius_all(8)
			syn_sb.content_margin_left = 6
			syn_sb.content_margin_right = 6
			syn_sb.content_margin_top = 1
			syn_sb.content_margin_bottom = 1
			if syn_active:
				syn_sb.bg_color = Color(0.2, 0.5, 0.2, 0.8)
			else:
				syn_sb.bg_color = Color(0.25, 0.25, 0.3, 0.8)
			syn_badge.add_theme_stylebox_override("panel", syn_sb)

			var syn_lbl = Label.new()
			syn_lbl.text = syn_name
			syn_lbl.add_theme_font_size_override("font_size", Styler.FONT_CAPTION)
			syn_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if not syn_active else Color(0.6, 1.0, 0.6))
			syn_badge.add_child(syn_lbl)

			syn_row.add_child(syn_badge)

	# T2/T3 tier descriptions (always visible)
	var t2_lbl = Label.new()
	t2_lbl.text = "T2 (rank 16): " + tier2_desc
	t2_lbl.add_theme_font_size_override("font_size", Styler.FONT_CAPTION + 1)
	t2_lbl.add_theme_color_override("font_color", active_color if tier >= 2 else desc_color)
	t2_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(t2_lbl)

	var t3_lbl = Label.new()
	t3_lbl.text = "T3 (rank 31): " + tier3_desc
	t3_lbl.add_theme_font_size_override("font_size", Styler.FONT_CAPTION + 1)
	t3_lbl.add_theme_color_override("font_color", active_color if tier >= 3 else desc_color)
	t3_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(t3_lbl)

	# --- Allocate "+" button ---
	var alloc_btn = Button.new()
	alloc_btn.text = "+"
	alloc_btn.custom_minimum_size = Vector2(44, 44)

	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.91, 0.27, 0.38)
	btn_sb.set_corner_radius_all(22)
	alloc_btn.add_theme_stylebox_override("normal", btn_sb)

	var btn_hover = btn_sb.duplicate()
	btn_hover.bg_color = Color(1.0, 0.35, 0.45)
	alloc_btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed = btn_sb.duplicate()
	btn_pressed.bg_color = Color(0.75, 0.2, 0.3)
	alloc_btn.add_theme_stylebox_override("pressed", btn_pressed)

	var btn_disabled = btn_sb.duplicate()
	btn_disabled.bg_color = Color(0.3, 0.15, 0.18)
	alloc_btn.add_theme_stylebox_override("disabled", btn_disabled)

	alloc_btn.add_theme_color_override("font_color", Color.WHITE)
	alloc_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	alloc_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	alloc_btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	alloc_btn.add_theme_font_size_override("font_size", 22)
	alloc_btn.pressed.connect(_on_allocate_pressed.bind(talent_id))
	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_child(alloc_btn)
	info_vbox.add_child(btn_row)

	return panel


func _get_synergy_info(syn_id) -> Dictionary:
	for syn in synergy_config:
		if syn.get("id", "") == str(syn_id):
			return syn
	return {"name": str(syn_id), "active": false}


func _on_allocate_pressed(talent_id: String) -> void:
	var now = Time.get_ticks_msec()
	var last_press: int = _allocate_debounce.get(talent_id, 0)
	if now - last_press < 300:
		return  # debounce
	_allocate_debounce[talent_id] = now
	SignalManager.signal_TalentAllocate.emit(talent_id)


func _on_filter_pressed(filter_name: String) -> void:
	_current_filter = filter_name
	# Update filter button visual states
	for key in _filter_buttons:
		var fbtn: Button = _filter_buttons[key]
		var base_col = Color(0.25, 0.25, 0.38) if key == filter_name else Color(0.16, 0.16, 0.24)
		Styler.style_button_small(fbtn, base_col)
		var font_col = Color(1.0, 1.0, 1.0) if key == filter_name else Color(0.7, 0.7, 0.8)
		fbtn.add_theme_color_override("font_color", font_col)
	_refresh_talents()


func _on_respec_pressed() -> void:
	SignalManager.signal_TalentRespec.emit()


# ==============================================================================
# SERVER MESSAGE HANDLERS (talent system)
# ==============================================================================
func _on_server_message(msg: Dictionary) -> void:
	var cmd = msg.get("cmd", "")
	if cmd == "talents_config":
		_on_talents_config(msg["data"])
	elif cmd == "talents_data":
		_on_talents_data(msg["data"])
	elif cmd == "talent_allocate":
		_on_talent_allocate(msg["data"])
	elif cmd == "talent_respec":
		_on_talent_respec(msg["data"])
	elif cmd == "talent_points_earned":
		_on_talent_points_earned(msg["data"])


func _on_talents_config(data: Dictionary) -> void:
	talent_config = data.get("registry", [])
	synergy_config = data.get("synergies", [])
	_refresh_talents()


func _on_talents_data(data: Dictionary) -> void:
	talent_data = data
	_refresh_talents()


func _on_talent_allocate(data: Dictionary) -> void:
	# Update local talent_data with the server response
	talent_data = data
	_refresh_talents()


func _on_talent_respec(data: Dictionary) -> void:
	talent_data = data
	_refresh_talents()


func _on_talent_points_earned(data: Dictionary) -> void:
	talent_data = data
	_refresh_talents()


# ==============================================================================
# SKILLS UI STRUCTURE BUILDER
# ==============================================================================
func _setup_skill_panel_structure() -> void:
	var main_sb = StyleBoxFlat.new()
	main_sb.bg_color = Styler.COLOR_PARCHMENT
	main_sb.border_width_left = 4
	main_sb.border_width_right = 4
	main_sb.border_width_top = 4
	main_sb.border_width_bottom = 4
	main_sb.border_color = Styler.COLOR_BORDER
	main_sb.set_corner_radius_all(4)
	skill_panel.add_theme_stylebox_override("panel", main_sb)

	v_box_skills.add_theme_constant_override("separation", 15)

	title_active_skills.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_active_skills.add_theme_font_size_override("font_size", 22)
	title_active_skills.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

	active_container.alignment = BoxContainer.ALIGNMENT_CENTER
	active_container.add_theme_constant_override("separation", 15)

	h_separator.modulate = Color(0, 0, 0, 0.3)

	title_spellbook.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_spellbook.add_theme_font_size_override("font_size", 22)
	title_spellbook.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

	mage_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mage_grid_spellbook.add_theme_constant_override("separation", 20)

	paladin_grid_spellbook.columns = 2
	paladin_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paladin_grid_spellbook.add_theme_constant_override("h_separation", 20)
	paladin_grid_spellbook.add_theme_constant_override("v_separation", 10)

	buffs_grid_spellbook.columns = 2
	buffs_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buffs_grid_spellbook.add_theme_constant_override("h_separation", 20)
	buffs_grid_spellbook.add_theme_constant_override("v_separation", 10)

	blood_grid_spellbook.columns = 2
	blood_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blood_grid_spellbook.add_theme_constant_override("h_separation", 20)
	blood_grid_spellbook.add_theme_constant_override("v_separation", 10)

	dark_grid_spellbook.columns = 2
	dark_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dark_grid_spellbook.add_theme_constant_override("h_separation", 20)
	dark_grid_spellbook.add_theme_constant_override("v_separation", 10)

	arcane_grid_spellbook.columns = 2
	arcane_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arcane_grid_spellbook.add_theme_constant_override("h_separation", 20)
	arcane_grid_spellbook.add_theme_constant_override("v_separation", 10)


# ==============================================================================
# SKILLS LOGIC & RENDERING
# ==============================================================================
func _refresh_skills_ui() -> void:
	_render_active_bar()
	_render_spellbook_lists()


func _render_active_bar() -> void:
	for c in active_container.get_children():
		c.queue_free()

	for i in range(5):
		var skill_id = _active_slots[i]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(96, 96)
		btn.toggle_mode = false
		btn.focus_mode = Control.FOCUS_NONE

		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.2)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Styler.COLOR_GOLD
		sb.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

		if skill_id != null:
			var skill_instance = {}
			for inst in _known_skills:
				if skill_id == int(inst["skill_id"]):
					skill_instance = inst
			btn.icon = ItemDB.get_icon(skill_instance["skill_icon"])
			btn.expand_icon = true
			btn.tooltip_text = skill_instance["name"] + "\n(Click to Unequip)"
		else:
			btn.text = ""
			btn.tooltip_text = "Empty Slot"

		btn.pressed.connect(_on_active_slot_clicked.bind(i))
		active_container.add_child(btn)


func _render_spellbook_lists() -> void:
	for c in mage_grid_spellbook.get_children():
		c.queue_free()
	for c in paladin_grid_spellbook.get_children():
		c.queue_free()
	for c in buffs_grid_spellbook.get_children():
		c.queue_free()
	for c in blood_grid_spellbook.get_children():
		c.queue_free()
	for c in dark_grid_spellbook.get_children():
		c.queue_free()
	for c in arcane_grid_spellbook.get_children():
		c.queue_free()

	# Separate mage skills by magic_type for section headers
	var fire_skills = []
	var frost_skills = []
	var other_mage_skills = []
	for skill_instance in _known_skills:
		if skill_instance["skill_type"] == "mage":
			var effect_data = skill_instance.get("effect", {})
			if typeof(effect_data) == TYPE_STRING:
				effect_data = JSON.parse_string(effect_data)
				if effect_data == null:
					effect_data = {}
			var magic_type = ""
			if typeof(effect_data) == TYPE_DICTIONARY:
				magic_type = effect_data.get("magic_type", "")
			var skill_name = skill_instance.get("skill_name", "")
			var is_frost = magic_type == "frost" or skill_name in [
				"mage_frostshield", "mage_ice_barrier", "mage_icy_veins"
			]
			if is_frost:
				frost_skills.append(skill_instance)
			elif magic_type == "fire":
				fire_skills.append(skill_instance)
			else:
				other_mage_skills.append(skill_instance)

	# Build mage columns: Fire (left) / Frost (right)
	var fire_vbox = VBoxContainer.new()
	fire_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fire_vbox.add_theme_constant_override("separation", 10)
	mage_grid_spellbook.add_child(fire_vbox)

	var frost_vbox = VBoxContainer.new()
	frost_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frost_vbox.add_theme_constant_override("separation", 10)
	mage_grid_spellbook.add_child(frost_vbox)

	var fire_header = Label.new()
	fire_header.text = "── Fire ──"
	fire_header.add_theme_color_override("font_color", Styler.COL_FIRE)
	fire_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	fire_header.add_theme_font_size_override("font_size", 18)
	fire_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire_vbox.add_child(fire_header)

	for skill_instance in fire_skills:
		fire_vbox.add_child(_make_skill_row_btn(skill_instance))

	for skill_instance in other_mage_skills:
		fire_vbox.add_child(_make_skill_row_btn(skill_instance))

	var frost_header = Label.new()
	frost_header.text = "── Frost ──"
	frost_header.add_theme_color_override("font_color", Styler.COL_FROST)
	frost_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	frost_header.add_theme_font_size_override("font_size", 18)
	frost_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frost_vbox.add_child(frost_header)

	for skill_instance in frost_skills:
		frost_vbox.add_child(_make_skill_row_btn(skill_instance))

	# Build remaining grids
	var holy_header = Label.new()
	holy_header.text = "── Holy ──"
	holy_header.add_theme_color_override("font_color", Styler.COL_HOLY)
	holy_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	holy_header.add_theme_font_size_override("font_size", 18)
	holy_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paladin_grid_spellbook.add_child(holy_header)
	paladin_grid_spellbook.add_child(Control.new())

	var dark_header = Label.new()
	dark_header.text = "── Dark ──"
	dark_header.add_theme_color_override("font_color", Styler.COL_DARK)
	dark_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	dark_header.add_theme_font_size_override("font_size", 18)
	dark_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dark_grid_spellbook.add_child(dark_header)
	dark_grid_spellbook.add_child(Control.new())

	var arcane_header = Label.new()
	arcane_header.text = "── Arcane ──"
	arcane_header.add_theme_color_override("font_color", Styler.COL_ARCANE)
	arcane_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	arcane_header.add_theme_font_size_override("font_size", 18)
	arcane_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arcane_grid_spellbook.add_child(arcane_header)
	arcane_grid_spellbook.add_child(Control.new())

	var utility_header = Label.new()
	utility_header.text = "── Utility ──"
	utility_header.add_theme_color_override("font_color", Styler.COL_UTILITY)
	utility_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	utility_header.add_theme_font_size_override("font_size", 18)
	utility_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buffs_grid_spellbook.add_child(utility_header)
	buffs_grid_spellbook.add_child(Control.new())

	var blood_header = Label.new()
	blood_header.text = "── Blood ──"
	blood_header.add_theme_color_override("font_color", Styler.COL_BLOOD)
	blood_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	blood_header.add_theme_font_size_override("font_size", 18)
	blood_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blood_grid_spellbook.add_child(blood_header)
	blood_grid_spellbook.add_child(Control.new())

	for skill_instance in _known_skills:
		if skill_instance["skill_type"] == "paladin":
			paladin_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "buff":
			buffs_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "blood":
			blood_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "dark":
			dark_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "arcane":
			arcane_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))


func _make_skill_row_btn(skill_instance: Dictionary) -> Button:
	var row_btn = Button.new()
	row_btn.custom_minimum_size = Vector2(320, 96)

	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0, 0, 0, 0.05)
	sb_norm.set_corner_radius_all(4)
	row_btn.add_theme_stylebox_override("normal", sb_norm)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.position = Vector2(5, 5)
	row_btn.add_child(hbox)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(96, 96)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.texture = ItemDB.get_icon(skill_instance["skill_icon"])
	hbox.add_child(icon_rect)

	var vbox_info = VBoxContainer.new()
	vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_info)

	var lbl_name = Label.new()
	lbl_name.text = skill_instance["name"]
	# TODO: Get rank from Account when skill_usage data is available
	# For now, just display the base name
	# When rank data is available:
	# var rank = Account.get_skill_rank(skill_instance["skill_name"])
	# if rank >= 2:
	#     var numerals = {2: " II", 3: " III", 4: " IV"}
	#     lbl_name.text += numerals.get(rank, "")
	lbl_name.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	lbl_name.add_theme_font_size_override("font_size", 16)
	vbox_info.add_child(lbl_name)

	row_btn.tooltip_text = skill_instance["descr"]

	var mp_hbox = HBoxContainer.new()
	mp_hbox.add_theme_constant_override("separation", 8)
	mp_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_info.add_child(mp_hbox)

	# Check for HP cost skills
	var effect_data = skill_instance.get("effect", {})
	if typeof(effect_data) == TYPE_STRING:
		effect_data = JSON.parse_string(effect_data)
		if effect_data == null:
			effect_data = {}
	var hp_cost = 0
	if typeof(effect_data) == TYPE_DICTIONARY:
		hp_cost = int(effect_data.get("HP Cost", 0))

	var lbl_mana = Label.new()
	if hp_cost > 0:
		lbl_mana.text = "HP: " + str(hp_cost)
		lbl_mana.add_theme_color_override("font_color", Styler.COLOR_TEXT_ERROR)
	else:
		lbl_mana.text = "Mana: " + _fmt(skill_instance["mp_cost"])
		lbl_mana.add_theme_color_override("font_color", Color.from_rgba8(64, 180, 255))
	lbl_mana.add_theme_font_size_override("font_size", 14)
	mp_hbox.add_child(lbl_mana)

	var lbl_cast = Label.new()
	lbl_cast.text = "Cast: " + _fmt(float(skill_instance["cast_time"]) / 10) + "s"
	lbl_cast.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	lbl_cast.add_theme_font_size_override("font_size", 14)
	mp_hbox.add_child(lbl_cast)

	var lbl_cd = Label.new()
	lbl_cd.text = "CD: " + _fmt(float(skill_instance["cooldown"]) / 10) + "s"
	lbl_cd.add_theme_color_override("font_color", Color.GREEN)
	lbl_cd.add_theme_font_size_override("font_size", 14)
	mp_hbox.add_child(lbl_cd)

	var effect = _parse_effects(skill_instance)
	var lbl_effect = Label.new()
	lbl_effect.text = effect
	lbl_effect.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	lbl_effect.add_theme_font_size_override("font_size", 12)
	vbox_info.add_child(lbl_effect)

	row_btn.pressed.connect(_on_spellbook_clicked.bind(skill_instance))
	return row_btn


# ==============================================================================
# INTERACTION
# ==============================================================================
func _on_active_slot_clicked(index: int) -> void:
	if _active_slots[index] != null:
		_active_slots[index] = null
		SignalManager.signal_UnEquipSkill.emit(index)
		_refresh_skills_ui()


func _on_spellbook_clicked(skill_instance: Dictionary) -> void:
	var skill_id = int(skill_instance["skill_id"])
	if skill_id in _active_slots:
		return
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
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_paladin_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = true
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_buffs_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = true
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_blood_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = true
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_dark_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = true
	arcane_panel.visible = false


func _on_btn_skills_arcane_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = true


func _fmt(v) -> String:
	if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
		var is_whole = is_equal_approx(v, float(int(v)))
		if is_whole:
			return str(int(v))
		else:
			return "%0.1f" % v
	return str(v)


func _parse_effects(skill_instance) -> String:
	var stats_line = ""
	var duration_line = ""
	var keys = skill_instance["effect"].keys()
	if "Magical Damage" in keys:
		var value = int(skill_instance["effect"]["Magical Damage"])
		stats_line += "Magic Damage: " + str(value) + " "
	if "DOT Damage" in keys:
		var value = int(skill_instance["effect"]["DOT Damage"])
		stats_line += "DOT Damage: " + str(value) + " "
	if "Max MP" in keys:
		var value = (float(skill_instance["effect"]["Max MP"]) - 1) * 100
		stats_line += "Max MP: +" + _fmt(value) + "% "
	if "Physical Attack" in keys:
		var value = (float(skill_instance["effect"]["Physical Attack"]) - 1) * 100
		stats_line += "Physical Attack: +" + _fmt(value) + "% "
	if "Max Health" in keys:
		var value = (float(skill_instance["effect"]["Max Health"]) - 1) * 100
		stats_line += "Max Health: +" + _fmt(value) + "% "
	if "DMG multi" in keys:
		var value = (float(skill_instance["effect"]["DMG multi"]) - 1) * 100
		stats_line += "Damage: +" + _fmt(value) + "% from Magic ATK "
	if "HEAL multi" in keys:
		var value = (float(skill_instance["effect"]["HEAL multi"]) - 1) * 100
		stats_line += "Healing: +" + _fmt(value) + "% "
	if "Max Shield" in keys:
		var value = (float(skill_instance["effect"]["Max Shield"]) - 1) * 100
		stats_line += "Max Shield: +" + _fmt(value) + "% "
	if "Recovery HP" in keys:
		var value = float(skill_instance["effect"]["Recovery HP"])
		stats_line += "Recovery HP: +" + _fmt(value) + "HP "
	if "All Spell DMG" in keys:
		var value = float(skill_instance["effect"]["All Spell DMG"]) * 100
		stats_line += "Spell Damage: +" + _fmt(value) + "% "
	if "Physical Attack Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Physical Attack Reduce"])) * 100
		stats_line += "ATK Reduce: -" + _fmt(value) + "% "
	if "Attack Speed Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Attack Speed Reduce"])) * 100
		stats_line += "Slow: -" + _fmt(value) + "% "
	if "Shield Restore" in keys:
		stats_line += "Restores Shield "
	if "Incoming Damage Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Incoming Damage Reduce"])) * 100
		stats_line += "DMG Taken: -" + _fmt(value) + "% "
	if "DMG Output Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["DMG Output Reduce"])) * 100
		stats_line += "Enemy DMG: -" + _fmt(value) + "% "
	if "Magic Resist Reduce" in keys:
		var value = float(skill_instance["effect"]["Magic Resist Reduce"]) * 100
		stats_line += "Magic Resist: -" + _fmt(value) + "% "
	if "P Def Boost" in keys:
		var value = float(skill_instance["effect"]["P Def Boost"]) * 100
		stats_line += "P.Def: +" + _fmt(value) + "% "
	if "Recovery MP" in keys:
		var value = float(skill_instance["effect"]["Recovery MP"])
		stats_line += "MP Regen: +" + _fmt(value) + " "
	if "Thorns Buff" in keys:
		var value = float(skill_instance["effect"]["Thorns Buff"]) * 100
		stats_line += "Thorns: " + _fmt(value) + "% "
	if "P Def Reduce" in keys:
		var value = float(skill_instance["effect"]["P Def Reduce"]) * 100
		stats_line += "P.Def Reduce: -" + _fmt(value) + "% "
	if "Crit Chance Reduce" in keys:
		var value = float(skill_instance["effect"]["Crit Chance Reduce"]) * 100
		stats_line += "Crit Reduce: -" + _fmt(value) + "% "
	if "Haste" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Haste"])) * 100
		duration_line += "Haste: +" + _fmt(value) + "% "
	if "apply_each" in keys:
		var value = float(skill_instance["effect"]["apply_each"])
		if value > 0:
			duration_line += "every: " + _fmt(value / 10) + "s "
	if "active_ticks" in keys:
		var value = float(skill_instance["effect"]["active_ticks"])
		if value > 0:
			duration_line += "Active for: " + _fmt(value / 10) + "s "
	var output = " " + stats_line.strip_edges()
	if duration_line != "":
		output += "\n " + duration_line.strip_edges()
	return output
