extends Control

const CREATE_USER_UI = preload("uid://d1bmiemb8yjfl")

var _panel: PanelContainer
var _username_edit: LineEdit
var _password_edit: LineEdit
var _status_label: Label
var _btn_login: Button
var _btn_create: Button
var _version_label: Label

var child: Node = null
var _login_ok = false
var _login_error = ""


func _ready() -> void:
	_build_ui()

	await AccountManager.signal_LoginParamsReceived

	var project_version = ProjectSettings.get_setting("application/config/version", "")
	_version_label.text = "v" + project_version + "  Server: " + ServerParams.SERVER_VERSION


func _build_ui() -> void:
	# Center container for the card
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Parchment card
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	_apply_login_panel_style(_panel)
	center.add_child(_panel)

	# Margin inside card
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# Game title
	var title = Label.new()
	title.text = "WalkAura"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.13, 0.37, 0.13))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Walk. Explore. Grow."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", Styler.QUADRAT_FONT)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	vbox.add_child(subtitle)

	# Separator
	var sep = HSeparator.new()
	sep.modulate = Color(0, 0, 0, 0.2)
	vbox.add_child(sep)

	# Username field
	var username_label = Label.new()
	username_label.text = "Username"
	Styler.style_parchment_label(username_label, Styler.COLOR_TEXT_DARK)
	vbox.add_child(username_label)

	_username_edit = LineEdit.new()
	_username_edit.placeholder_text = "Enter username"
	_username_edit.text = "test_user"
	_username_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_username_edit.add_theme_font_size_override("font_size", 18)
	_style_parchment_line_edit(_username_edit)
	vbox.add_child(_username_edit)

	# Password field
	var password_label = Label.new()
	password_label.text = "Password"
	Styler.style_parchment_label(password_label, Styler.COLOR_TEXT_DARK)
	vbox.add_child(password_label)

	_password_edit = LineEdit.new()
	_password_edit.placeholder_text = "Enter password"
	_password_edit.text = "1234"
	_password_edit.secret = true
	_password_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_password_edit.add_theme_font_size_override("font_size", 18)
	_style_parchment_line_edit(_password_edit)
	vbox.add_child(_password_edit)

	# Status label (errors)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color.from_rgba8(200, 40, 40))
	vbox.add_child(_status_label)

	# Buttons
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_box)

	_btn_login = Button.new()
	_btn_login.text = "Play"
	_btn_login.custom_minimum_size = Vector2(0, 48)
	Styler.style_button(_btn_login, Color(0.24, 0.51, 0.27))
	_btn_login.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_btn_login.add_theme_font_size_override("font_size", 20)
	Styler.wire_button_anim(_btn_login)
	_btn_login.pressed.connect(_on_login_pressed)
	btn_box.add_child(_btn_login)

	_btn_create = Button.new()
	_btn_create.text = "Create New Account"
	_btn_create.custom_minimum_size = Vector2(0, 40)
	Styler.style_button(_btn_create, Color(0.55, 0.53, 0.50))
	_btn_create.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_btn_create.add_theme_font_size_override("font_size", 16)
	Styler.wire_button_anim(_btn_create)
	_btn_create.pressed.connect(_on_create_pressed)
	btn_box.add_child(_btn_create)

	# Version label at bottom of screen
	_version_label = Label.new()
	_version_label.text = ""
	_version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_version_label.offset_left = 8
	_version_label.offset_top = -24
	_version_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	add_child(_version_label)


func _style_parchment_line_edit(le: LineEdit) -> void:
	le.custom_minimum_size = Vector2(0, 40)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.4)
	bg.border_color = Styler.COLOR_BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	bg.content_margin_left = 10
	bg.content_margin_right = 10
	le.add_theme_stylebox_override("normal", bg)
	var focus = bg.duplicate()
	focus.border_color = Color(0.13, 0.37, 0.13)
	focus.set_border_width_all(2)
	le.add_theme_stylebox_override("focus", focus)
	le.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	le.add_theme_color_override("caret_color", Styler.COLOR_TEXT_DARK)


func _apply_login_panel_style(panel: PanelContainer) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(Styler.COLOR_PARCHMENT, 0.7)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Styler.COLOR_BORDER
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.4)
	panel.add_theme_stylebox_override("panel", sb)


func _on_create_pressed() -> void:
	_panel.visible = false
	_status_label.text = ""
	child = CREATE_USER_UI.instantiate()
	add_child(child)
	child.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)


func _on_child_closed() -> void:
	_panel.visible = true
	child = null


func _on_login_pressed() -> void:
	_status_label.text = ""
	if _username_edit.text.strip_edges() == "" or _password_edit.text == "":
		_status_label.text = "Username and password are required"
		return
	if not ServerConnector._is_socket_open():
		_status_label.text = "Not connected to server"
		return
	_btn_login.disabled = true
	_btn_create.disabled = true
	_login_ok = false
	_login_error = ""
	_status_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	_status_label.text = "Logging in..."

	AccountManager.signal_LoginResult.connect(_on_login_result, CONNECT_ONE_SHOT)
	AccountManager.signal_AccountDataReceived.connect(_on_login_data, CONNECT_ONE_SHOT)
	SignalManager.signal_LoginUser.emit(_username_edit.text, _password_edit.text)


func _on_login_result(ok: bool, error: String) -> void:
	_login_ok = ok
	_login_error = error


func _on_login_data(_result) -> void:
	_btn_login.disabled = false
	_btn_create.disabled = false
	if _login_ok:
		SceneManage.goto("res://scenes/app_scenes_handler.tscn")
		SceneManage.reload()
	else:
		_status_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.2))
		match _login_error:
			"invalid_credentials":
				_status_label.text = "Invalid username or password"
			_:
				_status_label.text = "Login failed: " + _login_error
