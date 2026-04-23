extends Control

## Post-encounter fight result overlay for rift battles.
## Shows VICTORY/DEFEATED, enemy list, HP/MP delta, loot, fight stats,
## and node path progress. Dismisses with CONTINUE button.

const NODE_PATH_IND = preload("res://scenes/components/node_path_indicator.gd")

var fight_data: Dictionary = {}
var progress_data: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	anchor_left = 0.0; anchor_top = 0.0
	anchor_right = 1.0; anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Get tier color
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	var cfg = RiftData.RIFT_TABLE.get(rift_id, {})
	var tier = int(cfg.get("tier", 0))
	var tier_color = RiftData.TIER_COLORS.get(tier, Color.WHITE)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_dark_panel_style(panel, tier_color)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	# Extract fight data
	var result = fight_data.get("result", false)
	var m_idx = int(fight_data.get("milestone_index", 0))
	var monster_name = str(fight_data.get("monster_name", "Unknown"))
	var hp_before = int(fight_data.get("player_hp_before", 0))
	var hp_after = int(fight_data.get("player_hp_after", 0))
	var loot_counts = fight_data.get("loot_counts", {})
	var equipment_count = int(fight_data.get("equipment_count", 0))
	var fight_summary = fight_data.get("fight_summary", {})
	var enemies_status = fight_data.get("enemies_status", [])
	var monster_ids = str(fight_data.get("monster_id", "")).split(",", false)

	# Progress data
	var total_m = int(progress_data.get("rift_total_milestones", 1))
	var current_m = int(progress_data.get("rift_milestone_index", 0))
	var rift_complete = progress_data.get("rift_complete", false)
	var rift_died = progress_data.get("rift_died", false)
	var xp_gained = int(progress_data.get("xp_gained", 0))

	# --- VICTORY / DEFEATED header ---
	var result_header = Label.new()
	result_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_header.add_theme_font_override("font", Styler.JANDA_FONT)
	result_header.add_theme_font_size_override("font_size", 28)
	if result:
		result_header.text = "VICTORY"
		result_header.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	else:
		result_header.text = "DEFEATED"
		result_header.add_theme_color_override("font_color", Color.from_rgba8(220, 60, 60))
	vbox.add_child(result_header)

	# Subtitle
	var subtitle = Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
	if rift_complete:
		subtitle.text = "Rift Complete!"
	elif rift_died:
		subtitle.text = "Encounter #%d — You have fallen" % (m_idx + 1)
	else:
		subtitle.text = "Encounter #%d Complete" % (m_idx + 1)
	vbox.add_child(subtitle)

	# --- Enemy list ---
	if enemies_status.size() > 0:
		var enemies_panel = _make_section_panel()
		vbox.add_child(enemies_panel)
		var enemies_vbox = VBoxContainer.new()
		enemies_vbox.add_theme_constant_override("separation", 4)
		enemies_panel.add_child(enemies_vbox)

		var enemies_header = Label.new()
		enemies_header.text = "Enemies"
		enemies_header.add_theme_color_override("font_color", Color.from_rgba8(150, 150, 150))
		enemies_header.add_theme_font_size_override("font_size", 12)
		enemies_vbox.add_child(enemies_header)

		for i in enemies_status.size():
			var es = enemies_status[i]
			var enemy_row = HBoxContainer.new()
			enemy_row.add_theme_constant_override("separation", 8)
			enemy_row.custom_minimum_size.y = 40
			enemies_vbox.add_child(enemy_row)

			# Monster icon
			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(36, 36)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var mid = monster_ids[i].strip_edges() if i < monster_ids.size() else ""
			var icon_tex = ItemDB.get_monster_icon(mid)
			if icon_tex:
				icon_rect.texture = icon_tex
			enemy_row.add_child(icon_rect)

			var ename = Label.new()
			ename.text = str(es.get("name", "???"))
			ename.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ename.add_theme_color_override("font_color", Color.from_rgba8(220, 210, 200))
			ename.add_theme_font_size_override("font_size", 14)
			enemy_row.add_child(ename)

			var ehp = int(es.get("hp", 0))
			var ehp_max = int(es.get("hp_max", 1))
			var is_dead = ehp <= 0
			var status_lbl = Label.new()
			if is_dead:
				status_lbl.text = "SLAIN"
				status_lbl.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100))
			else:
				status_lbl.text = "%d/%d" % [ehp, ehp_max]
				status_lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 80, 80))
			status_lbl.add_theme_font_size_override("font_size", 12)
			enemy_row.add_child(status_lbl)
	elif monster_name != "Unknown":
		# Fallback: just show monster name from the fight entry
		var name_lbl = Label.new()
		name_lbl.text = "vs %s" % monster_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 190, 180))
		name_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_lbl)

	# --- Resource delta ---
	var stats_panel = _make_section_panel()
	vbox.add_child(stats_panel)
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(stats_vbox)

	var hp_delta = hp_after - hp_before
	var hp_row = _make_stat_row("HP", hp_before, hp_after, hp_delta)
	stats_vbox.add_child(hp_row)

	if xp_gained > 0:
		var xp_lbl = Label.new()
		xp_lbl.text = "XP: +%d" % xp_gained
		xp_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
		xp_lbl.add_theme_font_size_override("font_size", 14)
		stats_vbox.add_child(xp_lbl)

	# --- Fight summary stats ---
	if not fight_summary.is_empty():
		var summary_panel = _make_section_panel()
		vbox.add_child(summary_panel)
		var summary_vbox = VBoxContainer.new()
		summary_vbox.add_theme_constant_override("separation", 3)
		summary_panel.add_child(summary_vbox)

		var sum_header = Label.new()
		sum_header.text = "Combat Stats"
		sum_header.add_theme_color_override("font_color", Color.from_rgba8(150, 150, 150))
		sum_header.add_theme_font_size_override("font_size", 12)
		summary_vbox.add_child(sum_header)

		var dmg_dealt = int(fight_summary.get("total_damage_dealt", 0))
		var dmg_taken = int(fight_summary.get("total_damage_taken", 0))
		var crits = int(fight_summary.get("crit_count", 0))
		var dodges = int(fight_summary.get("dodge_count", 0))
		var ticks = int(fight_summary.get("duration_ticks", 0))
		var highest = int(fight_summary.get("highest_hit", 0))

		_add_stat_line(summary_vbox, "Damage Dealt", str(dmg_dealt), Styler.COL_OFFENSE)
		_add_stat_line(summary_vbox, "Damage Taken", str(dmg_taken), Color.from_rgba8(220, 80, 80))
		if crits > 0:
			_add_stat_line(summary_vbox, "Critical Hits", str(crits), Styler.COL_PRIMARY)
		if highest > 0:
			_add_stat_line(summary_vbox, "Highest Hit", str(highest), Styler.COL_PRIMARY)
		if dodges > 0:
			_add_stat_line(summary_vbox, "Dodges", str(dodges), Styler.COL_DEFENSE)
		if ticks > 0:
			_add_stat_line(summary_vbox, "Duration", "%d ticks" % ticks, Color.from_rgba8(180, 180, 180))

	# --- Loot ---
	var total_loot = 0
	if loot_counts is Dictionary:
		for v in loot_counts.values():
			total_loot += int(v)
	if total_loot > 0 or equipment_count > 0:
		var loot_panel = _make_section_panel()
		vbox.add_child(loot_panel)
		var loot_vbox = VBoxContainer.new()
		loot_vbox.add_theme_constant_override("separation", 3)
		loot_panel.add_child(loot_vbox)

		var loot_header = Label.new()
		loot_header.text = "Loot"
		loot_header.add_theme_color_override("font_color", Color.from_rgba8(150, 150, 150))
		loot_header.add_theme_font_size_override("font_size", 12)
		loot_vbox.add_child(loot_header)

		if total_loot > 0:
			var loot_lbl = Label.new()
			loot_lbl.text = "%d items collected" % total_loot
			loot_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 200, 200))
			loot_lbl.add_theme_font_size_override("font_size", 14)
			loot_vbox.add_child(loot_lbl)

		if equipment_count > 0:
			var equip_lbl = Label.new()
			equip_lbl.text = "%d equipment dropped!" % equipment_count
			equip_lbl.add_theme_color_override("font_color", Color.from_rgba8(163, 54, 237))
			equip_lbl.add_theme_font_size_override("font_size", 14)
			loot_vbox.add_child(equip_lbl)

	# --- Node path ---
	var node_path = NODE_PATH_IND.new()
	node_path.setup(total_m, current_m, tier_color)
	vbox.add_child(node_path)

	# --- CONTINUE button ---
	var continue_btn = Button.new()
	continue_btn.text = "CONTINUE"
	continue_btn.custom_minimum_size = Vector2(0, 52)
	continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(continue_btn, Color(tier_color, 0.7))
	continue_btn.add_theme_color_override("font_color", Color.WHITE)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.pressed.connect(queue_free)
	vbox.add_child(continue_btn)


func _make_section_panel() -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p


func _make_stat_row(label: String, before: int, after: int, delta: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl = Label.new()
	lbl.text = "%s: %d → %d" % [label, before, after]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 200, 200))
	lbl.add_theme_font_size_override("font_size", 14)
	row.add_child(lbl)

	var delta_lbl = Label.new()
	if delta >= 0:
		delta_lbl.text = "+%d" % delta
		delta_lbl.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100))
	else:
		delta_lbl.text = "%d" % delta
		delta_lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 80, 80))
	delta_lbl.add_theme_font_size_override("font_size", 14)
	row.add_child(delta_lbl)

	return row


func _add_stat_line(parent: VBoxContainer, label: String, value: String, color: Color) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color.from_rgba8(160, 160, 160))
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var val = Label.new()
	val.text = value
	val.add_theme_color_override("font_color", color)
	val.add_theme_font_size_override("font_size", 13)
	row.add_child(val)
