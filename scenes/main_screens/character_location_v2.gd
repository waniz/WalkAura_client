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

# --- Visual Theme Constants ---
const COLOR_PARCHMENT = Color(0.95, 0.92, 0.84, 1.0) # Beige Background
const COLOR_TEXT_DARK = Color(0.1, 0.1, 0.1, 1.0)    # Dark Ink Text
const COLOR_BORDER    = Color(0.2, 0.2, 0.2, 1.0)    # Dark Border

func _ready() -> void:
	# 1. Update Visuals
	_apply_visual_theme()
	
	# 2. Check Available Activities
	_update_activity_visibility()

	# 3. Load Location Image
	# Use a safer check in case Account.location is missing or null
	var loc_id = Account.location
	var path = "res://assets/background/locations/location_%d.png" % loc_id
	
	if ResourceLoader.exists(path):
		location_picture.texture = load(path)
	else:
		print("Warning: Location image not found at ", path)
		# Optional: Set a fallback image
		# location_picture.texture = load("res://assets/background/locations/default.png")

# ==============================================================================
# VISUAL STYLING
# ==============================================================================
func _apply_visual_theme() -> void:
	# Apply Parchment Background using LOCAL function
	_apply_parchment_style(location_image_panel)
	_apply_parchment_style(location_activities_panel)
	_apply_parchment_style(activity_details_panel)
	
	# Style the Stop button
	if "style_button" in Styler:
		Styler.style_button(btn_stop, Color(0.8, 0.3, 0.3)) # Reddish
	else:
		# Fallback if Styler singleton is missing
		btn_stop.modulate = Color(0.8, 0.3, 0.3)
	
	# Recursively find all Labels and make them Dark
	_style_labels_recursively(self)

func _apply_parchment_style(panel: PanelContainer) -> void:
	if not panel: return
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = COLOR_PARCHMENT
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = COLOR_BORDER
	sb.set_corner_radius_all(4)
	sb.shadow_size = 4
	sb.shadow_color = Color(0,0,0,0.3)
	
	panel.add_theme_stylebox_override("panel", sb)

func _style_labels_recursively(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		# Optional: Add font override if available
		# if "GROBOLT_FONT" in Styler:
		# 	node.add_theme_font_override("font", Styler.GROBOLT_FONT)
		
	for child in node.get_children():
		_style_labels_recursively(child)

# ==============================================================================
# LOGIC
# ==============================================================================
func _update_activity_visibility() -> void:
	# Safely get location key
	var loc_key = Account.location
	
	# Check if ServerParams has the data
	var sites = []
	if "ACTIVITIES_SITES" in ServerParams and ServerParams.ACTIVITIES_SITES.has(loc_key):
		sites = ServerParams.ACTIVITIES_SITES[loc_key]
	
	# Default to hidden if data missing
	#gathering_btb_herb.visible        = (1.0 in sites)
	#craft_btn_alchemy.visible         = (2.0 in sites)
	#battle_btn_hunting.visible        = (3.0 in sites)
	#gathering_btn_mining.visible      = (4.0 in sites)
	#gathering_btn_woodcutting.visible = (5.0 in sites)
	#gathering_btn_fishing.visible     = (6.0 in sites)
	
	gathering_btb_herb.visible        = true
	craft_btn_alchemy.visible         = true
	battle_btn_hunting.visible        = true
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

func _on_btn_stop_pressed() -> void:
	SignalManager.signal_UserActivity.emit(1, 1, "stop")
