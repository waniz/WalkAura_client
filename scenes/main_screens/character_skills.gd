extends Control

const TALENT_KEYS = [
	{"k":"thick_skin_lvl",       "n":"Thick Skin",       "exp": "thick_skin_xp"},
	{"k":"brutal_finish_lvl",    "n":"Brutal Finish",    "exp": "brutal_finish_xp"},
	{"k":"guardian_shell_lvl",   "n":"Guardian Shell",   "exp": "guardian_shell_xp"},
	{"k":"evasion_training_lvl", "n":"Evasion Training", "exp": "evasion_training_xp"},
]

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
var mage_grid_spellbook: GridContainer
var paladin_grid_spellbook: GridContainer
var buffs_grid_spellbook: GridContainer
var talent_grid: GridContainer
var title_talents: Label


func _ready() -> void:
	PASSIVE_TOTAL_TO_LEVEL = ServerParams.PASSIVE_TOTAL_TO_LEVEL
	_build_ui()

	AccountManager.signal_AllSkillsReceived.connect(_update_game_skills)
	AccountManager.signal_AccountSkillsReceived.connect(_update_skills)
	AccountManager.signal_AccountDataReceived.connect(_update_character_talents_signal)

	if Account.raw_structures.all_server_skills != null and not Account.raw_structures.all_server_skills.is_empty():
		_update_game_skills(Account.raw_structures.all_server_skills)

	if Account.raw_structures.account_skills != null and not Account.raw_structures.account_skills.is_empty():
		_update_skills(Account.raw_structures.account_skills)

	_update_character_talents()
	_setup_skill_panel_structure()
	_refresh_skills_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox_root := VBoxContainer.new()
	vbox_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	vbox_root.offset_left = Styler.CONTENT_MARGIN_H
	vbox_root.offset_top = Styler.content_top
	vbox_root.offset_right = -Styler.CONTENT_MARGIN_H
	vbox_root.offset_bottom = Styler.content_bottom
	add_child(vbox_root)

	# --- Tab Buttons ---
	var tab_hbox := HBoxContainer.new()
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
	var body := PanelContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_root.add_child(body)

	# --- Skill Panel ---
	skill_panel = PanelContainer.new()
	skill_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(skill_panel)

	var skill_margin := MarginContainer.new()
	skill_margin.add_theme_constant_override("margin_left", 10)
	skill_margin.add_theme_constant_override("margin_top", 10)
	skill_margin.add_theme_constant_override("margin_right", 10)
	skill_margin.add_theme_constant_override("margin_bottom", 10)
	skill_panel.add_child(skill_margin)

	var skill_vbox_outer := VBoxContainer.new()
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
	btn_skills_buffs.text = "Buffs"
	h_box_btn_control.add_child(btn_skills_buffs)

	spellbook_panel_base = PanelContainer.new()
	spellbook_panel_base.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spellbook_panel_base.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	skill_vbox_outer.add_child(spellbook_panel_base)

	mage_panel = PanelContainer.new()
	mage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mage_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	spellbook_panel_base.add_child(mage_panel)

	mage_grid_spellbook = GridContainer.new()
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

	# --- Talents Panel ---
	talents_panel = PanelContainer.new()
	talents_panel.visible = false
	talents_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(talents_panel)

	var talent_margin := MarginContainer.new()
	talent_margin.add_theme_constant_override("margin_left", 10)
	talent_margin.add_theme_constant_override("margin_top", 10)
	talent_margin.add_theme_constant_override("margin_right", 10)
	talent_margin.add_theme_constant_override("margin_bottom", 10)
	talents_panel.add_child(talent_margin)

	var talent_vbox := VBoxContainer.new()
	talent_margin.add_child(talent_vbox)

	title_talents = Label.new()
	title_talents.text = "Passive Skills"
	talent_vbox.add_child(title_talents)

	talent_grid = GridContainer.new()
	talent_grid.columns = 2
	talent_vbox.add_child(talent_grid)

	# --- Style ---
	Styler.style_button(btn_tab_skills, Color.from_rgba8(64, 180, 255))
	Styler.style_button(btn_tab_talents, Color.from_rgba8(64, 180, 255))
	_set_skills_tab_active(btn_tab_skills)

	Styler._apply_parchment_style(talents_panel)
	title_talents.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_talents.add_theme_font_size_override("font_size", 22)
	title_talents.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

	# --- Connect ---
	btn_tab_skills.pressed.connect(_on_btn_tab_skills_pressed)
	btn_tab_talents.pressed.connect(_on_btn_tab_talents_pressed)
	btn_skills_mage.pressed.connect(_on_btn_skills_mage_pressed)
	btn_skills_paladin.pressed.connect(_on_btn_skills_paladin_pressed)
	btn_skills_buffs.pressed.connect(_on_btn_skills_buffs_pressed)


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
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
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


func _update_character_talents() -> void:
	var stats = Account.to_dict()
	set_stats(stats)


func _update_character_talents_signal(_dummy) -> void:
	var stats = Account.to_dict()
	set_stats(stats)


func set_stats(d: Dictionary) -> void:
	_clear(talent_grid)
	var accent_color = Color.from_rgba8(64, 180, 255)
	for entry in TALENT_KEYS:
		var lvl = int(d.get(entry.k, 0))
		var xp = int(d.get(entry.exp, 0))
		var card = _make_mini_card_primary(entry.n, lvl, xp, accent_color)
		talent_grid.add_child(card)


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _make_mini_card_primary(stat_name: String, lvl: int, xp: int, accent: Color) -> Control:
	var lvl_key = str(lvl)
	var next_lvl_key = str(lvl + 1)
	var cur_base = PASSIVE_TOTAL_TO_LEVEL.get(lvl_key, 0)
	var next_base = PASSIVE_TOTAL_TO_LEVEL.get(next_lvl_key, cur_base + 100)
	var lvl_current = xp - cur_base
	var lvl_progress = next_base - cur_base
	var frac = 0.0
	if lvl_progress > 0: frac = float(lvl_current) / float(lvl_progress)
	var pct = int(round(frac * 100.0))

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 80)
	panel.tooltip_text = stat_name + "\n(Passive Talent)"

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_width_left = 1; sb.border_width_top = 1; sb.border_width_right = 1; sb.border_width_bottom = 1
	sb.border_color = Color(0.0, 0.0, 0.0, 0.2)
	sb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", sb)

	var main_hbox := HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 5); m.add_theme_constant_override("margin_right", 5)
	m.add_theme_constant_override("margin_top", 5); m.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(m)
	m.add_child(main_hbox)

	var icon_box := VBoxContainer.new()
	icon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(icon_box)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

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
	if ItemDB.has_icon(icon_key.get(stat_name)):
		icon.texture = ItemDB.get_icon(icon_key.get(stat_name))

	var spacer = Control.new()
	spacer.custom_minimum_size.x = 8
	main_hbox.add_child(spacer)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(vb)

	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)

	var n_lbl := Label.new()
	n_lbl.text = stat_name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	n_lbl.add_theme_font_size_override("font_size", 14)
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(lvl)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 18)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	hb.add_child(v_lbl)

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

	for skill_instance in _known_skills:
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

		if skill_instance["skill_type"] == "mage":
			mage_grid_spellbook.add_child(row_btn)
		elif skill_instance["skill_type"] == "paladin":
			paladin_grid_spellbook.add_child(row_btn)
		elif skill_instance["skill_type"] == "buff":
			buffs_grid_spellbook.add_child(row_btn)


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


func _parse_effects(skill_instance) -> String:
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
