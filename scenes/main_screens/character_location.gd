extends Control

@onready var location_desc_panel: Panel = $LocationDescPanel
@onready var activities_panel: Panel = $ActivitiesPanel
@onready var activites_label: Label = $ActivitiesPanel/ActivitesLabel

@onready var location_picture: TextureRect = $LocationDescPanel/LocationPicture
@onready var location_name: Label = $LocationDescPanel/LocationName
@onready var location_desc: Label = $LocationDescPanel/LocationDesc

@onready var prof_panel: Panel = $ProfPanel
@onready var title_label: Label = $ProfPanel/TitleLabel

@onready var herbalism_label: Label = $ProfPanel/TitleLabel/HBoxHerbalism/HerbalismLabel
@onready var herbalism_start_button: Button = $ProfPanel/TitleLabel/HBoxHerbalism/HerbalismStartButton
@onready var herbalism_end_button: Button = $ProfPanel/TitleLabel/HBoxHerbalism/HerbalismEndButton

@onready var alchemy_label: Label = $ProfPanel/TitleLabel/HBoxAlchemy/AlchemyLabel
@onready var alchemy_start_button: Button = $ProfPanel/TitleLabel/HBoxAlchemy/AlchemyStartButton
@onready var alchemy_end_button: Button = $ProfPanel/TitleLabel/HBoxAlchemy/AlchemyEndButton

var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)

func _ready() -> void:

	Styler.style_panel(location_desc_panel, COL_PANEL_BG, COL_PANEL_BR)
	Styler.style_panel(activities_panel, COL_PANEL_BG, COL_PANEL_BR)
	Styler.style_panel(prof_panel, COL_PANEL_BG, COL_PANEL_BR)
	
	Styler.style_title(activites_label)
	Styler.style_title(location_name)
	Styler.style_title(location_desc)
	Styler.style_title(title_label)
	
	Styler.style_title(herbalism_label)
	Styler.style_title(alchemy_label)
	
	Styler.style_button(herbalism_start_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(herbalism_end_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(alchemy_start_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(alchemy_end_button,  Color.from_rgba8(64,180,255))

	var account_location = int(Account.location)
	var texture = load("res://assets/background/locations/location_{0}.png".format([account_location])) as Texture2D 

	location_picture.texture = texture
	location_name.text = GameTextEn.location_texts[account_location]
	location_desc.text = GameTextEn.location_descriptions[account_location]


func _on_texture_button_button_down() -> void:
	prof_panel.visible = true


func _on_herbalism_start_button_pressed() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "start")


func _on_herbalism_end_button_pressed() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "stop")


func _on_alchemy_start_button_pressed() -> void:
	SignalManager.signal_UserActivity.emit(2, 1, "start")


func _on_alchemy_end_button_pressed() -> void:
	SignalManager.signal_UserActivity.emit(2, 1, "stop")
