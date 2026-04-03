extends Control

const BATTLE_REPLAY = preload("res://scenes/secondary_scenes/rift_battle_replay.gd")

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
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Inset panel — same clearance as rift.gd
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
	title.text = "FIGHT LOG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	header.add_child(title)

	var replay_btn = Button.new()
	replay_btn.text = "Watch Replay"
	Styler.style_button_small(replay_btn, Color.from_rgba8(100, 60, 180))
	replay_btn.pressed.connect(func():
		var replay = BATTLE_REPLAY.new()
		replay.fight_meta = fight_meta
		replay.fight_log = fight_log
		add_child(replay)
	)
	header.add_child(replay_btn)

	var close_btn = Button.new()
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
	var result_color    = Color.from_rgba8(100, 220, 100) if result else Color.from_rgba8(220, 80, 80)

	var sub_lbl = Label.new()
	sub_lbl.text = "#%d ⚔ %s — %s  |  HP: %d → %d (%+d)" % [
		m_idx + 1, monster_name,
		"WIN" if result else "LOSS",
		hp_before, hp_after, hp_delta,
	]
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Styler.style_parchment_label(sub_lbl, result_color)
	root_vbox.add_child(sub_lbl)

	# ── Fight summary stats ──────────────────────────────────────────────────
	var summary: Dictionary = fight_meta.get("fight_summary", {})
	if not summary.is_empty():
		var stats_grid = GridContainer.new()
		stats_grid.columns = 4
		stats_grid.add_theme_constant_override("h_separation", 8)
		stats_grid.add_theme_constant_override("v_separation", 2)
		root_vbox.add_child(stats_grid)
		var stat_pairs = [
			["Dmg Dealt", str(int(summary.get("total_damage_dealt", 0)))],
			["Dmg Taken", str(int(summary.get("total_damage_taken", 0)))],
			["Highest Hit", str(int(summary.get("highest_hit", 0)))],
			["Healing", str(int(summary.get("total_healing", 0)))],
			["Crits", str(int(summary.get("crit_count", 0)))],
			["Dodges", str(int(summary.get("dodge_count", 0)))],
			["Ticks", str(int(summary.get("duration_ticks", 0)))],
			["", ""],
		]
		for pair in stat_pairs:
			var key_lbl = Label.new()
			key_lbl.text = pair[0]
			Styler.style_parchment_label(key_lbl, Color.from_rgba8(150, 150, 150))
			key_lbl.add_theme_font_size_override("font_size", 12)
			stats_grid.add_child(key_lbl)
			var val_lbl = Label.new()
			val_lbl.text = pair[1]
			Styler.style_parchment_label(val_lbl, Styler.COLOR_TEXT_DARK)
			val_lbl.add_theme_font_size_override("font_size", 12)
			stats_grid.add_child(val_lbl)

	root_vbox.add_child(HSeparator.new())

	# ── Scrollable fight log with tick-by-tick replay ────────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var rtl = RichTextLabel.new()
	rtl.name = "log_rtl"
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	rtl.bbcode_enabled        = true
	rtl.fit_content           = true
	rtl.scroll_active         = false
	scroll.add_child(rtl)

	if fight_log.is_empty():
		rtl.append_text("[color=#969696]No events recorded.[/color]")
	else:
		# Tick-by-tick replay: add events one at a time with a timer
		_start_tick_replay(rtl)


var _replay_index: int = 0
var _replay_rtl: RichTextLabel = null
var _replay_timer: Timer = null


func _start_tick_replay(rtl: RichTextLabel) -> void:
	_replay_rtl = rtl
	_replay_index = 0
	_replay_timer = Timer.new()
	_replay_timer.wait_time = 0.08
	_replay_timer.timeout.connect(_on_replay_tick)
	add_child(_replay_timer)
	_replay_timer.start()


func _on_replay_tick() -> void:
	if _replay_index >= fight_log.size():
		_replay_timer.stop()
		_replay_timer.queue_free()
		return
	var event = fight_log[_replay_index]
	var line = _format_single_event(event)
	if _replay_index > 0:
		_replay_rtl.append_text("\n")
	_replay_rtl.append_text(line)
	_replay_index += 1


func _format_single_event(event: Dictionary) -> String:
	var etype: String = str(event.get("type", ""))
	var tick: int = int(event.get("t", 0))
	var actor: String = str(event.get("actor", "?"))
	var target: String = str(event.get("target", "?"))
	var val: int = int(event.get("value", 0))
	var absorbed: int = int(event.get("absorbed", 0))
	var is_crit: bool = event.get("crit", false)
	var skill: String = str(event.get("skill", ""))
	var php: int = int(event.get("p_hp", -1))
	var mhp: int = int(event.get("m_hp", -1))
	var t_tag: String = "[color=#aaaaaa][t=%d][/color]" % tick

	match etype:
		"auto":
			var line = "%s [color=#5dde70]⚔ %s → %s:  %d dmg" % [t_tag, actor, target, val]
			if absorbed > 0: line += " [color=#c8a820](+%d abs)[/color]" % absorbed
			if is_crit: line += " [color=#ffdd44][CRIT][/color]"
			return line + "[/color]" + _hp_suffix(php, mhp)
		"skill":
			var line = "%s [color=#5dde70]⚔ %s → %s:  %d dmg" % [t_tag, actor, target, val]
			if not skill.is_empty(): line += "  [color=#aaaaaa](%s)[/color]" % skill
			if is_crit: line += " [color=#ffdd44][CRIT][/color]"
			if absorbed > 0: line += " [color=#c8a820](+%d abs)[/color]" % absorbed
			return line + "[/color]" + _hp_suffix(php, mhp)
		"enemy_auto", "enemy_skill":
			var line = "%s [color=#de5d5d]⚔ %s → %s:  %d dmg" % [t_tag, actor, target, val]
			if not skill.is_empty() and etype == "enemy_skill":
				line += "  [color=#aaaaaa](%s)[/color]" % skill
			if absorbed > 0: line += " [color=#c8a820](+%d abs)[/color]" % absorbed
			if is_crit: line += " [color=#ffdd44][CRIT][/color]"
			return line + "[/color]" + _hp_suffix(php, mhp)
		"heal", "hot":
			var line = "%s [color=#a0de5d]♥ %s healed %d HP" % [t_tag, actor, val]
			if not skill.is_empty(): line += "  [color=#aaaaaa](%s)[/color]" % skill
			if etype == "hot": line += " [color=#ccff88][HOT][/color]"
			return line + "[/color]"
		"leech":
			return "%s [color=#b42828]♥ %s leeched %d HP[/color]" % [t_tag, actor, val]
		"buff":
			return "%s [color=#cc88ff]✨ %s activates:  %s[/color]" % [t_tag, actor, skill]
		"cast_start":
			return "%s [color=#aaaaaa]⏳ %s begins casting:  %s[/color]" % [t_tag, actor, skill]
		"dodge":
			return "%s [color=#88ccff]↩ %s dodged![/color]" % [t_tag, actor]
		"miss":
			var line = "%s [color=#888888]✗ %s missed!" % [t_tag, actor]
			if not skill.is_empty(): line += "  (%s)" % skill
			return line + "[/color]"
		"death":
			return "%s [b][color=#ff4444]☠ %s has fallen![/color][/b]" % [t_tag, target]
		_:
			return "%s [color=#888888]%s: %s[/color]" % [t_tag, etype, str(val)]


func _hp_suffix(php: int, mhp: int) -> String:
	if php < 0 and mhp < 0:
		return ""
	var parts: Array = []
	if php >= 0:
		parts.append("P:%d" % php)
	if mhp >= 0:
		parts.append("M:%d" % mhp)
	return "  [color=#888888]%s[/color]" % "  ".join(parts)
