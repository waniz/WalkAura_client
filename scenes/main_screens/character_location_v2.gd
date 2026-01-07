extends Control

@onready var location_image_panel: PanelContainer = $VBoxContainer/Location_Image_Panel
@onready var location_activities_panel: PanelContainer = $VBoxContainer/Location_Activities_Panel
@onready var activity_details_panel: PanelContainer = $VBoxContainer/Activity_Details_Panel

@onready var location_picture: TextureRect = $VBoxContainer/Location_Image_Panel/LocationPicture
@onready var btn_stop: Button = $VBoxContainer/Location_Activities_Panel/VBoxContainer/HBoxContainer/Btn_Stop

@onready var gathering_btb_herb: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btb_Herb
@onready var gathering_btn_mining: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btn_Mining
@onready var gathering_btn_woodcutting: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btn_Woodcutting
@onready var gathering_btn_fishing: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btn_Fishing
@onready var craft_btn_alchemy: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer/HBoxContainer/Craft_Btn_Alchemy
@onready var battle_btn_hunting: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/HBoxContainer/Battle_Btn_Hunting

var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)

func _ready() -> void:
	
	if 1.0 in ServerParams.ACTIVITIES_SITES[str(Account.location)]:
		gathering_btb_herb.visible = true
	if 2.0 in ServerParams.ACTIVITIES_SITES[str(Account.location)]:
		craft_btn_alchemy.visible = true
	if 3.0 in ServerParams.ACTIVITIES_SITES[str(Account.location)]:
		battle_btn_hunting.visible = true
	if 4.0 in ServerParams.ACTIVITIES_SITES[str(Account.location)]:
		gathering_btn_mining.visible = true
	if 5.0 in ServerParams.ACTIVITIES_SITES[str(Account.location)]:
		gathering_btn_woodcutting.visible = true
	if 6.0 in ServerParams.ACTIVITIES_SITES[str(Account.location)]:
		gathering_btn_fishing.visible = true

	Styler.style_panel(location_image_panel, Styler.COL_PANEL_GRAY, COL_PANEL_BR)
	Styler.style_panel(location_activities_panel, Styler.COL_PANEL_GRAY, COL_PANEL_BR)
	Styler.style_panel(activity_details_panel, Styler.COL_PANEL_GRAY, COL_PANEL_BR)
	
	Styler.style_button(btn_stop,  Color.from_rgba8(64,180,255))

	var account_location = int(Account.location)
	var texture = load("res://assets/background/locations/location_{0}.png".format([account_location])) as Texture2D 

	location_picture.texture = texture
	#location_name.text = GameTextEn.location_texts[account_location]
	#location_desc.text = GameTextEn.location_descriptions[account_location]

func _on_gathering_btb_herb_pressed() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "start")
	
func _on_gathering_btn_mining_pressed() -> void:
	SignalManager.signal_UserActivity.emit(4, 1, "start")

func _on_gathering_btn_woodcutting_pressed() -> void:
	SignalManager.signal_UserActivity.emit(5, 1, "start")

func _on_gathering_btn_fishing_pressed() -> void:
	SignalManager.signal_UserActivity.emit(6, 1, "start")

func _on_craft_btn_alchemy_pressed() -> void:
	SignalManager.signal_UserActivity.emit(2, 1, "start")

func _on_battle_btn_hunting_pressed() -> void:
	SignalManager.signal_UserActivity.emit(3, 1, "start")

func _on_btn_stop_pressed() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "stop")
