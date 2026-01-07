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
	
	await AccountManager.signal_LoginParamsReceived
	
	var project_version = ProjectSettings.get_setting("application/config/version", "")
	client_version_label.text = " Client version: " + project_version + " SERVER: " + ServerParams.SERVER_VERSION
	
	Styler.style_button(button_login,  Color.from_rgba8(64,180,255))   # cyan (primary)
	Styler.style_button(button_createuser, Color.from_rgba8(255,200,66)) # gold (secondary)
	
	Styler.wire_button_anim(button_login)
	Styler.wire_button_anim(button_createuser)
	
	Styler.style_panel(panel_main_login, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))
	
	Styler.style_line_edit(username_login_edit,)
	Styler.style_line_edit(password_login_edit, true)
	
	Styler.style_title(username_login_label)
	Styler.style_title(password_login_label)
	
	Styler.style_name_label(status_label, Color.from_rgba8(255, 10, 10, 220))

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
	button_login.disabled = true
	status_label.text = ""
	
	SignalManager.signal_LoginUser.emit(username_login_edit.text, password_login_edit.text)
	
	var login_result = await AccountManager.signal_LoginResult
	var login_data_result = await AccountManager.signal_AccountDataReceived
	button_login.disabled = false
	if login_result and login_data_result:
		SceneManage.goto("res://scenes/app_scenes_handler.tscn")
		SceneManage.reload()
	else:
		status_label.text = "Incorrect login data"
