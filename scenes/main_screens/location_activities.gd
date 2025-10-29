extends Control

@onready var location_desc_panel: Panel = $LocationDescPanel
@onready var activities_panel: Panel = $ActivitiesPanel
@onready var activites_label: Label = $ActivitiesPanel/ActivitesLabel

@onready var location_picture: TextureRect = $LocationDescPanel/LocationPicture
@onready var location_name: Label = $LocationDescPanel/LocationName
@onready var location_desc: Label = $LocationDescPanel/LocationDesc

@onready var prof_panel: Panel = $ProfPanel
@onready var prof_name_label: Label = $ProfPanel/ProfNameLabel
@onready var title_label: Label = $ProfPanel/TitleLabel
@onready var start_button: Button = $ProfPanel/StartButton
@onready var end_button: Button = $ProfPanel/EndButton


var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)

func _ready() -> void:

	Styler.style_panel(location_desc_panel, COL_PANEL_BG, COL_PANEL_BR)
	Styler.style_panel(activities_panel, COL_PANEL_BG, COL_PANEL_BR)
	Styler.style_panel(prof_panel, COL_PANEL_BG, COL_PANEL_BR)
	
	Styler.style_title(activites_label)
	Styler.style_title(location_name)
	Styler.style_title(location_desc)
	Styler.style_title(prof_name_label)
	Styler.style_title(title_label)
	
	Styler.style_button(start_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(end_button,  Color.from_rgba8(64,180,255))

	var account_location = int(Account.location)
	var texture = load("res://assets/background/locations/location_{0}.png".format([account_location])) as Texture2D 

	location_picture.texture = texture
	location_name.text = GameTextEn.location_texts[account_location]
	location_desc.text = GameTextEn.location_descriptions[account_location]


func _on_start_button_button_down() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "start")

func _on_texture_button_button_down() -> void:
	prof_panel.visible = true


func _on_end_button_button_down() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "stop")
