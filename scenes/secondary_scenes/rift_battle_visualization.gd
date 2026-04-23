extends Control

var fights_data: Array = []


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = MOUSE_FILTER_STOP

	# Dark backdrop
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Inset panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left   = mo["left"]
	panel.offset_right  = mo["right"]
	panel.offset_top    = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_parchment_style(panel)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	# ── Header ──────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title = Label.new()
	title.text = "BATTLE LOG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 44)
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# ── Milestone tick ───────────────────────────────────────────────────────
	var m_idx: int    = int(Account.rift_milestone_index)   if Account.rift_milestone_index   != null else 0
	var total_m: int  = int(Account.rift_total_milestones)  if Account.rift_total_milestones  != null else 8

	var tick_lbl = Label.new()
	tick_lbl.text = "Milestone Tick:  %d / %d" % [m_idx, total_m]
	tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(tick_lbl, Styler.COLOR_GOLD)
	root_vbox.add_child(tick_lbl)

	root_vbox.add_child(HSeparator.new())

	# ── 3-column arena ──────────────────────────────────────────────────────
	var arena = HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 10)
	root_vbox.add_child(arena)

	arena.add_child(_build_player_panel())
	arena.add_child(_build_fight_log())

	# Right panel: single enemy or raid enemy list
	var latest_fight = _get_latest_fight()
	if latest_fight.get("is_raid", false):
		arena.add_child(_build_raid_enemy_panel(latest_fight))
	else:
		arena.add_child(_build_enemy_panel(_current_enemy_name()))

	# ── Combat log summary (for raid fights) ────────────────────────────────
	if latest_fight.get("is_raid", false) and latest_fight.has("combat_log"):
		root_vbox.add_child(HSeparator.new())
		root_vbox.add_child(_build_combat_log_summary(latest_fight["combat_log"]))


# ── Helpers ─────────────────────────────────────────────────────────────────

func _get_latest_fight() -> Dictionary:
	if fights_data.is_empty():
		return {}
	var best: Dictionary = fights_data[0]
	for f in fights_data:
		if int(f.get("milestone_index", 0)) >= int(best.get("milestone_index", 0)):
			best = f
	return best


func _current_enemy_name() -> String:
	var latest = _get_latest_fight()
	if latest.is_empty():
		return "Unknown"
	return str(latest.get("monster_id", "unknown")).replace("_", " ").capitalize()


func _build_player_panel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 0)
	var _psb = StyleBoxFlat.new()
	_psb.bg_color     = Color.from_rgba8(80, 120, 200, 25)
	_psb.border_color = Color.from_rgba8(80, 120, 200, 160)
	_psb.set_border_width_all(1)
	_psb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", _psb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",   10)
	margin.add_theme_constant_override("margin_bottom",10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Face image
	var avatar = TextureRect.new()
	avatar.custom_minimum_size = Vector2(80, 80)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var face_path = "res://assets/character_faces/face0.png"
	if ResourceLoader.exists(face_path):
		avatar.texture = load(face_path)
	vbox.add_child(avatar)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = str(Account.username) if Account.username != null else "Hero"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styler.style_parchment_label(name_lbl, Styler.COLOR_TEXT_DARK)
	vbox.add_child(name_lbl)

	# HP bar
	var hp: int     = int(Account.hp)     if Account.hp     != null else 0
	var hp_max: int = max(1, int(Account.hp_max) if Account.hp_max != null else 1)

	var hp_bar = ProgressBar.new()
	hp_bar.min_value        = 0
	hp_bar.max_value        = hp_max
	hp_bar.value            = hp
	hp_bar.show_percentage  = false
	hp_bar.custom_minimum_size = Vector2(0, 10)
	var _hp_bg = StyleBoxFlat.new()
	_hp_bg.bg_color = Color(0.0, 0.0, 0.0, 0.2)
	_hp_bg.set_corner_radius_all(10)
	hp_bar.add_theme_stylebox_override("background", _hp_bg)
	var _hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = Color.from_rgba8(220, 60, 60)
	_hp_fill.set_corner_radius_all(10)
	hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	vbox.add_child(hp_bar)

	var hp_lbl = Label.new()
	hp_lbl.text = "%d / %d" % [hp, hp_max]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(hp_lbl, Styler.COLOR_TEXT_DARK)
	vbox.add_child(hp_lbl)

	return panel


func _build_enemy_panel(enemy_name: String) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 0)
	var _esb = StyleBoxFlat.new()
	_esb.bg_color     = Color.from_rgba8(200, 60, 60, 25)
	_esb.border_color = Color.from_rgba8(200, 60, 60, 160)
	_esb.set_border_width_all(1)
	_esb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", _esb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",   10)
	margin.add_theme_constant_override("margin_bottom",10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Monster placeholder
	var holder = PanelContainer.new()
	holder.custom_minimum_size = Vector2(80, 80)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var holder_style = StyleBoxFlat.new()
	holder_style.bg_color = Color.from_rgba8(80, 20, 20, 200)
	holder.add_theme_stylebox_override("panel", holder_style)

	var q_lbl = Label.new()
	q_lbl.text = "?"
	q_lbl.add_theme_font_size_override("font_size", 42)
	q_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 80, 80, 180))
	q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	q_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	holder.add_child(q_lbl)

	vbox.add_child(holder)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = enemy_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styler.style_parchment_label(name_lbl, Styler.COLOR_TEXT_DARK)
	vbox.add_child(name_lbl)

	var type_lbl = Label.new()
	type_lbl.text = "ENEMY"
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(type_lbl, Styler.COLOR_TEXT_DARK)
	vbox.add_child(type_lbl)

	return panel


func _build_raid_enemy_panel(fight: Dictionary) -> Control:
	"""Build a scrollable panel with multiple enemy portraits and HP bars."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 0)
	var _esb = StyleBoxFlat.new()
	_esb.bg_color     = Color.from_rgba8(200, 60, 60, 25)
	_esb.border_color = Color.from_rgba8(200, 60, 60, 160)
	_esb.set_border_width_all(1)
	_esb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", _esb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   6)
	margin.add_theme_constant_override("margin_right",  6)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	# Title
	var title_lbl = Label.new()
	title_lbl.text = "ENEMIES"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(title_lbl, Styler.COLOR_GOLD)
	vbox.add_child(title_lbl)

	# Enemy list from enemies_status
	var enemies = fight.get("enemies_status", [])
	for enemy in enemies:
		vbox.add_child(_build_raid_enemy_row(enemy))

	return panel


func _build_raid_enemy_row(enemy: Dictionary) -> Control:
	"""Build a compact row for one enemy: name, role badge, HP bar."""
	var row_panel = PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var _rsb = StyleBoxFlat.new()
	var is_dead = int(enemy.get("hp", 0)) <= 0
	_rsb.bg_color = Color.from_rgba8(40, 10, 10, 100) if is_dead else Color.from_rgba8(80, 20, 20, 80)
	_rsb.set_corner_radius_all(4)
	row_panel.add_theme_stylebox_override("panel", _rsb)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",  4)
	m.add_theme_constant_override("margin_right", 4)
	m.add_theme_constant_override("margin_top",   3)
	m.add_theme_constant_override("margin_bottom",3)
	row_panel.add_child(m)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	m.add_child(vbox)

	# Name + role
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	vbox.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = str(enemy.get("name", "?"))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_color = Color.from_rgba8(120, 80, 80) if is_dead else Styler.COLOR_TEXT_DARK
	Styler.style_parchment_label(name_lbl, name_color)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_row.add_child(name_lbl)

	if is_dead:
		var dead_lbl = Label.new()
		dead_lbl.text = "DEAD"
		Styler.style_parchment_label(dead_lbl, Color.from_rgba8(180, 60, 60))
		dead_lbl.add_theme_font_size_override("font_size", 11)
		name_row.add_child(dead_lbl)

	# HP bar
	var hp_val = max(0, int(enemy.get("hp", 0)))
	var hp_max_val = max(1, int(enemy.get("hp_max", 1)))

	var hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = hp_max_val
	hp_bar.value = hp_val
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 6)
	var _hp_bg = StyleBoxFlat.new()
	_hp_bg.bg_color = Color(0, 0, 0, 0.2)
	_hp_bg.set_corner_radius_all(6)
	hp_bar.add_theme_stylebox_override("background", _hp_bg)
	var _hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = Color.from_rgba8(200, 80, 80) if not is_dead else Color.from_rgba8(80, 40, 40)
	_hp_fill.set_corner_radius_all(6)
	hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	vbox.add_child(hp_bar)

	return row_panel


func _build_combat_log_summary(combat_log: Dictionary) -> Control:
	"""Build a compact combat log summary: damage by element + recommendations."""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var summary = combat_log.get("encounter_summary", {})
	var result_text = str(summary.get("result", "unknown")).to_upper()
	var ticks = int(summary.get("duration_ticks", 0))
	var killed = int(summary.get("enemies_killed", 0))
	var total_enemies = int(summary.get("enemies_total", 0))

	# Result header
	var result_lbl = Label.new()
	var is_win = result_text == "WIN"
	result_lbl.text = "%s  (%d ticks, %d/%d killed)" % [result_text, ticks, killed, total_enemies]
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var result_color = Styler.COLOR_GOLD if is_win else Color.from_rgba8(200, 80, 80)
	Styler.style_parchment_label(result_lbl, result_color)
	vbox.add_child(result_lbl)

	# Damage by element
	var dmg_by_elem = combat_log.get("damage_taken_by_element", {})
	if not dmg_by_elem.is_empty():
		var dmg_total = 0
		for v in dmg_by_elem.values():
			dmg_total += int(v)
		dmg_total = max(dmg_total, 1)

		var elem_row = HBoxContainer.new()
		elem_row.add_theme_constant_override("separation", 6)
		elem_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(elem_row)

		# Color map for elements
		var elem_colors = {
			"physical": Color.from_rgba8(180, 160, 120),
			"fire": Color.from_rgba8(220, 100, 40),
			"frost": Color.from_rgba8(80, 160, 220),
			"arcane": Color.from_rgba8(160, 80, 200),
			"dark": Color.from_rgba8(120, 60, 140),
			"holy": Color.from_rgba8(240, 220, 100),
			"nature": Color.from_rgba8(80, 180, 80),
			"blood": Color.from_rgba8(160, 40, 40),
		}

		for elem_key in dmg_by_elem:
			var amount = int(dmg_by_elem[elem_key])
			var pct = int(100.0 * amount / dmg_total)
			if pct < 5:
				continue
			var chip = PanelContainer.new()
			var chip_sb = StyleBoxFlat.new()
			var chip_color = elem_colors.get(elem_key, Color.from_rgba8(150, 150, 150))
			chip_sb.bg_color = Color(chip_color.r, chip_color.g, chip_color.b, 0.3)
			chip_sb.border_color = chip_color
			chip_sb.set_border_width_all(1)
			chip_sb.set_corner_radius_all(4)
			chip.add_theme_stylebox_override("panel", chip_sb)

			var chip_lbl = Label.new()
			chip_lbl.text = " %s %d%% " % [str(elem_key).capitalize(), pct]
			Styler.style_parchment_label(chip_lbl, chip_color)
			chip_lbl.add_theme_font_size_override("font_size", 12)
			chip.add_child(chip_lbl)

			elem_row.add_child(chip)

	# Recommendations
	var recs = combat_log.get("recommendations", [])
	if not recs.is_empty():
		var rec_title = Label.new()
		rec_title.text = "Recommendations:"
		Styler.style_parchment_label(rec_title, Styler.COLOR_GOLD)
		rec_title.add_theme_font_size_override("font_size", 14)
		vbox.add_child(rec_title)

		for rec in recs:
			var rec_lbl = Label.new()
			rec_lbl.text = "  - " + str(rec)
			rec_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			Styler.style_parchment_label(rec_lbl, Styler.COLOR_TEXT_DARK)
			rec_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(rec_lbl)

	return vbox


func _build_fight_log() -> Control:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	if fights_data.is_empty():
		var lbl = Label.new()
		lbl.text = "No battles recorded yet."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(lbl, Color.from_rgba8(150, 150, 150))
		vbox.add_child(lbl)
		return scroll

	var hp_max: int = max(1, int(Account.hp_max) if Account.hp_max != null else 100)

	for fight in fights_data:
		vbox.add_child(_build_fight_card(fight, hp_max))

	return scroll


func _build_fight_card(fight: Dictionary, hp_max: int) -> Control:
	var m_idx: int      = int(fight.get("milestone_index", 0))
	var monster_raw: String = str(fight.get("monster_name", fight.get("monster_id", "unknown")))
	var result: bool    = fight.get("result", false)
	var hp_before: int  = int(fight.get("player_hp_before", 0))
	var hp_after: int   = int(fight.get("player_hp_after",  0))
	var dmg: int        = hp_after - hp_before

	var result_color  = Color.from_rgba8(80,  220, 100, 255) if result else Color.from_rgba8(220, 70,  70,  255)
	var border_color  = Color.from_rgba8(60,  180,  80, 200) if result else Color.from_rgba8(180, 60,  60,  200)
	var bar_color     = Color.from_rgba8(80,  200, 100)      if result else Color.from_rgba8(200, 80,  80)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var _fsb = StyleBoxFlat.new()
	_fsb.bg_color     = Color(0.0, 0.0, 0.0, 0.05)
	_fsb.border_color = border_color
	_fsb.set_border_width_all(1)
	_fsb.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", _fsb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# ── Row 1: fight number  ⚔  monster name  WIN/LOSS ──────────────────
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var num_lbl = Label.new()
	num_lbl.text = "#%d" % (m_idx + 1)
	Styler.style_parchment_label(num_lbl, Styler.COLOR_TEXT_DARK)
	top_row.add_child(num_lbl)

	var sword_lbl = Label.new()
	sword_lbl.text = "⚔"
	top_row.add_child(sword_lbl)

	var monster_lbl = Label.new()
	if fight.get("is_raid", false):
		# Show enemy count for raid encounters
		var enemy_count = len(fight.get("enemies_status", []))
		monster_lbl.text = "%s (%d)" % [monster_raw, enemy_count]
	else:
		monster_lbl.text = monster_raw.replace("_", " ").capitalize()
	monster_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_parchment_label(monster_lbl, Styler.COLOR_TEXT_DARK)
	monster_lbl.add_theme_font_size_override("font_size", 13)
	top_row.add_child(monster_lbl)

	var result_lbl = Label.new()
	result_lbl.text = "WIN" if result else "LOSS"
	Styler.style_parchment_label(result_lbl, result_color)
	top_row.add_child(result_lbl)

	# ── Row 2: HP before → after  (+/- delta) ────────────────────────────
	var hp_row = HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	vbox.add_child(hp_row)

	var hp_label = Label.new()
	hp_label.text = "HP  %d → %d" % [hp_before, hp_after]
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_parchment_label(hp_label, Styler.COLOR_TEXT_DARK)
	hp_row.add_child(hp_label)

	var dmg_lbl = Label.new()
	dmg_lbl.text = "(%+d)" % dmg
	Styler.style_parchment_label(dmg_lbl, result_color)
	hp_row.add_child(dmg_lbl)

	# ── Row 3: remaining-HP bar ───────────────────────────────────────────
	var bar = ProgressBar.new()
	bar.min_value           = 0
	bar.max_value           = hp_max
	bar.value               = hp_after
	bar.show_percentage     = false
	bar.custom_minimum_size = Vector2(0, 8)
	var _bar_bg = StyleBoxFlat.new()
	_bar_bg.bg_color = Color(0.0, 0.0, 0.0, 0.2)
	_bar_bg.set_corner_radius_all(10)
	bar.add_theme_stylebox_override("background", _bar_bg)
	var _bar_fill = StyleBoxFlat.new()
	_bar_fill.bg_color = bar_color
	_bar_fill.set_corner_radius_all(10)
	bar.add_theme_stylebox_override("fill", _bar_fill)
	vbox.add_child(bar)

	# ── Row 4 (raid only): killed count ──────────────────────────────────
	if fight.get("is_raid", false):
		var cl = fight.get("combat_log", {})
		var es = cl.get("encounter_summary", {})
		var killed = int(es.get("enemies_killed", 0))
		var total_e = int(es.get("enemies_total", 0))
		var kill_lbl = Label.new()
		kill_lbl.text = "Enemies killed: %d / %d" % [killed, total_e]
		Styler.style_parchment_label(kill_lbl, Styler.COLOR_TEXT_DARK)
		kill_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(kill_lbl)

	return card
