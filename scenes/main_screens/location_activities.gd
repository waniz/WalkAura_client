extends Control

@onready var rich_text_label: RichTextLabel = $MainParamsHolder/RichTextLabel

@onready var hp_progress_bar: ProgressBar = $MainAttrsHolder/HPProgressBar
@onready var mp_progress_bar: ProgressBar = $MainAttrsHolder/MPProgressBar
@onready var shield_progress_bar: ProgressBar = $MainAttrsHolder/ShieldProgressBar


func _ready() -> void:
	AccountManager.signal_AccountDataReceived.connect(_update_character_data)
	_update_character_data()
		
func _update_character_data(result_of_call=true):
	rich_text_label.text = "UID         : " + str(Account.user_uid) + "\n" + "UserID : " + str(Account.userid) + "\n" + "Name  :  " + str(Account.username)
	
	hp_progress_bar.max_value = Account.hp_max
	hp_progress_bar.value = Account.hp_current
	mp_progress_bar.max_value = Account.mp_max
	mp_progress_bar.value = Account.mp_current
	shield_progress_bar.max_value = Account.shield_max
	shield_progress_bar.value = Account.shield_current


func _on_start_button_button_down() -> void:
	print("calling activity")
	SignalManager.signal_UserActivity.emit("herbalist", "start")
