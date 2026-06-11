class_name MapHUD extends Control

signal waypoint_pressed(waypoint_id: String)

@export var mini_map_size: Vector2 = Vector2(142, 142)

const ZOOM_MIN = 0.25
const ZOOM_MAX = 4.0
const PAN_SPEED  = 0.55   # fraction of raw finger/mouse delta applied each event
const PINCH_DAMPEN = 0.45 # how much of the raw pinch ratio is applied (0=none, 1=full)
const WHEEL_STEP = 1.05   # zoom factor per mouse-wheel tick

# Dev-only: double-click on the full map prints the clicked point as a Vector2 ratio
# suitable for pasting into ItemDB.WAYPOINTS. Disable before shipping.
const DEBUG_WAYPOINT_PICKER: bool = true

@onready var mini_map_frame: PanelContainer = $MiniMapFrame
@onready var mini_map_texture: TextureRect = $MiniMapFrame/Mask/MapTexture
@onready var mini_player_marker: TextureRect = $MiniMapFrame/Mask/PlayerMarker
@onready var mini_map_btn: Button = $MiniMapFrame/Button

@onready var full_map_overlay: Panel = $FullMapOverlay
@onready var map_view: Control = $FullMapOverlay/MapView
@onready var map_canvas: Control = $FullMapOverlay/MapView/MapCanvas
@onready var big_map_texture: TextureRect = $FullMapOverlay/MapView/MapCanvas/BigMapTexture
@onready var close_btn: Button = $FullMapOverlay/CloseButton

var player_pos_ratio: Vector2 = Vector2(0.33, 0.42)
var map_texture: Texture2D = load("res://assets/world_map_v2.webp")

const CONFIRMATION_DIALOG = preload("res://scenes/secondary_scenes/confirmation_dialog.tscn")
var _confirm_dialog: Control = null

const SYSTEM_MENU_SCENE = preload("res://scenes/support_screens/system_menu.tscn")
const SETTINGS_SCREEN = preload("res://scenes/support_screens/settings_screen.gd")
var _system_menu: Control = null
var _settings_screen: Control = null
var _menu_btn: Button

const DEV_MENU_SCENE = preload("res://scenes/support_screens/dev_menu.tscn")
var _dev_menu: Control = null
var _dev_btn: Button = null
var _auto_walk_active: bool = false
var _auto_walk_rate: int = 25
var _auto_walk_timer: Timer = null
var _dev_btn_pulse_tween: Tween = null

var _tooltip_panel: PanelContainer = null
var _tooltip_label: Label = null
var _tooltip_vbox: VBoxContainer = null
# Waypoint "armed" for travel. On touch, the first tap shows the tooltip (arms)
# and the second tap on the same waypoint travels — so a single tap no longer
# pops the travel dialog. On desktop, hover arms, so a click still travels once.
var _pending_travel_waypoint: String = ""

# Per-activity accent dot colors, matching the Location Hub activity-color
# identity in DESIGN.md (herbalism green, mining gold, hunting offense-red,
# fishing frost, alchemy arcane-purple, rift arcane). Keyed by profession.
const _ACTIVITY_ACCENT = {
	"herbalism": Color(0.235, 0.784, 0.392),
	"mining": Color(1.0, 0.784, 0.259),
	"woodcutting": Color(0.6, 0.78, 0.5),
	"fishing": Color(0.302, 0.6, 1.0),
	"hunting": Color(1.0, 0.471, 0.353),
	"alchemy": Color(0.639, 0.212, 0.929),
	"rift": Color(0.302, 0.702, 0.902),
}
var _big_player_marker: TextureRect = null

var _avatar_shader: Shader = preload("res://shaders/avatar_shader.gdshader")

# Route preview line
var _route_line: Line2D = null
var _route_glow: Line2D = null
var _active_route: Array = []  # location IDs of current travel route
var _active_route_index: int = 0

# Passing-through toast
var _toast_panel: PanelContainer = null
var _toast_label: Label = null
var _toast_tween: Tween = null

# Pan / zoom state
var _offset: Vector2 = Vector2.ZERO
var _scale: float = 1.0

# Mouse drag (desktop)
var _mouse_dragging: bool = false

# Touch tracking: finger index -> last screen position
var _touches: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	mini_map_frame.custom_minimum_size = mini_map_size
	mini_map_texture.texture = map_texture

	full_map_overlay.visible = false
	big_map_texture.texture = map_texture
	if map_texture:
		big_map_texture.size = map_texture.get_size()

	_create_tooltip()
	_build_waypoints()
	waypoint_pressed.connect(_on_waypoint_pressed)
	Styler.style_button(close_btn, Color.from_rgba8(64, 180, 255))
	var _btn_transparent = StyleBoxFlat.new()
	_btn_transparent.bg_color = Color(0, 0, 0, 0)
	_btn_transparent.set_corner_radius_all(30)
	for state in ["normal", "hover", "pressed", "focus"]:
		mini_map_btn.add_theme_stylebox_override(state, _btn_transparent)
	mini_map_btn.pressed.connect(_on_mini_map_clicked)
	close_btn.pressed.connect(_on_close_clicked)

	# Apply circle shader to minimap player marker
	_apply_circle_shader(mini_player_marker, mini_player_marker.size)

	_big_player_marker = TextureRect.new()
	_big_player_marker.texture = mini_player_marker.texture
	_big_player_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big_player_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_big_player_marker.custom_minimum_size = Vector2(64, 64)
	_big_player_marker.size = Vector2(64, 64)
	_big_player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_circle_shader(_big_player_marker, Vector2(64, 64))
	map_canvas.add_child(_big_player_marker)

	# Route preview line (glow layer behind, main line on top)
	_route_glow = Line2D.new()
	_route_glow.width = 8.0
	_route_glow.default_color = Color(0.18, 0.55, 0.24, 0.3)
	_route_glow.antialiased = true
	_route_glow.z_index = 0
	_route_glow.visible = false
	map_canvas.add_child(_route_glow)

	_route_line = Line2D.new()
	_route_line.width = 4.0
	_route_line.default_color = Color(0.18, 0.55, 0.24, 0.7)
	_route_line.antialiased = true
	_route_line.z_index = 1
	_route_line.visible = false
	_route_line.texture = _create_dash_texture()
	_route_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_route_line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_canvas.add_child(_route_line)

	# Passing-through toast
	_create_toast()

	AccountManager.signal_AccountDataReceived.connect(_on_account_data_received)
	SignalManager.signal_AvatarChanged.connect(_on_avatar_changed_signal)
	SignalManager.signal_TravelPassingThrough.connect(_on_travel_passing_through)
	_update_avatar_texture()
	if Account.location != null:
		update_location(_location_to_map_ratio(Account.location))
	else:
		update_location(player_pos_ratio)

	# Circular hamburger menu button — centered on minimap bottom-right corner
	var btn_size = 32
	_menu_btn = Button.new()
	_menu_btn.text = "☰"
	_menu_btn.custom_minimum_size = Vector2(btn_size, btn_size)
	# Circular style
	var circle_normal = StyleBoxFlat.new()
	circle_normal.bg_color = Color.from_rgba8(40, 42, 54, 220)
	circle_normal.set_corner_radius_all(btn_size / 2)
	circle_normal.border_color = Color(1.0, 0.78, 0.26, 0.6)
	circle_normal.set_border_width_all(2)
	var circle_hover = circle_normal.duplicate()
	circle_hover.bg_color = Color.from_rgba8(60, 62, 74, 230)
	var circle_pressed = circle_normal.duplicate()
	circle_pressed.bg_color = Color.from_rgba8(30, 32, 44, 240)
	_menu_btn.add_theme_stylebox_override("normal", circle_normal)
	_menu_btn.add_theme_stylebox_override("hover", circle_hover)
	_menu_btn.add_theme_stylebox_override("pressed", circle_pressed)
	_menu_btn.add_theme_font_size_override("font_size", 18)
	_menu_btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
	_menu_btn.pressed.connect(_on_menu_btn_pressed)
	add_child(_menu_btn)
	# Center on minimap bottom-right corner
	await get_tree().process_frame
	_menu_btn.position = Vector2(
		mini_map_frame.position.x + mini_map_frame.size.x - btn_size / 2,
		mini_map_frame.position.y + mini_map_frame.size.y - btn_size / 2
	)

	# Dev menu button — debug builds only, bottom-left of minimap
	if OS.is_debug_build():
		_dev_btn = Button.new()
		_dev_btn.text = "D"
		_dev_btn.custom_minimum_size = Vector2(btn_size, btn_size)
		var dev_normal = StyleBoxFlat.new()
		dev_normal.bg_color = Color.from_rgba8(40, 42, 54, 220)
		dev_normal.set_corner_radius_all(btn_size / 2)
		dev_normal.border_color = Color(1.0, 0.78, 0.26, 0.6)
		dev_normal.set_border_width_all(2)
		var dev_hover = dev_normal.duplicate()
		dev_hover.bg_color = Color.from_rgba8(60, 62, 74, 230)
		var dev_pressed = dev_normal.duplicate()
		dev_pressed.bg_color = Color.from_rgba8(30, 32, 44, 240)
		_dev_btn.add_theme_stylebox_override("normal", dev_normal)
		_dev_btn.add_theme_stylebox_override("hover", dev_hover)
		_dev_btn.add_theme_stylebox_override("pressed", dev_pressed)
		_dev_btn.add_theme_font_size_override("font_size", 16)
		_dev_btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
		_dev_btn.pressed.connect(_on_dev_btn_pressed)
		add_child(_dev_btn)
		_dev_btn.position = Vector2(
			mini_map_frame.position.x - btn_size / 2,
			mini_map_frame.position.y + mini_map_frame.size.y - btn_size / 2
		)

		# Auto-walk timer (starts stopped)
		_auto_walk_timer = Timer.new()
		_auto_walk_timer.wait_time = 1.0
		_auto_walk_timer.autostart = false
		_auto_walk_timer.timeout.connect(_on_auto_walk_tick)
		add_child(_auto_walk_timer)

	if DEBUG_WAYPOINT_PICKER:
		big_map_texture.mouse_filter = Control.MOUSE_FILTER_PASS
		big_map_texture.gui_input.connect(_on_big_map_picker_input)


func _on_big_map_picker_input(event: InputEvent) -> void:
	if not DEBUG_WAYPOINT_PICKER or not map_texture:
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed or not event.double_click:
		return
	var sz: Vector2 = map_texture.get_size()
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	var ratio: Vector2 = event.position / sz
	ratio.x = clampf(ratio.x, 0.0, 1.0)
	ratio.y = clampf(ratio.y, 0.0, 1.0)
	print("[Waypoint Picker] Vector2(%.3f, %.3f),  # paste into ItemDB.WAYPOINTS" % [ratio.x, ratio.y])


# Call whenever the player moves. pos_ratio: Vector2 where x/y are 0.0–1.0.
func update_location(pos_ratio: Vector2) -> void:
	player_pos_ratio = pos_ratio
	_update_mini_map(pos_ratio)
	if _big_player_marker and map_texture:
		var marker_size = _big_player_marker.size
		_big_player_marker.position = map_texture.get_size() * pos_ratio - marker_size / 2.0


func _update_mini_map(pos_ratio: Vector2) -> void:
	if not map_texture:
		return
	var target_pixel = map_texture.get_size() * pos_ratio
	var center = mini_map_size / 2.0
	mini_map_texture.position = -target_pixel + center
	mini_player_marker.position = center - mini_player_marker.size / 2.0


func _on_mini_map_clicked() -> void:
	full_map_overlay.visible = true
	_menu_btn.visible = false
	if _dev_btn != null:
		_dev_btn.visible = false
	_scale = 1.0
	_touches.clear()
	_mouse_dragging = false
	await get_tree().process_frame
	_center_on_player()


func _on_close_clicked() -> void:
	full_map_overlay.visible = false
	_menu_btn.visible = true
	if _dev_btn != null:
		_dev_btn.visible = true
	_touches.clear()
	_mouse_dragging = false
	_hide_tooltip()


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Tooltip follows pointer on motion
	if _tooltip_panel and _tooltip_panel.visible:
		if event is InputEventMouseMotion or event is InputEventScreenDrag:
			_update_tooltip_pos()

	if not full_map_overlay.visible:
		return

	# ── Touch ──
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		# NOT consumed — waypoint buttons still receive this touch event

	elif event is InputEventScreenDrag:
		var old_pos: Vector2 = _touches.get(event.index, event.position)
		_touches[event.index] = event.position

		if _touches.size() == 1:
			_pan((event.position - old_pos) * PAN_SPEED)
		elif _touches.size() >= 2:
			# Pinch zoom: compare old and new distance between the two fingers.
			var keys = _touches.keys()
			var other_idx: int = keys[0] if keys[1] == event.index else keys[1]
			var other_pos: Vector2 = _touches[other_idx]
			var old_dist = old_pos.distance_to(other_pos)
			var new_dist = event.position.distance_to(other_pos)
			if old_dist > 1.0:
				var raw_factor = new_dist / old_dist
				var damped_factor = lerpf(1.0, raw_factor, PINCH_DAMPEN)
				_zoom_at((event.position + other_pos) * 0.5, damped_factor)
		get_viewport().set_input_as_handled()

	# ── Mouse (desktop / editor testing) ──
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_mouse_dragging = event.pressed
				# NOT consumed — waypoint buttons still receive left-click
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_at(event.position, WHEEL_STEP)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_at(event.position, 1.0 / WHEEL_STEP)
					get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if _mouse_dragging:
			_pan(event.relative * PAN_SPEED)
			get_viewport().set_input_as_handled()


func _event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return event.position
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	return Vector2.INF


# ── Pan / Zoom ─────────────────────────────────────────────────────────────────

func _pan(delta: Vector2) -> void:
	_offset += delta
	_apply_transform()


func _zoom_at(focal_screen: Vector2, factor: float) -> void:
	var new_scale = clampf(_scale * factor, ZOOM_MIN, ZOOM_MAX)
	var actual_factor = new_scale / _scale
	_offset = focal_screen + (_offset - focal_screen) * actual_factor
	_scale = new_scale
	_apply_transform()


func _apply_transform() -> void:
	_clamp_offset()
	map_canvas.position = _offset
	map_canvas.scale = Vector2(_scale, _scale)


func _clamp_offset() -> void:
	if not map_texture:
		return
	var view = map_view.size
	var map_w = map_texture.get_size().x * _scale
	var map_h = map_texture.get_size().y * _scale

	if map_w > view.x:
		_offset.x = clampf(_offset.x, view.x - map_w, 0.0)
	else:
		_offset.x = (view.x - map_w) * 0.5

	if map_h > view.y:
		_offset.y = clampf(_offset.y, view.y - map_h, 0.0)
	else:
		_offset.y = (view.y - map_h) * 0.5


func _build_waypoints() -> void:
	if not map_texture:
		return
	for id in ItemDB.WAYPOINTS:
		var pos_ratio: Vector2 = ItemDB.WAYPOINTS[id]
		var btn = Button.new()
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(54, 54)
		btn.size = Vector2(54, 54)
		btn.position = map_texture.get_size() * pos_ratio - Vector2(27.0, 27.0)
		_style_waypoint(btn)
		var icon = TextureRect.new()
		icon.offset_left = 8.0
		icon.offset_top = 8.0
		icon.offset_right = 46.0
		icon.offset_bottom = 46.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)
		btn.pressed.connect(func(): waypoint_pressed.emit(id))
		var display_name = _format_waypoint_name(id)
		# Desktop hover shows the tooltip AND arms travel, so a click still
		# travels in one go. On touch there's no real hover (and emulated mouse
		# events must not arm travel), so arming happens only on the first tap
		# inside _on_waypoint_pressed.
		btn.mouse_entered.connect(func(): _on_waypoint_hover(id))
		btn.mouse_exited.connect(_on_waypoint_unhover)
		map_canvas.add_child(btn)

		# Location name label below the waypoint
		var loc_id: int = ItemDB.WAYPOINT_LOCATION_IDS.get(id, -1)
		var loc_name: String = ItemDB.LOCATION_NAMES.get(loc_id, display_name)
		var label_w: float = 160.0
		var name_label = Label.new()
		name_label.text = loc_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.custom_minimum_size = Vector2(label_w, 0)
		name_label.size = Vector2(label_w, 20)
		name_label.add_theme_font_override("font", load("res://assets/fonts/janda.ttf"))
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.33, 0.95))
		name_label.add_theme_color_override("font_outline_color", Color(0.07, 0.05, 0.04, 1.0))
		name_label.add_theme_constant_override("outline_size", 3)
		name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		name_label.add_theme_constant_override("shadow_offset_x", 1)
		name_label.add_theme_constant_override("shadow_offset_y", 1)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.position = Vector2(
			btn.position.x + btn.size.x / 2.0 - label_w / 2.0,
			btn.position.y + btn.size.y + 2.0
		)
		map_canvas.add_child(name_label)


func _update_tooltip_pos() -> void:
	var mp = get_viewport().get_mouse_position()
	var vp_size = get_viewport().get_visible_rect().size
	var tp_size = _tooltip_panel.size
	var pos = mp + Vector2(12.0, -tp_size.y - 6.0)
	pos.x = clampf(pos.x, 4.0, vp_size.x - tp_size.x - 4.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - tp_size.y - 4.0)
	_tooltip_panel.position = pos


func _create_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	# Dark chrome, per DESIGN.md (floating HUD that overlays the painted map).
	sb.bg_color = Styler.COL_PANEL_BG
	sb.border_color = Styler.COL_PRIMARY
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Styler.COL_GOLD_GLOW
	sb.shadow_size = 6
	# 8px internal padding (DESIGN.md tooltip margin) so rows don't kiss the border.
	sb.set_content_margin_all(8)
	_tooltip_panel.add_theme_stylebox_override("panel", sb)
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Header (location name) + a gold hairline + one row per activity live in a
	# VBox so the tooltip grows with the activity list.
	_tooltip_vbox = VBoxContainer.new()
	_tooltip_vbox.add_theme_constant_override("separation", 3)
	_tooltip_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_child(_tooltip_vbox)

	_tooltip_label = Label.new()
	_tooltip_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_tooltip_label.add_theme_font_size_override("font_size", 15)
	_tooltip_label.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	_tooltip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_tooltip_label.add_theme_constant_override("outline_size", 2)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_vbox.add_child(_tooltip_label)

	full_map_overlay.add_child(_tooltip_panel)
	_tooltip_panel.visible = false


func _format_waypoint_name(id: String) -> String:
	var words = id.split("_")
	var result = ""
	for word in words:
		if result != "":
			result += " "
		result += word.capitalize()
	return result


func _show_tooltip(waypoint_id: String) -> void:
	_tooltip_label.text = _format_waypoint_name(waypoint_id)
	_populate_tooltip_activities(waypoint_id)
	_tooltip_panel.visible = true
	_update_tooltip_pos()


# Rebuild the per-activity rows for the hovered waypoint's location. Each row
# shows availability for THIS player: available (meets req_skill) or locked
# (with the required level). Data is already client-side — no round-trip.
#
# Availability is signalled by COLOR + OPACITY (always renders) with a ✓/🔒
# glyph as a secondary cue — the glyph sits in a default-font label so it falls
# back gracefully if the themed font lacks it, instead of showing tofu.
func _populate_tooltip_activities(waypoint_id: String) -> void:
	# Drop everything but the header; rebuild the hairline + rows fresh.
	for child in _tooltip_vbox.get_children():
		if child != _tooltip_label:
			child.queue_free()

	var loc_id: int = ItemDB.WAYPOINT_LOCATION_IDS.get(waypoint_id, -1)
	var loc_data: Dictionary = ServerParams.LOCATIONS.get(str(loc_id), {})
	var activities: Array = loc_data.get("activities", [])
	if activities.is_empty():
		return

	# Gold hairline separating the location header from the activity rows.
	var rule = Panel.new()
	var rule_sb = StyleBoxFlat.new()
	rule_sb.bg_color = Color(Styler.COL_PRIMARY, 0.35)
	rule.add_theme_stylebox_override("panel", rule_sb)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_vbox.add_child(rule)

	for act in activities:
		var prof: String = str(act.get("profession", ""))
		var req: int = int(act.get("req_skill", 1))
		var lvl: int = int(ServerParams.profession_levels.get(prof, 1))
		var available: bool = lvl >= req
		var act_name: String = str(act.get("name", prof.capitalize()))
		var accent: Color = _ACTIVITY_ACCENT.get(prof, Styler.COL_PRIMARY)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Activity-identity dot (crisp circle via stylebox, never a glyph).
		var dot = Panel.new()
		var dot_sb = StyleBoxFlat.new()
		dot_sb.bg_color = accent
		dot_sb.set_corner_radius_all(4)
		dot.add_theme_stylebox_override("panel", dot_sb)
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)

		# Status glyph — default font (no override) so ✓/🔒 fall back cleanly.
		var status = Label.new()
		status.add_theme_font_size_override("font_size", 12)
		status.add_theme_color_override("font_outline_color", Color.BLACK)
		status.add_theme_constant_override("outline_size", 2)
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if available:
			status.text = "✓"
			status.add_theme_color_override("font_color", Color(0.235, 0.784, 0.392))
		else:
			status.text = "🔒"
			status.add_theme_color_override("font_color", Color(0.66, 0.66, 0.68))
		row.add_child(status)

		# Activity name (+ required level when locked).
		var name_lbl = Label.new()
		name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		name_lbl.add_theme_constant_override("outline_size", 2)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if available:
			name_lbl.text = act_name
			name_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
		else:
			name_lbl.text = "%s · Lv %d" % [act_name, req]
			name_lbl.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
		row.add_child(name_lbl)

		# Locked rows read dimmer overall.
		if not available:
			row.modulate.a = 0.6

		_tooltip_vbox.add_child(row)


func _on_waypoint_hover(id: String) -> void:
	# Desktop only. On touch devices the emulated mouse must not arm travel —
	# arming there happens on the first real tap in _on_waypoint_pressed.
	if DisplayServer.is_touchscreen_available():
		return
	_show_tooltip(id)
	_pending_travel_waypoint = id


func _on_waypoint_unhover() -> void:
	if DisplayServer.is_touchscreen_available():
		return
	_hide_tooltip()
	_pending_travel_waypoint = ""


func _hide_tooltip() -> void:
	if _tooltip_panel:
		_tooltip_panel.visible = false


func _style_waypoint(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(18.0 / 255.0, 14.0 / 255.0, 10.0 / 255.0, 130.0 / 255.0)
	normal.border_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.65)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(27)
	normal.shadow_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.40)
	normal.shadow_size = 6

	var hover = normal.duplicate()
	var hover_bg = normal.bg_color.lightened(0.18)
	hover_bg.a = 180.0 / 255.0
	hover.bg_color = hover_bg
	hover.border_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.9)
	hover.shadow_size = 12

	var pressed = normal.duplicate()
	var pressed_bg = normal.bg_color.darkened(0.12)
	pressed_bg.a = 170.0 / 255.0
	pressed.bg_color = pressed_bg
	pressed.border_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.75)
	pressed.shadow_size = 3

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)


func _center_on_player() -> void:
	var player_px = map_texture.get_size() * player_pos_ratio
	_offset = map_view.size * 0.5 - player_px * _scale
	_apply_transform()



func _on_account_data_received(_value) -> void:
	update_location(_location_to_map_ratio(Account.location))
	_update_avatar_texture()
	# Update route progress during travel
	var route: Array = Account.travel_route
	var route_index: int = Account.travel_route_index
	if route.size() >= 2 and Account.activity == 8:
		if _active_route != route:
			show_route_preview(route)
		update_route_progress(route_index)
	elif _active_route.size() > 0 and Account.activity != 8:
		clear_route_preview()


func _on_avatar_changed_signal(_id: int) -> void:
	_update_avatar_texture()


func _update_avatar_texture() -> void:
	var tex = ItemDB.AVATARS.get(str(Account.avatar_id), ItemDB.AVATARS.get("0"))
	if tex == null:
		return
	mini_player_marker.texture = tex
	if _big_player_marker != null:
		_big_player_marker.texture = tex


func _apply_circle_shader(target: TextureRect, sz: Vector2) -> void:
	var mat = ShaderMaterial.new()
	mat.shader = _avatar_shader
	mat.set_shader_parameter("rect_size", sz)
	mat.set_shader_parameter("border_color", Color(0.86, 0.69, 0.27, 1.0))
	mat.set_shader_parameter("border_px", 2.0)
	mat.set_shader_parameter("feather_px", 1.5)
	target.material = mat


func _location_to_map_ratio(location_id: int) -> Vector2:
	for key in ItemDB.WAYPOINT_LOCATION_IDS:
		if ItemDB.WAYPOINT_LOCATION_IDS[key] == location_id:
			return ItemDB.WAYPOINTS.get(key, player_pos_ratio)
	return player_pos_ratio


func _on_waypoint_pressed(waypoint_id: String) -> void:
	# Two-stage tap. First press on a waypoint just shows its tooltip and arms
	# travel; only a second press on the SAME (armed) waypoint travels. On
	# desktop, hover already armed it, so the first click travels in one go.
	# This stops a single mobile tap from instantly popping the travel dialog.
	if _pending_travel_waypoint != waypoint_id:
		_show_tooltip(waypoint_id)
		_pending_travel_waypoint = waypoint_id
		return
	_pending_travel_waypoint = ""
	_hide_tooltip()
	var location_id: int = ItemDB.WAYPOINT_LOCATION_IDS.get(waypoint_id, -1)
	if location_id == -1:
		return
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	if location_id == int(Account.location):
		return

	var location_name: String = ItemDB.LOCATION_NAMES.get(location_id, "Unknown")

	# Request travel cost from server with a timeout
	var result: Dictionary = {"steps": -1, "done": false}
	SignalManager.signal_TravelCostRequest.emit(location_id)

	var cost_cb = func(recv_loc: int, recv_steps: int):
		if recv_loc == location_id:
			result["steps"] = recv_steps
			result["done"] = true
	SignalManager.signal_TravelCostReceived.connect(cost_cb, CONNECT_ONE_SHOT)
	var timeout_timer = get_tree().create_timer(2.0)
	while not result["done"] and timeout_timer.time_left > 0:
		await get_tree().process_frame
	if not result["done"] and SignalManager.signal_TravelCostReceived.is_connected(cost_cb):
		SignalManager.signal_TravelCostReceived.disconnect(cost_cb)

	var travel_steps: int = result["steps"]
	var text: String
	var distance_line: String = "Distance: %d steps" % travel_steps if travel_steps >= 0 else ""
	if Account.activity:
		var current_name: String = GameTextEn.activities_texts.get(Account.activity, "Activity")
		text = "Stop %s and Travel to %s?" % [current_name, location_name]
	else:
		text = "Travel to %s?" % location_name
	if distance_line != "":
		text += "\n" + distance_line

	_confirm_dialog = CONFIRMATION_DIALOG.instantiate()
	_confirm_dialog.setup(text)
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		full_map_overlay.visible = false
		_menu_btn.visible = true
		if _dev_btn != null:
			_dev_btn.visible = true
		_hide_tooltip()
		SignalManager.signal_TravelRequest.emit(location_id)
	)
	_confirm_dialog.tree_exited.connect(func(): _confirm_dialog = null, CONNECT_ONE_SHOT)


func _on_dev_btn_pressed() -> void:
	if _dev_menu and is_instance_valid(_dev_menu):
		return
	_dev_menu = DEV_MENU_SCENE.instantiate()
	_dev_menu.setup(_dev_btn.global_position, _auto_walk_active, _auto_walk_rate)
	add_child(_dev_menu)
	_dev_menu.auto_walk_toggled.connect(_on_auto_walk_toggled)
	_dev_menu.auto_walk_rate_changed.connect(_on_auto_walk_rate_changed)
	_dev_menu.tree_exited.connect(func(): _dev_menu = null, CONNECT_ONE_SHOT)


func _on_auto_walk_toggled(active: bool) -> void:
	_auto_walk_active = active
	if _auto_walk_active:
		_auto_walk_timer.wait_time = 1.0
		_auto_walk_timer.start()
		_start_dev_btn_pulse()
	else:
		_auto_walk_timer.stop()
		_stop_dev_btn_pulse()


func _on_auto_walk_rate_changed(rate: int) -> void:
	_auto_walk_rate = rate


func _on_auto_walk_tick() -> void:
	SignalManager.signal_StepsUpdatesCheats.emit(_auto_walk_rate)


func _start_dev_btn_pulse() -> void:
	if not _dev_btn:
		return
	var style: StyleBoxFlat = _dev_btn.get_theme_stylebox("normal")
	style.border_color = Color(0.31, 0.86, 0.31, 0.6)
	if _dev_btn_pulse_tween and _dev_btn_pulse_tween.is_valid():
		_dev_btn_pulse_tween.kill()
	_dev_btn_pulse_tween = create_tween().set_loops()
	_dev_btn_pulse_tween.tween_property(style, "border_color:a", 1.0, 0.75)
	_dev_btn_pulse_tween.tween_property(style, "border_color:a", 0.4, 0.75)


func _stop_dev_btn_pulse() -> void:
	if not _dev_btn:
		return
	if _dev_btn_pulse_tween and _dev_btn_pulse_tween.is_valid():
		_dev_btn_pulse_tween.kill()
		_dev_btn_pulse_tween = null
	var style: StyleBoxFlat = _dev_btn.get_theme_stylebox("normal")
	style.border_color = Color(1.0, 0.78, 0.26, 0.6)


func _on_menu_btn_pressed() -> void:
	if _system_menu and is_instance_valid(_system_menu):
		return
	_system_menu = SYSTEM_MENU_SCENE.instantiate()
	_system_menu.setup(_menu_btn.global_position)
	add_child(_system_menu)
	_system_menu.settings_pressed.connect(_on_settings)
	_system_menu.relogin_pressed.connect(_on_relogin)
	_system_menu.exit_pressed.connect(_on_exit)
	_system_menu.tree_exited.connect(func(): _system_menu = null, CONNECT_ONE_SHOT)


func _on_settings() -> void:
	if _settings_screen and is_instance_valid(_settings_screen):
		return
	_settings_screen = SETTINGS_SCREEN.new()
	add_child(_settings_screen)
	_settings_screen.logout_requested.connect(_on_relogin)
	_settings_screen.tree_exited.connect(func(): _settings_screen = null, CONNECT_ONE_SHOT)


func _on_relogin() -> void:
	ServerConnector.socket.close()
	ServerConnector.clear_credentials()
	Account.clear()
	SceneManage.goto("res://scenes/login_screen/login_scene.tscn")
	ServerConnector.connect_to_server.call_deferred()


func _on_exit() -> void:
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	# Hide reconnect overlay so it doesn't block the exit confirmation
	ServerConnector.suppress_reconnect_overlay = true
	if ServerConnector._reconnect_overlay:
		ServerConnector._hide_reconnect_overlay()
	_confirm_dialog = CONFIRMATION_DIALOG.instantiate()
	_confirm_dialog.setup("Are you sure you want to exit?")
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		get_tree().quit()
	)
	_confirm_dialog.tree_exited.connect(func():
		_confirm_dialog = null
		ServerConnector.suppress_reconnect_overlay = false
	, CONNECT_ONE_SHOT)


func _on_travel_passing_through(location_name: String) -> void:
	show_toast("Passing through %s" % location_name)


# ── Route preview line ────────────────────────────────────────────────────────

func _create_dash_texture() -> ImageTexture:
	var dash_len: int = 16
	var gap_len: int = 12
	var w: int = dash_len + gap_len
	var h: int = 4
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		for y in h:
			if x < dash_len:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex = ImageTexture.create_from_image(img)
	return tex

func show_route_preview(route_ids: Array) -> void:
	"""Draw animated golden route line on the full map."""
	if not map_texture or route_ids.size() < 2:
		clear_route_preview()
		return

	_active_route = route_ids
	var points: PackedVector2Array = PackedVector2Array()
	for loc_id in route_ids:
		var wp_id = _location_id_to_waypoint(loc_id)
		if wp_id == "":
			continue
		var ratio: Vector2 = ItemDB.WAYPOINTS.get(wp_id, Vector2.ZERO)
		points.append(map_texture.get_size() * ratio)

	if points.size() < 2:
		clear_route_preview()
		return

	# Set points on both glow and main line
	_route_glow.clear_points()
	_route_line.clear_points()
	for pt in points:
		_route_glow.add_point(pt)
		_route_line.add_point(pt)

	_route_glow.visible = true
	_route_line.visible = true

	# Animate the line drawing (0.5s)
	_route_line.modulate.a = 0.0
	_route_glow.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_route_line, "modulate:a", 1.0, 0.5)
	tween.tween_property(_route_glow, "modulate:a", 1.0, 0.5)


func clear_route_preview() -> void:
	"""Remove the route line from the map."""
	_active_route = []
	_active_route_index = 0
	if _route_line:
		_route_line.visible = false
		_route_line.clear_points()
	if _route_glow:
		_route_glow.visible = false
		_route_glow.clear_points()


func update_route_progress(route_index: int) -> void:
	"""Dim completed segments of the route line."""
	_active_route_index = route_index
	if not _route_line or _route_line.get_point_count() < 2:
		return
	# Rebuild line colors: completed segments are dimmed
	var gradient = Gradient.new()
	var total_points = _route_line.get_point_count()
	if total_points < 2:
		return
	# Use gradient to dim completed parts
	var completed_ratio = float(route_index - 1) / float(total_points - 1) if total_points > 1 else 0.0
	completed_ratio = clampf(completed_ratio, 0.0, 1.0)
	var dimmed = Color(0.18, 0.55, 0.24, 0.25)
	var bright = Color(0.18, 0.55, 0.24, 0.7)
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, dimmed)
	if completed_ratio > 0.01 and completed_ratio < 0.99:
		gradient.add_point(completed_ratio, dimmed)
		gradient.add_point(completed_ratio + 0.01, bright)
	gradient.set_offset(gradient.get_point_count() - 1, 1.0)
	gradient.set_color(gradient.get_point_count() - 1, bright)
	_route_line.gradient = gradient


func _fit_map_to_route(route_ids: Array) -> void:
	"""Zoom and pan to show the full route with padding."""
	if not map_texture or route_ids.size() < 2:
		return
	var min_pt = Vector2(INF, INF)
	var max_pt = Vector2(-INF, -INF)
	for loc_id in route_ids:
		var wp_id = _location_id_to_waypoint(loc_id)
		if wp_id == "":
			continue
		var ratio: Vector2 = ItemDB.WAYPOINTS.get(wp_id, Vector2.ZERO)
		var pt = map_texture.get_size() * ratio
		min_pt = Vector2(min(min_pt.x, pt.x), min(min_pt.y, pt.y))
		max_pt = Vector2(max(max_pt.x, pt.x), max(max_pt.y, pt.y))

	if min_pt.x == INF:
		return

	var padding = 100.0
	min_pt -= Vector2(padding, padding)
	max_pt += Vector2(padding, padding)
	var route_size = max_pt - min_pt
	var route_center = (min_pt + max_pt) / 2.0
	var view_size = map_view.size

	# Calculate scale to fit route in view
	var scale_x = view_size.x / route_size.x if route_size.x > 0 else 1.0
	var scale_y = view_size.y / route_size.y if route_size.y > 0 else 1.0
	_scale = clampf(min(scale_x, scale_y), ZOOM_MIN, ZOOM_MAX)

	# Center on route
	_offset = view_size * 0.5 - route_center * _scale
	_apply_transform()


func _location_id_to_waypoint(loc_id: int) -> String:
	"""Convert a location ID to its waypoint string key."""
	for key in ItemDB.WAYPOINT_LOCATION_IDS:
		if ItemDB.WAYPOINT_LOCATION_IDS[key] == loc_id:
			return key
	return ""


# ── Toast notification ────────────────────────────────────────────────────────

func _create_toast() -> void:
	_toast_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(18.0 / 255.0, 14.0 / 255.0, 10.0 / 255.0, 230.0 / 255.0)
	sb.border_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.4)
	sb.shadow_size = 4
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_toast_panel.add_theme_stylebox_override("panel", sb)
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_toast_label = Label.new()
	_toast_label.add_theme_font_override("font", load("res://assets/fonts/janda.ttf"))
	_toast_label.add_theme_font_size_override("font_size", 14)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.33, 0.95))
	_toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast_label.add_theme_constant_override("outline_size", 2)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)

	add_child(_toast_panel)
	_toast_panel.visible = false


func show_toast(text: String) -> void:
	"""Show a passing-through notification at top-center."""
	if not _toast_panel:
		return
	_toast_label.text = text
	_toast_panel.visible = true

	# Position top-center with safe area
	await get_tree().process_frame
	var vp_size = get_viewport().get_visible_rect().size
	_toast_panel.position = Vector2(
		(vp_size.x - _toast_panel.size.x) / 2.0,
		60.0  # safe area offset for notch/status bar
	)

	# Animate: fade in, hold 3s, fade out
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_panel.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func(): _toast_panel.visible = false)
