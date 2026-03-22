extends Control

@onready var panel_main_login: Panel = $Panel_main_login
@onready var client_version_label: Label = $Client_version_label

@onready var username_login_edit: LineEdit = $Panel_main_login/VBoxContainer/HBoxContainer/username_loginEdit
@onready var password_login_edit: LineEdit = $Panel_main_login/VBoxContainer/HBoxContainer2/password_loginEdit
@onready var status_label: Label = $Panel_main_login/status_label

@onready var button_login: Button = $Panel_main_login/button_login
@onready var button_createuser: Button = $Panel_main_login/button_createuser

@onready var username_login_label: Label = $Panel_main_login/VBoxContainer/HBoxContainer/username_loginLabel
@onready var password_login_label: Label = $Panel_main_login/VBoxContainer/HBoxContainer2/password_loginLabel


const CREATE_USER_UI = preload("uid://d1bmiemb8yjfl")
var child: Node = null
var status_login = false


func _ready() -> void:
	Styler.style_name_label(client_version_label, Color.from_rgba8(255, 215, 128))
	Styler.style_button(button_login,  Color.from_rgba8(64,180,255))   # cyan (primary)
	Styler.style_button(button_createuser, Color.from_rgba8(255,200,66)) # gold (secondary)
	Styler.wire_button_anim(button_login)
	Styler.wire_button_anim(button_createuser)
	Styler.style_panel(panel_main_login, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))
	Styler.style_line_edit(username_login_edit)
	Styler.style_line_edit(password_login_edit, true)
	Styler.style_title(username_login_label)
	Styler.style_title(password_login_label)
	Styler.style_name_label(status_label, Color.from_rgba8(255, 10, 10, 220))

	await AccountManager.signal_LoginParamsReceived

	var project_version = ProjectSettings.get_setting("application/config/version", "")
	client_version_label.text = " Client version: " + project_version + " SERVER: " + ServerParams.SERVER_VERSION

func _on_button_createuser_button_down() -> void:
	panel_main_login.visible = false
	status_label.text = ""
	
	child = CREATE_USER_UI.instantiate()
	add_child(child)
	
	child.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)
	
func _on_child_closed() -> void:
	panel_main_login.visible = true
	child = null

func _on_button_login_button_down() -> void:
	status_label.text = ""
	if username_login_edit.text.strip_edges() == "" or password_login_edit.text == "":
		status_label.text = "Username and password are required"
		return
	button_login.disabled = true

	var login_ok := false
	var login_error := ""
	AccountManager.signal_LoginResult.connect(func(ok: bool, error: String):
		login_ok = ok
		login_error = error
	, CONNECT_ONE_SHOT)
	AccountManager.signal_AccountDataReceived.connect(func(_result):
		button_login.disabled = false
		if login_ok:
			SceneManage.goto("res://scenes/app_scenes_handler.tscn")
			SceneManage.reload()
		else:
			match login_error:
				"invalid_credentials":
					status_label.text = "Invalid username or password"
				_:
					status_label.text = "Login failed: " + login_error
	, CONNECT_ONE_SHOT)

	SignalManager.signal_LoginUser.emit(username_login_edit.text, password_login_edit.text)
