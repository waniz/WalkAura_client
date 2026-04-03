extends Control

const ACTIVITY_HERBALISM   = 1
const ACTIVITY_ALCHEMY     = 2
const ACTIVITY_HUNTING     = 3
const ACTIVITY_MINING      = 4
const ACTIVITY_WOODCUTTING = 5
const ACTIVITY_FISHING     = 6
const ACTIVITY_RIFT        = 7
const ACTIVITY_TRAVEL      = 8

const ACTIVITY_PROF_NAME = {
	ACTIVITY_HERBALISM:   "herbalism",
	ACTIVITY_ALCHEMY:     "alchemy",
	ACTIVITY_HUNTING:     "hunting",
	ACTIVITY_MINING:      "mining",
	ACTIVITY_WOODCUTTING: "woodcutting",
	ACTIVITY_FISHING:     "fishing",
	ACTIVITY_RIFT:        "rift",
}

const CONFIRMATION_DIALOG = preload("res://scenes/secondary_scenes/confirmation_dialog.tscn")
var _confirm_dialog: Control = null

# --- Scene References ---
@onready var main_panel: PanelContainer = $VBoxContainer/Main_Panel
@onready var location_title: Label = $VBoxContainer/Main_Panel/ScrollContainer/Content_VBox/Info_Margin/Info_VBox/Location_Title
@onready var image_frame: PanelContainer = $VBoxContainer/Main_Panel/ScrollContainer/Content_VBox/Image_Frame
@onready var location_picture: TextureRect = $VBoxContainer/Main_Panel/ScrollContainer/Content_VBox/Image_Frame/LocationPicture
@onready var location_desc: Label = $VBoxContainer/Main_Panel/ScrollContainer/Content_VBox/Info_Margin/Info_VBox/Location_Desc
@onready var activities_header: Label = $VBoxContainer/Main_Panel/ScrollContainer/Content_VBox/Activities_Margin/Activities_VBox_Wrapper/Activities_Header
@onready var activities_vbox: VBoxContainer = $VBoxContainer/Main_Panel/ScrollContainer/Content_VBox/Activities_Margin/Activities_VBox_Wrapper/Activities_VBox

@onready var status_panel: PanelContainer = $VBoxContainer/Status_Panel
@onready var status_title: Label = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Status_Title
@onready var status_xp_bar: ProgressBar = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Status_XP_Bar
@onready var status_xp_label: Label = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Status_XP_Label
@onready var status_steps_label: Label = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Status_Steps_Label
@onready var status_actions_label: Label = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Status_Actions_Label
@onready var status_progress_label: Label = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Status_Progress_Label
@onready var btn_stop: Button = $VBoxContainer/Status_Panel/MarginContainer/Status_VBox/Btn_Stop

var ACTIVITY_TOTAL_TO_LEVEL = {1: 0}

# Session tracking (client-side fallback)
var _session_steps: int = 0
var _session_actions: int = 0
var _session_xp_gained: int = 0
var _tracked_activity: int = -1
var _last_xp_into: int = 0
var _last_xp_to_next: int = 0

# Track activity card nodes for highlighting
var _activity_cards: Dictionary = {}
var _last_built_location: int = -1


func _ready() -> void:
	$VBoxContainer.offset_top = Styler.content_top
	$VBoxContainer.offset_bottom = Styler.content_bottom

	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS
	_apply_visual_theme()

	btn_stop.pressed.connect(_on_btn_stop_pressed)
	AccountManager.signal_AccountDataReceived.connect(_on_account_data_received)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)
	_refresh()


# ==============================================================================
# VISUAL STYLING
# ==============================================================================
func _apply_visual_theme() -> void:
	Styler._apply_parchment_style(main_panel)
	Styler._apply_parchment_style(status_panel)

	# Image frame border
	var img_sb = StyleBoxFlat.new()
	img_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.04)
	img_sb.border_color = Color(0.0, 0.0, 0.0, 0.25)
	img_sb.set_border_width_all(1)
	img_sb.set_corner_radius_all(4)
	image_frame.add_theme_stylebox_override("panel", img_sb)

	# Location title
	location_title.add_theme_font_override("font", Styler.JANDA_FONT)
	location_title.add_theme_font_size_override("font_size", 18)
	location_title.add_theme_color_override("font_color", Styler.COLOR_GOLD)

	# Location description
	location_desc.add_theme_font_override("font", Styler.QUADRAT_FONT)
	location_desc.add_theme_font_size_override("font_size", 14)
	location_desc.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)

	# Activities header
	activities_header.add_theme_font_override("font", Styler.JANDA_FONT)
	activities_header.add_theme_font_size_override("font_size", 16)
	activities_header.add_theme_color_override("font_color", Styler.COLOR_GOLD)

	# Status panel labels
	status_title.add_theme_font_override("font", Styler.JANDA_FONT)
	status_title.add_theme_font_size_override("font_size", 16)
	status_title.add_theme_color_override("font_color", Styler.COLOR_GOLD)

	Styler.style_mini_progress(status_xp_bar, Color.from_rgba8(80, 160, 255))

	for lbl in [status_xp_label, status_steps_label, status_actions_label, status_progress_label]:
		lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)

	# Stop button
	Styler.style_button(btn_stop, Color.from_rgba8(180, 60, 60))


# ==============================================================================
# LOGIC
# ==============================================================================
func _on_account_data_received(_value) -> void:
	_refresh()


func _refresh() -> void:
	var loc = int(Account.location)

	# Only rebuild cards + location visuals when the location actually changes
	if loc != _last_built_location:
		_last_built_location = loc

		var path = "res://assets/background/locations/location_%d.png" % loc
		if ResourceLoader.exists(path):
			location_picture.texture = load(path)

		location_title.text = ItemDB.LOCATION_NAMES.get(loc, "Unknown Location")
		location_desc.text = GameTextEn.location_descriptions.get(loc, "")

		_build_activity_cards()

	_update_status_panel()


func _build_activity_cards() -> void:
	# Clear existing
	for child in activities_vbox.get_children():
		child.queue_free()
	_activity_cards.clear()

	# Get available activities for current location (new format: array of dicts)
	var site_entries: Array = []
	if ServerParams.ACTIVITIES_SITES != null:
		var raw = ServerParams.ACTIVITIES_SITES.get(str(Account.location),
				  ServerParams.ACTIVITIES_SITES.get(Account.location, []))
		for v in raw:
			site_entries.append(v)

	if site_entries.is_empty():
		return

	# Separate into gathering and battle groups
	var gathering_ids: Array = []
	if ServerParams.GATHERING_ACTIVITIES != null:
		for v in ServerParams.GATHERING_ACTIVITIES:
			gathering_ids.append(int(v))
	var battle_ids: Array = []
	if ServerParams.BATTLE_ACTIVITIES != null:
		for v in ServerParams.BATTLE_ACTIVITIES:
			battle_ids.append(int(v))

	var gathering_entries: Array = []
	var battle_entries: Array = []
	for entry in site_entries:
		var act_id = int(entry["id"])
		if act_id in gathering_ids:
			gathering_entries.append(entry)
		elif act_id in battle_ids:
			battle_entries.append(entry)

	# Two-column layout: gathering (left) | battle (right)
	var columns = HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 8)
	activities_vbox.add_child(columns)

	var groups = [
		{"name": "Gathering", "entries": gathering_entries},
		{"name": "Battle", "entries": battle_entries},
	]
	for group in groups:
		var col_vbox = VBoxContainer.new()
		col_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_vbox.add_theme_constant_override("separation", 4)
		columns.add_child(col_vbox)

		# Column header
		var grp_lbl = Label.new()
		grp_lbl.text = group.name.to_upper()
		grp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grp_lbl.add_theme_color_override("font_color", Styler.COLOR_GOLD)
		grp_lbl.add_theme_font_size_override("font_size", 14)
		grp_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		col_vbox.add_child(grp_lbl)

		if group.entries.is_empty():
			var empty_lbl = Label.new()
			empty_lbl.text = "—"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			col_vbox.add_child(empty_lbl)
		else:
			for entry in group.entries:
				var card = _make_activity_card(entry)
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				col_vbox.add_child(card)
				_activity_cards[int(entry["id"])] = card

	_highlight_active_card()


func _make_activity_card(entry: Dictionary) -> PanelContainer:
	var activity_id = int(entry["id"])
	var activity_name: String = entry.get("name", "")
	var profession: String = entry.get("profession", "")

	# Card container
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 44)
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	card_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(5)
	card_sb.content_margin_left = 8
	card_sb.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", card_sb)
	panel.set_meta("sb", card_sb)

	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_hbox)

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = ItemDB.get_icon(profession)
	main_hbox.add_child(icon)

	# Activity name (left-aligned)
	var n_lbl = Label.new()
	n_lbl.text = activity_name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	n_lbl.add_theme_font_size_override("font_size", 16)
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	main_hbox.add_child(n_lbl)

	# Connect click
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_activity_card_clicked(activity_id)
	)

	return panel


func _on_activity_card_clicked(activity_id: int) -> void:
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	var activity_name: String = GameTextEn.activities_texts.get(activity_id, "Activity")
	var text: String
	if activity_id == ACTIVITY_RIFT:
		# Rift browser opens without changing the current activity;
		# the actual activity switch happens when the player clicks ENTER RIFT
		SignalManager.signal_ShowRift.emit()
		return
	if Account.activity:
		var current_name: String = GameTextEn.activities_texts.get(Account.activity, "Activity")
		text = "Stop %s and Start %s?" % [current_name, activity_name]
	else:
		text = "Start %s?" % activity_name
	_confirm_dialog = CONFIRMATION_DIALOG.instantiate()
	_confirm_dialog.setup(text)
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		SignalManager.signal_UserActivity.emit(activity_id, Account.location, "start")
	)
	_confirm_dialog.tree_exited.connect(func(): _confirm_dialog = null, CONNECT_ONE_SHOT)


func _highlight_active_card() -> void:
	for act_id in _activity_cards:
		var card: PanelContainer = _activity_cards[act_id]
		var sb: StyleBoxFlat = card.get_meta("sb") as StyleBoxFlat
		if act_id == Account.activity:
			sb.bg_color     = Color(0.8, 0.6, 0.0, 0.15)
			sb.border_color = Styler.COLOR_GOLD
			sb.set_border_width_all(2)
		else:
			sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
			sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
			sb.set_border_width_all(1)


func _on_activity_progress(data: Dictionary) -> void:
	var raw = data.get("data", data)
	var d: Dictionary = raw.get("data", raw)

	# Prefer server-side session data, fall back to client-side accumulation
	if d.has("session_steps"):
		_session_steps = int(d["session_steps"])
		_session_actions = int(d.get("session_actions", 0))
		_session_xp_gained = int(d.get("session_xp_gained", 0))
	else:
		# Reset session counters if activity changed
		if Account.activity != _tracked_activity:
			_session_steps = 0
			_session_actions = 0
			_session_xp_gained = 0
			_tracked_activity = Account.activity
		_session_steps += int(d.get("steps_in", 0))
		_session_actions += int(d.get("activities_completed", 0))
		_session_xp_gained += int(d.get("xp_gained", 0))

	_last_xp_into = int(d.get("xp_into_level", 0))
	_last_xp_to_next = int(d.get("xp_to_next", 0))
	_update_status_panel()


func _update_status_panel() -> void:
	var act = Account.activity
	_highlight_active_card()

	# Reset session counters when activity changes (stop/start)
	if act != _tracked_activity:
		_session_steps = 0
		_session_actions = 0
		_session_xp_gained = 0
		_last_xp_into = 0
		_last_xp_to_next = 0
		_tracked_activity = act

	# Travel state
	if act == ACTIVITY_TRAVEL:
		status_panel.visible = true
		var dest_name: String = ItemDB.LOCATION_NAMES.get(Account.travel_destination, "Unknown")
		status_title.text = "Travelling to %s" % dest_name

		if Account.travel_steps_max > 0:
			status_xp_bar.max_value = Account.travel_steps_max
			status_xp_bar.value = Account.travel_steps
			var pct = int(round(float(Account.travel_steps) / float(Account.travel_steps_max) * 100.0))
			status_xp_label.text = "%d / %d steps (%d%%)" % [Account.travel_steps, Account.travel_steps_max, pct]
		else:
			status_xp_bar.value = 0
			status_xp_label.text = ""

		status_steps_label.text = ""
		status_actions_label.text = ""
		status_progress_label.text = ""
		btn_stop.visible = true
		return

	# Active activity state
	var is_active = act != 0 and ACTIVITY_PROF_NAME.has(act)
	status_panel.visible = is_active
	if not is_active:
		return

	var prof = ACTIVITY_PROF_NAME[act]
	var lvl = int(Account.get(prof + "_lvl"))

	# Look up the location-specific activity name, fall back to generic
	var display_name: String = _find_activity_name(act)
	if display_name.is_empty():
		display_name = GameTextEn.activities_texts.get(act, prof.capitalize())

	status_title.text = "%s — Level %d" % [display_name, lvl]

	# Use last activity progress data, or compute from account profession XP
	var xp_into = _last_xp_into
	var xp_to_next = _last_xp_to_next
	if xp_to_next <= 0:
		var total_xp = int(Account.get(prof + "_xp"))
		var floor_xp: int = ACTIVITY_TOTAL_TO_LEVEL.get(str(lvl), total_xp)
		var next_xp: int = ACTIVITY_TOTAL_TO_LEVEL.get(str(lvl + 1), -1)
		if next_xp >= 0:
			xp_into = total_xp - floor_xp
			xp_to_next = next_xp - floor_xp

	if xp_to_next > 0:
		status_xp_bar.max_value = xp_to_next
		status_xp_bar.value = xp_into
		var pct = int(round(float(xp_into) / float(xp_to_next) * 100.0))
		status_xp_label.text = "%d / %d XP (%d%%)" % [xp_into, xp_to_next, pct]
	else:
		status_xp_bar.value = status_xp_bar.max_value
		status_xp_label.text = "Max level reached"

	status_steps_label.text = "Session steps:   %d" % _session_steps
	status_actions_label.text = "Actions done:    %d" % _session_actions
	status_progress_label.text = "XP gained:       %d" % _session_xp_gained
	btn_stop.visible = true


func _find_activity_name(activity_id: int) -> String:
	if ServerParams.ACTIVITIES_SITES == null:
		return ""
	var raw = ServerParams.ACTIVITIES_SITES.get(str(Account.location),
			  ServerParams.ACTIVITIES_SITES.get(Account.location, []))
	for entry in raw:
		if int(entry["id"]) == activity_id:
			return entry.get("name", "")
	return ""


func _on_btn_stop_pressed() -> void:
	if Account.activity == ACTIVITY_TRAVEL:
		# Stop travel — reset travel state by sending stop for travel activity
		SignalManager.signal_UserActivity.emit(ACTIVITY_TRAVEL, Account.activity_site, "stop")
	else:
		SignalManager.signal_UserActivity.emit(Account.activity, Account.activity_site, "stop")
