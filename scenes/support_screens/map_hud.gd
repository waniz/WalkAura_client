class_name MapHUD extends Control

signal waypoint_pressed(waypoint_id: String)

@export var mini_map_size: Vector2 = Vector2(162, 162)

const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
const PAN_SPEED  := 0.55   # fraction of raw finger/mouse delta applied each event
const PINCH_DAMPEN := 0.45 # how much of the raw pinch ratio is applied (0=none, 1=full)
const WHEEL_STEP := 1.05   # zoom factor per mouse-wheel tick

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
var map_texture: Texture2D = load("res://assets/world_map_v1.png")

const CONFIRMATION_DIALOG = preload("res://scenes/secondary_scenes/confirmation_dialog.tscn")
var _confirm_dialog: Control = null

const SYSTEM_MENU_SCENE = preload("res://scenes/support_screens/system_menu.tscn")
var _system_menu: Control = null
var _menu_btn: Button

var _tooltip_panel: PanelContainer = null
var _tooltip_label: Label = null
var _big_player_marker: TextureRect = null

var _avatar_shader: Shader = preload("res://shaders/avatar_shader.gdshader")

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
	var _btn_transparent := StyleBoxFlat.new()
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

	AccountManager.signal_AccountDataReceived.connect(_on_account_data_received)
	SignalManager.signal_AvatarChanged.connect(_on_avatar_changed_signal)
	_update_avatar_texture()
	if Account.location != null:
		update_location(_location_to_map_ratio(Account.location))
	else:
		update_location(player_pos_ratio)

	# Hamburger menu button (bottom-right corner of minimap)
	_menu_btn = Button.new()
	_menu_btn.text = "☰"
	_menu_btn.custom_minimum_size = Vector2(36, 36)
	Styler.style_button(_menu_btn, Color.from_rgba8(40, 42, 54, 220))
	_menu_btn.add_theme_font_size_override("font_size", 20)
	_menu_btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))  # gold
	_menu_btn.pressed.connect(_on_menu_btn_pressed)
	add_child(_menu_btn)
	# Position at bottom-right corner of minimap, overlapping slightly
	await get_tree().process_frame
	_menu_btn.position = Vector2(
		mini_map_frame.position.x + mini_map_frame.size.x - 36,
		mini_map_frame.position.y + mini_map_frame.size.y - 36
	)


# Call whenever the player moves. pos_ratio: Vector2 where x/y are 0.0–1.0.
func update_location(pos_ratio: Vector2) -> void:
	player_pos_ratio = pos_ratio
	_update_mini_map(pos_ratio)
	if _big_player_marker and map_texture:
		var marker_size := _big_player_marker.size
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
	_scale = 1.0
	_touches.clear()
	_mouse_dragging = false
	await get_tree().process_frame
	_center_on_player()


func _on_close_clicked() -> void:
	full_map_overlay.visible = false
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
	var new_scale := clampf(_scale * factor, ZOOM_MIN, ZOOM_MAX)
	var actual_factor := new_scale / _scale
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
	var view := map_view.size
	var map_w := map_texture.get_size().x * _scale
	var map_h := map_texture.get_size().y * _scale

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
		var btn := Button.new()
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(72, 72)
		btn.size = Vector2(72, 72)
		btn.position = map_texture.get_size() * pos_ratio - Vector2(36.0, 36.0)
		_style_waypoint(btn)
		var icon := TextureRect.new()
		icon.offset_left = 4.0
		icon.offset_top = 4.0
		icon.offset_right = 68.0
		icon.offset_bottom = 68.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)
		btn.pressed.connect(func(): waypoint_pressed.emit(id))
		var display_name := _format_waypoint_name(id)
		btn.mouse_entered.connect(func(): _show_tooltip(display_name))
		btn.mouse_exited.connect(_hide_tooltip)
		map_canvas.add_child(btn)


func _update_tooltip_pos() -> void:
	var mp := get_viewport().get_mouse_position()
	var vp_size := get_viewport().get_visible_rect().size
	var tp_size := _tooltip_panel.size
	var pos := mp + Vector2(12.0, -tp_size.y - 6.0)
	pos.x = clampf(pos.x, 4.0, vp_size.x - tp_size.x - 4.0)
	pos.y = clampf(pos.y, 4.0, vp_size.y - tp_size.y - 4.0)
	_tooltip_panel.position = pos


func _create_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(18.0 / 255.0, 14.0 / 255.0, 10.0 / 255.0, 230.0 / 255.0)
	sb.border_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.4)
	sb.shadow_size = 4
	_tooltip_panel.add_theme_stylebox_override("panel", sb)
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_tooltip_label = Label.new()
	_tooltip_label.add_theme_font_override("font", load("res://assets/fonts/janda.ttf"))
	_tooltip_label.add_theme_font_size_override("font_size", 14)
	_tooltip_label.add_theme_color_override("font_color", Color(255.0 / 255.0, 210.0 / 255.0, 80.0 / 255.0, 1.0))
	_tooltip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_tooltip_label.add_theme_constant_override("outline_size", 2)
	_tooltip_panel.add_child(_tooltip_label)

	full_map_overlay.add_child(_tooltip_panel)
	_tooltip_panel.visible = false


func _format_waypoint_name(id: String) -> String:
	var words := id.split("_")
	var result := ""
	for word in words:
		if result != "":
			result += " "
		result += word.capitalize()
	return result


func _show_tooltip(text: String) -> void:
	_tooltip_label.text = text
	_tooltip_panel.visible = true
	_update_tooltip_pos()


func _hide_tooltip() -> void:
	if _tooltip_panel:
		_tooltip_panel.visible = false


func _style_waypoint(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(18.0 / 255.0, 14.0 / 255.0, 10.0 / 255.0, 220.0 / 255.0)
	normal.border_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 1.0)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.55)
	normal.shadow_size = 6

	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.18)
	hover.shadow_size = 12

	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.12)
	pressed.shadow_size = 3

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)


func _center_on_player() -> void:
	var player_px := map_texture.get_size() * player_pos_ratio
	_offset = map_view.size * 0.5 - player_px * _scale
	_apply_transform()



func _on_account_data_received(_value) -> void:
	update_location(_location_to_map_ratio(Account.location))
	_update_avatar_texture()


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
	var mat := ShaderMaterial.new()
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
	var location_id: int = ItemDB.WAYPOINT_LOCATION_IDS.get(waypoint_id, -1)
	if location_id == -1:
		return
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	var location_name: String = ItemDB.LOCATION_NAMES.get(location_id, "Unknown")
	var text: String
	if Account.activity:
		var current_name: String = GameTextEn.activities_texts.get(Account.activity, "Activity")
		text = "Stop %s and Travel to %s?" % [current_name, location_name]
	else:
		text = "Travel to %s?" % location_name
	_confirm_dialog = CONFIRMATION_DIALOG.instantiate()
	_confirm_dialog.setup(text)
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		full_map_overlay.visible = false
		_hide_tooltip()
		SignalManager.signal_TravelRequest.emit(location_id)
	)
	_confirm_dialog.tree_exited.connect(func(): _confirm_dialog = null, CONNECT_ONE_SHOT)


func _on_menu_btn_pressed() -> void:
	if _system_menu and is_instance_valid(_system_menu):
		return
	_system_menu = SYSTEM_MENU_SCENE.instantiate()
	_system_menu.setup(_menu_btn.global_position)
	add_child(_system_menu)
	_system_menu.relogin_pressed.connect(_on_relogin)
	_system_menu.exit_pressed.connect(_on_exit)
	_system_menu.tree_exited.connect(func(): _system_menu = null, CONNECT_ONE_SHOT)


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
