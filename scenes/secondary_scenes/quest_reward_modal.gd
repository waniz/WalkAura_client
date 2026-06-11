extends Control

# Quest-complete reward modal. Set `quest_uid` + `rewards` (the server
# rewards_granted list, server shape) before add_child(). Shown by
# app_scenes_handler on SignalManager.signal_QuestTurnedIn (return-to-NPC
# turn-ins) and signal_QuestCompletedToast (auto_with_toast quests).

var quest_uid: String = ""
var rewards: Array = []


func _ready() -> void:
	anchor_left = 0; anchor_top = 0
	anchor_right = 1; anchor_bottom = 1
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()


func _quest_title() -> String:
	# Best-effort: the quest may still be in the cache (now status "done").
	for q in QuestManager.quests:
		if String(q.get("id", "")) == quest_uid:
			var nm = String(q.get("name", ""))
			if nm != "":
				return nm
	return quest_uid


func _build_ui() -> void:
	var accent: Color = Styler.COL_PRIMARY

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			queue_free()
	)
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(16, 18, 24, 248)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(accent, 0.5)
	sb.shadow_size = 20
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var banner = Label.new()
	banner.text = "✦ QUEST COMPLETE ✦"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", Styler.JANDA_FONT)
	banner.add_theme_font_size_override("font_size", 22)
	banner.add_theme_color_override("font_color", accent)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	banner.add_theme_constant_override("outline_size", 2)
	vb.add_child(banner)

	var title_lbl = Label.new()
	title_lbl.text = _quest_title()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 212, 192))
	vb.add_child(title_lbl)

	var rule = ColorRect.new()
	rule.color = Color(accent, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	vb.add_child(rule)

	var rew_hdr = Label.new()
	rew_hdr.text = "REWARDS"
	rew_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew_hdr.add_theme_font_override("font", Styler.JANDA_FONT)
	rew_hdr.add_theme_font_size_override("font_size", 12)
	rew_hdr.add_theme_color_override("font_color", accent.lightened(0.1))
	vb.add_child(rew_hdr)

	var any_shown = false
	for r in rewards:
		if typeof(r) != TYPE_DICTIONARY:
			continue
		var cell = _reward_cell(r)
		if cell != null:
			vb.add_child(cell)
			any_shown = true
	if not any_shown:
		var none = Label.new()
		none.text = "—"
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.add_theme_color_override("font_color", Color(accent, 0.5))
		vb.add_child(none)

	var claim = Button.new()
	claim.text = "CLAIM"
	claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim.custom_minimum_size = Vector2(0, 48)
	claim.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	claim.add_theme_font_override("font", Styler.JANDA_FONT)
	claim.add_theme_font_size_override("font_size", 15)
	claim.add_theme_color_override("font_color", Color.WHITE)
	claim.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	claim.add_theme_constant_override("outline_size", 2)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var b_sb = StyleBoxFlat.new()
		b_sb.bg_color = accent
		b_sb.border_color = accent.lightened(0.25)
		b_sb.border_width_bottom = 2
		b_sb.border_width_top = 1
		b_sb.border_width_left = 1
		b_sb.border_width_right = 1
		b_sb.set_corner_radius_all(5)
		b_sb.shadow_color = Color(accent, 0.5)
		b_sb.shadow_size = 12 if state_name != "hover" else 18
		claim.add_theme_stylebox_override(state_name, b_sb)
	claim.pressed.connect(queue_free)
	vb.add_child(claim)


func _reward_cell(r: Dictionary):
	# Renders one server-shape reward. Returns null for non-player-facing types.
	var rtype: String = String(r.get("type", ""))
	var text: String = ""
	var col: Color = Styler.COL_PRIMARY
	match rtype:
		"gold":
			text = "⛁  %d gold" % int(r.get("amount", 0))
		"xp":
			# Profession xp carries kind/profession; account xp does not.
			if String(r.get("kind", "")) == "profession":
				text = "⦿  %s +%d XP" % [String(r.get("profession", "")).capitalize(), int(r.get("amount", 0))]
			else:
				text = "⦿  %d XP" % int(r.get("amount", 0))
		"item":
			text = "◆  %s ×%d" % [String(r.get("item_uid", "")), int(r.get("qty", 1))]
			col = Styler.COL_PRIMARY
		"title":
			text = "✦  %s" % ServerParams.title_name(r.get("title_id", 0))
		"world_state_flag":
			return null
		_:
			text = String(rtype)

	var cell = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.3)
	sb.set_corner_radius_all(4)
	sb.border_color = Color(col, 0.4)
	sb.set_border_width_all(1)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	cell.add_theme_stylebox_override("panel", sb)
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", col)
	cell.add_child(lbl)
	return cell
