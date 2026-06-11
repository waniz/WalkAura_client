extends Control

# Quest detail overlay — P3 boilerplate. Shows full quest info with
# Untrack/Abandon/Turn-in actions wired to QuestManager.

var quest_id: String = ""
var _q: Dictionary = {}


func _ready() -> void:
	anchor_left = 0; anchor_top = 0
	anchor_right = 1; anchor_bottom = 1
	mouse_filter = MOUSE_FILTER_STOP
	_resolve_quest()
	_build_ui()
	QuestManager.signal_QuestsUpdated.connect(_on_quests_updated)


func _resolve_quest() -> void:
	for q in QuestManager.quests:
		if q.get("id", "") == quest_id:
			_q = q
			return
	_q = {}


func _on_quests_updated() -> void:
	_resolve_quest()
	if _q.is_empty():
		queue_free()


func _build_ui() -> void:
	# Dim backdrop.
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			queue_free()
	)
	add_child(bg)

	# Card panel.
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	var tier: int = int(_q.get("tier", 0))
	var is_story: bool = _q.get("type", "") == "story"
	var accent: Color = Styler.COL_PRIMARY if is_story else Styler.get_tier_color(tier)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(16, 18, 24, 245)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(accent, 0.4)
	sb.shadow_size = 16
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	# Header row: back + title + level.
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	vb.add_child(head)

	var back = Button.new()
	back.text = "‹"
	back.custom_minimum_size = Vector2(40, 40)
	back.add_theme_font_override("font", Styler.JANDA_FONT)
	back.add_theme_font_size_override("font_size", 22)
	back.add_theme_color_override("font_color", Styler.COLOR_TEXT_SUCCESS)
	back.add_theme_color_override("font_hover_color", Styler.COLOR_TEXT_SUCCESS.lightened(0.15))
	for s in ["normal", "hover", "pressed", "focus"]:
		var b_sb = StyleBoxFlat.new()
		b_sb.bg_color = Color(Styler.COLOR_BTN_SUCCESS, 0.28)
		b_sb.border_color = Styler.COLOR_TEXT_SUCCESS
		b_sb.set_border_width_all(2)
		b_sb.set_corner_radius_all(4)
		b_sb.shadow_color = Color(Styler.COLOR_TEXT_SUCCESS, 0.35)
		b_sb.shadow_size = 6
		if s == "hover":
			b_sb.bg_color = Color(Styler.COLOR_BTN_SUCCESS, 0.42)
		back.add_theme_stylebox_override(s, b_sb)
	back.pressed.connect(queue_free)
	head.add_child(back)

	var title_block = VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 2)
	head.add_child(title_block)

	var eyebrow = Label.new()
	eyebrow.text = _eyebrow_text()
	eyebrow.add_theme_font_override("font", Styler.JANDA_FONT)
	eyebrow.add_theme_font_size_override("font_size", 11)
	eyebrow.add_theme_color_override("font_color", accent)
	title_block.add_child(eyebrow)

	var name_lbl = Label.new()
	name_lbl.text = String(_q.get("name", ""))
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	title_block.add_child(name_lbl)

	var lvl = Label.new()
	lvl.text = "Lvl %d" % int(_q.get("level", 0))
	lvl.add_theme_font_override("font", Styler.JANDA_FONT)
	lvl.add_theme_font_size_override("font_size", 13)
	lvl.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.7))
	head.add_child(lvl)

	# Lore block.
	var lore_text: String = String(_q.get("lore", ""))
	if lore_text != "":
		var lore_panel = PanelContainer.new()
		var lore_sb = StyleBoxFlat.new()
		lore_sb.bg_color = Color(1, 1, 1, 0.04)
		lore_sb.border_color = Color(accent, 0.3)
		lore_sb.border_width_left = 2
		lore_sb.set_corner_radius_all(4)
		lore_sb.content_margin_left = 10
		lore_sb.content_margin_right = 10
		lore_sb.content_margin_top = 8
		lore_sb.content_margin_bottom = 8
		lore_panel.add_theme_stylebox_override("panel", lore_sb)
		var lore_lbl = Label.new()
		lore_lbl.text = lore_text
		lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		lore_lbl.add_theme_font_size_override("font_size", 13)
		lore_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 192, 170))
		lore_panel.add_child(lore_lbl)
		vb.add_child(lore_panel)

	# Giver block.
	var giver = Label.new()
	giver.text = "GIVEN BY  %s  ·  %s" % [String(_q.get("giver", "?")), String(_q.get("turnin_location", "?"))]
	giver.add_theme_font_override("font", Styler.JANDA_FONT)
	giver.add_theme_font_size_override("font_size", 11)
	giver.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.6))
	vb.add_child(giver)

	# Objectives section.
	vb.add_child(_section_header("OBJECTIVES", accent))
	for obj in _q.get("objectives", []):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var check = Label.new()
		var done: bool = int(obj.get("count", 0)) >= int(obj.get("total", 1))
		check.text = "✓" if done else "○"
		check.add_theme_font_size_override("font_size", 14)
		check.add_theme_color_override("font_color", Styler.COLOR_BTN_SUCCESS if done else Color(1, 1, 1, 0.35))
		row.add_child(check)
		var nm = Label.new()
		nm.text = String(obj.get("label", ""))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.add_theme_font_override("font", Styler.QUADRAT_FONT)
		nm.add_theme_font_size_override("font_size", 14)
		nm.add_theme_color_override("font_color", Color.from_rgba8(232, 224, 207))
		row.add_child(nm)
		var cnt = Label.new()
		cnt.text = "%d / %d" % [int(obj.get("count", 0)), int(obj.get("total", 0))]
		cnt.add_theme_font_override("font", Styler.JANDA_FONT)
		cnt.add_theme_font_size_override("font_size", 13)
		cnt.add_theme_color_override("font_color", accent)
		row.add_child(cnt)
		vb.add_child(row)

	# Rewards section.
	vb.add_child(_section_header("REWARDS", accent))
	var rew_grid = GridContainer.new()
	rew_grid.columns = 2
	rew_grid.add_theme_constant_override("h_separation", 6)
	rew_grid.add_theme_constant_override("v_separation", 4)
	for r in _q.get("rewards", []):
		rew_grid.add_child(_reward_cell(r))
	vb.add_child(rew_grid)

	# Action buttons.
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	vb.add_child(actions)

	if _q.get("is_ready_to_turn_in", false):
		var turnin = Button.new()
		turnin.text = "✓ TURN IN"
		turnin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		turnin.custom_minimum_size = Vector2(0, 48)
		_style_action(turnin, Styler.COL_PRIMARY, true)
		turnin.pressed.connect(func():
			QuestManager.turn_in(quest_id)
			queue_free()
		)
		actions.add_child(turnin)
	else:
		var track = Button.new()
		track.text = "TRACK" if not _q.get("is_tracked", false) else "UNTRACK"
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.custom_minimum_size = Vector2(0, 44)
		_style_action(track, Styler.COL_PRIMARY, false)
		track.pressed.connect(func():
			if _q.get("is_tracked", false):
				QuestManager.set_tracked("")
			else:
				QuestManager.set_tracked(quest_id)
		)
		actions.add_child(track)
		# No ABANDON button: the server exposes no abandon verb (see
		# QUEST_PROTOCOL.md). Quests progress accept → complete; there is no
		# drop. QuestManager.abandon() is a no-op kept only for API stability.


func _section_header(text: String, accent: Color) -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var hdr = Label.new()
	hdr.text = text
	hdr.add_theme_font_override("font", Styler.JANDA_FONT)
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", accent.lightened(0.1))
	v.add_child(hdr)
	var rule = ColorRect.new()
	rule.color = Color(accent, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	v.add_child(rule)
	return v


func _reward_cell(r: Dictionary) -> Control:
	var cell = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.3)
	sb.set_corner_radius_all(4)
	sb.border_color = Color(Styler.COL_PRIMARY, 0.3)
	sb.set_border_width_all(1)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var col: Color = Styler.COL_PRIMARY
	if r.get("type", "") == "item":
		col = Styler.QUALITY_COLORS.get(int(r.get("quality", 1)), Styler.COL_PRIMARY)
		sb.border_color = col
	cell.add_theme_stylebox_override("panel", sb)
	var lbl = Label.new()
	var ic: String = String(r.get("icon", ""))
	var text: String
	match r.get("type", ""):
		"xp":
			if String(r.get("kind", "")) == "profession":
				text = "%s  %s +%d XP" % [ic, String(r.get("profession", "")).capitalize(), int(r.get("value", 0))]
			else:
				text = "%s  %d XP" % [ic, int(r.get("value", 0))]
		"gold": text = "%s  %dg" % [ic, int(r.get("value", 0))]
		"item": text = "%s  %s" % [ic, String(r.get("name", ""))]
		"title": text = "%s  %s" % [ic, String(r.get("name", ""))]
		_: text = String(r.get("name", ""))
	lbl.text = text
	lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", col)
	cell.add_child(lbl)
	return cell


func _style_action(btn: Button, accent: Color, embossed: bool) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color.WHITE if embossed else accent)
	btn.add_theme_color_override("font_hover_color", Color.WHITE if embossed else accent.lightened(0.2))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	btn.add_theme_constant_override("outline_size", 2)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		if embossed:
			sb.bg_color = accent
			sb.border_color = accent.lightened(0.25)
			sb.border_width_bottom = 2
			sb.border_width_top = 1
			sb.border_width_left = 1
			sb.border_width_right = 1
			sb.shadow_color = Color(accent, 0.5)
			sb.shadow_size = 12
		else:
			sb.bg_color = Color(accent, 0.15)
			sb.border_color = Color(accent, 0.55)
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		if state_name == "hover":
			sb.shadow_size = (sb.shadow_size if embossed else 0) + 6
		btn.add_theme_stylebox_override(state_name, sb)


func _eyebrow_text() -> String:
	var typ: String = _q.get("type", "")
	var tier: int = int(_q.get("tier", 0))
	match typ:
		"story": return "⭐ CHAPTER · STORY"
		"slay": return "⚔ SLAY · TIER %d" % tier
		"gather": return "🌿 GATHER · TIER %d" % tier
		"craft": return "🛠 CRAFT · TIER %d" % tier
		"explore": return "🗺 EXPLORE · TIER %d" % tier
		"delivery": return "📦 DELIVERY"
	return typ.to_upper()
