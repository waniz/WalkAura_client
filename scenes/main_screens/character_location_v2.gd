extends Control

const ACTIVITY_HERBALISM   := 1
const ACTIVITY_ALCHEMY     := 2
const ACTIVITY_HUNTING     := 3
const ACTIVITY_MINING      := 4
const ACTIVITY_WOODCUTTING := 5
const ACTIVITY_FISHING     := 6
const ACTIVITY_RIFT        := 7
const ACTIVITY_TRAVEL      := 8

const ACTIVITY_PROF_NAME := {
	ACTIVITY_HERBALISM:   "herbalism",
	ACTIVITY_ALCHEMY:     "alchemy",
	ACTIVITY_HUNTING:     "hunting",
	ACTIVITY_MINING:      "mining",
	ACTIVITY_WOODCUTTING: "woodcutting",
	ACTIVITY_FISHING:     "fishing",
	ACTIVITY_RIFT:        "rift",
}

# --- Scene References ---
@onready var location_image_panel: PanelContainer = $VBoxContainer/Location_Image_Panel
@onready var location_activities_panel: PanelContainer = $VBoxContainer/Location_Activities_Panel
@onready var activity_details_panel: PanelContainer = $VBoxContainer/Activity_Details_Panel
@onready var location_info_panel: PanelContainer = $VBoxContainer/Location_Info_Panel

@onready var location_picture: TextureRect = $VBoxContainer/Location_Image_Panel/LocationPicture
@onready var btn_stop: Button = $VBoxContainer/Location_Activities_Panel/VBoxContainer/HBoxContainer/Btn_Stop

# Activity Buttons
@onready var gathering_btb_herb: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/VBoxContainer/HBoxContainer/Gathering_Btb_Herb
@onready var gathering_btn_mining: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/VBoxContainer/HBoxContainer/Gathering_Btn_Mining
@onready var gathering_btn_woodcutting: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/VBoxContainer/HBoxContainer/Gathering_Btn_Woodcutting
@onready var gathering_btn_fishing: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/VBoxContainer/HBoxContainer/Gathering_Btn_Fishing
@onready var craft_btn_alchemy: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer/VBoxContainer/HBoxContainer/Craft_Btn_Alchemy
@onready var battle_btn_hunting: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/VBoxContainer/HBoxContainer/Battle_Btn_Hunting
@onready var battle_btn_rift: TextureButton = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/VBoxContainer/HBoxContainer/Battle_Btn_Rift

# Category outer/inner panels for styling
@onready var gathering_panel_outer: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel
@onready var gathering_panel_inner: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer
@onready var crafting_panel_outer: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel
@onready var crafting_panel_inner: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer
@onready var battle_panel_outer: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel
@onready var battle_panel_inner: PanelContainer = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer

# Section labels
@onready var label_header: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/HBoxContainer/Label
@onready var label_gathering: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/gathering_panel/PanelContainer/VBoxContainer/Label
@onready var label_crafting: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/crafting_panel/PanelContainer/VBoxContainer/Label
@onready var label_battle: Label = $VBoxContainer/Location_Activities_Panel/VBoxContainer/battle_panel/PanelContainer/VBoxContainer/Label

# Location info panel labels
@onready var location_name_label: Label = $VBoxContainer/Location_Info_Panel/MarginContainer/VBoxContainer/Location_Name_Label
@onready var location_desc_label: Label = $VBoxContainer/Location_Info_Panel/MarginContainer/VBoxContainer/Location_Desc_Label

# Activity stats panel
@onready var activity_stats_panel: PanelContainer = $VBoxContainer/Activity_Stats_Panel
@onready var stats_title_label: Label = $VBoxContainer/Activity_Stats_Panel/MarginContainer/VBoxContainer/Stats_Title_Label
@onready var stats_xp_bar: ProgressBar = $VBoxContainer/Activity_Stats_Panel/MarginContainer/VBoxContainer/Stats_XP_Bar
@onready var stats_xp_label: Label = $VBoxContainer/Activity_Stats_Panel/MarginContainer/VBoxContainer/Stats_XP_Label
@onready var stats_steps_label: Label = $VBoxContainer/Activity_Stats_Panel/MarginContainer/VBoxContainer/Stats_Steps_Label
@onready var stats_actions_label: Label = $VBoxContainer/Activity_Stats_Panel/MarginContainer/VBoxContainer/Stats_Actions_Label

var _travel_label: Label = null

# Session tracking
var _session_steps: int = 0
var _session_actions: int = 0
var _tracked_activity: int = -1
var _last_xp_into: int = 0
var _last_xp_to_next: int = 0


func _ready() -> void:
	_apply_visual_theme()

	# Create travel status label inside activity_details_panel
	_travel_label = Label.new()
	_travel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_travel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_travel_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_travel_label.add_theme_font_size_override("font_size", 16)
	_travel_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	activity_details_panel.add_child(_travel_label)

	AccountManager.signal_AccountDataReceived.connect(_on_account_data_received)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)
	_refresh()


# ==============================================================================
# VISUAL STYLING
# ==============================================================================
func _apply_visual_theme() -> void:
	# Main panels — parchment background
	Styler._apply_parchment_style(location_image_panel)
	Styler._apply_parchment_style(location_info_panel)
	Styler._apply_parchment_style(location_activities_panel)
	Styler._apply_parchment_style(activity_stats_panel)

	# Category outer panels — transparent
	for outer in [gathering_panel_outer, crafting_panel_outer, battle_panel_outer]:
		_clear_panel(outer)

	# Category inner panels — faint inventory-style card on parchment, with margins
	for inner in [gathering_panel_inner, crafting_panel_inner, battle_panel_inner]:
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
		sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		sb.content_margin_left   = 6
		sb.content_margin_right  = 6
		sb.content_margin_top    = 6
		sb.content_margin_bottom = 6
		inner.add_theme_stylebox_override("panel", sb)

	# Header label — "Location Activities:"
	label_header.label_settings = null
	label_header.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	label_header.add_theme_font_size_override("font_size", 22)
	label_header.add_theme_font_override("font", Styler.JANDA_FONT)

	# Location info labels
	location_name_label.add_theme_font_override("font", Styler.JANDA_FONT)
	location_name_label.add_theme_font_size_override("font_size", 18)
	location_name_label.add_theme_color_override("font_color", Styler.COLOR_GOLD)
	location_desc_label.add_theme_font_override("font", Styler.JANDA_FONT)
	location_desc_label.add_theme_font_size_override("font_size", 12)
	location_desc_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)

	# Section labels — compact gold header
	for lbl in [label_gathering, label_crafting, label_battle]:
		lbl.label_settings = null
		lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Styler.COLOR_GOLD)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Stop button
	Styler.style_button(btn_stop, Color.from_rgba8(180, 60, 60))

	# Stats panel labels
	stats_title_label.add_theme_font_override("font", Styler.JANDA_FONT)
	stats_title_label.add_theme_font_size_override("font_size", 16)
	stats_title_label.add_theme_color_override("font_color", Styler.COLOR_GOLD)

	Styler.style_mini_progress(stats_xp_bar, Color.from_rgba8(80, 160, 255))

	for lbl in [stats_xp_label, stats_steps_label, stats_actions_label]:
		lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)


func _clear_panel(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	panel.add_theme_stylebox_override("panel", sb)


# ==============================================================================
# LOGIC
# ==============================================================================
func _on_account_data_received(_value) -> void:
	_refresh()


func _refresh() -> void:
	# Location image
	var path := "res://assets/background/locations/location_%d.png" % Account.location
	if ResourceLoader.exists(path):
		location_picture.texture = load(path)

	# Location info panel
	location_name_label.text = ItemDB.LOCATION_NAMES.get(Account.location, "Unknown Location")
	location_desc_label.text = GameTextEn.location_descriptions.get(Account.location, "")

	# Travel in progress
	if Account.activity == ACTIVITY_TRAVEL:
		var dest_name: String = ItemDB.LOCATION_NAMES.get(Account.travel_destination, "Unknown")
		if _travel_label:
			_travel_label.text = "Travelling to %s\n(%d / %d steps)" % [
				dest_name, Account.travel_steps, Account.travel_steps_max
			]
		activity_details_panel.visible        = true
		gathering_btb_herb.visible            = false
		gathering_btn_mining.visible          = false
		gathering_btn_woodcutting.visible     = false
		gathering_btn_fishing.visible         = false
		craft_btn_alchemy.visible             = false
		battle_btn_hunting.visible            = false
		battle_btn_rift.visible               = false
		btn_stop.visible                      = false
		_update_stats_panel()
		return

	activity_details_panel.visible = false
	btn_stop.visible               = true

	# Available activities from server — normalise to int to guard against JSON float keys
	var available: Array[int] = []
	if ServerParams.ACTIVITIES_SITES != null:
		var raw = ServerParams.ACTIVITIES_SITES.get(str(Account.location),
				  ServerParams.ACTIVITIES_SITES.get(Account.location, []))
		for v in raw:
			available.append(int(v))
	var show_all := available.is_empty()

	gathering_btb_herb.visible        = show_all or ACTIVITY_HERBALISM   in available
	gathering_btn_mining.visible      = show_all or ACTIVITY_MINING      in available
	gathering_btn_woodcutting.visible = show_all or ACTIVITY_WOODCUTTING in available
	gathering_btn_fishing.visible     = show_all or ACTIVITY_FISHING     in available
	craft_btn_alchemy.visible         = show_all or ACTIVITY_ALCHEMY     in available
	battle_btn_hunting.visible        = show_all or ACTIVITY_HUNTING     in available
	battle_btn_rift.visible           = show_all or ACTIVITY_RIFT        in available

	_update_stats_panel()


func _on_activity_progress(data: Dictionary) -> void:
	var d: Dictionary = data.get("data", data)
	# Reset session counters if activity changed
	if Account.activity != _tracked_activity:
		_session_steps    = 0
		_session_actions  = 0
		_tracked_activity = Account.activity
	_session_steps   += int(d.get("steps_in", 0))
	_session_actions += int(d.get("activities_completed", 0))
	_last_xp_into    = int(d.get("xp_into_level", 0))
	_last_xp_to_next = int(d.get("xp_to_next", 0))
	_update_stats_panel()


func _update_stats_panel() -> void:
	var act = Account.activity
	var is_active = act != 0 and act != ACTIVITY_TRAVEL and ACTIVITY_PROF_NAME.has(act)
	activity_stats_panel.visible = is_active
	if not is_active:
		return

	var prof = ACTIVITY_PROF_NAME[act]
	var lvl  = int(Account.get(prof + "_lvl"))
	var name = GameTextEn.activities_texts.get(act, prof.capitalize())

	stats_title_label.text = "%s — Level %d" % [name, lvl]

	if _last_xp_to_next > 0:
		stats_xp_bar.max_value = _last_xp_to_next
		stats_xp_bar.value     = _last_xp_into
		stats_xp_label.text    = "%d / %d XP to next level" % [_last_xp_into, _last_xp_to_next]
	else:
		stats_xp_bar.value  = stats_xp_bar.max_value
		stats_xp_label.text = "Max level reached"

	stats_steps_label.text   = "Session steps:   %d" % _session_steps
	stats_actions_label.text = "Actions done:    %d" % _session_actions


# --- Button Signals ---
func _on_gathering_btb_herb_pressed() -> void:
	SignalManager.signal_UserActivity.emit(ACTIVITY_HERBALISM, Account.location, "start")

func _on_gathering_btn_mining_pressed() -> void:
	SignalManager.signal_UserActivity.emit(ACTIVITY_MINING, Account.location, "start")

func _on_gathering_btn_woodcutting_pressed() -> void:
	SignalManager.signal_UserActivity.emit(ACTIVITY_WOODCUTTING, Account.location, "start")

func _on_gathering_btn_fishing_pressed() -> void:
	SignalManager.signal_UserActivity.emit(ACTIVITY_FISHING, Account.location, "start")

func _on_craft_btn_alchemy_pressed() -> void:
	SignalManager.signal_UserActivity.emit(ACTIVITY_ALCHEMY, Account.location, "start")

func _on_battle_btn_hunting_pressed() -> void:
	SignalManager.signal_UserActivity.emit(ACTIVITY_HUNTING, Account.location, "start")

func _on_battle_btn_rift_pressed() -> void:
	SignalManager.signal_ShowRift.emit()

func _on_btn_stop_pressed() -> void:
	SignalManager.signal_UserActivity.emit(Account.activity, Account.activity_site, "stop")
