extends Control

# Mirrors server RIFT_LOCATION_TABLE
const RIFTS := [
	{"id": 1, "name": "Ancient Rift", "req_lvl": 1, "total_milestones": 8, "total_steps": 5000},
	{"id": 2, "name": "Infernal Rift", "req_lvl": 5, "total_milestones": 10, "total_steps": 8000},
]

const BATTLE_VIS = preload("res://scenes/secondary_scenes/rift_battle_visualization.gd")

var _selection_container: VBoxContainer
var _active_container: VBoxContainer
var _rift_name_label: Label
var _rift_lvl_label: Label
var _progress_bar: ProgressBar
var _steps_label: Label
var _milestone_row: HBoxContainer
var _fight_list: VBoxContainer
var _battle_log_btn: Button
var _cached_fights: Array = []
var _battle_log_overlay: Control = null


func _ready() -> void:
	_build_ui()
	AccountManager.signal_AccountDataReceived.connect(_on_account_data)
	AccountManager.signal_RiftFightsReceived.connect(_on_rift_fights_received)
	_refresh()


func _build_ui() -> void:
	# Root covers full parent area and blocks input to layers below
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	# Dark semi-transparent background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Main panel — inset to clear the top CharacterHUD (~154 px) and bottom CanvasLayer HUD (~97 px)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 210
	panel.offset_bottom = -150
	Styler.style_panel_no_margins(panel, Color.from_rgba8(16, 18, 24, 245), Color.from_rgba8(255, 200, 66, 180))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	# --- Header ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "RIFT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_title(title)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# Scrollable content area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(content_vbox)

	# --- Rift Selection Container ---
	_selection_container = VBoxContainer.new()
	_selection_container.add_theme_constant_override("separation", 10)
	content_vbox.add_child(_selection_container)

	var sel_title := Label.new()
	sel_title.text = "Choose a Rift to Enter:"
	Styler.style_name_label(sel_title, Color.from_rgba8(220, 200, 150))
	_selection_container.add_child(sel_title)

	var cards_hbox := HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 10)
	_selection_container.add_child(cards_hbox)

	for rift_cfg in RIFTS:
		cards_hbox.add_child(_build_rift_card(rift_cfg))

	# --- Active Rift Container ---
	_active_container = VBoxContainer.new()
	_active_container.add_theme_constant_override("separation", 10)
	content_vbox.add_child(_active_container)

	_rift_name_label = Label.new()
	Styler.style_title(_rift_name_label)
	_active_container.add_child(_rift_name_label)

	_rift_lvl_label = Label.new()
	Styler.style_name_label(_rift_lvl_label, Color.from_rgba8(160, 200, 240))
	_active_container.add_child(_rift_lvl_label)

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 32)
	_progress_bar.show_percentage = false
	Styler.style_bar(_progress_bar, Color.from_rgba8(80, 200, 120), Color.from_rgba8(30, 35, 50, 255))
	_active_container.add_child(_progress_bar)

	# Milestone marker row (colored blocks, one per milestone)
	_milestone_row = HBoxContainer.new()
	_milestone_row.custom_minimum_size = Vector2(0, 18)
	_milestone_row.add_theme_constant_override("separation", 3)
	_active_container.add_child(_milestone_row)

	_steps_label = Label.new()
	Styler.style_name_label(_steps_label, Color.from_rgba8(200, 220, 200))
	_active_container.add_child(_steps_label)

	# Fight history header row
	var fight_header_row := HBoxContainer.new()
	fight_header_row.add_theme_constant_override("separation", 10)
	_active_container.add_child(fight_header_row)

	var fight_title := Label.new()
	fight_title.text = "Fight History:"
	fight_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_name_label(fight_title, Color.from_rgba8(180, 180, 180))
	fight_header_row.add_child(fight_title)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	Styler.style_button_small(refresh_btn, Color.from_rgba8(60, 100, 160))
	refresh_btn.pressed.connect(_on_refresh_fights_pressed)
	fight_header_row.add_child(refresh_btn)

	_battle_log_btn = Button.new()
	_battle_log_btn.text = "Battle Log"
	_battle_log_btn.disabled = true
	Styler.style_button_small(_battle_log_btn, Color.from_rgba8(100, 60, 180))
	_battle_log_btn.pressed.connect(_on_battle_log_pressed)
	fight_header_row.add_child(_battle_log_btn)

	var fight_scroll := ScrollContainer.new()
	fight_scroll.custom_minimum_size = Vector2(0, 160)
	fight_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_active_container.add_child(fight_scroll)

	_fight_list = VBoxContainer.new()
	_fight_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_list.add_theme_constant_override("separation", 4)
	fight_scroll.add_child(_fight_list)

	# Action buttons row
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_container.add_child(action_row)

	var pause_btn := Button.new()
	pause_btn.text = "PAUSE RIFT"
	pause_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(pause_btn, Color.from_rgba8(200, 140, 40))
	pause_btn.pressed.connect(_on_pause_pressed)
	action_row.add_child(pause_btn)

	var exit_btn := Button.new()
	exit_btn.text = "EXIT RIFT"
	exit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(exit_btn, Color.from_rgba8(180, 60, 60))
	exit_btn.pressed.connect(_on_stop_pressed)
	action_row.add_child(exit_btn)


func _build_rift_card(cfg: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_panel_no_margins(card, Color.from_rgba8(26, 28, 36, 255), Color.from_rgba8(100, 80, 40, 200))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Image placeholder (replace ColorRect with TextureRect once art is ready)
	var placeholder := ColorRect.new()
	placeholder.custom_minimum_size = Vector2(0, 140)
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.color = Color.from_rgba8(35, 45, 65, 255)
	vbox.add_child(placeholder)

	var name_lbl := Label.new()
	name_lbl.text = cfg["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_name_label(name_lbl, Color.from_rgba8(255, 200, 66))
	vbox.add_child(name_lbl)

	var req_lbl := Label.new()
	req_lbl.text = "Req: Rift Lvl %d" % cfg["req_lvl"]
	req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_name_label(req_lbl, Color.from_rgba8(180, 180, 180))
	vbox.add_child(req_lbl)

	var info_lbl := Label.new()
	info_lbl.text = "%d steps / %d milestones" % [cfg["total_steps"], cfg["total_milestones"]]
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_name_label(info_lbl, Color.from_rgba8(140, 170, 140))
	vbox.add_child(info_lbl)

	var rift_lvl: int = int(Account.rift_lvl) if Account.rift_lvl != null else 1
	var start_btn := Button.new()
	var rift_id: int = cfg["id"]
	if rift_lvl < int(cfg["req_lvl"]):
		start_btn.text = "LOCKED (Lvl %d)" % cfg["req_lvl"]
		start_btn.disabled = true
		Styler.style_button(start_btn, Color.from_rgba8(70, 70, 70))
	else:
		start_btn.text = "ENTER RIFT"
		Styler.style_button(start_btn, Color.from_rgba8(60, 130, 70))
		start_btn.pressed.connect(func(): _on_start_rift(rift_id))
	vbox.add_child(start_btn)

	return card


func _refresh() -> void:
	var rift_id: int = int(Account.rift_id) if Account.rift_id != null else 0
	var is_in_rift := rift_id > 0
	_selection_container.visible = not is_in_rift
	_active_container.visible = is_in_rift
	if is_in_rift:
		_refresh_active_view()


func _refresh_active_view() -> void:
	var rift_id: int = int(Account.rift_id) if Account.rift_id != null else 0
	var rift_name := ""
	for cfg in RIFTS:
		if cfg["id"] == rift_id:
			rift_name = cfg["name"]
			break

	var rift_lvl: int = int(Account.rift_lvl) if Account.rift_lvl != null else 1
	_rift_name_label.text = rift_name
	_rift_lvl_label.text = "Rift Level: %d" % rift_lvl

	var steps: int     = int(Account.rift_steps)            if Account.rift_steps            != null else 0
	var max_steps: int = int(Account.rift_steps_max)        if Account.rift_steps_max        != null else 1
	var m_idx: int     = int(Account.rift_milestone_index)  if Account.rift_milestone_index  != null else 0
	var total_m: int   = int(Account.rift_total_milestones) if Account.rift_total_milestones != null else 8

	# Cumulative progress across all milestones so the bar never resets mid-rift
	var step_size: int   = max(1, max_steps)
	var total_done: int  = m_idx * step_size + steps
	var total_max: int   = total_m * step_size

	_progress_bar.max_value = max(1, total_max)
	_progress_bar.value     = total_done
	_steps_label.text = "Steps: %d / %d   Milestones: %d / %d" % [steps, max_steps, m_idx, total_m]

	# Rebuild milestone marker row
	for child in _milestone_row.get_children():
		child.queue_free()
	for i in range(total_m):
		var marker := ColorRect.new()
		marker.custom_minimum_size = Vector2(0, 16)
		marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marker.color = Color.from_rgba8(100, 220, 100, 240) if i < m_idx else Color.from_rgba8(70, 80, 100, 180)
		_milestone_row.add_child(marker)


func _on_account_data(_ok) -> void:
	_refresh()


func _on_start_rift(rift_id: int) -> void:
	SignalManager.signal_UserActivity.emit(7, rift_id, "start")


func _on_pause_pressed() -> void:
	var rift_id: int = int(Account.rift_id) if Account.rift_id != null else 0
	SignalManager.signal_UserActivity.emit(7, rift_id, "pause")


func _on_stop_pressed() -> void:
	var rift_id: int = int(Account.rift_id) if Account.rift_id != null else 0
	SignalManager.signal_UserActivity.emit(7, rift_id, "stop")


func _on_refresh_fights_pressed() -> void:
	var instance_id: String = str(Account.rift_instance_id) if Account.rift_instance_id != null else ""
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


func _on_rift_fights_received(data) -> void:
	for child in _fight_list.get_children():
		child.queue_free()

	var fights = data.get("data", {}).get("fights", [])
	_cached_fights = fights if fights != null else []
	_battle_log_btn.disabled = _cached_fights.is_empty()
	if fights == null or fights.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No fights yet."
		Styler.style_name_label(empty_lbl, Color.from_rgba8(150, 150, 150))
		_fight_list.add_child(empty_lbl)
		return

	for fight in fights:
		var m_idx: int = int(fight.get("milestone_index", 0))
		var monster_id: String = str(fight.get("monster_id", "unknown")).replace("_", " ").capitalize()
		var result: bool = fight.get("result", false)
		var hp_before: int = int(fight.get("player_hp_before", 0))
		var hp_after: int = int(fight.get("player_hp_after", 0))
		var result_color := Color.from_rgba8(100, 220, 100) if result else Color.from_rgba8(220, 80, 80)

		var row := Label.new()
		row.text = "#%d: %s  %s  HP: %d→%d" % [
			m_idx + 1, monster_id,
			"WIN" if result else "LOSS",
			hp_before, hp_after,
		]
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Styler.style_name_label(row, result_color)
		_fight_list.add_child(row)
