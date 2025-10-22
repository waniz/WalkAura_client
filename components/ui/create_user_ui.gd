class_name CreateUserUI extends Control

@onready var username_edit: LineEdit = $Panel_create_user/VBoxContainer/HBoxContainer/usernameEdit
@onready var password_edit: LineEdit = $Panel_create_user/VBoxContainer/HBoxContainer2/passwordEdit
@onready var panel_create_user: Panel = $Panel_create_user
@onready var username_label: Label = $Panel_create_user/VBoxContainer/HBoxContainer/usernameLabel
@onready var password_label: Label = $Panel_create_user/VBoxContainer/HBoxContainer2/passwordLabel
@onready var button_createuser: Button = $Panel_create_user/button_createuser
@onready var close: Button = $Panel_create_user/close
@onready var rich_text_label: Label = $Panel_create_user/RichTextLabel


func _ready() -> void:
	Styler.style_name_label(rich_text_label, Color.from_rgba8(255, 215, 128))
	
	Styler.style_button(button_createuser,  Color.from_rgba8(64,180,255))   # cyan (primary)
	Styler.style_button(close, Color.from_rgba8(255,200,66)) # gold (secondary)
	Styler.wire_button_anim(button_createuser)
	Styler.wire_button_anim(close)
	
	Styler.style_line_edit(username_edit,)
	Styler.style_line_edit(password_edit, true)
	
	Styler.style_title(username_label)
	Styler.style_title(password_label)
	
	Styler.style_panel(panel_create_user, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))

func _on_button_createuser_button_down() -> void:
	SignalManager.signal_CreateUser.emit(username_edit.text, password_edit.text)
	
	queue_free()


func _on_close_button_down() -> void:	
	queue_free()
