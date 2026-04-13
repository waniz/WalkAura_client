extends Control

const ACTIVITY_HERBALISM = 1
const ACTIVITY_ALCHEMY = 2
const ACTIVITY_HUNTING = 3
const ACTIVITY_MINING = 4
const ACTIVITY_WOODCUTTING = 5
const ACTIVITY_FISHING = 6
const ACTIVITY_RIFT = 7
const ACTIVITY_TRAVEL = 8

const ACTIVITY_PROF_NAME = {
	ACTIVITY_HERBALISM: "herbalism",
	ACTIVITY_ALCHEMY: "alchemy",
	ACTIVITY_HUNTING: "hunting",
	ACTIVITY_MINING: "mining",
	ACTIVITY_WOODCUTTING: "woodcutting",
	ACTIVITY_FISHING: "fishing",
	ACTIVITY_RIFT: "rift",
}

const ACTIVITY_CONFIRM_DIALOG = preload("res://scenes/secondary_scenes/activity_confirm_dialog.tscn")


# --- UI Nodes ---
@onready var _vbox = %VBox
@onready var _bg_container = %BackgroundContainer
@onready var _bg_rect = %BackgroundRect
@onready var _status_panel = %StatusPanel
@onready var _status_title = %StatusTitle
@onready var _status_xp_bar = %StatusXPBar
@onready var _status_xp_label = %StatusXPLabel
@onready var _status_steps_label = %StatusStepsLabel
@onready var _status_actions_label = %StatusActionsLabel
@onready var _status_progress_label = %StatusProgressLabel
@onready var _btn_stop = %BtnStop

# --- State ---
var _confirm_dialog: Control = null
var _marker_panels: Array = []   # Array of {panel, activity_id, sb}
var ACTIVITY_TOTAL_TO_LEVEL = {1: 0}

var _session_steps: int = 0
var _session_actions: int = 0
var _session_xp_gained: int = 0
var _tracked_activity: int = -1
var _last_xp_into: int = 0
var _last_xp_to_next: int = 0
var _last_built_location: int = -1


func _ready() -> void:
	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS

	_vbox.offset_top = Styler.content_top
	_vbox.offset_right = size.x
	_vbox.offset_bottom = Styler.content_bottom

	_btn_stop.pressed.connect(_on_btn_stop_pressed)
	_bg_container.resized.connect(_reposition_markers)

	_apply_visual_theme()

	AccountManager.signal_AccountDataReceived.connect(_on_account_data)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)

	_load_location(int(Account.location))
	_update_status_panel()


# ==============================================================================
# VISUAL THEME
# ==============================================================================

func _apply_visual_theme() -> void:
	_status_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_status_panel.custom_minimum_size.x = size.x / 3.0
	Styler._apply_parchment_style(_status_panel)

	_status_title.add_theme_font_override("font", Styler.JANDA_FONT)
	_status_title.add_theme_font_size_override("font_size", 16)
	_status_title.add_theme_color_override("font_color", Color(0.13, 0.37, 0.13))

	Styler.style_mini_progress(_status_xp_bar, Color.from_rgba8(80, 160, 255))

	for lbl in [_status_xp_label, _status_steps_label, _status_actions_label, _status_progress_label]:
		lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)

	Styler.style_button(_btn_stop, Color.from_rgba8(180, 60, 60))


# ==============================================================================
# LOCATION / MARKERS
# ==============================================================================

func _resolve_activity_icon(act: Dictionary) -> String:
	# Try activity-specific icon first, fall back to profession icon
	var activity_name: String = act.get("name", "").to_lower().replace(" ", "_")
	var activity_path: String = "res://assets/general_icons/activities/%s.png" % activity_name
	if ResourceLoader.exists(activity_path):
		return activity_path
	return "res://assets/general_icons/professions/%s.png" % act.get("profession", "")


func _load_location(location_id: int) -> void:
	if location_id == _last_built_location:
		return
	_last_built_location = location_id

	# Background — resolve from server image_id, fall back to ItemDB
	var bg_path: String = ""
	var loc_key: String = str(location_id)
	var loc_data: Dictionary = ServerParams.LOCATIONS.get(loc_key, {})
	var image_id: String = loc_data.get("image_id", "")
	if image_id != "":
		var candidate: String = "res://assets/locations/%s/background.png" % image_id
		if ResourceLoader.exists(candidate):
			bg_path = candidate
	if bg_path == "":
		bg_path = ItemDB.LOCATION_BACKGROUNDS.get(location_id, "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		_bg_rect.texture = load(bg_path)

	# Clear old markers
	for m in _marker_panels:
		if is_instance_valid(m.panel):
			m.panel.queue_free()
	_marker_panels.clear()

	# Build markers from server LOCATIONS data
	var activities: Array = loc_data.get("activities", [])
	var count: int = activities.size()
	for i in count:
		var act: Dictionary = activities[i]
		# Spread markers evenly along the bottom of the scene
		var x_pos: float = float(i + 1) / float(count + 1)
		var marker_data: Dictionary = {
			"activity_id": int(act.get("id", 0)),
			"name": act.get("name", ""),
			"profession": act.get("profession", ""),
			"req_skill": int(act.get("req_skill", 1)),
			"texture": _resolve_activity_icon(act),
			"pos": Vector2(x_pos, 0.88),
		}
		_create_marker(marker_data)


func _create_marker(data: Dictionary) -> void:
	var activity_id: int = int(data["activity_id"])
	var tex_path: String = data.get("texture", "")
	var norm_pos: Vector2 = data.get("pos", Vector2(0.5, 0.5))

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Gold border style
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.3)
	sb.border_color = Styler.COLOR_GOLD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)

	# Texture inside
	var tex_rect = TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex_path != "" and ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	panel.add_child(tex_rect)

	# Tap handler — directly start activity via confirmation dialog
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_marker_tapped(data, panel)
		elif event is InputEventScreenTouch and event.pressed:
			_on_marker_tapped(data, panel)
	)

	_bg_container.add_child(panel)
	panel.set_meta("norm_pos", norm_pos)
	_marker_panels.append({"panel": panel, "activity_id": activity_id, "sb": sb})


func _reposition_markers() -> void:
	var container_size = _bg_container.size
	if container_size == Vector2.ZERO:
		return
	for m in _marker_panels:
		var panel: PanelContainer = m.panel
		if not is_instance_valid(panel):
			continue
		var norm_pos: Vector2 = panel.get_meta("norm_pos")
		var marker_size = panel.size
		panel.position = Vector2(
			norm_pos.x * container_size.x - marker_size.x * 0.5,
			norm_pos.y * container_size.y - marker_size.y * 0.5
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if _vbox != null:
			_vbox.offset_right = size.x


func _on_marker_tapped(data: Dictionary, panel: PanelContainer) -> void:
	# Scale animation
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)

	# Start activity directly
	var activity_id = int(data.get("activity_id", 0))
	if activity_id > 0:
		_start_activity(activity_id)


func _highlight_active_marker() -> void:
	var act = Account.activity
	for m in _marker_panels:
		var sb: StyleBoxFlat = m.sb
		if m.activity_id == act:
			sb.border_color = Color(0.2, 0.8, 0.2)
			sb.shadow_color = Color(0.2, 0.8, 0.2, 0.5)
			sb.shadow_size = 6
		else:
			sb.border_color = Styler.COLOR_GOLD
			sb.shadow_color = Color(0, 0, 0, 0)
			sb.shadow_size = 0


# ==============================================================================
# ACTIVITY LOGIC (adapted from character_location.gd)
# ==============================================================================

func _start_activity(activity_id: int) -> void:
	if activity_id == Account.activity:
		return
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	if activity_id == ACTIVITY_RIFT:
		SignalManager.signal_ShowRift.emit()
		return
	var new_name = GameTextEn.activities_texts.get(activity_id, "Activity")
	var current_name = ""
	if Account.activity:
		current_name = GameTextEn.activities_texts.get(Account.activity, "Activity")
	var profession = ACTIVITY_PROF_NAME.get(activity_id, "")
	_confirm_dialog = ACTIVITY_CONFIRM_DIALOG.instantiate()
	_confirm_dialog.setup(current_name, new_name, activity_id, profession)
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		SignalManager.signal_UserActivity.emit(activity_id, Account.location, "start")
	)
	_confirm_dialog.tree_exited.connect(func(): _confirm_dialog = null, CONNECT_ONE_SHOT)


func _on_btn_stop_pressed() -> void:
	if Account.activity == ACTIVITY_TRAVEL:
		SignalManager.signal_UserActivity.emit(ACTIVITY_TRAVEL, Account.activity_site, "stop")
	else:
		SignalManager.signal_UserActivity.emit(Account.activity, Account.activity_site, "stop")


# ==============================================================================
# STATUS PANEL (adapted from character_location.gd)
# ==============================================================================

func _on_account_data(_value) -> void:
	var loc = int(Account.location)
	if loc != _last_built_location:
		_load_location(loc)
	_update_status_panel()


func _on_activity_progress(data: Dictionary) -> void:
	var raw = data.get("data", data)
	var d: Dictionary = raw.get("data", raw)

	if d.has("session_steps"):
		_session_steps = int(d["session_steps"])
		_session_actions = int(d.get("session_actions", 0))
		_session_xp_gained = int(d.get("session_xp_gained", 0))
	else:
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

	if act != _tracked_activity:
		_session_steps = 0
		_session_actions = 0
		_session_xp_gained = 0
		_last_xp_into = 0
		_last_xp_to_next = 0
		_tracked_activity = act

	_highlight_active_marker()

	# Travel state
	if act == ACTIVITY_TRAVEL:
		_status_panel.visible = true
		var dest_name: String = ItemDB.LOCATION_NAMES.get(Account.travel_destination, "Unknown")
		_status_title.text = "Travelling to %s" % dest_name
		if Account.travel_steps_max > 0:
			_status_xp_bar.max_value = Account.travel_steps_max
			_status_xp_bar.value = Account.travel_steps
			var pct = int(round(float(Account.travel_steps) / float(Account.travel_steps_max) * 100.0))
			_status_xp_label.text = "%d / %d steps (%d%%)" % [Account.travel_steps, Account.travel_steps_max, pct]
		else:
			_status_xp_bar.value = 0
			_status_xp_label.text = ""
		_status_steps_label.text = ""
		_status_actions_label.text = ""
		_status_progress_label.text = ""
		_btn_stop.visible = true
		return

	# Active activity
	var is_active = act != 0 and ACTIVITY_PROF_NAME.has(act)
	_status_panel.visible = is_active
	if not is_active:
		return

	var prof = ACTIVITY_PROF_NAME[act]
	var lvl = int(Account.get(prof + "_lvl"))
	var display_name: String = GameTextEn.activities_texts.get(act, prof.capitalize())
	_status_title.text = "%s — Level %d" % [display_name, lvl]

	if _last_xp_to_next > 0:
		_status_xp_bar.visible = true
		_status_xp_bar.max_value = _last_xp_to_next
		_status_xp_bar.value = _last_xp_into
		var pct = int(round(float(_last_xp_into) / float(_last_xp_to_next) * 100.0))
		_status_xp_label.text = "%d / %d XP (%d%%)" % [_last_xp_into, _last_xp_to_next, pct]
	else:
		_status_xp_bar.visible = false
		_status_xp_label.text = ""

	_status_steps_label.text = "Session steps:   %d" % _session_steps
	_status_actions_label.text = "Actions done:    %d" % _session_actions
	_status_progress_label.text = "XP gained:       %d" % _session_xp_gained
	_btn_stop.visible = true
