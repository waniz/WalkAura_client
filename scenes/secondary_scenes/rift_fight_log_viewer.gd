extends Control

var fight_meta: Dictionary = {}
var fight_log: Array = []


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
	Styler._apply_parchment_style(panel)
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
	title.text = "FIGHT LOG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(44, 44)
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# ── Sub-header: fight summary ────────────────────────────────────────────
	var m_idx: int      = int(fight_meta.get("milestone_index", 0))
	var monster_name: String = str(fight_meta.get("monster_id", "unknown")).replace("_", " ").capitalize()
	var result: bool    = fight_meta.get("result", false)
	var hp_before: int  = int(fight_meta.get("player_hp_before", 0))
	var hp_after: int   = int(fight_meta.get("player_hp_after", 0))
	var hp_delta: int   = hp_after - hp_before
	var result_color    := Color.from_rgba8(100, 220, 100) if result else Color.from_rgba8(220, 80, 80)

	var sub_lbl := Label.new()
	sub_lbl.text = "#%d ⚔ %s — %s  |  HP: %d → %d (%+d)" % [
		m_idx + 1, monster_name,
		"WIN" if result else "LOSS",
		hp_before, hp_after, hp_delta,
	]
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styler.style_name_label(sub_lbl, result_color)
	root_vbox.add_child(sub_lbl)

	root_vbox.add_child(HSeparator.new())

	# ── Scrollable fight log ─────────────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var rtl := RichTextLabel.new()
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	rtl.bbcode_enabled        = true
	rtl.fit_content           = true
	rtl.scroll_active         = false
	scroll.add_child(rtl)

	if fight_log.is_empty():
		rtl.append_text("[color=#969696]No events recorded.[/color]")
	else:
		rtl.append_text(_build_log_bbcode())


func _build_log_bbcode() -> String:
	var lines: PackedStringArray = []

	for event in fight_log:
		var etype: String = str(event.get("type", ""))
		var tick: int     = int(event.get("t", 0))
		var actor: String = str(event.get("actor", "?"))
		var target: String = str(event.get("target", "?"))
		var val: int      = int(event.get("value", 0))
		var absorbed: int = int(event.get("absorbed", 0))
		var is_crit: bool = event.get("crit", false)
		var skill: String = str(event.get("skill", ""))
		var php: int      = int(event.get("p_hp", -1))
		var mhp: int      = int(event.get("m_hp", -1))

		var t_tag: String = "[color=#aaaaaa][t=%d][/color]" % tick

		match etype:
			"auto":
				var line := "%s [color=#5dde70]⚔ %s → %s:  %d dmg" % [t_tag, actor, target, val]
				if absorbed > 0:
					line += " [color=#c8a820](+%d absorbed)[/color]" % absorbed
				if is_crit:
					line += " [color=#ffdd44][CRIT][/color]"
				line += "[/color]"
				line += _hp_suffix(php, mhp)
				lines.append(line)

			"skill":
				var line := "%s [color=#5dde70]⚔ %s → %s:  %d dmg" % [t_tag, actor, target, val]
				if not skill.is_empty():
					line += "  [color=#aaaaaa](%s)[/color]" % skill
				if is_crit:
					line += " [color=#ffdd44][CRIT][/color]"
				if absorbed > 0:
					line += " [color=#c8a820](+%d absorbed)[/color]" % absorbed
				line += "[/color]"
				line += _hp_suffix(php, mhp)
				lines.append(line)

			"enemy_auto", "enemy_skill":
				var line := "%s [color=#de5d5d]⚔ %s → %s:  %d dmg" % [t_tag, actor, target, val]
				if not skill.is_empty() and etype == "enemy_skill":
					line += "  [color=#aaaaaa](%s)[/color]" % skill
				if absorbed > 0:
					line += " [color=#c8a820](+%d absorbed)[/color]" % absorbed
				if is_crit:
					line += " [color=#ffdd44][CRIT][/color]"
				line += "[/color]"
				line += _hp_suffix(php, mhp)
				lines.append(line)

			"heal":
				var line := "%s [color=#a0de5d]♥ %s healed %d HP" % [t_tag, actor, val]
				if not skill.is_empty():
					line += "  [color=#aaaaaa](%s)[/color]" % skill
				line += "[/color]"
				if php >= 0:
					line += "  [color=#888888]P:%d[/color]" % php
				lines.append(line)

			"hot":
				var line := "%s [color=#a0de5d]♥ %s healed %d HP" % [t_tag, actor, val]
				if not skill.is_empty():
					line += "  [color=#aaaaaa](%s)[/color]" % skill
				line += " [color=#ccff88][HOT][/color][/color]"
				if php >= 0:
					line += "  [color=#888888]P:%d[/color]" % php
				lines.append(line)

			"buff":
				var line := "%s [color=#cc88ff]✨ %s activates:  %s[/color]" % [t_tag, actor, skill]
				if php >= 0:
					line += "  [color=#888888]P:%d[/color]" % php
				lines.append(line)

			"cast_start":
				lines.append("%s [color=#aaaaaa]⏳ %s begins casting:  %s[/color]" % [t_tag, actor, skill])

			"dodge":
				lines.append("%s [color=#88ccff]↩ %s dodged![/color]" % [t_tag, actor])

			"miss":
				var line := "%s [color=#888888]✗ %s missed!" % [t_tag, actor]
				if not skill.is_empty():
					line += "  (%s)" % skill
				line += "[/color]"
				lines.append(line)

			"death":
				lines.append("%s [b][color=#ff4444]☠ %s has fallen![/color][/b]" % [t_tag, target])

			_:
				# Fallback: show raw type and any value
				lines.append("%s [color=#888888]%s: %s[/color]" % [t_tag, etype, str(event)])

	return "\n".join(lines)


func _hp_suffix(php: int, mhp: int) -> String:
	if php < 0 and mhp < 0:
		return ""
	var parts: Array = []
	if php >= 0:
		parts.append("P:%d" % php)
	if mhp >= 0:
		parts.append("M:%d" % mhp)
	return "  [color=#888888]%s[/color]" % "  ".join(parts)
