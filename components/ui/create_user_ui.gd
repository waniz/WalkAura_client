class_name CreateUserUI extends Control

@onready var username_edit: TextEdit = $Panel_create_user/VBoxContainer/HBoxContainer/usernameEdit
@onready var password_edit: LineEdit = $Panel_create_user/VBoxContainer/HBoxContainer2/passwordEdit


func _on_button_createuser_button_down() -> void:
	SignalManager.signal_CreateUser.emit(username_edit.text, password_edit.text)
	
	queue_free()


func _on_close_button_down() -> void:	
	queue_free()
