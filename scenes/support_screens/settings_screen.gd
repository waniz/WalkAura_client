extends Control

# Settings overlay (alpha). Sound on/off (master bus mute), language pick
# (EN-only i18n scaffold — no locale switching yet), and Log Out (emits
# logout_requested; the host wires it to the existing re-login flow). Built
# programmatically like the other overlays; styled via Styler.

signal logout_requested


func _ready() -> void:
	anchor_left = 0; anchor_top = 0
	anchor_right = 1; anchor_bottom = 1
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()


func _build_ui() -> void:
	var accent: Color = Styler.COL_PRIMARY

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			queue_free()
	)
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(16, 18, 24, 246)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	# Header.
	var head = HBoxContainer.new()
	vb.add_child(head)
	var title = Label.new()
	title.text = "SETTINGS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", accent)
	head.add_child(title)
	var close = Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(40, 40)
	close.add_theme_font_override("font", Styler.JANDA_FONT)
	close.add_theme_color_override("font_color", accent)
	close.pressed.connect(queue_free)
	head.add_child(close)

	vb.add_child(_rule(accent))

	# Sound toggle (master bus mute).
	var sound_row = HBoxContainer.new()
	sound_row.add_theme_constant_override("separation", 8)
	vb.add_child(sound_row)
	sound_row.add_child(_setting_label("Sound"))
	var sound_btn = CheckButton.new()
	sound_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	var master_bus = 0
	sound_btn.button_pressed = not AudioServer.is_bus_mute(master_bus)
	sound_btn.toggled.connect(func(on: bool):
		AudioServer.set_bus_mute(master_bus, not on)
	)
	sound_row.add_child(sound_btn)

	# Language (EN-only scaffold).
	var lang_row = HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	vb.add_child(lang_row)
	lang_row.add_child(_setting_label("Language"))
	var lang = OptionButton.new()
	lang.size_flags_horizontal = Control.SIZE_SHRINK_END
	lang.add_item("English")
	lang.disabled = true   # i18n scaffold only — no locale switching yet
	lang.add_theme_font_override("font", Styler.QUADRAT_FONT)
	lang_row.add_child(lang)

	vb.add_child(_rule(accent))

	# Log out.
	var logout = Button.new()
	logout.text = "LOG OUT"
	logout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logout.custom_minimum_size = Vector2(0, 46)
	logout.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	logout.add_theme_font_override("font", Styler.JANDA_FONT)
	logout.add_theme_font_size_override("font_size", 15)
	logout.add_theme_color_override("font_color", Color.WHITE)
	var danger: Color = Styler.COL_OFFENSE
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var l_sb = StyleBoxFlat.new()
		l_sb.bg_color = Color(danger, 0.85)
		l_sb.border_color = danger
		l_sb.set_border_width_all(1)
		l_sb.set_corner_radius_all(5)
		logout.add_theme_stylebox_override(state_name, l_sb)
	logout.pressed.connect(func():
		logout_requested.emit()
		queue_free()
	)
	vb.add_child(logout)


func _setting_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 212, 192))
	return lbl


func _rule(accent: Color) -> ColorRect:
	var rule = ColorRect.new()
	rule.color = Color(accent, 0.3)
	rule.custom_minimum_size = Vector2(0, 1)
	return rule
