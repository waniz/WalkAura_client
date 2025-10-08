extends Control

@onready var debugger_label: RichTextLabel = $debuggerLabel
@onready var panel_main_login: Panel = $Panel_main_login
@onready var client_version_label: Label = $Client_version_label

@onready var username_login_edit: TextEdit = $Panel_main_login/VBoxContainer/HBoxContainer/username_loginEdit
@onready var password_login_edit: LineEdit = $Panel_main_login/VBoxContainer/HBoxContainer2/password_loginEdit
@onready var status_label: RichTextLabel = $Panel_main_login/status_label

@onready var button_login: Button = $Panel_main_login/button_login


const CREATE_USER_UI = preload("uid://d1bmiemb8yjfl")
var child: Node = null
var status_login = false


func _ready() -> void:
	var project_version = ProjectSettings.get_setting("application/config/version", "")
	client_version_label.text = "Client version: " + project_version
	
	Debugger.signalLogUpdated.connect(_on_message)
	
func _on_message(message):
		debugger_label.text = message

func _on_button_createuser_button_down() -> void:
	panel_main_login.visible = false
	
	child = CREATE_USER_UI.instantiate()
	add_child(child)
	
	child.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)
	
func _on_child_closed() -> void:
	panel_main_login.visible = true
	child = null

func _on_button_login_button_down() -> void:
	button_login.disabled = true
	
	SignalManager.signal_LoginUser.emit(username_login_edit.text, password_login_edit.text)
	
	var login_result = await AccountManager.signal_LoginResult
	var login_data_result = await AccountManager.signal_AccountDataReceived
	button_login.disabled = false
	if login_result and login_data_result:
		#SceneManage.goto("res://scenes/main_screens/character_stats.tscn")
		SceneManage.goto("res://scenes/main_screens/ui_control/app_scenes_handler.tscn")
		SceneManage.reload()
	else:
		status_label.text = "[color=red]" + "Incorrect login data" + "[/color]"
