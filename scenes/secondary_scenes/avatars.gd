extends Control

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Panel — inset to clear the HUDs (mirrors rift.gd offsets)
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
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	margin.add_child(vbox)

	# Header row
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title = Label.new()
	title.text = "Choose Avatar"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	header_hbox.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.pressed.connect(queue_free)
	header_hbox.add_child(close_btn)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for key in ItemDB.AVATARS.keys():
		var tex: Texture2D = ItemDB.AVATARS[key]
		var id: int = int(key)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 180)
		btn.toggle_mode = false
		btn.focus_mode = Control.FOCUS_NONE

		var is_selected: bool = (id == Account.avatar_id)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.05)
		sb.set_corner_radius_all(8)
		sb.border_color = Styler.COLOR_GOLD if is_selected else Color(0, 0, 0, 0.2)
		sb.set_border_width_all(3 if is_selected else 1)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

		var btn_vbox = VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(btn_vbox)

		var img = TextureRect.new()
		img.texture = tex
		img.custom_minimum_size = Vector2(112, 112)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(img)

		var lbl = Label.new()
		lbl.text = GameTextEn.avatar_names.get(key, "Avatar " + key)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(lbl)

		btn.pressed.connect(_on_avatar_selected.bind(id))
		grid.add_child(btn)


func _on_avatar_selected(id: int) -> void:
	Account.avatar_id = id
	SignalManager.signal_AvatarChanged.emit(id)
	queue_free()
