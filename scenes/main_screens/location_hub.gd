extends Control

const ACTIVITY_HERBALISM = 1
const ACTIVITY_ALCHEMY = 2
const ACTIVITY_HUNTING = 3
const ACTIVITY_MINING = 4
const ACTIVITY_WOODCUTTING = 5
const ACTIVITY_FISHING = 6
const ACTIVITY_RIFT = 7
const ACTIVITY_TRAVEL = 8
const ACTIVITY_ENCHANTING = 9
const ACTIVITY_BLACKSMITHING = 10

# Activities removed from the CLIENT only — server still serves them (TODO re-enable).
const HIDDEN_ACTIVITIES = [ACTIVITY_WOODCUTTING, ACTIVITY_FISHING]

const ACTIVITY_PROF_NAME = {
	ACTIVITY_HERBALISM: "herbalism",
	ACTIVITY_ALCHEMY: "alchemy",
	ACTIVITY_HUNTING: "hunting",
	ACTIVITY_MINING: "mining",
	ACTIVITY_WOODCUTTING: "woodcutting",
	ACTIVITY_FISHING: "fishing",
	ACTIVITY_RIFT: "rift",
	ACTIVITY_ENCHANTING: "enchanting",
	ACTIVITY_BLACKSMITHING: "blacksmithing",
}

const ACTIVITY_CONFIRM_DIALOG = preload("res://scenes/secondary_scenes/activity_confirm_dialog.tscn")
const QUEST_TRACKER = preload("res://scenes/support_screens/quest_tracker.gd")


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
var _activity_grid: GridContainer = null
var ACTIVITY_TOTAL_TO_LEVEL = {1: 0}

var _session_steps: int = 0
var _session_actions: int = 0
var _session_xp_gained: int = 0
var _tracked_activity: int = -1
var _last_xp_into: int = 0
var _last_xp_to_next: int = 0
var _last_built_location: int = -1
var _last_locked: bool = false
var _last_req_skill: int = 0

# --- Edge bar (Activities drawer) ---
var _edge_overlay: Control = null
var _scrim: ColorRect = null
var _rails: Control = null
var _drawer_act: PanelContainer = null
var _rail_act_stub: ColorRect = null
var _disc_act: Label = null
var _rail_act_disc: Label = null
var _act_empty: Label = null
var _act_inner: VBoxContainer = null   # scroll content (for height measurement)
var _open_order: Array = []          # ["act"], last == front
var _drawer_w: float = 280.0
var _drawer_tweens: Dictionary = {}  # id -> Tween


func _ready() -> void:
	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS

	_vbox.offset_top = Styler.content_top
	_vbox.offset_right = size.x
	_vbox.offset_bottom = Styler.content_bottom

	_btn_stop.pressed.connect(_on_btn_stop_pressed)

	_apply_visual_theme()
	_build_edge_bars()

	# Quest tracker pill at the top of the hub (hides itself when nothing is
	# tracked). Reads QuestManager.tracked_quest().
	var _tracker = QUEST_TRACKER.new()
	_vbox.add_child(_tracker)
	_vbox.move_child(_tracker, 0)

	AccountManager.signal_AccountDataReceived.connect(_on_account_data)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)

	_load_location(int(Account.location))
	_update_status_panel()


# ==============================================================================
# EDGE BAR — Activities drawer (2026-06-07)
# Activity discovery moves off the inline scroll into a single right-edge drawer.
# Closed = a thin gold vertical-text rail; open = a ~25% chrome sheet that slides
# over the painted hero with a scrim. The hub main column keeps only live state
# (quest tracker + active-activity status panel). NPCs live on the Quest screen.
# ==============================================================================

func _build_edge_bars() -> void:
	# Overlay covers the body band (between top HUD and bottom nav), full width.
	_edge_overlay = Control.new()
	_edge_overlay.name = "EdgeOverlay"
	# IGNORE (not PASS): the overlay never intercepts input, so hero drags reach
	# the parallax background underneath. Rails/drawers/scrim are STOP and still
	# receive their own taps.
	_edge_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_edge_overlay)
	# Mirror the working VBox layout: preset-0 anchors, absolute offsets.
	_edge_overlay.anchor_left = 0.0
	_edge_overlay.anchor_right = 0.0
	_edge_overlay.anchor_top = 0.0
	_edge_overlay.anchor_bottom = 0.0
	_edge_overlay.offset_left = 0
	_edge_overlay.offset_right = size.x
	_edge_overlay.offset_top = Styler.content_top
	_edge_overlay.offset_bottom = Styler.content_bottom

	# Scrim — dims the hero when any drawer is open; tap to close all.
	_scrim = ColorRect.new()
	_scrim.color = Color(0, 0, 0, 0.55)
	_scrim.visible = false
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge_overlay.add_child(_scrim)
	_scrim.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_close_all_drawers()
	)

	var act = _build_drawer("ACTIVITIES", "⚒", "act")
	_drawer_act = act[0]
	_act_inner = act[1]
	_activity_grid = _make_grid()
	_act_inner.add_child(_activity_grid)
	_disc_act = act[2]
	_act_empty = act[3]
	_act_empty.text = "Nothing to do here yet."

	_build_rails()

	# Park the drawer off-screen to the right, then center it vertically.
	_layout_metrics()
	_drawer_act.offset_left = 12
	_drawer_act.offset_right = 12 + _drawer_w
	call_deferred("_center_drawer_v")
	_restack()


# Returns [panel, scroll_inner_vbox, count_label, empty_label].
func _build_drawer(title: String, icon: String, _id: String) -> Array:
	var panel = PanelContainer.new()
	# Horizontal: pinned to the right edge (slides via offset_left/right).
	# Vertical: centered (height set by _center_drawer_v).
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(16, 18, 24, 247)
	sb.border_color = Styler.COL_PRIMARY
	sb.set_border_width_all(1)
	sb.border_width_left = 2
	sb.set_corner_radius_all(10)
	sb.shadow_color = Styler.COL_GOLD_GLOW
	sb.shadow_size = 8
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	_edge_overlay.add_child(panel)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)

	# Header: [icon | title | count | close]
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	body.add_child(header)

	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 20)
	header.add_child(icon_lbl)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var count_lbl = Label.new()
	count_lbl.text = "0"
	count_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.7))
	header.add_child(count_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func(): _close_drawer(_id))
	header.add_child(close_btn)

	# Gold hairline under the header.
	var rule = ColorRect.new()
	rule.color = Color(Styler.COL_PRIMARY, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	body.add_child(rule)

	# Scrollable content.
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)

	var empty = Label.new()
	empty.add_theme_font_override("font", Styler.QUADRAT_FONT)
	empty.add_theme_font_size_override("font_size", 13)
	empty.add_theme_color_override("font_color", Color.from_rgba8(140, 130, 110))
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(empty)

	return [panel, inner, count_lbl, empty]


func _make_grid() -> GridContainer:
	var g = GridContainer.new()
	g.columns = 1   # ≤20% drawer — single column; markers stack vertically
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g


func _build_rails() -> void:
	_rails = Control.new()
	_rails.name = "EdgeRails"
	_rails.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rails.anchor_left = 1.0
	_rails.anchor_right = 1.0
	_rails.anchor_top = 0.0
	_rails.anchor_bottom = 1.0
	_rails.offset_left = -36
	_rails.offset_right = 0
	_rails.offset_top = 0
	_rails.offset_bottom = 0
	_edge_overlay.add_child(_rails)

	var col = VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER   # compact rail centered vertically
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rails.add_child(col)

	col.add_child(_make_rail("ACTIVITIES", "⚒", true))


func _make_rail(title: String, icon: String, is_top: bool) -> Button:
	# Button (not Panel+gui_input) so taps/touches fire reliably via `pressed`.
	var p = Button.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.custom_minimum_size = Vector2(36, 240)   # compact centered tab, not full height
	p.focus_mode = Control.FOCUS_NONE
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color.from_rgba8(16, 18, 24, 235)
		if state_name == "hover" or state_name == "pressed":
			sb.bg_color = Color.from_rgba8(28, 30, 40, 245)
		sb.border_color = Color(Styler.COL_PRIMARY, 0.25)
		sb.border_width_left = 1
		sb.corner_radius_top_left = 8
		sb.corner_radius_bottom_left = 8
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 4
		p.add_theme_stylebox_override(state_name, sb)

	# Chevron pinned to the top.
	var chev = Label.new()
	chev.text = "‹"
	chev.add_theme_font_size_override("font_size", 15)
	chev.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	chev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chev.anchor_left = 0.0
	chev.anchor_right = 1.0
	chev.anchor_top = 0.0
	chev.anchor_bottom = 0.0
	chev.offset_top = 6
	chev.offset_bottom = 26
	p.add_child(chev)

	# Title: a real single-line JANDA label rotated -90° so it reads bottom-to-top
	# (same font as the drawer header, just turned), centered in the rail.
	var vlabel = Label.new()
	vlabel.text = title
	vlabel.add_theme_font_override("font", Styler.JANDA_FONT)
	vlabel.add_theme_font_size_override("font_size", 15)
	vlabel.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	vlabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(vlabel)
	var ms = vlabel.get_minimum_size()
	vlabel.anchor_left = 0.5
	vlabel.anchor_right = 0.5
	vlabel.anchor_top = 0.5
	vlabel.anchor_bottom = 0.5
	vlabel.offset_left = -ms.x * 0.5
	vlabel.offset_right = ms.x * 0.5
	vlabel.offset_top = -ms.y * 0.5
	vlabel.offset_bottom = ms.y * 0.5
	vlabel.pivot_offset = ms * 0.5
	vlabel.rotation_degrees = -90

	# Icon + count pinned to the bottom.
	var bottom = VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -48
	bottom.offset_bottom = -8
	p.add_child(bottom)

	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 16)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(icon_lbl)

	var disc = Label.new()
	disc.text = "0"
	disc.add_theme_font_override("font", Styler.QUADRAT_FONT)
	disc.add_theme_font_size_override("font_size", 10)
	disc.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	disc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(disc)

	# 3px accent stub at the screen-edge (right) end of the rail.
	var stub = ColorRect.new()
	stub.color = Styler.COL_PRIMARY
	stub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_top:
		stub.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		stub.offset_left = -3
		stub.offset_right = 0
		stub.offset_top = 12
		stub.offset_bottom = 38
	else:
		stub.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		stub.offset_left = -3
		stub.offset_right = 0
		stub.offset_top = -38
		stub.offset_bottom = -12
	p.add_child(stub)

	_rail_act_stub = stub
	_rail_act_disc = disc

	p.pressed.connect(func(): _toggle_drawer("act"))
	return p


# --- Drawer open/close state machine ---------------------------------------

func _drawer_node(_id: String) -> PanelContainer:
	return _drawer_act


func _toggle_drawer(id: String) -> void:
	var idx = _open_order.find(id)
	if idx == -1:
		_open_order.append(id)
	elif idx != _open_order.size() - 1:
		_open_order.remove_at(idx)
		_open_order.append(id)
	else:
		_open_order.remove_at(idx)
	_apply_drawer_states(true)


func _close_drawer(id: String) -> void:
	var idx = _open_order.find(id)
	if idx != -1:
		_open_order.remove_at(idx)
		_apply_drawer_states(true)


func _close_all_drawers() -> void:
	if _open_order.is_empty():
		return
	_open_order.clear()
	_apply_drawer_states(true)


const RAIL_W = 36.0    # right-edge rail strip width
const RAIL_GAP = 10.0  # gap between an open drawer and the rail


func _layout_metrics() -> void:
	var bw = _edge_overlay.size.x if _edge_overlay != null else 0.0
	if bw <= 0.0:
		bw = get_viewport_rect().size.x
	# Drawer ≤ 20% of screen width (floored so a 72px marker still fits).
	_drawer_w = clamp(bw * 0.20, 110.0, 200.0)


# Sizes the drawer to its content (capped) and centers it vertically on the
# right edge — a compact floating frame, not a full-height sheet.
func _center_drawer_v() -> void:
	if _drawer_act == null or _edge_overlay == null:
		return
	var body_h = _edge_overlay.size.y
	if body_h <= 0.0:
		body_h = get_viewport_rect().size.y
	var content_h = _act_inner.get_combined_minimum_size().y if _act_inner != null else 0.0
	# +88 ≈ header + hairline + paddings/separations.
	var h = clamp(content_h + 88.0, 140.0, body_h * 0.85)
	_drawer_act.offset_top = -h * 0.5
	_drawer_act.offset_bottom = h * 0.5


func _drawer_targets(state: String) -> Vector2:
	# Returns (offset_left, offset_right) relative to the right edge (anchor 1).
	var w = _drawer_w
	var edge = RAIL_W + RAIL_GAP   # open drawers sit a gap inboard of the rail
	match state:
		"front":
			return Vector2(-(edge + w), -edge)
		"rear":
			return Vector2(-(edge + w + 8.0), -(edge + 8.0))
		_:
			return Vector2(12.0, 12.0 + w)


func _state_for(id: String) -> String:
	if not _open_order.has(id):
		return "closed"
	if _open_order.back() == id:
		return "front"
	return "rear"


func _apply_drawer_states(animate: bool) -> void:
	_layout_metrics()
	for id in ["act"]:
		var st = _state_for(id)
		var t = _drawer_targets(st)
		var d = _drawer_node(id)
		if animate:
			var dur = 0.18 if st == "closed" else 0.22
			var ease_mode = Tween.EASE_IN if st == "closed" else Tween.EASE_OUT
			if _drawer_tweens.has(id) and _drawer_tweens[id] != null and _drawer_tweens[id].is_running():
				_drawer_tweens[id].kill()
			var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(ease_mode)
			tw.tween_property(d, "offset_left", t.x, dur)
			tw.tween_property(d, "offset_right", t.y, dur)
			_drawer_tweens[id] = tw
		else:
			d.offset_left = t.x
			d.offset_right = t.y
	_scrim.visible = not _open_order.is_empty()
	_restack()
	_refresh_rail_states()


func _restack() -> void:
	# Rear drawers first, front last, rails always on top so they stay tappable.
	for id in _open_order:
		_edge_overlay.move_child(_drawer_node(id), _edge_overlay.get_child_count() - 1)
	if _rails != null:
		_edge_overlay.move_child(_rails, _edge_overlay.get_child_count() - 1)


func _refresh_rail_states() -> void:
	var is_active = Account.activity != 0 and ACTIVITY_PROF_NAME.has(Account.activity)
	if _rail_act_stub != null:
		_rail_act_stub.color = Styler.COLOR_BTN_SUCCESS if is_active else Styler.COL_PRIMARY


func _set_act_count(n: int) -> void:
	if _disc_act != null:
		_disc_act.text = str(n)
	if _rail_act_disc != null:
		_rail_act_disc.text = str(n)
	if _act_empty != null:
		_act_empty.visible = n == 0
	if _activity_grid != null:
		_activity_grid.visible = n > 0
	_refresh_rail_states()
	call_deferred("_center_drawer_v")


func _fmt_n(n: int) -> String:
	# Thousands separator for the status chips ("Steps 12,480").
	var s = str(n)
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


# ==============================================================================
# VISUAL THEME
# ==============================================================================

func _apply_visual_theme() -> void:
	_status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_panel.custom_minimum_size.x = 0
	# Stronger chrome treatment so the status reads as "off the painting".
	var status_sb = StyleBoxFlat.new()
	status_sb.bg_color = Color.from_rgba8(16, 18, 24, 235)
	status_sb.set_corner_radius_all(8)
	status_sb.border_color = Color(Styler.COL_PRIMARY, 0.5)
	status_sb.border_width_left = 3
	status_sb.shadow_color = Color(0, 0, 0, 0.6)
	status_sb.shadow_size = 8
	status_sb.content_margin_left = 14
	status_sb.content_margin_right = 14
	status_sb.content_margin_top = 10
	status_sb.content_margin_bottom = 10
	_status_panel.add_theme_stylebox_override("panel", status_sb)

	# Two-row HUD strip: [title | xp bar | xp text] / [chips … stop].
	# Reparent the tscn nodes so all existing @onready refs and update
	# logic keep working; only the geometry changes.
	var status_vbox = _status_title.get_parent()
	status_vbox.add_theme_constant_override("separation", 6)
	var row_top = HBoxContainer.new()
	row_top.add_theme_constant_override("separation", 10)
	var row_bottom = HBoxContainer.new()
	row_bottom.add_theme_constant_override("separation", 14)
	for n in [_status_title, _status_xp_bar, _status_xp_label,
			_status_steps_label, _status_actions_label, _status_progress_label, _btn_stop]:
		n.get_parent().remove_child(n)
	status_vbox.add_child(row_top)
	status_vbox.add_child(row_bottom)
	row_top.add_child(_status_title)
	row_top.add_child(_status_xp_bar)
	row_top.add_child(_status_xp_label)
	row_bottom.add_child(_status_steps_label)
	row_bottom.add_child(_status_actions_label)
	row_bottom.add_child(_status_progress_label)
	var row_spacer = Control.new()
	row_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_bottom.add_child(row_spacer)
	row_bottom.add_child(_btn_stop)

	_status_title.add_theme_font_override("font", Styler.JANDA_FONT)
	_status_title.add_theme_font_size_override("font_size", 17)
	_status_title.add_theme_color_override("font_color", Styler.COL_PRIMARY)

	Styler.make_painted_progressbar(_status_xp_bar, Styler.COL_PRIMARY, Styler.COL_PRIMARY.darkened(0.4), 4)
	_status_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_xp_bar.custom_minimum_size = Vector2(0, 14)

	var label_color = Color(1.0, 1.0, 1.0, 0.78)
	for lbl in [_status_xp_label, _status_steps_label, _status_actions_label, _status_progress_label]:
		lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", label_color)

	# Stop — compact dark-red square at the strip's right end; gold square
	# glyph drawn as a ColorRect (no font dependency for ■).
	_btn_stop.text = ""
	_btn_stop.tooltip_text = "Stop activity"
	_btn_stop.custom_minimum_size = Vector2(48, 36)
	_btn_stop.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color.from_rgba8(58, 22, 22)
		sb.set_corner_radius_all(6)
		sb.border_color = Color.from_rgba8(180, 60, 60)
		sb.set_border_width_all(1)
		if state_name == "hover":
			sb.bg_color = Color.from_rgba8(76, 28, 28)
		elif state_name == "pressed":
			sb.bg_color = Color.from_rgba8(44, 16, 16)
		_btn_stop.add_theme_stylebox_override(state_name, sb)
	if _btn_stop.get_child_count() == 0:
		var stop_center = CenterContainer.new()
		stop_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stop_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var stop_glyph = ColorRect.new()
		stop_glyph.color = Styler.COL_PRIMARY
		stop_glyph.custom_minimum_size = Vector2(12, 12)
		stop_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stop_center.add_child(stop_glyph)
		_btn_stop.add_child(stop_center)


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

	# Clear old marker cells from the grid.
	for m in _marker_panels:
		if is_instance_valid(m.panel):
			m.panel.queue_free()
	_marker_panels.clear()
	if _activity_grid != null:
		for c in _activity_grid.get_children():
			c.queue_free()

	# Build activity markers in the Activities drawer grid.
	var activities: Array = loc_data.get("activities", [])
	var shown_count = 0
	for act in activities:
		var act_id = int(act.get("id", 0))
		if act_id in HIDDEN_ACTIVITIES:
			continue  # Forester/Fishing hidden client-side (server still serves them)
		var marker_data: Dictionary = {
			"activity_id": act_id,
			"name": act.get("name", ""),
			"profession": act.get("profession", ""),
			"req_skill": int(act.get("req_skill", 1)),
			"texture": _resolve_activity_icon(act),
		}
		_create_marker(marker_data)
		shown_count += 1
	_set_act_count(shown_count)


func _create_marker(data: Dictionary) -> void:
	var activity_id: int = int(data["activity_id"])
	var tex_path: String = data.get("texture", "")

	# Each grid cell: VBox = [circle marker + name label below]. Grid lays
	# them out 3-col automatically; no more norm_pos absolute positioning.
	var cell = VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_theme_constant_override("separation", 4)

	# Circular marker.
	var marker = PanelContainer.new()
	marker.custom_minimum_size = Vector2(72, 72)
	marker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marker.mouse_filter = Control.MOUSE_FILTER_STOP
	marker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(10, 12, 18, 220)
	sb.border_color = Styler.COL_PRIMARY
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(36)  # half of 72 = perfect circle
	sb.shadow_color = Styler.COL_GOLD_GLOW
	sb.shadow_size = 8
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	marker.add_theme_stylebox_override("panel", sb)

	var tex_rect = TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex_path != "" and ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	marker.add_child(tex_rect)

	marker.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_marker_tapped(data, marker)
		elif event is InputEventScreenTouch and event.pressed:
			_on_marker_tapped(data, marker)
	)
	cell.add_child(marker)

	# Name label below the circle.
	var name_lbl = Label.new()
	name_lbl.text = String(data.get("name", "")).capitalize()
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(name_lbl)

	_activity_grid.add_child(cell)
	_marker_panels.append({"panel": marker, "activity_id": activity_id, "sb": sb})


# Removed _reposition_markers — GridContainer handles layout automatically.


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if _vbox != null:
			_vbox.offset_right = size.x
		if _edge_overlay != null:
			_edge_overlay.offset_right = size.x
			_edge_overlay.offset_bottom = Styler.content_bottom
			# Reposition drawers to their current state at the new width.
			_apply_drawer_states(false)
			_center_drawer_v()


func _on_marker_tapped(data: Dictionary, panel: PanelContainer) -> void:
	# Scale animation
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)

	# Start activity directly
	var activity_id = int(data.get("activity_id", 0))
	if activity_id > 0:
		_close_all_drawers()
		_start_activity(activity_id)


func _highlight_active_marker() -> void:
	var act = Account.activity
	for m in _marker_panels:
		var sb: StyleBoxFlat = m.sb
		if m.activity_id == act:
			sb.border_color = Styler.COLOR_BTN_SUCCESS
			sb.set_border_width_all(3)
			sb.shadow_color = Color(Styler.COLOR_BTN_SUCCESS, 0.6)
			sb.shadow_size = 14
		else:
			sb.border_color = Styler.COL_PRIMARY
			sb.set_border_width_all(2)
			sb.shadow_color = Styler.COL_GOLD_GLOW
			sb.shadow_size = 10
	_refresh_rail_states()


# ==============================================================================
# ACTIVITY LOGIC (adapted from character_location.gd)
# ==============================================================================

func _start_activity(activity_id: int) -> void:
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	if activity_id == ACTIVITY_RIFT:
		SignalManager.signal_ShowRift.emit(Account.location)
		return
	if activity_id == Account.activity:
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
	_last_locked = bool(d.get("locked", false))
	_last_req_skill = int(d.get("req_skill", 0))
	_update_status_panel()


func _update_status_panel() -> void:
	var act = Account.activity

	if act != _tracked_activity:
		_session_steps = 0
		_session_actions = 0
		_session_xp_gained = 0
		_last_xp_into = 0
		_last_xp_to_next = 0
		_last_locked = false
		_last_req_skill = 0
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

	# Active activity. The running-state summary (XP bar, session chips, stop)
	# lives in the character HUD's activity capsule now — the hub panel only
	# surfaces travel (above) and the skill-lock warning (below).
	var is_active = act != 0 and ACTIVITY_PROF_NAME.has(act)
	var show_warning = is_active and _last_locked and _last_req_skill > 0
	_status_panel.visible = show_warning
	if not show_warning:
		return

	var prof = ACTIVITY_PROF_NAME[act]
	var lvl = int(Account.get(prof + "_lvl"))
	var display_name: String = GameTextEn.activities_texts.get(act, prof.capitalize())
	_status_title.text = "%s · %d" % [display_name, lvl]
	_status_xp_bar.visible = false
	_status_xp_label.text = ""
	_status_steps_label.text = "⚠ Need %s %d — you are %d" % [display_name, _last_req_skill, lvl]
	_status_steps_label.add_theme_color_override("font_color", Color.from_rgba8(230, 120, 90))
	_status_actions_label.text = ""
	_status_progress_label.text = ""
	_btn_stop.visible = true
