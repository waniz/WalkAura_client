extends Control

## Active rift screen (AAA dark panel style).
## Shows progress with node path, encounter card for pending fights,
## completed encounter results, and pause/exit controls.

const BATTLE_VIS    = preload("res://scenes/secondary_scenes/rift_battle_visualization.gd")
const FIGHT_LOG_VIS = preload("res://scenes/secondary_scenes/rift_fight_log_viewer.gd")
const COMPLETION_SCREEN = preload("res://scenes/secondary_scenes/rift_completion_screen.gd")
const NODE_PATH_IND = preload("res://scenes/components/node_path_indicator.gd")

var _rift_name_label: Label
var _rift_lvl_label: Label
var _progress_bar: ProgressBar
var _steps_label: Label
var _node_path_container: HBoxContainer
var _encounter_card: PanelContainer
var _encounter_card_vbox: VBoxContainer
var _fight_list: VBoxContainer
var _battle_log_btn: Button
var _cached_fights: Array = []
var _battle_log_overlay: Control = null
var _pending_fight_request: Dictionary = {}
var _last_rift_instance_id: String = ""
var _cached_pending_monster: Dictionary = {}
var _pause_btn: Button
var _exit_btn: Button
var _resume_btn: Button
var _tier_color: Color = Color.WHITE
var _rift_died: bool = false


func _ready() -> void:
	_build_ui()
	AccountManager.signal_AccountDataReceived.connect(_on_account_data)
	AccountManager.signal_RiftFightsReceived.connect(_on_rift_fights_received)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)
	# Restore pending monster info that arrived before this scene was created
	if AccountManager.cached_rift_pending_monster and not AccountManager.cached_rift_pending_monster.is_empty():
		_cached_pending_monster = AccountManager.cached_rift_pending_monster
	_refresh()


func _build_ui() -> void:
	anchor_left = 0.0; anchor_top = 0.0
	anchor_right = 1.0; anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Get tier color from rift data
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	var cfg = RiftData.RIFT_TABLE.get(rift_id, {})
	var tier = int(cfg.get("tier", 0))
	_tier_color = RiftData.TIER_COLORS.get(tier, Color.WHITE)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_dark_panel_style(panel, _tier_color)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	# --- Header ---
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	_rift_name_label = Label.new()
	_rift_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rift_name_label.add_theme_font_size_override("font_size", 22)
	_rift_name_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_rift_name_label.add_theme_color_override("font_color", _tier_color)
	header.add_child(_rift_name_label)

	var close_btn = Button.new()
	close_btn.text = "X"
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	# --- Rift banner image ---
	if ItemDB.has_rift_icon(rift_id):
		var banner_clip = Control.new()
		banner_clip.custom_minimum_size = Vector2(0, 300)
		banner_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banner_clip.clip_contents = true
		root_vbox.add_child(banner_clip)

		var banner = TextureRect.new()
		banner.texture = ItemDB.get_rift_icon(rift_id)
		banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_clip.add_child(banner)

	_rift_lvl_label = Label.new()
	_rift_lvl_label.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
	_rift_lvl_label.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(_rift_lvl_label)

	# --- Progress bar (painted, tier-colored) ---
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 22)
	_progress_bar.show_percentage = false
	Styler.make_painted_progressbar(_progress_bar, _tier_color, _tier_color.darkened(0.45), 6)
	root_vbox.add_child(_progress_bar)

	_steps_label = Label.new()
	_steps_label.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
	_steps_label.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(_steps_label)

	# --- Node path ---
	_node_path_container = HBoxContainer.new()
	_node_path_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_node_path_container)

	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(content_vbox)

	# --- Encounter card (shown when fight is pending) ---
	_encounter_card = PanelContainer.new()
	_encounter_card.visible = false
	var ec_sb = StyleBoxFlat.new()
	ec_sb.bg_color = Color(1, 1, 1, 0.04)
	ec_sb.border_color = Color.from_rgba8(200, 50, 50, 200)
	ec_sb.border_width_left = 2
	ec_sb.border_width_right = 2
	ec_sb.border_width_top = 2
	ec_sb.border_width_bottom = 2
	ec_sb.set_corner_radius_all(8)
	ec_sb.content_margin_left = 12
	ec_sb.content_margin_right = 12
	ec_sb.content_margin_top = 10
	ec_sb.content_margin_bottom = 10
	_encounter_card.add_theme_stylebox_override("panel", ec_sb)
	content_vbox.add_child(_encounter_card)

	_encounter_card_vbox = VBoxContainer.new()
	_encounter_card_vbox.add_theme_constant_override("separation", 6)
	_encounter_card.add_child(_encounter_card_vbox)

	# --- Fight history ---
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(1, 1, 1, 0.08))
	content_vbox.add_child(sep)

	var fight_header_row = HBoxContainer.new()
	fight_header_row.add_theme_constant_override("separation", 10)
	content_vbox.add_child(fight_header_row)

	var fight_title = Label.new()
	fight_title.text = "Fight History"
	fight_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fight_title.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
	fight_title.add_theme_font_size_override("font_size", 14)
	fight_header_row.add_child(fight_title)

	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh"
	Styler.style_button_small(refresh_btn, Color.from_rgba8(40, 60, 100))
	refresh_btn.add_theme_color_override("font_color", Color.from_rgba8(150, 180, 220))
	refresh_btn.pressed.connect(_on_refresh_fights_pressed)
	fight_header_row.add_child(refresh_btn)

	_battle_log_btn = Button.new()
	_battle_log_btn.text = "Battle Log"
	_battle_log_btn.disabled = true
	Styler.style_button_small(_battle_log_btn, Color.from_rgba8(60, 40, 100))
	_battle_log_btn.add_theme_color_override("font_color", Color.from_rgba8(160, 140, 220))
	_battle_log_btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	_battle_log_btn.pressed.connect(_on_battle_log_pressed)
	fight_header_row.add_child(_battle_log_btn)

	var fight_scroll = ScrollContainer.new()
	fight_scroll.custom_minimum_size = Vector2(0, 120)
	fight_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_vbox.add_child(fight_scroll)

	_fight_list = VBoxContainer.new()
	_fight_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_list.add_theme_constant_override("separation", 4)
	fight_scroll.add_child(_fight_list)

	# --- Action buttons ---
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(action_row)

	_resume_btn = Button.new()
	_resume_btn.text = "RESUME"
	_resume_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(_resume_btn, Color.from_rgba8(40, 100, 50))
	_resume_btn.add_theme_color_override("font_color", Color.WHITE)
	_resume_btn.pressed.connect(_on_resume_pressed)
	_resume_btn.visible = false
	action_row.add_child(_resume_btn)

	_pause_btn = Button.new()
	_pause_btn.text = "PAUSE"
	_pause_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(_pause_btn, Color.from_rgba8(140, 100, 30))
	_pause_btn.add_theme_color_override("font_color", Color.WHITE)
	_pause_btn.pressed.connect(_on_pause_pressed)
	action_row.add_child(_pause_btn)

	_exit_btn = Button.new()
	_exit_btn.text = "EXIT RIFT"
	_exit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(_exit_btn, Color.from_rgba8(140, 40, 40))
	_exit_btn.add_theme_color_override("font_color", Color.WHITE)
	_exit_btn.pressed.connect(_on_stop_pressed)
	action_row.add_child(_exit_btn)


func _refresh() -> void:
	if _rift_died:
		return
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	if rift_id == 0:
		return

	var current_instance_id = str(Account.rift_instance_id) if Account.rift_instance_id != null else ""
	if current_instance_id != _last_rift_instance_id:
		_last_rift_instance_id = current_instance_id
		_cached_fights = []
		_battle_log_btn.disabled = true
		for child in _fight_list.get_children():
			child.queue_free()
		_on_refresh_fights_pressed()

	_refresh_active_view()


func _refresh_active_view() -> void:
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	var cfg = RiftData.RIFT_TABLE.get(rift_id, {})
	_rift_name_label.text = cfg.get("name", "Active Rift")

	var rift_lvl = int(Account.rift_lvl) if Account.rift_lvl != null else 1
	_rift_lvl_label.text = "Rift Level: %d" % rift_lvl

	var steps = int(Account.rift_steps) if Account.rift_steps != null else 0
	var max_steps = int(Account.rift_steps_max) if Account.rift_steps_max != null else 1
	var m_idx = int(Account.rift_milestone_index) if Account.rift_milestone_index != null else 0
	var total_m = int(Account.rift_total_milestones) if Account.rift_total_milestones != null else 1

	_progress_bar.max_value = max(1, max_steps)
	_progress_bar.value = steps
	_steps_label.text = "%d / %d steps   ·   Milestone %d / %d" % [steps, max_steps, m_idx, total_m]

	# Node path
	for child in _node_path_container.get_children():
		child.queue_free()
	var node_path = NODE_PATH_IND.new()
	node_path.setup(total_m, m_idx, _tier_color)
	_node_path_container.add_child(node_path)

	# Encounter card
	for child in _encounter_card_vbox.get_children():
		child.queue_free()

	if Account.rift_pending_fight:
		_encounter_card.visible = true
		var enc_title = Label.new()
		var enc_text = "ENCOUNTER #%d" % (m_idx + 1)
		if m_idx == total_m - 1:
			enc_text = "FINAL " + enc_text
		enc_title.text = enc_text
		enc_title.add_theme_font_override("font", Styler.JANDA_FONT)
		enc_title.add_theme_font_size_override("font_size", 18)
		enc_title.add_theme_color_override("font_color", Color.from_rgba8(220, 60, 60))
		_encounter_card_vbox.add_child(enc_title)

		if not _cached_pending_monster.is_empty():
			var monsters = _cached_pending_monster.get("encounter_monsters", [])
			if monsters.size() > 0:
				var count_lbl = Label.new()
				count_lbl.text = "%d enemies:" % monsters.size()
				count_lbl.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
				count_lbl.add_theme_font_size_override("font_size", 13)
				_encounter_card_vbox.add_child(count_lbl)

				for em in monsters:
					var em_row = HBoxContainer.new()
					em_row.add_theme_constant_override("separation", 6)
					em_row.custom_minimum_size.y = 32
					_encounter_card_vbox.add_child(em_row)

					# Monster icon
					var icon_rect = TextureRect.new()
					icon_rect.custom_minimum_size = Vector2(56, 56)
					icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					var em_id = str(em.get("id", ""))
					var icon_tex = ItemDB.get_monster_icon(em_id)
					if icon_tex:
						icon_rect.texture = icon_tex
					em_row.add_child(icon_rect)

					var em_name = Label.new()
					var name_text = str(em.get("name", "???"))
					em_name.text = "%s  Lv%d" % [name_text, int(em.get("level", 1))]
					em_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					em_name.add_theme_color_override("font_color", Color.from_rgba8(220, 210, 200))
					em_name.add_theme_font_size_override("font_size", 13)
					em_row.add_child(em_name)

					var role = em.get("role", "")
					if role != "" and role != null:
						var role_lbl = Label.new()
						role_lbl.text = str(role).to_upper()
						role_lbl.add_theme_font_size_override("font_size", 11)
						var role_color = _get_role_color(str(role))
						role_lbl.add_theme_color_override("font_color", role_color)
						em_row.add_child(role_lbl)

			var rec_gs = int(_cached_pending_monster.get("recommended_gear_score", 0))
			if rec_gs > 0:
				var gs_lbl = Label.new()
				gs_lbl.text = "Gear Score: %d" % rec_gs
				gs_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
				gs_lbl.add_theme_font_size_override("font_size", 13)
				_encounter_card_vbox.add_child(gs_lbl)

			var rec_resists = _cached_pending_monster.get("recommended_resistances", [])
			if rec_resists is Array and rec_resists.size() > 0:
				var resist_parts: Array = []
				for r in rec_resists:
					resist_parts.append(str(r).capitalize())
				var resist_lbl = Label.new()
				resist_lbl.text = "Resist: %s" % ", ".join(resist_parts)
				resist_lbl.add_theme_color_override("font_color", Color.from_rgba8(100, 180, 220))
				resist_lbl.add_theme_font_size_override("font_size", 13)
				_encounter_card_vbox.add_child(resist_lbl)

		var fight_btn = Button.new()
		fight_btn.text = "⚔  FIGHT NOW"
		fight_btn.custom_minimum_size = Vector2(0, 52)
		fight_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_red_emboss_button(fight_btn)
		fight_btn.pressed.connect(_on_quick_fight_pressed)
		_encounter_card_vbox.add_child(fight_btn)
	else:
		_encounter_card.visible = false

	# Pause/resume toggle
	var is_paused = rift_id > 0 and int(Account.activity) != 7
	_resume_btn.visible = is_paused
	_pause_btn.visible = not is_paused


func _get_role_color(role: String) -> Color:
	match role:
		"tank": return Color.from_rgba8(100, 160, 220)
		"healer": return Color.from_rgba8(100, 220, 120)
		"dps": return Color.from_rgba8(220, 100, 80)
		"caster": return Color.from_rgba8(180, 120, 240)
		_: return Color.from_rgba8(160, 160, 160)


func _on_account_data(_ok) -> void:
	if _rift_died:
		return
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	if rift_id == 0:
		queue_free()
		return
	_refresh()


func _on_quick_fight_pressed() -> void:
	var skill_ids: Array = []
	var player_skills = Account.raw_structures.account_skills if Account.raw_structures.account_skills != null else {}
	if player_skills is Dictionary:
		for slot in player_skills:
			var skill = player_skills[slot]
			if skill is Dictionary:
				skill_ids.append(int(skill.get("skill_id", 0)))
	ServerConnector.send_message({
		"cmd": "confirm_fight",
		"payload": {"skill_loadout": skill_ids}
	})


func _on_pause_pressed() -> void:
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	SignalManager.signal_UserActivity.emit(7, rift_id, "pause")


func _on_resume_pressed() -> void:
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	SignalManager.signal_UserActivity.emit(7, rift_id, "start")


func _on_stop_pressed() -> void:
	if _rift_died:
		queue_free()
		return
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	SignalManager.signal_UserActivity.emit(7, rift_id, "stop")


func _on_refresh_fights_pressed() -> void:
	var instance_id = str(Account.rift_instance_id) if Account.rift_instance_id != null else ""
	if instance_id.is_empty():
		return
	SignalManager.signal_RequestRiftFights.emit(instance_id)


func _on_battle_log_pressed() -> void:
	if _cached_fights.is_empty():
		return
	if _battle_log_overlay != null and is_instance_valid(_battle_log_overlay):
		return
	_battle_log_overlay = BATTLE_VIS.new()
	_battle_log_overlay.fights_data = _cached_fights
	_battle_log_overlay.tree_exited.connect(func(): _battle_log_overlay = null, Object.CONNECT_ONE_SHOT)
	add_child(_battle_log_overlay)


func _on_fight_row_pressed(fight: Dictionary) -> void:
	var instance_id = str(Account.rift_instance_id) if Account.rift_instance_id != null else ""
	var fight_uid = str(fight.get("fight_uid", ""))
	if instance_id.is_empty() or fight_uid.is_empty():
		return
	_pending_fight_request = fight
	SignalManager.signal_RequestRiftFightLog.emit(instance_id, fight_uid)


func _on_activity_progress(data: Dictionary) -> void:
	var d = data.get("data", {}).get("data", data)

	var pending_monster = d.get("pending_monster", {})
	if pending_monster is Dictionary and not pending_monster.is_empty():
		_cached_pending_monster = pending_monster

	if d.get("pending_fight", false):
		_refresh()
		return

	var milestone_fights = d.get("milestone_fights", [])
	if milestone_fights != null and not milestone_fights.is_empty():
		_cached_pending_monster = {}
		_on_refresh_fights_pressed()
		_refresh()

	if d.get("rift_died", false):
		_rift_died = true
		_pause_btn.disabled = true
		_resume_btn.disabled = true
		_encounter_card.visible = false
		_rift_name_label.text = _rift_name_label.text + "  [FALLEN]"
		_exit_btn.text = "CLOSE"

	if d.get("rift_complete", false):
		var completion = COMPLETION_SCREEN.new()
		completion.completion_data = data
		add_child(completion)


func _on_rift_fights_received(data) -> void:
	var d = data.get("data", data)
	for child in _fight_list.get_children():
		child.queue_free()

	var fights = d.get("fights", [])
	_cached_fights = fights if fights != null else []
	_battle_log_btn.disabled = _cached_fights.is_empty()
	if fights == null or fights.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No fights yet."
		empty_lbl.add_theme_color_override("font_color", Color.from_rgba8(100, 100, 100))
		_fight_list.add_child(empty_lbl)
		return

	for fight in fights:
		var m_idx = int(fight.get("milestone_index", 0))
		var monster_id = str(fight.get("monster_id", "unknown")).replace("_", " ").capitalize()
		var result = fight.get("result", false)
		var hp_before = int(fight.get("player_hp_before", 0))
		var hp_after = int(fight.get("player_hp_after", 0))
		var result_color = Color.from_rgba8(60, 200, 100) if result else Color.from_rgba8(220, 80, 80)

		var loot_counts = fight.get("loot_counts", {})
		var loot_text = ""
		if loot_counts != null and loot_counts is Dictionary and not loot_counts.is_empty():
			var total_items = 0
			for v in loot_counts.values():
				total_items += int(v)
			loot_text = "  Loot: %d" % total_items

		var result_icon = "✓" if result else "✗"
		var result_str = "WIN" if result else "LOSS"

		var row = Button.new()
		row.text = "%s #%d  %s  HP %d→%d%s" % [
			result_icon, m_idx + 1, result_str,
			hp_before, hp_after, loot_text,
		]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		Styler.style_button_small(row, Color(result_color, 0.15))
		row.add_theme_color_override("font_color", result_color)
		var fight_copy = fight.duplicate()
		row.pressed.connect(func(): _on_fight_row_pressed(fight_copy))
		_fight_list.add_child(row)

	var fight_log = d.get("fight_log")
	if fight_log != null and not _pending_fight_request.is_empty():
		var viewer = FIGHT_LOG_VIS.new()
		viewer.fight_meta = _pending_fight_request
		viewer.fight_log = fight_log
		viewer.tree_exited.connect(func(): _pending_fight_request = {}, CONNECT_ONE_SHOT)
		add_child(viewer)


# Red embossed button — eye-grab "FIGHT NOW" CTA per P5.4 spec.
func _style_red_emboss_button(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	btn.add_theme_constant_override("outline_size", 2)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Styler.COL_OFFENSE
		sb.set_corner_radius_all(5)
		sb.border_color = Color.from_rgba8(255, 144, 112)
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 2
		sb.shadow_color = Color(Styler.COL_OFFENSE, 0.5)
		sb.shadow_size = 12
		match state_name:
			"hover":
				sb.bg_color = Styler.COL_OFFENSE.lightened(0.1)
				sb.shadow_size = 18
			"pressed":
				sb.bg_color = Styler.COL_OFFENSE.darkened(0.08)
				sb.shadow_size = 4
				sb.content_margin_top = 2
		btn.add_theme_stylebox_override(state_name, sb)
