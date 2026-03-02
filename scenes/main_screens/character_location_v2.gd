extends Control

# --- Scene References ---
@onready var location_image_panel: PanelContainer = $VBoxContainer/Location_Image_Panel
@onready var location_activities_panel: PanelContainer = $VBoxContainer/Location_Activities_Panel
@onready var activity_details_panel: PanelContainer = $VBoxContainer/Activity_Details_Panel

@onready var location_picture: TextureRect = $VBoxContainer/Location_Image_Panel/LocationPicture
@onready var btn_stop: Button = $VBoxContainer/Location_Activities_Panel/VBoxContainer/HBoxContainer/Btn_Stop

# Activity Buttons
@onready var gathering_btb_herb: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btb_Herb
@onready var gathering_btn_mining: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btn_Mining
@onready var gathering_btn_woodcutting: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btn_Woodcutting
@onready var gathering_btn_fishing: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Gathering_Btn_Fishing
@onready var craft_btn_alchemy: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer/HBoxContainer/Craft_Btn_Alchemy
@onready var battle_btn_hunting: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/HBoxContainer/Battle_Btn_Hunting
@onready var battle_btn_rift: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/HBoxContainer/Battle_Btn_Rift

# Category outer/inner panels for styling
@onready var gathering_panel_outer: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel
@onready var gathering_panel_inner: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer
@onready var crafting_panel_outer: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel
@onready var crafting_panel_inner: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer
@onready var battle_panel_outer: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel
@onready var battle_panel_inner: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer

# Section labels
@onready var label_header: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/HBoxContainer/Label
@onready var label_gathering: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/HBoxContainer/Label
@onready var label_crafting: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer/HBoxContainer/Label
@onready var label_battle: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/HBoxContainer/Label


func _ready() -> void:
	_apply_visual_theme()
	_update_activity_visibility()

	var loc_id = Account.location
	var path = "res://assets/background/locations/location_%d.png" % loc_id
	if ResourceLoader.exists(path):
		location_picture.texture = load(path)


# ==============================================================================
# VISUAL STYLING
# ==============================================================================
func _apply_visual_theme() -> void:
	var COL_BG          := Color.from_rgba8(16,  18,  24,  240)
	var COL_BORDER      := Color.from_rgba8(255, 200, 66,  160)
	var COL_CARD_BG     := Color.from_rgba8(26,  28,  36,  255)
	var COL_CARD_BORDER := Color.from_rgba8(180, 140, 60,  150)

	# Main panels
	Styler.style_panel_no_margins(location_image_panel,    COL_BG, COL_BORDER)
	Styler.style_panel_no_margins(location_activities_panel, COL_BG, COL_BORDER)

	# Category outer panels — transparent so the dark main panel shows through
	for outer in [gathering_panel_outer, crafting_panel_outer, battle_panel_outer]:
		_clear_panel(outer)

	# Category inner panels — dark card style matching rift cards
	for inner in [gathering_panel_inner, crafting_panel_inner, battle_panel_inner]:
		Styler.style_panel_no_margins(inner, COL_CARD_BG, COL_CARD_BORDER)

	# Section labels
	Styler.style_title(label_header)
	Styler.style_name_label(label_gathering, Color.from_rgba8(255, 200, 66))
	Styler.style_name_label(label_crafting,  Color.from_rgba8(255, 200, 66))
	Styler.style_name_label(label_battle,    Color.from_rgba8(255, 200, 66))

	# Stop button
	Styler.style_button(btn_stop, Color.from_rgba8(180, 60, 60))


func _clear_panel(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	panel.add_theme_stylebox_override("panel", sb)


# ==============================================================================
# LOGIC
# ==============================================================================
func _update_activity_visibility() -> void:
	gathering_btb_herb.visible        = true
	craft_btn_alchemy.visible         = true
	battle_btn_hunting.visible        = true
	battle_btn_rift.visible           = true
	gathering_btn_mining.visible      = true
	gathering_btn_woodcutting.visible = true
	gathering_btn_fishing.visible     = true


# --- Button Signals ---
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

func _on_battle_btn_rift_pressed() -> void:
	SignalManager.signal_ShowRift.emit()

func _on_btn_stop_pressed() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "stop")
