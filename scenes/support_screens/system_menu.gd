extends Control

signal settings_pressed
signal relogin_pressed
signal exit_pressed

var _anchor_pos: Vector2 = Vector2.ZERO

func setup(anchor_position: Vector2) -> void:
	_anchor_pos = anchor_position


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

	# Menu items
	_add_menu_item(vbox, "Settings", func(): settings_pressed.emit(); queue_free())
	_add_separator(vbox)
	_add_menu_item(vbox, "Re-Login", func(): relogin_pressed.emit(); queue_free())
	_add_separator(vbox)
	_add_menu_item(vbox, "Exit", func(): exit_pressed.emit(); queue_free(), Color.from_rgba8(220, 80, 80))

	# Position: right-aligned with button, dropping below
	await get_tree().process_frame
	var panel_size = panel.size
	panel.position = Vector2(
		_anchor_pos.x + 32 - panel_size.x,
		_anchor_pos.y + 32 + 6
	)

	gui_input.connect(_on_backdrop_input)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)


func _add_menu_item(parent: VBoxContainer, text: String, callback: Callable, color: Color = Color(0.9, 0.9, 0.9)) -> void:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(120, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.78, 0.26))
	# Subtle hover background
	var hover_sb = StyleBoxFlat.new()
	hover_sb.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hover_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_sb)
	var pressed_sb = StyleBoxFlat.new()
	pressed_sb.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	pressed_sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.pressed.connect(callback)
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
