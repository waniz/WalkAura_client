extends Control

const FIGHTS_VIEWER = preload("res://scenes/secondary_scenes/rift_fights_viewer.gd")
const RIFT_NAMES = {1: "Ancient Rift", 2: "Infernal Rift"}

const QUALITY_COLORS = {
	1:           Color(0.6, 0.6, 0.6),              # Common
	2:           Color(30.0/255, 180.0/255, 30.0/255),   # Uncommon
	3:           Color(50.0/255, 100.0/255, 220.0/255),  # Rare
	4:           Color(160.0/255, 50.0/255, 200.0/255),  # Epic
	5:           Color(220.0/255, 150.0/255, 30.0/255),  # Legendary
	6:           Color(220.0/255, 50.0/255, 50.0/255),   # Mythic
}

var _list_container: VBoxContainer
var _loading_label: Label


func _ready() -> void:
	_build_ui()
	AccountManager.signal_RiftHistoryReceived.connect(_on_history_received)
	SignalManager.signal_RequestRiftHistory.emit()


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
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
	title.text = "RIFT HISTORY"
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

	# Scrollable content area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_list_container)

	_loading_label = Label.new()
	_loading_label.text = "Loading..."
	Styler.style_parchment_label(_loading_label, Styler.COLOR_TEXT_DARK)
	_list_container.add_child(_loading_label)


func _on_history_received(data) -> void:
	for child in _list_container.get_children():
		child.queue_free()

	var history: Array = data.get("data", {}).get("history", [])
	if history == null or history.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No rift history found."
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		empty_lbl.add_theme_font_size_override("font_size", 18)
		_list_container.add_child(empty_lbl)
		return

	for entry in history:
		_list_container.add_child(_build_entry_card(entry))


func _build_entry_card(entry: Dictionary) -> PanelContainer:
	var status: String = entry.get("status", "abandoned")
	var border_color: Color
	if status == "completed":
		border_color = Color.from_rgba8(60, 200, 100)
	elif status == "died":
		border_color = Color.from_rgba8(220, 60, 60)
	else:
		border_color = Color.from_rgba8(120, 120, 120)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var csb = StyleBoxFlat.new()
	csb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	csb.border_color = border_color
	csb.border_width_left = 4
	csb.border_width_top = 1
	csb.border_width_right = 1
	csb.border_width_bottom = 1
	csb.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", csb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Row 1: rift name + status badge
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	var rift_type: int = int(entry.get("rift_type", 0))
	var rift_name: String = RIFT_NAMES.get(rift_type, "Unknown Rift")
	var name_lbl = Label.new()
	name_lbl.text = rift_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	row1.add_child(name_lbl)

	var badge_text: String
	match status:
		"completed": badge_text = "CLEARED"
		"died":      badge_text = "DIED"
		_:           badge_text = "ABANDONED"
	var badge_lbl = Label.new()
	badge_lbl.text = badge_text
	badge_lbl.add_theme_font_size_override("font_size", 13)
	badge_lbl.add_theme_color_override("font_color", border_color)
	row1.add_child(badge_lbl)

	# Row 2: fights + deaths
	var total_milestones: int = int(entry.get("total_milestones", 0))
	var fights_won: int = int(entry.get("fights_won", 0))
	var death_count: int = int(entry.get("death_count", 0))
	var stats_lbl = Label.new()
	var total_fights: int = fights_won + death_count
	stats_lbl.text = "Fights: %d/%d  Won: %d  Deaths: %d" % [total_fights, total_milestones, fights_won, death_count]
	Styler.style_parchment_label(stats_lbl, Styler.COLOR_TEXT_DARK)
	vbox.add_child(stats_lbl)

	# Row 3: reward item (if any)
	var reward_name: String = str(entry.get("reward_item_name", ""))
	var reward_quality: int = int(entry.get("reward_quality", 0))
	if reward_name != "":
		var reward_lbl = Label.new()
		var quality_color: Color = QUALITY_COLORS.get(reward_quality, Color(0.6, 0.6, 0.6))
		reward_lbl.text = "Reward: %s" % reward_name
		Styler.style_parchment_label(reward_lbl, quality_color)
		vbox.add_child(reward_lbl)

	# Row 4: date
	var started_at: String = str(entry.get("started_at", ""))
	if started_at != "":
		# Trim to date portion only (e.g. "2026-03-30" from "2026-03-30T12:34:56")
		var date_str = started_at.substr(0, 10)
		var date_lbl = Label.new()
		date_lbl.text = date_str
		Styler.style_parchment_label(date_lbl, Color.from_rgba8(140, 130, 110))
		vbox.add_child(date_lbl)

	# Row 5: drill-down button
	var instance_id: String = str(entry.get("rift_instance_id", ""))
	var drill_btn = Button.new()
	drill_btn.text = "View Fights >"
	drill_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Styler.style_button_small(drill_btn, Color.from_rgba8(80, 100, 160))
	drill_btn.add_theme_color_override("font_color", Color.WHITE)
	drill_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	drill_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	drill_btn.pressed.connect(func(): _open_fights_viewer(instance_id))
	vbox.add_child(drill_btn)

	return card


func _open_fights_viewer(instance_id: String) -> void:
	var viewer = FIGHTS_VIEWER.new()
	viewer.rift_instance_id = instance_id
	add_child(viewer)
