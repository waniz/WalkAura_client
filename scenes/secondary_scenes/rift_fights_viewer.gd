extends Control

## Standalone fight list viewer for past rift runs.
## Opened from rift_history_screen when "View Fights >" is pressed.

const FIGHT_LOG_VIS = preload("res://scenes/secondary_scenes/rift_fight_log_viewer.gd")

var rift_instance_id: String = ""

var _fight_list: VBoxContainer
var _loading_label: Label
var _pending_fight_request: Dictionary = {}


func _ready() -> void:
	_build_ui()
	AccountManager.signal_RiftFightsReceived.connect(_on_rift_fights_received)
	if not rift_instance_id.is_empty():
		SignalManager.signal_RequestRiftFights.emit(rift_instance_id)


func _build_ui() -> void:
	anchor_left = 0.0; anchor_top = 0.0
	anchor_right = 1.0; anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_parchment_style(panel)
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

	var title = Label.new()
	title.text = "FIGHT HISTORY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	var sep = HSeparator.new()
	root_vbox.add_child(sep)

	# --- Scrollable fight list ---
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_fight_list = VBoxContainer.new()
	_fight_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_fight_list)

	_loading_label = Label.new()
	_loading_label.text = "Loading fights..."
	Styler.style_parchment_label(_loading_label, Styler.COLOR_TEXT_DARK)
	_fight_list.add_child(_loading_label)


func _on_rift_fights_received(data) -> void:
	var d = data.get("data", data)

	# Only process responses for our instance
	var resp_instance = str(d.get("rift_instance_id", ""))
	if resp_instance != rift_instance_id:
		return

	for child in _fight_list.get_children():
		child.queue_free()

	var fights = d.get("fights", [])
	if fights == null or fights.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No fights recorded."
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		empty_lbl.add_theme_font_size_override("font_size", 16)
		_fight_list.add_child(empty_lbl)
		return

	for fight in fights:
		var m_idx = int(fight.get("milestone_index", 0))
		var monster_id = str(fight.get("monster_id", "unknown")).replace("_", " ").capitalize()
		var result = fight.get("result", false)
		var hp_before = int(fight.get("player_hp_before", 0))
		var hp_after = int(fight.get("player_hp_after", 0))
		var result_color = Color.from_rgba8(60, 160, 80) if result else Color.from_rgba8(180, 50, 50)

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

	# Handle fight log if we requested one
	var fight_log = d.get("fight_log")
	if fight_log != null and not _pending_fight_request.is_empty():
		var viewer = FIGHT_LOG_VIS.new()
		viewer.fight_meta = _pending_fight_request
		viewer.fight_log = fight_log
		viewer.tree_exited.connect(func(): _pending_fight_request = {}, CONNECT_ONE_SHOT)
		add_child(viewer)


func _on_fight_row_pressed(fight: Dictionary) -> void:
	var fight_uid = str(fight.get("fight_uid", ""))
	if rift_instance_id.is_empty() or fight_uid.is_empty():
		return
	_pending_fight_request = fight
	SignalManager.signal_RequestRiftFightLog.emit(rift_instance_id, fight_uid)
