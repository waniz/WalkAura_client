extends Control

@onready var debugger_label: RichTextLabel = $debuggerLabel
@onready var panel_main_login: Panel = $Panel_main_login
@onready var client_version_label: Label = $Client_version_label

@onready var username_login_edit: TextEdit = $Panel_main_login/VBoxContainer/HBoxContainer/username_loginEdit
@onready var password_login_edit: LineEdit = $Panel_main_login/VBoxContainer/HBoxContainer2/password_loginEdit
@onready var status_label: RichTextLabel = $Panel_main_login/status_label


const CREATE_USER_UI = preload("uid://d1bmiemb8yjfl")
var child: Node = null


func _ready() -> void:
	var project_version = ProjectSettings.get_setting("application/config/version", "")
	client_version_label.text = "Client version: " + project_version
	
	ServerConnector.server_connector_message_bus.connect(_on_message)
	
func _on_message(message):
	if "ERROR" in message:
		debugger_label.text += "\n" + "[color=red]" + message + "[/color]"
	elif "Client" in message:
		debugger_label.text += "\n" + "[color=yellow]" + message + "[/color]"
	elif "SERVER" in message:
		debugger_label.text += "\n" + "[color=green]" + message + "[/color]"
		_update_status_label(message)
	else:
		debugger_label.text += "\n" + message

func _update_status_label(message):
	if '"ok":true,"cmd":"login_user"' in message:
		status_label.text = "[color=green]" + "Successful login" + "[/color]"
	elif '"ok":false,"cmd":"login_user"' in message:
		status_label.text = "[color=red]" + "Incorrect login data" + "[/color]"

func _on_button_createuser_button_down() -> void:
	panel_main_login.visible = false
	
	child = CREATE_USER_UI.instantiate()
	add_child(child)
	
	child.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)
	
func _on_child_closed() -> void:
	panel_main_login.visible = true
	child = null


func _on_button_login_button_down() -> void:
	SignalManager.signal_LoginUser.emit(username_login_edit.text, password_login_edit.text)
