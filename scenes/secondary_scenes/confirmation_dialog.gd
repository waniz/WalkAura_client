extends Control

signal confirmed
signal cancelled

var _label: Label
var _confirm_btn: Button
var _cancel_btn: Button
var _text: String = ""

func setup(text: String) -> void:
	_text = text
	if _label:
		_label.text = text


func _ready() -> void:
	# Root Control — full screen, catches backdrop taps
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dimmed backdrop
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
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
	panel.custom_minimum_size = Vector2(280, 0)
	Styler._apply_parchment_style(panel)
	center.add_child(panel)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	# VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Label
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	vbox.add_child(_label)

	# Button row
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	_cancel_btn = Button.new()
	_cancel_btn.text = "Cancel"
	_cancel_btn.custom_minimum_size = Vector2(100, 40)
	Styler.style_button(_cancel_btn, Color(0.55, 0.53, 0.50))
	_cancel_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_cancel_btn.add_theme_font_size_override("font_size", 14)
	_cancel_btn.pressed.connect(_on_cancel)
	hbox.add_child(_cancel_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm"
	_confirm_btn.custom_minimum_size = Vector2(100, 40)
	Styler.style_button(_confirm_btn, Color(0.24, 0.51, 0.27))
	_confirm_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_confirm_btn.add_theme_font_size_override("font_size", 14)
	_confirm_btn.pressed.connect(_on_confirm)
	hbox.add_child(_confirm_btn)

	# Apply text if setup() was called before _ready()
	if _text != "":
		_label.text = _text

	# Fade in
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

	# Backdrop tap → cancel (deferred so the emulated mouse click from the
	# same touch that opened this dialog doesn't immediately close it)
	get_tree().process_frame.connect(func(): gui_input.connect(_on_backdrop_input), CONNECT_ONE_SHOT)


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
