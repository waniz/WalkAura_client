extends Control

signal auto_walk_toggled(active: bool)
signal auto_walk_rate_changed(rate: int)

var _anchor_pos: Vector2 = Vector2.ZERO
var _auto_walk_active: bool = false
var _auto_walk_rate: int = 25

const RATES = [25, 50, 100]


func setup(anchor_position: Vector2, auto_walk_active: bool, auto_walk_rate: int) -> void:
	_anchor_pos = anchor_position
	_auto_walk_active = auto_walk_active
	_auto_walk_rate = auto_walk_rate


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Transparent backdrop — tapping dismisses
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.3)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Menu panel
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	Styler.style_panel(panel, Color.from_rgba8(16, 18, 24, 235), Color.from_rgba8(255, 255, 255, 30))
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	# Step buttons
	_add_step_item(vbox, "+ 100 steps", 100)
	_add_separator(vbox)
	_add_step_item(vbox, "+ 500 steps", 500)
	_add_separator(vbox)
	_add_step_item(vbox, "+ 1k steps", 1000)
	_add_separator(vbox)
	_add_step_item(vbox, "+ 5k steps", 5000)
	_add_separator(vbox)
	_add_simulate_offline_item(vbox, "Simulate login +1k", 1000)
	_add_separator(vbox)
	_add_talent_points_item(vbox, "+ 1 talent pt", 1)
	_add_separator(vbox)
	_add_talent_points_item(vbox, "+ 10 talent pts", 10)
	_add_separator(vbox)

	# Auto-walk toggle
	var auto_btn = Button.new()
	auto_btn.flat = true
	auto_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	auto_btn.custom_minimum_size = Vector2(140, 36)
	auto_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	auto_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	auto_btn.add_theme_font_size_override("font_size", 16)
	_update_auto_btn_text(auto_btn)
	auto_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5) if _auto_walk_active else Color(0.9, 0.9, 0.9))
	auto_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	var hover_sb = StyleBoxFlat.new()
	hover_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hover_sb.set_corner_radius_all(4)
	auto_btn.add_theme_stylebox_override("hover", hover_sb)
	var pressed_sb = StyleBoxFlat.new()
	pressed_sb.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	pressed_sb.set_corner_radius_all(4)
	auto_btn.add_theme_stylebox_override("pressed", pressed_sb)
	auto_btn.pressed.connect(func():
		_auto_walk_active = not _auto_walk_active
		_update_auto_btn_text(auto_btn)
		auto_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5) if _auto_walk_active else Color(0.9, 0.9, 0.9))
		auto_walk_toggled.emit(_auto_walk_active)
	)
	vbox.add_child(auto_btn)

	# Rate selector row
	var rate_row = HBoxContainer.new()
	rate_row.add_theme_constant_override("separation", 4)
	vbox.add_child(rate_row)

	var rate_label = Label.new()
	rate_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	rate_label.add_theme_font_size_override("font_size", 13)
	rate_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	rate_label.text = "%d/s" % _auto_walk_rate
	rate_label.custom_minimum_size = Vector2(42, 0)

	var left_btn = Button.new()
	left_btn.text = "◀"
	left_btn.flat = true
	left_btn.custom_minimum_size = Vector2(28, 28)
	left_btn.add_theme_font_size_override("font_size", 12)
	left_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	left_btn.pressed.connect(func():
		var idx = RATES.find(_auto_walk_rate)
		idx = max(0, idx - 1)
		_auto_walk_rate = RATES[idx]
		rate_label.text = "%d/s" % _auto_walk_rate
		auto_walk_rate_changed.emit(_auto_walk_rate)
	)

	var right_btn = Button.new()
	right_btn.text = "▶"
	right_btn.flat = true
	right_btn.custom_minimum_size = Vector2(28, 28)
	right_btn.add_theme_font_size_override("font_size", 12)
	right_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	right_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	right_btn.pressed.connect(func():
		var idx = RATES.find(_auto_walk_rate)
		idx = min(RATES.size() - 1, idx + 1)
		_auto_walk_rate = RATES[idx]
		rate_label.text = "%d/s" % _auto_walk_rate
		auto_walk_rate_changed.emit(_auto_walk_rate)
	)

	rate_row.add_child(left_btn)
	rate_row.add_child(rate_label)
	rate_row.add_child(right_btn)

	# Position: left-aligned with button, dropping below
	await get_tree().process_frame
	panel.position = Vector2(
		_anchor_pos.x,
		_anchor_pos.y + 32 + 6
	)

	gui_input.connect(_on_backdrop_input)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)


func _update_auto_btn_text(btn: Button) -> void:
	btn.text = "%s Auto-Walk" % ("⏸" if _auto_walk_active else "▶")


func _add_step_item(parent: VBoxContainer, text: String, amount: int) -> void:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(140, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	var hover_sb = StyleBoxFlat.new()
	hover_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hover_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_sb)
	var pressed_sb = StyleBoxFlat.new()
	pressed_sb.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	pressed_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.pressed.connect(func():
		SignalManager.signal_StepsUpdatesCheats.emit(amount)
		queue_free()
	)
	parent.add_child(btn)


func _add_simulate_offline_item(parent: VBoxContainer, text: String, amount: int) -> void:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(140, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	var hover_sb = StyleBoxFlat.new()
	hover_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hover_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_sb)
	var pressed_sb = StyleBoxFlat.new()
	pressed_sb.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	pressed_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.pressed.connect(func():
		SignalManager.signal_StepsSimulateOffline.emit(amount)
		queue_free()
	)
	parent.add_child(btn)


func _add_talent_points_item(parent: VBoxContainer, text: String, points: int) -> void:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(140, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	var hover_sb = StyleBoxFlat.new()
	hover_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hover_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_sb)
	var pressed_sb = StyleBoxFlat.new()
	pressed_sb.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	pressed_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.pressed.connect(func():
		SignalManager.signal_TalentCheatPoints.emit(points)
		queue_free()
	)
	parent.add_child(btn)


func _add_separator(parent: VBoxContainer) -> void:
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	var line_sb = StyleBoxLine.new()
	line_sb.color = Color(1.0, 1.0, 1.0, 0.1)
	line_sb.thickness = 1
	sep.add_theme_stylebox_override("separator", line_sb)
	parent.add_child(sep)


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()
	elif event is InputEventScreenTouch and event.pressed:
		queue_free()
