extends Control

@onready var location_picture: TextureRect = $LocationDescPanel/LocationPicture
@onready var location_text: RichTextLabel = $LocationDescPanel/LocationText


func _ready() -> void:
	#AccountManager.signal_AccountDataReceived.connect(_update_character_data)

	var account_location = int(Account.location)
	var texture = load("res://assets/background/locations/location_{0}.png".format([account_location])) as Texture2D 

	location_picture.texture = texture
	location_text.text = GameTextEn.location_texts[account_location]


func _on_start_button_button_down() -> void:
	print("calling activity")
	SignalManager.signal_UserActivity.emit("herbalist", "start")
