extends CanvasLayer
## Generic bottom-sheet picker. Used for title selector and stat picker in the
## achievements flow. `configure(title, options, on_pick)` opens the sheet.
##
## options can be:
##   - Array of String — label == value
##   - Array of Dictionary — {"value": Variant, "label": String}

signal picked(value)

var _on_pick_callback: Callable
var _dim: ColorRect
var _sheet: PanelContainer
var _title_label: Label
var _options_vbox: VBoxContainer


func configure(title_text: String, options: Array, on_pick: Callable) -> void:
	_on_pick_callback = on_pick
	_ensure_built()
	_title_label.text = title_text
	for child in _options_vbox.get_children():
		child.queue_free()
	for opt in options:
		var label: String
		var value
		if opt is Dictionary:
			label = str(opt.get("label", opt.get("value", "")))
			value = opt.get("value")
		else:
			label = str(opt)
			value = opt
		_options_vbox.add_child(_build_option_button(label, value))


func _ensure_built() -> void:
	if _sheet != null:
		return

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.anchor_right = 1.0
	_dim.anchor_bottom = 1.0
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close(null))
	add_child(_dim)

	_sheet = PanelContainer.new()
	_sheet.anchor_left = 0.0
	_sheet.anchor_right = 1.0
	_sheet.anchor_top = 1.0
	_sheet.anchor_bottom = 1.0
	_sheet.offset_top = -360
	var sb = StyleBoxFlat.new()
	sb.bg_color = Styler.COLOR_PANEL_DARK
	sb.border_width_top = 2
	sb.border_color = Styler.COLOR_GOLD
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	_sheet.add_theme_stylebox_override("panel", sb)
	add_child(_sheet)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_sheet.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Styler.COLOR_GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	_options_vbox = VBoxContainer.new()
	_options_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(_options_vbox)

	var cancel = Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(0, 44)
	cancel.pressed.connect(func(): _close(null))
	vbox.add_child(cancel)


func _build_option_button(label: String, value) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(func(): _close(value))
	return btn


func _close(value) -> void:
	if value != null and _on_pick_callback.is_valid():
		_on_pick_callback.call(value)
		picked.emit(value)
	queue_free()
