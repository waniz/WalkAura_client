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
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Inset panel — same clearance as rift.gd
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left   =  24
	panel.offset_right  = -24
	panel.offset_top    =  210
	panel.offset_bottom = -150
	Styler.style_panel_no_margins(panel,
		Color.from_rgba8(16, 18, 24, 245),
		Color.from_rgba8(255, 200, 66, 180))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	# ── Header ──────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "BATTLE LOG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_title(title)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 44)
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# ── Milestone tick ───────────────────────────────────────────────────────
	var m_idx: int    = int(Account.rift_milestone_index)   if Account.rift_milestone_index   != null else 0
	var total_m: int  = int(Account.rift_total_milestones)  if Account.rift_total_milestones  != null else 8

	var tick_lbl := Label.new()
	tick_lbl.text = "Milestone Tick:  %d / %d" % [m_idx, total_m]
	tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_name_label(tick_lbl, Color.from_rgba8(255, 200, 66))
	root_vbox.add_child(tick_lbl)

	root_vbox.add_child(HSeparator.new())

	# ── 3-column arena ──────────────────────────────────────────────────────
	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 10)
	root_vbox.add_child(arena)

	arena.add_child(_build_player_panel())
	arena.add_child(_build_fight_log())
	arena.add_child(_build_enemy_panel(_current_enemy_name()))


# ── Helpers ─────────────────────────────────────────────────────────────────

func _current_enemy_name() -> String:
	if fights_data.is_empty():
		return "Unknown"
	var best: Dictionary = fights_data[0]
	for f in fights_data:
		if int(f.get("milestone_index", 0)) >= int(best.get("milestone_index", 0)):
			best = f
	return str(best.get("monster_id", "unknown")).replace("_", " ").capitalize()


func _build_player_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 0)
	Styler.style_panel_no_margins(panel,
		Color.from_rgba8(18, 28, 50, 220),
		Color.from_rgba8(80, 120, 200, 150))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",   10)
	margin.add_theme_constant_override("margin_bottom",10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Face image
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(80, 80)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var face_path := "res://assets/character_faces/face0.png"
	if ResourceLoader.exists(face_path):
		avatar.texture = load(face_path)
	vbox.add_child(avatar)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = str(Account.username) if Account.username != null else "Hero"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = 3
	Styler.style_name_label(name_lbl, Color.from_rgba8(255, 200, 66))
	vbox.add_child(name_lbl)

	# HP bar
	var hp: int     = int(Account.hp)     if Account.hp     != null else 0
	var hp_max: int = max(1, int(Account.hp_max) if Account.hp_max != null else 1)

	var hp_bar := ProgressBar.new()
	hp_bar.min_value        = 0
	hp_bar.max_value        = hp_max
	hp_bar.value            = hp
	hp_bar.show_percentage  = false
	hp_bar.custom_minimum_size = Vector2(0, 10)
	Styler.style_bar(hp_bar, Color.from_rgba8(220, 60, 60), Color.from_rgba8(40, 20, 20))
	vbox.add_child(hp_bar)

	var hp_lbl := Label.new()
	hp_lbl.text = "%d / %d" % [hp, hp_max]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_name_label(hp_lbl, Color.from_rgba8(220, 100, 100))
	vbox.add_child(hp_lbl)

	return panel


func _build_enemy_panel(enemy_name: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 0)
	Styler.style_panel_no_margins(panel,
		Color.from_rgba8(50, 18, 18, 220),
		Color.from_rgba8(200, 60, 60, 150))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",   10)
	margin.add_theme_constant_override("margin_bottom",10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Monster placeholder: PanelContainer sizes itself, Label fills via container
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(80, 80)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var holder_style := StyleBoxFlat.new()
	holder_style.bg_color = Color.from_rgba8(80, 20, 20, 200)
	holder.add_theme_stylebox_override("panel", holder_style)

	var q_lbl := Label.new()
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
	var name_lbl := Label.new()
	name_lbl.text = enemy_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = 3
	Styler.style_name_label(name_lbl, Color.from_rgba8(220, 120, 100))
	vbox.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "ENEMY"
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_name_label(type_lbl, Color.from_rgba8(150, 80, 80))
	vbox.add_child(type_lbl)

	return panel


func _build_fight_log() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	if fights_data.is_empty():
		var lbl := Label.new()
		lbl.text = "No battles recorded yet."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_name_label(lbl, Color.from_rgba8(150, 150, 150))
		vbox.add_child(lbl)
		return scroll

	var hp_max: int = max(1, int(Account.hp_max) if Account.hp_max != null else 100)

	for fight in fights_data:
		vbox.add_child(_build_fight_card(fight, hp_max))

	return scroll


func _build_fight_card(fight: Dictionary, hp_max: int) -> Control:
	var m_idx: int      = int(fight.get("milestone_index", 0))
	var monster_raw: String = str(fight.get("monster_id", "unknown"))
	var result: bool    = fight.get("result", false)
	var hp_before: int  = int(fight.get("player_hp_before", 0))
	var hp_after: int   = int(fight.get("player_hp_after",  0))
	var dmg: int        = hp_after - hp_before

	var result_color  := Color.from_rgba8(80,  220, 100, 255) if result else Color.from_rgba8(220, 70,  70,  255)
	var border_color  := Color.from_rgba8(60,  180,  80, 200) if result else Color.from_rgba8(180, 60,  60,  200)
	var bar_color     := Color.from_rgba8(80,  200, 100)      if result else Color.from_rgba8(200, 80,  80)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_panel_no_margins(card, Color.from_rgba8(22, 24, 32, 240), border_color)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# ── Row 1: fight number  ⚔  monster name  WIN/LOSS ──────────────────
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var num_lbl := Label.new()
	num_lbl.text = "#%d" % (m_idx + 1)
	Styler.style_name_label(num_lbl, Color.from_rgba8(140, 140, 140))
	top_row.add_child(num_lbl)

	var sword_lbl := Label.new()
	sword_lbl.text = "⚔"
	top_row.add_child(sword_lbl)

	var monster_lbl := Label.new()
	monster_lbl.text = monster_raw.replace("_", " ").capitalize()
	monster_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_name_label(monster_lbl, Color.from_rgba8(220, 190, 120))
	top_row.add_child(monster_lbl)

	var result_lbl := Label.new()
	result_lbl.text = "WIN" if result else "LOSS"
	Styler.style_name_label(result_lbl, result_color)
	top_row.add_child(result_lbl)

	# ── Row 2: HP before → after  (+/- delta) ────────────────────────────
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	vbox.add_child(hp_row)

	var hp_label := Label.new()
	hp_label.text = "HP  %d → %d" % [hp_before, hp_after]
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_name_label(hp_label, Color.from_rgba8(180, 180, 180))
	hp_row.add_child(hp_label)

	var dmg_lbl := Label.new()
	dmg_lbl.text = "(%+d)" % dmg
	Styler.style_name_label(dmg_lbl, result_color)
	hp_row.add_child(dmg_lbl)

	# ── Row 3: remaining-HP bar ───────────────────────────────────────────
	var bar := ProgressBar.new()
	bar.min_value           = 0
	bar.max_value           = hp_max
	bar.value               = hp_after
	bar.show_percentage     = false
	bar.custom_minimum_size = Vector2(0, 8)
	Styler.style_bar(bar, bar_color, Color.from_rgba8(30, 35, 50, 255))
	vbox.add_child(bar)

	return card
