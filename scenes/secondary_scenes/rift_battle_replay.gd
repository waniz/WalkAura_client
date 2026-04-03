extends Control

var fight_meta: Dictionary = {}
var fight_log: Array = []

# ── Internal state ───────────────────────────────────────────────────────────
var _replay_index: int = 0
var _timer: Timer = null
var _is_paused: bool = false
var _speed_index: int = 0

const _SPEEDS: Array = [0.15, 0.08, 0.04]
const _SPEED_LABELS: Array = ["1x", "2x", "4x"]

# ── UI refs ──────────────────────────────────────────────────────────────────
var _player_hp_bar: ProgressBar = null
var _player_hp_lbl: Label = null
var _player_shield_bar: ProgressBar = null
var _monster_hp_bar: ProgressBar = null
var _monster_hp_lbl: Label = null
var _event_rtl: RichTextLabel = null
var _scroll: ScrollContainer = null
var _tick_lbl: Label = null
var _play_btn: Button = null
var _restart_btn: Button = null
var _speed_btn: Button = null
var _result_lbl: Label = null


func _ready() -> void:
	_build_ui()
	_start_replay()


func _build_ui() -> void:
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = MOUSE_FILTER_STOP

	# Dark backdrop
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Inset panel with parchment style
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

	# ── Header ───────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title = Label.new()
	title.text = "BATTLE REPLAY"
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

	# ── Arena: player | events | monster ─────────────────────────────────────
	var arena = HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 8)
	root_vbox.add_child(arena)

	# Player panel (30%)
	var player_panel = VBoxContainer.new()
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_panel.size_flags_stretch_ratio = 0.3
	player_panel.add_theme_constant_override("separation", 4)
	arena.add_child(player_panel)

	var player_title = Label.new()
	player_title.text = "Player"
	Styler.style_parchment_label(player_title, Styler.COLOR_TEXT_DARK)
	player_title.add_theme_font_size_override("font_size", 14)
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(player_title)

	_player_hp_bar = _make_progress_bar(Color.from_rgba8(80, 200, 100))
	player_panel.add_child(_player_hp_bar)

	_player_hp_lbl = Label.new()
	_player_hp_lbl.text = "HP: —"
	Styler.style_parchment_label(_player_hp_lbl, Color.from_rgba8(80, 200, 100))
	_player_hp_lbl.add_theme_font_size_override("font_size", 11)
	_player_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(_player_hp_lbl)

	_player_shield_bar = _make_progress_bar(Color.from_rgba8(80, 200, 220))
	player_panel.add_child(_player_shield_bar)

	var shield_lbl = Label.new()
	shield_lbl.text = "Shield"
	Styler.style_parchment_label(shield_lbl, Color.from_rgba8(80, 200, 220))
	shield_lbl.add_theme_font_size_override("font_size", 10)
	shield_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(shield_lbl)

	# Event feed (40%)
	var feed_vbox = VBoxContainer.new()
	feed_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_vbox.size_flags_stretch_ratio = 0.4
	feed_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_child(feed_vbox)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	feed_vbox.add_child(_scroll)

	_event_rtl = RichTextLabel.new()
	_event_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_rtl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_event_rtl.bbcode_enabled = true
	_event_rtl.fit_content    = true
	_event_rtl.scroll_active  = false
	_scroll.add_child(_event_rtl)

	# Monster panel (30%)
	var monster_panel = VBoxContainer.new()
	monster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	monster_panel.size_flags_stretch_ratio = 0.3
	monster_panel.add_theme_constant_override("separation", 4)
	arena.add_child(monster_panel)

	var monster_name: String = str(fight_meta.get("monster_id", "Monster")).replace("_", " ").capitalize()
	var monster_title = Label.new()
	monster_title.text = monster_name
	Styler.style_parchment_label(monster_title, Styler.COLOR_TEXT_DARK)
	monster_title.add_theme_font_size_override("font_size", 14)
	monster_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monster_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	monster_panel.add_child(monster_title)

	_monster_hp_bar = _make_progress_bar(Color.from_rgba8(210, 70, 70))
	monster_panel.add_child(_monster_hp_bar)

	_monster_hp_lbl = Label.new()
	_monster_hp_lbl.text = "HP: —"
	Styler.style_parchment_label(_monster_hp_lbl, Color.from_rgba8(210, 70, 70))
	_monster_hp_lbl.add_theme_font_size_override("font_size", 11)
	_monster_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monster_panel.add_child(_monster_hp_lbl)

	root_vbox.add_child(HSeparator.new())

	# ── Controls ──────────────────────────────────────────────────────────────
	var controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root_vbox.add_child(controls)

	_play_btn = Button.new()
	_play_btn.text = "⏸ Pause"
	_play_btn.custom_minimum_size = Vector2(0, 40)
	_play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button_small(_play_btn, Color.from_rgba8(80, 140, 200))
	_play_btn.add_theme_color_override("font_color", Color.WHITE)
	_play_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_play_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	_play_btn.add_theme_font_size_override("font_size", 15)
	_play_btn.pressed.connect(_on_play_pause_pressed)
	controls.add_child(_play_btn)

	_restart_btn = Button.new()
	_restart_btn.text = "⟲ Restart"
	_restart_btn.custom_minimum_size = Vector2(0, 40)
	_restart_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button_small(_restart_btn, Color.from_rgba8(180, 120, 50))
	_restart_btn.add_theme_color_override("font_color", Color.WHITE)
	_restart_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_restart_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	_restart_btn.add_theme_font_size_override("font_size", 15)
	_restart_btn.pressed.connect(_on_restart_pressed)
	controls.add_child(_restart_btn)

	_speed_btn = Button.new()
	_speed_btn.text = "1x"
	_speed_btn.custom_minimum_size = Vector2(0, 40)
	_speed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button_small(_speed_btn, Color.from_rgba8(80, 140, 60))
	_speed_btn.add_theme_color_override("font_color", Color.WHITE)
	_speed_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_speed_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	_speed_btn.add_theme_font_size_override("font_size", 15)
	_speed_btn.pressed.connect(_on_speed_pressed)
	controls.add_child(_speed_btn)

	_tick_lbl = Label.new()
	_tick_lbl.text = "Tick: 0 / %d" % fight_log.size()
	_tick_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_parchment_label(_tick_lbl, Styler.COLOR_TEXT_DARK)
	_tick_lbl.add_theme_font_size_override("font_size", 13)
	controls.add_child(_tick_lbl)

	# ── Result banner (hidden) ────────────────────────────────────────────────
	_result_lbl = Label.new()
	_result_lbl.visible = false
	_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_lbl.add_theme_font_size_override("font_size", 32)
	_result_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	root_vbox.add_child(_result_lbl)


func _make_progress_bar(fill_color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.custom_minimum_size = Vector2(0, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Style the fill
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill_style)
	# Style the background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	bar.add_theme_stylebox_override("background", bg_style)
	return bar


func _start_replay() -> void:
	# Set initial HP values from fight_meta
	var player_hp_max: int = int(fight_meta.get("player_hp_before", 100))
	if player_hp_max <= 0:
		player_hp_max = 100
	_player_hp_bar.max_value = player_hp_max
	_player_hp_bar.value = player_hp_max
	_player_hp_lbl.text = "HP: %d" % player_hp_max

	# Derive monster max HP from first event that has m_hp, or fight_meta
	var monster_hp_max: int = int(fight_meta.get("monster_hp", 0))
	if monster_hp_max <= 0 and not fight_log.is_empty():
		for ev in fight_log:
			var mhp: int = int(ev.get("m_hp", -1))
			if mhp > 0:
				monster_hp_max = mhp
				break
	if monster_hp_max <= 0:
		monster_hp_max = 100
	_monster_hp_bar.max_value = monster_hp_max
	_monster_hp_bar.value = monster_hp_max
	_monster_hp_lbl.text = "HP: %d" % monster_hp_max

	# Shield bar — start at 0 (no shield info before first event)
	_player_shield_bar.max_value = max(1, player_hp_max)
	_player_shield_bar.value = 0

	if fight_log.is_empty():
		_event_rtl.append_text("[color=#969696]No events recorded.[/color]")
		_show_result_banner()
		return

	_timer = Timer.new()
	_timer.wait_time = _SPEEDS[_speed_index]
	_timer.one_shot = false
	_timer.timeout.connect(_on_replay_tick)
	add_child(_timer)
	_timer.start()


func _on_replay_tick() -> void:
	if _replay_index >= fight_log.size():
		_timer.stop()
		_show_result_banner()
		return
	var event: Dictionary = fight_log[_replay_index]
	_process_event(event)
	_replay_index += 1
	var tick_val: int = int(fight_log[_replay_index - 1].get("t", _replay_index))
	_tick_lbl.text = "Tick: %d / %d" % [tick_val, fight_log.size()]


func _process_event(event: Dictionary) -> void:
	var p_hp: int     = int(event.get("p_hp", -1))
	var m_hp: int     = int(event.get("m_hp", -1))
	var p_shield: int = int(event.get("p_shield", 0))

	# Smooth HP bar animation via Tween
	if p_hp >= 0 or m_hp >= 0:
		var tween = create_tween()
		if p_hp >= 0:
			tween.tween_property(_player_hp_bar, "value", float(p_hp), 0.1)
			_player_hp_lbl.text = "HP: %d" % p_hp
		if m_hp >= 0:
			tween.parallel().tween_property(_monster_hp_bar, "value", float(m_hp), 0.1)
			_monster_hp_lbl.text = "HP: %d" % m_hp

	# Shield bar
	_player_shield_bar.value = float(p_shield)

	# Format and append event line
	var line = _format_single_event(event)
	if _replay_index > 0:
		_event_rtl.append_text("\n")
	_event_rtl.append_text(line)

	# Auto-scroll to bottom
	await get_tree().process_frame
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value


func _format_single_event(event: Dictionary) -> String:
	var etype: String  = str(event.get("type", ""))
	var tick: int      = int(event.get("t", 0))
	var actor: String  = str(event.get("actor", "?"))
	var target: String = str(event.get("target", "?"))
	var val: int       = int(event.get("value", 0))
	var absorbed: int  = int(event.get("absorbed", 0))
	var is_crit: bool  = event.get("crit", false)
	var skill: String  = str(event.get("skill", ""))
	var php: int       = int(event.get("p_hp", -1))
	var mhp: int       = int(event.get("m_hp", -1))
	var t_tag: String  = "[color=#aaaaaa][t=%d][/color]" % tick

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


func _show_result_banner() -> void:
	var won: bool = fight_meta.get("result", false)
	_result_lbl.text = "VICTORY" if won else "DEFEAT"
	_result_lbl.add_theme_color_override(
		"font_color",
		Color.from_rgba8(80, 220, 80) if won else Color.from_rgba8(220, 60, 60)
	)
	_result_lbl.visible = true
	# Disable play/pause once replay is done
	if _play_btn:
		_play_btn.disabled = true


func _on_play_pause_pressed() -> void:
	if _timer == null:
		return
	_is_paused = not _is_paused
	_timer.paused = _is_paused
	_play_btn.text = "▶ Play" if _is_paused else "⏸ Pause"


func _on_restart_pressed() -> void:
	# Stop current timer
	if _timer != null:
		_timer.stop()
		_timer.queue_free()
		_timer = null
	# Reset state
	_replay_index = 0
	_is_paused = false
	_speed_index = 0
	_play_btn.text = "⏸ Pause"
	_speed_btn.text = "1x"
	# Clear event log
	_event_rtl.clear()
	# Hide result banner
	if _result_lbl != null:
		_result_lbl.visible = false
	# Restart
	_start_replay()


func _on_speed_pressed() -> void:
	_speed_index = (_speed_index + 1) % _SPEEDS.size()
	_speed_btn.text = _SPEED_LABELS[_speed_index]
	if _timer != null:
		_timer.wait_time = _SPEEDS[_speed_index]
