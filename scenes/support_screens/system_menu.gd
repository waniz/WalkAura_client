extends Control

signal relogin_pressed
signal exit_pressed

var _anchor_pos: Vector2 = Vector2.ZERO

func setup(anchor_position: Vector2) -> void:
	_anchor_pos = anchor_position


func _ready() -> void:
	# Root Control — full screen, catches backdrop taps to dismiss
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Transparent backdrop (clicking dismisses menu)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.3)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Menu panel — NOT centered, positioned at anchor
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	Styler.style_panel(panel, Color.from_rgba8(16, 18, 24, 230), Color.from_rgba8(255, 255, 255, 30))
	add_child(panel)

	# Margin inside panel
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	# VBox for buttons
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Re-Login button
	var relogin_btn = Button.new()
	relogin_btn.text = "Re-Login"
	relogin_btn.custom_minimum_size = Vector2(140, 40)
	Styler.style_button(relogin_btn, Color.from_rgba8(64, 180, 255))
	relogin_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	relogin_btn.add_theme_font_size_override("font_size", 16)
	relogin_btn.pressed.connect(func():
		relogin_pressed.emit()
		queue_free()
	)
	vbox.add_child(relogin_btn)

	# Exit button
	var exit_btn = Button.new()
	exit_btn.text = "Exit"
	exit_btn.custom_minimum_size = Vector2(140, 40)
	Styler.style_button(exit_btn, Color.from_rgba8(200, 60, 60))
	exit_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	exit_btn.add_theme_font_size_override("font_size", 16)
	exit_btn.pressed.connect(func():
		exit_pressed.emit()
		queue_free()
	)
	vbox.add_child(exit_btn)

	# Position the panel: top-right of panel aligns with bottom-right of anchor button
	# Wait one frame so panel size is calculated
	await get_tree().process_frame
	var panel_size = panel.size
	panel.position = Vector2(
		_anchor_pos.x + 36 - panel_size.x,  # right-align with button right edge
		_anchor_pos.y + 36 + 4  # just below the button
	)

	# Backdrop tap → close
	gui_input.connect(_on_backdrop_input)

	# Fade in
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()
