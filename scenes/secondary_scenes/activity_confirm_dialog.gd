extends Control

signal confirmed
signal cancelled

var _current_activity_name: String = ""
var _new_activity_name: String = ""
var _new_activity_id: int = 0
var _profession_name: String = ""
var _scroll_content: VBoxContainer
var _loading_label: Label
var _title_label: Label
var _confirm_btn: Button
var _cancel_btn: Button


func setup(current_name: String, new_name: String, activity_id: int, profession: String) -> void:
	_current_activity_name = current_name
	_new_activity_name = new_name
	_new_activity_id = activity_id
	_profession_name = profession


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dimmed backdrop
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center container
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Parchment card
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(620, 0)
	Styler._apply_parchment_style(panel)
	center.add_child(panel)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	# Scroll for content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 450)
	margin.add_child(scroll)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(outer_vbox)

	# Title (updated with activity_name from server response)
	_title_label = Label.new()
	_title_label.text = "Loading..."
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	outer_vbox.add_child(_title_label)

	# Buttons (right after the question, before stats/loot)
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 12)
	outer_vbox.add_child(btn_hbox)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm"
	_confirm_btn.custom_minimum_size = Vector2(100, 40)
	Styler.style_button(_confirm_btn, Color(0.24, 0.51, 0.27))
	_confirm_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_confirm_btn.add_theme_font_size_override("font_size", 14)
	_confirm_btn.pressed.connect(_on_confirm)
	btn_hbox.add_child(_confirm_btn)

	_cancel_btn = Button.new()
	_cancel_btn.text = "Cancel"
	_cancel_btn.custom_minimum_size = Vector2(100, 40)
	Styler.style_button(_cancel_btn, Color(0.55, 0.53, 0.50))
	_cancel_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_cancel_btn.add_theme_font_size_override("font_size", 14)
	_cancel_btn.pressed.connect(_on_cancel)
	btn_hbox.add_child(_cancel_btn)

	# Content area (filled when server responds)
	_scroll_content = VBoxContainer.new()
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_theme_constant_override("separation", 6)
	outer_vbox.add_child(_scroll_content)

	# Loading label
	_loading_label = Label.new()
	_loading_label.text = "Loading..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_loading_label.add_theme_font_size_override("font_size", 14)
	_loading_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	_scroll_content.add_child(_loading_label)

	# Fade in
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

	# Backdrop tap to cancel (deferred to avoid emulated mouse click closing it)
	get_tree().process_frame.connect(func(): gui_input.connect(_on_backdrop_input), CONNECT_ONE_SHOT)

	# Request profession info from server
	SignalManager.signal_ProfessionInfoReceived.connect(_on_profession_info)
	SignalManager.signal_RequestProfessionInfo.emit(_profession_name)


func _exit_tree() -> void:
	if SignalManager.signal_ProfessionInfoReceived.is_connected(_on_profession_info):
		SignalManager.signal_ProfessionInfoReceived.disconnect(_on_profession_info)


func _on_profession_info(data: Dictionary) -> void:
	if SignalManager.signal_ProfessionInfoReceived.is_connected(_on_profession_info):
		SignalManager.signal_ProfessionInfoReceived.disconnect(_on_profession_info)
	_loading_label.queue_free()
	_build_content(data)


func _build_content(data: Dictionary) -> void:
	var level = int(data.get("level", 1))
	var xp = int(data.get("xp", 0))
	var xp_to_next = int(data.get("xp_to_next", 0))
	var base_steps = int(data.get("base_steps", 0))
	var base_steps_original = int(data.get("base_steps_original", base_steps))
	var loot_items: Array = data.get("loot_table", [])

	# Update title with the server's activity_name (e.g. "Meadow Herb Picking")
	var activity_name = data.get("activity_name", _new_activity_name)
	var prof_display = _new_activity_name
	if _current_activity_name.is_empty():
		_title_label.text = "Start %s (%s)?" % [activity_name, prof_display]
	else:
		_title_label.text = "You are doing %s.\nStart %s (%s) instead?" % [_current_activity_name, activity_name, prof_display]

	# Stats section
	var stats_header = Label.new()
	stats_header.text = "Activity Details"
	stats_header.add_theme_font_override("font", Styler.JANDA_FONT)
	stats_header.add_theme_font_size_override("font_size", 14)
	stats_header.add_theme_color_override("font_color", Color(0.13, 0.37, 0.13))
	_scroll_content.add_child(stats_header)

	var stats_panel = PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var stats_sb = StyleBoxFlat.new()
	stats_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	stats_sb.border_color = Color(0.0, 0.0, 0.0, 0.15)
	stats_sb.set_border_width_all(1)
	stats_sb.set_corner_radius_all(5)
	stats_sb.content_margin_left = 8
	stats_sb.content_margin_right = 8
	stats_sb.content_margin_top = 6
	stats_sb.content_margin_bottom = 6
	stats_panel.add_theme_stylebox_override("panel", stats_sb)
	_scroll_content.add_child(stats_panel)

	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 16)
	stats_panel.add_child(stats_hbox)

	_add_stat_line(stats_hbox, "Level: %d" % level)

	var stats_right = VBoxContainer.new()
	stats_right.add_theme_constant_override("separation", 3)
	stats_hbox.add_child(stats_right)

	if base_steps_original > base_steps and base_steps_original > 0:
		var pct = int(round((1.0 - float(base_steps) / float(base_steps_original)) * 100.0))
		_add_stat_line(stats_right, "Steps per action: %d  [-%d%% from stats, base %d]" % [base_steps, pct, base_steps_original])
	else:
		_add_stat_line(stats_right, "Steps per action: %d" % base_steps)
	if xp_to_next > 0:
		_add_stat_line(stats_right, "XP to next level: %d / %d" % [xp, xp_to_next])
	else:
		_add_stat_line(stats_right, "XP: Max level reached")

	# Loot section (2-column grid)
	if not loot_items.is_empty():
		var loot_header = Label.new()
		loot_header.text = "Possible Loot"
		loot_header.add_theme_font_override("font", Styler.JANDA_FONT)
		loot_header.add_theme_font_size_override("font_size", 14)
		loot_header.add_theme_color_override("font_color", Color(0.13, 0.37, 0.13))
		_scroll_content.add_child(loot_header)

		var loot_grid = GridContainer.new()
		loot_grid.columns = 2
		loot_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		loot_grid.add_theme_constant_override("h_separation", 6)
		loot_grid.add_theme_constant_override("v_separation", 4)
		_scroll_content.add_child(loot_grid)

		for item in loot_items:
			var row = _build_loot_row(item)
			loot_grid.add_child(row)


func _add_stat_line(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	parent.add_child(lbl)


func _build_loot_row(item: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.15)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_key = item.get("icon", "")
	var icon_tex = ItemDB.get_item_icon(icon_key)
	if icon_tex == null:
		icon_tex = ItemDB.get_icon(icon_key)
	if icon_tex:
		icon.texture = icon_tex
	hbox.add_child(icon)

	# Name (quality-colored)
	var quality = int(item.get("quality", 0))
	var name_lbl = Label.new()
	name_lbl.text = str(item.get("name", "")).replace("_", " ").capitalize()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", _quality_color(quality))
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(name_lbl)

	# Drop chance
	var pct_lbl = Label.new()
	pct_lbl.text = "%.1f%%" % float(item.get("drop_pct", 0))
	pct_lbl.add_theme_font_size_override("font_size", 14)
	pct_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	pct_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(pct_lbl)

	return panel


func _quality_color(quality: int) -> Color:
	match quality:
		0: return Styler.COLOR_TEXT_DARK
		1: return Color.from_rgba8(30, 180, 30)
		2: return Color.from_rgba8(50, 100, 220)
		3: return Color.from_rgba8(160, 50, 200)
		4: return Color.from_rgba8(220, 150, 30)
		5: return Color.from_rgba8(230, 70, 70)
		_: return Styler.COLOR_TEXT_DARK


func _on_confirm() -> void:
	confirmed.emit()
	queue_free()


func _on_cancel() -> void:
	cancelled.emit()
	queue_free()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel()
	elif event is InputEventScreenTouch and event.pressed:
		_on_cancel()
