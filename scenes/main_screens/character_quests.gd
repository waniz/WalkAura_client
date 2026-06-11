extends Control

# Quest screen — P3 client boilerplate. Data from QuestManager autoload until
# server quest_agent ships. Mockup: design-mockups/quests.html.

const QUEST_DETAIL = preload("res://scenes/secondary_scenes/quest_detail.gd")

@onready var _list_vbox: VBoxContainer = null
var _active_filter: String = "active"   # active / available / daily / done
var _filter_chips: Dictionary = {}      # filter_name -> Button
var _scroll: ScrollContainer = null


func _ready() -> void:
	_build_ui()
	QuestManager.signal_QuestsUpdated.connect(_refresh)
	QuestManager.signal_AvailableQuestsUpdated.connect(_refresh)
	# Pull the offers for wherever the player currently stands so the Available
	# tab is populated the moment they open it.
	QuestManager.request_available_quests(int(Account.location))
	_refresh()


func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = Styler.content_top
	root.offset_bottom = Styler.content_bottom
	root.offset_left = 8
	root.offset_right = -8
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	# Filter chip row.
	var chips = HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(chips)

	for f in [["active", "Active"], ["available", "Available"], ["daily", "Daily"], ["done", "Done"]]:
		var btn = Button.new()
		btn.text = f[1]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		var f_id: String = f[0]
		_style_chip(btn, f_id == _active_filter)
		btn.pressed.connect(func(): _on_filter(f_id))
		chips.add_child(btn)
		_filter_chips[f_id] = btn

	# Scrollable list.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list_vbox)


func _on_filter(filter_id: String) -> void:
	_active_filter = filter_id
	for k in _filter_chips.keys():
		_style_chip(_filter_chips[k], k == filter_id)
	# Refresh offers from the server each time the player opens the Available tab.
	if filter_id == "available":
		QuestManager.request_available_quests(int(Account.location))
	_refresh()


func _refresh() -> void:
	if _list_vbox == null:
		return
	for c in _list_vbox.get_children():
		c.queue_free()

	# Available tab renders NPC offer frames, not flat quest cards.
	if _active_filter == "available":
		_refresh_available()
		return

	var matching: Array = []
	for q in QuestManager.quests:
		if q.get("status", "") == _active_filter:
			matching.append(q)

	if matching.is_empty():
		var empty = Label.new()
		match _active_filter:
			"active":
				empty.text = "No active quests.\nVisit a quest giver to pick one up."
			"available":
				empty.text = "No quests available.\nExplore new locations to find more."
			"daily":
				empty.text = "No daily quests right now.\nCheck back after reset."
			_:
				empty.text = "No completed quests yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_override("font", Styler.QUADRAT_FONT)
		empty.add_theme_font_size_override("font_size", 17)
		empty.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.55))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list_vbox.add_child(empty)
		return

	for q in matching:
		_list_vbox.add_child(_build_quest_card(q))


func _style_chip(btn: Button, active: bool) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Styler.COL_PRIMARY if active else Color(Styler.COL_PRIMARY, 0.45))
	btn.add_theme_color_override("font_hover_color", Styler.COL_PRIMARY)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		if active:
			sb.bg_color = Color(Styler.COL_PRIMARY, 0.18)
			sb.border_color = Styler.COL_PRIMARY
			sb.set_border_width_all(1)
			sb.shadow_color = Styler.COL_GOLD_GLOW
			sb.shadow_size = 6
		else:
			sb.bg_color = Color.from_rgba8(20, 22, 30, 220)
			sb.border_color = Color(Styler.COL_PRIMARY, 0.2)
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		btn.add_theme_stylebox_override(state_name, sb)


# Compact quest card — head, progress, rewards strip, meta footer.
func _build_quest_card(q: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var tier: int = int(q.get("tier", 0))
	var is_story: bool = q.get("type", "") == "story"
	var is_ready: bool = q.get("is_ready_to_turn_in", false)
	var accent: Color = Styler.COL_PRIMARY if is_story else Styler.get_tier_color(tier)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(24, 26, 34, 245)
	sb.border_color = Color(accent, 0.5)
	sb.set_border_width_all(0)
	sb.border_width_left = 3
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if is_ready:
		sb.border_color = Styler.COL_PRIMARY
		sb.set_border_width_all(2)
		sb.border_width_left = 3
		sb.shadow_color = Styler.COL_GOLD_GLOW
		sb.shadow_size = 12
	else:
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 4
	card.add_theme_stylebox_override("panel", sb)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	# Head row: type/tier eyebrow + name + level.
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)

	var title_block = VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 2)
	head.add_child(title_block)

	var eyebrow = Label.new()
	eyebrow.text = _eyebrow_text(q)
	eyebrow.add_theme_font_override("font", Styler.JANDA_FONT)
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", accent)
	title_block.add_child(eyebrow)

	var name_lbl = Label.new()
	name_lbl.text = q.get("name", "")
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", Color.from_rgba8(232, 224, 207))
	title_block.add_child(name_lbl)

	var lvl_lbl = Label.new()
	lvl_lbl.text = "Lvl %d" % int(q.get("level", 0))
	lvl_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	lvl_lbl.add_theme_font_size_override("font_size", 15)
	lvl_lbl.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.7))
	head.add_child(lvl_lbl)

	if is_ready:
		var ready_pill = Label.new()
		ready_pill.text = "  READY  "
		ready_pill.add_theme_font_override("font", Styler.JANDA_FONT)
		ready_pill.add_theme_font_size_override("font_size", 13)
		ready_pill.add_theme_color_override("font_color", Color.from_rgba8(20, 16, 10))
		var pill_sb = StyleBoxFlat.new()
		pill_sb.bg_color = Styler.COL_PRIMARY
		pill_sb.set_corner_radius_all(3)
		var pill_panel = PanelContainer.new()
		pill_panel.add_theme_stylebox_override("panel", pill_sb)
		pill_panel.add_child(ready_pill)
		head.add_child(pill_panel)

	# Objectives — collapsed progress bar if single obj, checklist if multi.
	var objectives: Array = q.get("objectives", [])
	if objectives.size() == 1:
		var obj = objectives[0]
		var prog_row = HBoxContainer.new()
		prog_row.add_theme_constant_override("separation", 8)
		var bar = ProgressBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 6)
		bar.show_percentage = false
		bar.max_value = max(1, int(obj.get("total", 1)))
		bar.value = int(obj.get("count", 0))
		Styler.make_painted_progressbar(bar, accent, accent.darkened(0.45), 3)
		prog_row.add_child(bar)
		var cnt = Label.new()
		cnt.text = "%d / %d" % [int(obj.get("count", 0)), int(obj.get("total", 0))]
		cnt.add_theme_font_override("font", Styler.JANDA_FONT)
		cnt.add_theme_font_size_override("font_size", 14)
		cnt.add_theme_color_override("font_color", accent)
		prog_row.add_child(cnt)
		box.add_child(prog_row)
	else:
		for obj in objectives:
			box.add_child(_make_objective_row(obj))

	# Rewards strip.
	box.add_child(_build_rewards_strip(q.get("rewards", [])))

	# Meta footer.
	var meta = HBoxContainer.new()
	meta.add_theme_constant_override("separation", 6)
	var giver = Label.new()
	giver.text = String(q.get("giver", ""))
	giver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	giver.add_theme_font_override("font", Styler.QUADRAT_FONT)
	giver.add_theme_font_size_override("font_size", 13)
	giver.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.55))
	meta.add_child(giver)
	var loc = Label.new()
	loc.text = String(q.get("turnin_location", ""))
	loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loc.add_theme_font_override("font", Styler.QUADRAT_FONT)
	loc.add_theme_font_size_override("font_size", 13)
	loc.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
	meta.add_child(loc)
	box.add_child(meta)

	# Tap → open detail.
	var q_id: String = String(q.get("id", ""))
	card.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed):
			_open_detail(q_id)
	)
	return card


func _eyebrow_text(q: Dictionary) -> String:
	var typ: String = q.get("type", "")
	var tier: int = int(q.get("tier", 0))
	match typ:
		"story": return "⭐ CHAPTER · STORY"
		"slay": return "⚔ SLAY · TIER %d" % tier
		"gather": return "🌿 GATHER · TIER %d" % tier
		"craft": return "🛠 CRAFT · TIER %d" % tier
		"explore": return "🗺 EXPLORE · TIER %d" % tier
		"delivery": return "📦 DELIVERY"
	return typ.to_upper()


func _make_objective_row(obj: Dictionary) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var done: bool = int(obj.get("count", 0)) >= int(obj.get("total", 1))
	var check = Label.new()
	check.text = "✓" if done else "○"
	check.custom_minimum_size = Vector2(14, 0)
	check.add_theme_color_override("font_color", Styler.COLOR_BTN_SUCCESS if done else Color(1, 1, 1, 0.35))
	row.add_child(check)
	var lbl = Label.new()
	lbl.text = String(obj.get("label", ""))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	lbl.add_theme_font_size_override("font_size", 15)
	if done:
		lbl.add_theme_color_override("font_color", Color(Styler.COLOR_BTN_SUCCESS, 0.7))
	else:
		lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 192, 170))
	row.add_child(lbl)
	var cnt = Label.new()
	cnt.text = "%d / %d" % [int(obj.get("count", 0)), int(obj.get("total", 0))]
	cnt.add_theme_font_override("font", Styler.JANDA_FONT)
	cnt.add_theme_font_size_override("font_size", 14)
	cnt.add_theme_color_override("font_color", Styler.COLOR_BTN_SUCCESS if done else Color(Styler.COL_PRIMARY, 0.7))
	row.add_child(cnt)
	return row


func _build_rewards_strip(rewards: Array) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for r in rewards:
		var chip = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.4)
		sb.set_corner_radius_all(3)
		sb.border_color = Color(Styler.COL_PRIMARY, 0.3)
		sb.set_border_width_all(1)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		# Item-quality colored border.
		if r.get("type", "") == "item":
			var q: int = int(r.get("quality", 1))
			var q_col: Color = Styler.QUALITY_COLORS.get(q, Styler.COL_PRIMARY)
			sb.border_color = q_col
		chip.add_theme_stylebox_override("panel", sb)
		var lbl = Label.new()
		var ic: String = String(r.get("icon", ""))
		var text: String
		match r.get("type", ""):
			"xp":
				if String(r.get("kind", "")) == "profession":
					text = "%s %s +%d XP" % [ic, String(r.get("profession", "")).capitalize(), int(r.get("value", 0))]
				else:
					text = "%s %d XP" % [ic, int(r.get("value", 0))]
			"gold": text = "%s %dg" % [ic, int(r.get("value", 0))]
			"item": text = "%s %s" % [ic, String(r.get("name", ""))]
			"title": text = "%s %s" % [ic, String(r.get("name", ""))]
			_: text = String(r.get("name", ""))
		lbl.text = text
		lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		lbl.add_theme_font_size_override("font_size", 13)
		var col: Color = Styler.COL_PRIMARY
		if r.get("type", "") == "item":
			col = Styler.QUALITY_COLORS.get(int(r.get("quality", 1)), Styler.COL_PRIMARY)
		lbl.add_theme_color_override("font_color", col)
		chip.add_child(lbl)
		row.add_child(chip)
	return row


func _open_detail(quest_id: String) -> void:
	var overlay = QUEST_DETAIL.new()
	overlay.quest_id = quest_id
	add_child(overlay)


# ── Available tab — NPC offer frames (see DESIGN.md "Quest Available Tab") ────

func _refresh_available() -> void:
	var npcs: Array = QuestManager.available_npcs
	if npcs.is_empty():
		var empty = Label.new()
		empty.text = "No quest givers here.\nExplore to find more."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_override("font", Styler.QUADRAT_FONT)
		empty.add_theme_font_size_override("font_size", 17)
		empty.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.55))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list_vbox.add_child(empty)
		return
	for npc in npcs:
		_list_vbox.add_child(_build_npc_frame(npc))


func _build_npc_frame(npc: Dictionary) -> Control:
	var frame = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(24, 26, 34, 245)
	sb.border_color = Color(Styler.COL_PRIMARY, 0.22)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	frame.add_theme_stylebox_override("panel", sb)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)

	# Header: face + name block.
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	header.add_child(_make_face(String(npc.get("npc_uid", ""))))

	var name_block = VBoxContainer.new()
	name_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_block.add_theme_constant_override("separation", 2)
	header.add_child(name_block)

	var eyebrow = Label.new()
	eyebrow.text = "QUEST GIVER"
	eyebrow.add_theme_font_override("font", Styler.JANDA_FONT)
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Color(0.55, 0.5, 0.4))
	name_block.add_child(eyebrow)

	var name_lbl = Label.new()
	name_lbl.text = String(npc.get("name", ""))
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	name_block.add_child(name_lbl)

	# Gold hairline under the header.
	var rule = Panel.new()
	rule.custom_minimum_size = Vector2(0, 1)
	var rule_sb = StyleBoxFlat.new()
	rule_sb.bg_color = Color(Styler.COL_PRIMARY, 0.35)
	rule.add_theme_stylebox_override("panel", rule_sb)
	box.add_child(rule)

	# Offered-quest rows.
	var quests: Array = npc.get("quests", [])
	for i in quests.size():
		box.add_child(_make_offer_row(quests[i]))
		if i < quests.size() - 1:
			var div = Panel.new()
			div.custom_minimum_size = Vector2(0, 1)
			var div_sb = StyleBoxFlat.new()
			div_sb.bg_color = Color(1, 1, 1, 0.06)
			div.add_theme_stylebox_override("panel", div_sb)
			box.add_child(div)
	return frame


func _make_face(npc_uid: String) -> Control:
	# 48x48 dark-chrome circle frame holding the codex SVG face (emoji fallback).
	var holder = PanelContainer.new()
	holder.custom_minimum_size = Vector2(48, 48)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb = StyleBoxFlat.new()
	sb.bg_color = Styler.COLOR_PANEL_DARK
	sb.border_color = Styler.COL_PRIMARY
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(24)
	sb.shadow_color = Styler.COL_GOLD_GLOW
	sb.shadow_size = 6
	holder.add_theme_stylebox_override("panel", sb)

	var short: String = npc_uid.trim_prefix("npc_")
	var path: String = "res://assets/npcs/%s.svg" % short
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex != null:
			var tr = TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(44, 44)
			holder.add_child(tr)
			return holder
	# Fallback glyph.
	var glyph = Label.new()
	glyph.text = "🧙"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 30)
	holder.add_child(glyph)
	return holder


func _make_offer_row(q: Dictionary) -> Control:
	var typ: String = q.get("type", "story")
	var accent: Color = _offer_accent(typ)

	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)

	# Head: icon + title + level.
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)

	var icon = Label.new()
	icon.text = String(q.get("icon", "•"))
	icon.custom_minimum_size = Vector2(28, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 24)
	head.add_child(icon)

	var title_block = VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 1)
	head.add_child(title_block)

	var eyebrow = Label.new()
	var tag: String = typ.to_upper()
	if q.get("is_daily", false):
		tag = "DAILY · " + tag
	eyebrow.text = tag
	eyebrow.add_theme_font_override("font", Styler.JANDA_FONT)
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", accent)
	title_block.add_child(eyebrow)

	var title = Label.new()
	title.text = String(q.get("title", ""))
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color.from_rgba8(232, 224, 207))
	title_block.add_child(title)

	var lvl = Label.new()
	lvl.text = "Lv.%d" % int(q.get("level", 1))
	lvl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvl.add_theme_font_override("font", Styler.JANDA_FONT)
	lvl.add_theme_font_size_override("font_size", 14)
	lvl.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.7))
	head.add_child(lvl)

	# Description (2-line clamp).
	var desc = Label.new()
	desc.text = String(q.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.max_lines_visible = 2
	desc.add_theme_font_override("font", Styler.QUADRAT_FONT)
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color.from_rgba8(140, 130, 110))
	col.add_child(desc)

	# Rewards + Accept row.
	var foot = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	var rewards = _build_rewards_strip(q.get("rewards", []))
	rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(rewards)

	var quid: String = String(q.get("quest_uid", ""))
	foot.add_child(_make_accept_button(quid))
	col.add_child(foot)
	return col


func _make_accept_button(quest_uid: String) -> Button:
	var btn = Button.new()
	btn.text = "ACCEPT"
	btn.custom_minimum_size = Vector2(96, 32)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color.from_rgba8(20, 16, 10))
	btn.add_theme_color_override("font_hover_color", Color.from_rgba8(20, 16, 10))
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Styler.COL_PRIMARY if state_name != "hover" else Styler.COL_PRIMARY.lightened(0.1)
		sb.set_corner_radius_all(4)
		# Emboss: light top edge, dark bottom edge.
		sb.border_width_top = 1
		sb.border_width_bottom = 2
		sb.border_color = Color(0.35, 0.25, 0.06)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		if state_name == "pressed":
			sb.bg_color = Styler.COL_PRIMARY.darkened(0.12)
		btn.add_theme_stylebox_override(state_name, sb)
	btn.pressed.connect(func(): _on_accept(quest_uid))
	return btn


func _on_accept(quest_uid: String) -> void:
	if quest_uid == "":
		return
	# accept_quest is the authoritative gate; on success the server pushes
	# quest_accepted, QuestManager drops it from available_npcs + refreshes.
	QuestManager.accept_quest(quest_uid)


func _offer_accent(typ: String) -> Color:
	match typ:
		"story": return Styler.COL_PRIMARY
		"slay": return Styler.COL_OFFENSE
		_: return Styler.COLOR_BTN_SUCCESS
