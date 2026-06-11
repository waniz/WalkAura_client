extends Control

# Login scene — Phase 5.1 ornate redesign (2026-05-16).
# DESIGN.md "Login Screen" spec. Mockup: design-mockups/login.html.

const CREATE_USER_UI = preload("uid://d1bmiemb8yjfl")

var _panel: PanelContainer
var _username_edit: LineEdit
var _password_edit: LineEdit
var _status_label: Label
var _btn_login: Button
var _btn_create: Button
var _btn_google: Button
var _version_label: Label
var _motes: CPUParticles2D
var _google_toast: Label

# Loading UI — shown after login press, while resources are preloaded
var _loading_panel: Control
var _progress_bar: ProgressBar
var _progress_label: Label

var child: Node = null
var _login_ok = false
var _login_error = ""

# Preload state machine
var _preload_manifest: Array[String] = []
var _preload_total: int = 0
var _preload_done: bool = false
var _login_result_received: bool = false   # signal_LoginResult arrived
var _login_data_received: bool = false     # signal_AccountDataReceived arrived
var _inventory_received: bool = false      # signal_InventoryReceived arrived (Phase 2)
var _finalized: bool = false               # guards double-fire of _try_finalize
var _last_reported_done: int = -1          # skips redundant label/bar writes

# Strong refs to every successfully preloaded resource. Holding these until
# SceneManage.goto() runs prevents Godot's cache from evicting entries
# between preload completion and scene swap.
var _preloaded_refs: Array[Resource] = []
var _resolved_paths: Dictionary = {}
var _failed_paths: Dictionary = {}

# 15-second timeout safety net for flaky networks. If the server never
# responds, the timer fires and restores the panel with an error instead of
# leaving the user stuck watching a full progress bar.
const _LOGIN_TIMEOUT_SEC: float = 15.0
var _login_timeout_timer: SceneTreeTimer = null

# Set when the server rejects our version. Blocks auto-login on entry — an
# out-of-date client must not silently push a login through the version gate.
var _version_blocked: bool = false


func _ready() -> void:
	# Suspend _process until preload starts. Otherwise the default-enabled
	# _process would fire on frame 0 with an empty manifest and immediately
	# flip _preload_done = true before the user has even tapped Play.
	set_process(false)

	_build_ui()

	# Belt-and-suspenders: the update overlay (ServerConnector) blocks mouse
	# interaction, but keyboard focus isn't blocked by a CanvasLayer. Disable
	# the login/register buttons outright on version_mismatch so a
	# tab-and-enter can't still fire an action beneath the overlay.
	AccountManager.signal_VersionMismatch.connect(_on_version_blocked)

	await AccountManager.signal_LoginParamsReceived

	var project_version = ProjectSettings.get_setting("application/config/version", "")
	_version_label.text = "v" + project_version + "  Server: " + ServerParams.SERVER_VERSION

	# Auto-login on app entry: if we hold a persisted session token (and the
	# build isn't version-blocked), show the loading bar and wait. ServerConnector
	# owns the actual login_token send — it fires once on client_hello_ack, so we
	# must NOT send it here too (a second send before the handshake ack got the
	# socket closed with version_mismatch/4000). The loading flow's own
	# signal_LoginResult / AccountDataReceived handlers drive the transition
	# regardless of who sent the token. A rejected token falls back to the manual
	# card via _restore_panel_with_error / AccountManager wiping the bad token.
	if not _version_blocked and ServerConnector.has_saved_token() and ServerConnector._is_socket_open():
		_begin_login_flow(func(): pass)


func _on_version_blocked(_info: Dictionary) -> void:
	_version_blocked = true
	if _btn_login:
		_btn_login.disabled = true
	if _btn_create:
		_btn_create.disabled = true


func _build_ui() -> void:
	# Atmospheric gold motes drifting up over the painted background.
	_build_motes()

	# Title mark — centred near the top of the screen, NOT inside the card.
	# Stays large + ornate even on tall portrait screens. Anchored to top.
	_build_title_mark()

	# Center container for the card
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Ornate gold-framed card.
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	_apply_login_panel_style(_panel)
	center.add_child(_panel)
	_add_corner_brackets(_panel)

	# Margin inside card
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Username field
	var username_label = Label.new()
	username_label.text = "USERNAME"
	_style_field_label(username_label)
	vbox.add_child(username_label)

	_username_edit = LineEdit.new()
	_username_edit.placeholder_text = "Enter username"
	_username_edit.text = "test_user"
	_username_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_username_edit.add_theme_font_size_override("font_size", 18)
	_style_ornate_line_edit(_username_edit)
	vbox.add_child(_username_edit)

	# Password field
	var password_label = Label.new()
	password_label.text = "PASSWORD"
	_style_field_label(password_label)
	vbox.add_child(password_label)

	_password_edit = LineEdit.new()
	_password_edit.placeholder_text = "Enter password"
	_password_edit.text = "qwertypoiu"
	_password_edit.secret = true
	_password_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_password_edit.add_theme_font_size_override("font_size", 18)
	_style_ornate_line_edit(_password_edit)
	vbox.add_child(_password_edit)

	# Status label (errors)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color.from_rgba8(220, 80, 80))
	vbox.add_child(_status_label)

	# Buttons
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_box)

	_btn_login = Button.new()
	_btn_login.text = "ENTER THE REALM"
	_btn_login.custom_minimum_size = Vector2(0, 52)
	_style_gold_emboss_button(_btn_login)
	Styler.wire_button_anim(_btn_login)
	_btn_login.pressed.connect(_on_login_pressed)
	btn_box.add_child(_btn_login)

	# "Sign in with Google" — official branding: real 4-color G logo + the
	# Google-sanctioned dark button variant (see _style_google_button).
	_btn_google = Button.new()
	_btn_google.text = "Sign in with Google"
	_btn_google.icon = _load_google_logo()
	_btn_google.expand_icon = false
	_btn_google.custom_minimum_size = Vector2(0, 44)
	_style_google_button(_btn_google)
	Styler.wire_button_anim(_btn_google)
	_btn_google.pressed.connect(_on_google_pressed)
	btn_box.add_child(_btn_google)

	# OR separator with hairlines.
	btn_box.add_child(_build_or_separator())

	_btn_create = Button.new()
	_btn_create.text = "Create New Account"
	_btn_create.custom_minimum_size = Vector2(0, 40)
	_style_outlined_button(_btn_create)
	Styler.wire_button_anim(_btn_create)
	_btn_create.pressed.connect(_on_create_pressed)
	btn_box.add_child(_btn_create)

	# Fallback toast shown only off-Android (no plugin singleton present).
	_google_toast = Label.new()
	_google_toast.text = "Google sign-in is only available on Android"
	_google_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_google_toast.offset_top = -90
	_google_toast.offset_bottom = -60
	_google_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_google_toast.add_theme_font_override("font", Styler.JANDA_FONT)
	_google_toast.add_theme_font_size_override("font_size", 14)
	_google_toast.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	_google_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_google_toast.add_theme_constant_override("outline_size", 3)
	_google_toast.modulate.a = 0.0
	add_child(_google_toast)

	# Version label — bottom-right, muted gold.
	_version_label = Label.new()
	_version_label.text = ""
	_version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_version_label.offset_left = -200
	_version_label.offset_top = -28
	_version_label.offset_right = -10
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_version_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_version_label.add_theme_font_size_override("font_size", 11)
	_version_label.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.45))
	add_child(_version_label)

	_build_loading_ui()


# Progress bar + label pinned to the bottom of the login background. Hidden by
# default; shown in _on_login_pressed once credentials look valid and the
# server round-trip is in flight. Content is updated each frame by _process
# while preloading runs.
func _build_loading_ui() -> void:
	_loading_panel = Control.new()
	_loading_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_loading_panel.offset_top = -80
	_loading_panel.offset_bottom = -24
	_loading_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_panel.visible = false
	add_child(_loading_panel)

	# Anchored directly — 10% inset per side on small portrait screens
	# (360×640 → 288px effective strip, comfortable for the label).
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.1
	vbox.anchor_right = 0.9
	vbox.anchor_top = 0.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_loading_panel.add_child(vbox)

	# Label uses the warm-light cream token that achievements uses for header
	# metadata — stays consistent with the civic-family typography.
	_progress_label = Label.new()
	_progress_label.text = "Loading..."
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_progress_label.add_theme_font_size_override("font_size", 13)
	_progress_label.add_theme_color_override("font_color", Color.from_rgba8(220, 210, 180))
	# Outline — parchment-family pattern (Styler uses outline/shadow_color via
	# LabelSettings, not the theme drop-shadow constant). Keeps the label
	# readable over any background art without a jarring hard shadow.
	_progress_label.add_theme_constant_override("outline_size", 2)
	_progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	vbox.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	_progress_bar.show_percentage = false
	_progress_bar.min_value = 0
	_progress_bar.value = 0
	# Track + fill use Styler.COLOR_GOLD — matches the accent language
	# established for rewards, XP, and primary highlights across the game.
	var bar_track = StyleBoxFlat.new()
	bar_track.bg_color = Color(0, 0, 0, 0.45)
	bar_track.set_corner_radius_all(3)
	_progress_bar.add_theme_stylebox_override("background", bar_track)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Styler.COLOR_GOLD
	bar_fill.set_corner_radius_all(3)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_progress_bar)


func _style_parchment_line_edit(le: LineEdit) -> void:
	le.custom_minimum_size = Vector2(0, 40)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.4)
	bg.border_color = Styler.COLOR_BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	bg.content_margin_left = 10
	bg.content_margin_right = 10
	le.add_theme_stylebox_override("normal", bg)
	var focus = bg.duplicate()
	focus.border_color = Color(0.13, 0.37, 0.13)
	focus.set_border_width_all(2)
	le.add_theme_stylebox_override("focus", focus)
	le.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	le.add_theme_color_override("caret_color", Styler.COLOR_TEXT_DARK)


func _apply_login_panel_style(panel: PanelContainer) -> void:
	# Ornate dark card with gold border + gold-glow halo. Replaces parchment
	# treatment — login is dark-chrome family, not codex.
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(20, 22, 30, 240)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Styler.COL_PRIMARY
	sb.shadow_color = Styler.COL_GOLD_GLOW
	sb.shadow_size = 16
	panel.add_theme_stylebox_override("panel", sb)


# Four 24×24 L-corner brackets drawn in gold on the corners of the card —
# matches the location hero corner-bracket motif. Pure decoration; no input.
func _add_corner_brackets(panel: PanelContainer) -> void:
	for corner in [
		{"preset": Control.PRESET_TOP_LEFT,     "ox": -2, "oy": -2, "flip_h": false, "flip_v": false},
		{"preset": Control.PRESET_TOP_RIGHT,    "ox":  2, "oy": -2, "flip_h": true,  "flip_v": false},
		{"preset": Control.PRESET_BOTTOM_LEFT,  "ox": -2, "oy":  2, "flip_h": false, "flip_v": true},
		{"preset": Control.PRESET_BOTTOM_RIGHT, "ox":  2, "oy":  2, "flip_h": true,  "flip_v": true},
	]:
		var bracket = _LCornerBracket.new()
		bracket.flip_h = corner.flip_h
		bracket.flip_v = corner.flip_v
		bracket.color = Styler.COL_PRIMARY
		bracket.custom_minimum_size = Vector2(24, 24)
		bracket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bracket)
		bracket.set_anchors_preset(corner.preset)
		match corner.preset:
			Control.PRESET_TOP_LEFT:
				bracket.offset_left = corner.ox
				bracket.offset_top = corner.oy
				bracket.offset_right = corner.ox + 24
				bracket.offset_bottom = corner.oy + 24
			Control.PRESET_TOP_RIGHT:
				bracket.offset_left = -24 + corner.ox
				bracket.offset_top = corner.oy
				bracket.offset_right = corner.ox
				bracket.offset_bottom = corner.oy + 24
			Control.PRESET_BOTTOM_LEFT:
				bracket.offset_left = corner.ox
				bracket.offset_top = -24 + corner.oy
				bracket.offset_right = corner.ox + 24
				bracket.offset_bottom = corner.oy
			Control.PRESET_BOTTOM_RIGHT:
				bracket.offset_left = -24 + corner.ox
				bracket.offset_top = -24 + corner.oy
				bracket.offset_right = corner.ox
				bracket.offset_bottom = corner.oy


# Inner class — draws an L-shape via two lines. Flipping handles all 4 corners.
class _LCornerBracket extends Control:
	var color: Color = Color(1, 1, 1, 1)
	var flip_h: bool = false
	var flip_v: bool = false
	const THICKNESS: float = 2.0
	const ARM: float = 22.0

	func _draw() -> void:
		var origin = Vector2(0, 0)
		var horiz_end = Vector2(ARM, 0)
		var vert_end = Vector2(0, ARM)
		if flip_h:
			origin.x = size.x
			horiz_end.x = size.x - ARM
			vert_end.x = size.x
		if flip_v:
			origin.y = size.y
			horiz_end.y = size.y
			vert_end.y = size.y - ARM
		# Slight outer shadow for the gold glow effect.
		draw_line(origin, horiz_end, Color(color, 0.4), THICKNESS + 4)
		draw_line(origin, vert_end, Color(color, 0.4), THICKNESS + 4)
		draw_line(origin, horiz_end, color, THICKNESS)
		draw_line(origin, vert_end, color, THICKNESS)


# Title mark: big gold "WalkAura" with ornament glyphs + italic tagline.
func _build_title_mark() -> void:
	var mark = VBoxContainer.new()
	mark.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mark.offset_top = 60
	mark.offset_bottom = 160
	mark.alignment = BoxContainer.ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_theme_constant_override("separation", 4)
	add_child(mark)

	var title_green = Color.from_rgba8(96, 220, 110)
	var title_green_glow = Color(96.0 / 255.0, 220.0 / 255.0, 110.0 / 255.0, 0.35)

	var title = Label.new()
	title.text = "✦  WalkAura  ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", title_green)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_shadow_color", title_green_glow)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 14)
	mark.add_child(title)

	var tagline = Label.new()
	tagline.text = "Walk · Explore · Grow"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_override("font", Styler.QUADRAT_FONT)
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", title_green)
	tagline.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	tagline.add_theme_constant_override("outline_size", 2)
	mark.add_child(tagline)


# 4-5 gold motes drifting up from below the card area. CPUParticles2D so we
# avoid the GPU particles compile path on low-end Android.
func _build_motes() -> void:
	_motes = CPUParticles2D.new()
	_motes.amount = 8
	_motes.lifetime = 6.0
	_motes.preprocess = 3.0
	_motes.emitting = true
	# Node2D — uses position, not Control anchors. Mid-screen emission point.
	_motes.position = Vector2(get_viewport_rect().size.x / 2.0, get_viewport_rect().size.y - 80)
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(180, 80)
	_motes.direction = Vector2(0, -1)
	_motes.spread = 25.0
	_motes.initial_velocity_min = 10.0
	_motes.initial_velocity_max = 25.0
	_motes.gravity = Vector2(0, -8)
	_motes.scale_amount_min = 1.5
	_motes.scale_amount_max = 3.0
	_motes.color = Styler.COL_PRIMARY
	_motes.color_ramp = _make_mote_color_ramp()
	add_child(_motes)


func _make_mote_color_ramp() -> Gradient:
	var g = Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(Styler.COL_PRIMARY, 0.0))
	g.add_point(0.2, Color(Styler.COL_PRIMARY, 0.85))
	g.add_point(0.8, Color(Styler.COL_PRIMARY, 0.6))
	g.set_offset(g.get_point_count() - 1, 1.0)
	g.set_color(g.get_point_count() - 1, Color(Styler.COL_PRIMARY, 0.0))
	return g


# Gold gradient embossed button — "ENTER THE REALM" primary CTA.
func _style_gold_emboss_button(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.from_rgba8(20, 16, 10))
	btn.add_theme_color_override("font_hover_color", Color.from_rgba8(20, 16, 10))
	btn.add_theme_color_override("font_pressed_color", Color.from_rgba8(20, 16, 10))
	btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.25, 0.15, 0.5))
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Styler.COL_PRIMARY
		sb.set_corner_radius_all(6)
		sb.border_color = Color.from_rgba8(216, 160, 64)
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 2
		sb.shadow_color = Styler.COL_GOLD_GLOW
		sb.shadow_size = 14
		match state_name:
			"hover":
				sb.bg_color = Styler.COL_PRIMARY.lightened(0.08)
				sb.shadow_size = 20
			"pressed":
				sb.bg_color = Styler.COL_PRIMARY.darkened(0.08)
				sb.shadow_size = 6
				sb.content_margin_top = 2
			"disabled":
				sb.bg_color = Styler.COL_PRIMARY.darkened(0.4)
				sb.shadow_size = 0
		btn.add_theme_stylebox_override(state_name, sb)


# White Google-styled button. Placeholder — no real auth in P5 scope.
# Google-sanctioned DARK button variant. Colors/border/typography follow the
# "Sign in with Google" branding guidelines. NOTE: spec font is Roboto Medium;
# the project ships QUADRAT, the closest bundled face — drop in a Roboto Medium
# .ttf here for strict brand compliance.
func _style_google_button(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	btn.add_theme_font_size_override("font_size", 14)
	var text_col = Color.from_rgba8(0xE3, 0xE3, 0xE3)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_color_override("font_focus_color", text_col)
	btn.add_theme_color_override("font_disabled_color", Color(text_col, 0.38))
	# Clamp the 48px logo down to the spec ~20px and apply the logo→label gap.
	btn.add_theme_constant_override("icon_max_width", 20)
	btn.add_theme_constant_override("h_separation", 12)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color.from_rgba8(0x13, 0x13, 0x14)      # #131314
		sb.set_corner_radius_all(4)
		sb.border_color = Color.from_rgba8(0x8E, 0x91, 0x8F)  # #8E918F
		sb.set_border_width_all(1)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		# State layers: subtle white overlay on hover/press per Material/Google.
		match state_name:
			"hover":
				sb.bg_color = Color.from_rgba8(0x1E, 0x1F, 0x20)
			"pressed":
				sb.bg_color = Color.from_rgba8(0x2A, 0x2B, 0x2C)
		btn.add_theme_stylebox_override(state_name, sb)


# Outlined button — "Create New Account" secondary action.
func _style_outlined_button(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.75))
	btn.add_theme_color_override("font_hover_color", Styler.COL_PRIMARY)
	btn.add_theme_color_override("font_pressed_color", Styler.COL_PRIMARY)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.3)
		sb.set_corner_radius_all(6)
		sb.border_color = Color(Styler.COL_PRIMARY, 0.5)
		sb.set_border_width_all(1)
		match state_name:
			"hover":
				sb.bg_color = Color(0, 0, 0, 0.5)
				sb.border_color = Styler.COL_PRIMARY
			"pressed":
				sb.bg_color = Color(0, 0, 0, 0.4)
				sb.content_margin_top = 1
		btn.add_theme_stylebox_override(state_name, sb)


# Hairline "OR" separator between primary + secondary CTAs.
func _build_or_separator() -> HBoxContainer:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.custom_minimum_size = Vector2(0, 20)
	var left_rule = ColorRect.new()
	left_rule.color = Color(Styler.COL_PRIMARY, 0.18)
	left_rule.custom_minimum_size = Vector2(0, 1)
	left_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(left_rule)
	var or_lbl = Label.new()
	or_lbl.text = "OR"
	or_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	or_lbl.add_theme_font_size_override("font_size", 11)
	or_lbl.add_theme_color_override("font_color", Color.from_rgba8(150, 134, 100))
	hb.add_child(or_lbl)
	var right_rule = ColorRect.new()
	right_rule.color = Color(Styler.COL_PRIMARY, 0.18)
	right_rule.custom_minimum_size = Vector2(0, 1)
	right_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(right_rule)
	return hb


# Tiny uppercase gold-soft field label.
func _style_field_label(lbl: Label) -> void:
	lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.85))
	lbl.add_theme_constant_override("outline_size", 1)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))


# Ornate dark line edit with gold-soft left edge + gold focus glow.
func _style_ornate_line_edit(le: LineEdit) -> void:
	le.custom_minimum_size = Vector2(0, 42)
	le.add_theme_color_override("font_color", Color.from_rgba8(232, 224, 207))
	le.add_theme_color_override("caret_color", Styler.COL_PRIMARY)
	le.add_theme_color_override("font_placeholder_color", Color(Styler.COL_PRIMARY, 0.35))
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color.from_rgba8(10, 10, 16, 180)
	bg.set_corner_radius_all(4)
	bg.set_border_width_all(1)
	bg.border_color = Color.from_rgba8(255, 255, 255, 30)
	bg.border_width_left = 2
	bg.content_margin_left = 12
	bg.content_margin_right = 10
	bg.shadow_color = Color(0, 0, 0, 0.5)
	bg.shadow_size = 2
	le.add_theme_stylebox_override("normal", bg)
	var focus = bg.duplicate()
	focus.border_color = Styler.COL_PRIMARY
	focus.set_border_width_all(2)
	focus.border_width_left = 2
	focus.shadow_color = Styler.COL_GOLD_GLOW
	focus.shadow_size = 8
	le.add_theme_stylebox_override("focus", focus)


# Official Google "G" logo asset (4-color, exact geometry — brand-compliant,
# unlike the old hand-drawn conic approximation). Loaded at runtime so the SVG
# import doesn't have to resolve at parse time.
func _load_google_logo() -> Texture2D:
	var tex = load("res://scenes/login_screen/google_g_logo.svg")
	if tex is Texture2D:
		return tex
	return null


const _ANDROID_PLUGIN_NAME := "GodotAndroidPlugin"

# Google sign-in. On Android the plugin launches the Google account picker and
# emits `google_sign_in_completed(id_token, error)`; on success we run the
# id_token through the shared login flow (server verifies + mints our token).
# Off Android (desktop/editor) the plugin is absent, so we flash the toast.
func _on_google_pressed() -> void:
	if not Engine.has_singleton(_ANDROID_PLUGIN_NAME):
		_show_google_toast()
		return
	var plugin = Engine.get_singleton(_ANDROID_PLUGIN_NAME)
	if not plugin.has_method("signInWithGoogle"):
		_show_google_toast()
		return
	if not ServerConnector._is_socket_open():
		_status_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.2))
		_status_label.text = "Not connected to server"
		return
	_status_label.text = ""
	_btn_google.disabled = true
	if not plugin.is_connected("google_sign_in_completed", _on_google_sign_in_completed):
		plugin.connect("google_sign_in_completed", _on_google_sign_in_completed, CONNECT_ONE_SHOT)
	plugin.signInWithGoogle()

func _on_google_sign_in_completed(id_token: String, error: String) -> void:
	_btn_google.disabled = false
	if error != "" or id_token == "":
		_status_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.2))
		_status_label.text = "Google sign-in failed"
		return
	# Reuse the full login machinery; server replies on cmd=login_google with
	# the same message sequence as a password login.
	_begin_login_flow(func(): SignalManager.signal_LoginGoogle.emit(id_token))

# Fallback toast for platforms without the Android plugin.
func _show_google_toast() -> void:
	if _google_toast == null:
		return
	_google_toast.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(_google_toast, "modulate:a", 1.0, 0.18)
	t.tween_interval(2.0)
	t.tween_property(_google_toast, "modulate:a", 0.0, 0.5)


func _on_create_pressed() -> void:
	_panel.visible = false
	_status_label.text = ""
	child = CREATE_USER_UI.instantiate()
	add_child(child)
	child.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)


func _on_child_closed() -> void:
	_panel.visible = true
	child = null


func _on_login_pressed() -> void:
	_status_label.text = ""
	if _username_edit.text.strip_edges() == "" or _password_edit.text == "":
		_status_label.text = "Username and password are required"
		return
	if not ServerConnector._is_socket_open():
		_status_label.text = "Not connected to server"
		return
	_begin_login_flow(func(): SignalManager.signal_LoginUser.emit(_username_edit.text, _password_edit.text))

# Shared login machinery for both manual (password) and auto (token) login.
# `emit_login` sends the actual login command; everything else — state reset,
# loading UI, signal wiring, threaded preload, and the 15s timeout — is identical
# whichever way we authenticated.
func _begin_login_flow(emit_login: Callable) -> void:
	_btn_login.disabled = true
	_btn_create.disabled = true
	# Reset all state — also covers the retry-after-error case
	_login_ok = false
	_login_error = ""
	_login_result_received = false
	_login_data_received = false
	_inventory_received = false
	_preload_done = false
	_finalized = false
	_last_reported_done = -1
	_preloaded_refs.clear()
	_resolved_paths.clear()
	_failed_paths.clear()

	# Hide the login panel — user now sees background art + loading bar
	_panel.visible = false
	_loading_panel.visible = true

	# Defensive: on auth-fail or timeout paths, a CONNECT_ONE_SHOT handler may
	# not have fired yet (e.g. signal_InventoryReceived never arrives for a
	# rejected login). Disconnect any lingering handler first so the new
	# connection is the only one that fires on this attempt.
	_disconnect_login_signals()
	AccountManager.signal_LoginResult.connect(_on_login_result, CONNECT_ONE_SHOT)
	AccountManager.signal_AccountDataReceived.connect(_on_login_data, CONNECT_ONE_SHOT)
	AccountManager.signal_InventoryReceived.connect(_on_inventory_received, CONNECT_ONE_SHOT)
	emit_login.call()

	# Kick off threaded preload in parallel with the WS round-trip. When all
	# gates close (login + inventory + preload), _try_finalize transitions.
	_start_preload()

	# Safety net: if the server never responds within 15s, restore the panel
	# with a timeout error instead of leaving the user at "Loading... 65/65"
	# forever. Passing `false` disables physics-process scaling so the timer
	# fires on wall-clock time even if the game pauses.
	_login_timeout_timer = get_tree().create_timer(_LOGIN_TIMEOUT_SEC)
	_login_timeout_timer.timeout.connect(_on_login_timeout)


# Dispatches every manifest path to ResourceLoader in one shot. Godot threads
# the requests internally; we poll their status in _process.
func _start_preload() -> void:
	_preload_manifest = PreloadManifest.get_manifest()
	_preload_total = _preload_manifest.size()
	_progress_bar.max_value = _preload_total
	_progress_bar.value = 0
	_progress_label.text = "Loading... 0 / %d resources" % _preload_total
	for path in _preload_manifest:
		ResourceLoader.load_threaded_request(path)
	set_process(true)


func _process(_dt: float) -> void:
	if _preload_done or _finalized:
		return
	if not is_inside_tree():
		return
	var failed: int = 0
	for path in _preload_manifest:
		if _resolved_paths.has(path):
			continue
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				_resolved_paths[path] = true
				# Claim the Resource and hold a strong ref. Prevents Godot's
				# cache from evicting the entry between now and the later
				# SceneManage.goto() that relies on the cache hit.
				var res = ResourceLoader.load_threaded_get(path)
				if res and not _preloaded_refs.has(res):
					_preloaded_refs.append(res)
			ResourceLoader.THREAD_LOAD_FAILED:
				_resolved_paths[path] = true
				_failed_paths[path] = true
				printerr("Preload FAILED: ", path)
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_resolved_paths[path] = true
				_failed_paths[path] = true
				printerr("Preload INVALID: ", path)
			# THREAD_LOAD_IN_PROGRESS → not counted
	var done: int = _resolved_paths.size()
	failed = _failed_paths.size()
	# Skip redundant label + bar writes when nothing changed (saves BiDi
	# layout re-runs on slower mobile devices).
	if done != _last_reported_done:
		_progress_bar.max_value = _preload_total
		_progress_bar.value = done
		_progress_label.text = "Loading... %d / %d resources" % [done, _preload_total]
		_last_reported_done = done
	if done >= _preload_total:
		_preload_done = true
		set_process(false)
		if failed > 0:
			printerr("Preload: %d of %d resources failed (non-fatal)" % [failed, _preload_total])
		_try_finalize()


func _on_login_result(ok: bool, error: String) -> void:
	_login_ok = ok
	_login_error = error
	_login_result_received = true


func _on_login_data(_result) -> void:
	_login_data_received = true
	# On auth failure, don't make the player watch the loading bar finish —
	# surface the error immediately. The _finalized guard prevents the later
	# _try_finalize (from _process or _on_inventory_received) from firing.
	# Check _login_result_received defensively in case the emit order ever
	# changes in account_manager.gd.
	if _login_result_received and not _login_ok:
		_finalized = true
		_cancel_timeout()
		_restore_panel_with_error()
		return
	_try_finalize()


func _on_inventory_received(data) -> void:
	_inventory_received = true
	# Phase 2: player's actual equipment is now known. Enqueue each equipped
	# item's icon + overlay path so the paper doll and inventory slots don't
	# stutter on the first post-login frame.
	var extra_paths: Array[String] = _build_equipment_preload_paths(data)
	if not extra_paths.is_empty():
		for path in extra_paths:
			if _preload_manifest.has(path):
				continue   # already in the static manifest
			_preload_manifest.append(path)
			ResourceLoader.load_threaded_request(path)
		_preload_total = _preload_manifest.size()
		# Unfreeze _process if it already finished before inventory arrived
		if _preload_done:
			_preload_done = false
			set_process(true)
	_try_finalize()


# Translates each equipped item's icon_key to ItemDB's registered icon path
# and, when the slot has a paper-doll overlay, the overlay path. Returns a
# flat list suitable for append to _preload_manifest.
func _build_equipment_preload_paths(data) -> Array[String]:
	var out: Array[String] = []
	if typeof(data) != TYPE_DICTIONARY:
		return out
	if not data.has("equipment"):
		return out
	for item in data.equipment:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var raw = item.get("item_icon", "")
		var icon_key: String = raw[0] if raw is Array and not raw.is_empty() else str(raw)
		if icon_key == "":
			continue
		if ItemDB._item_icon_paths.has(icon_key):
			out.append(ItemDB._item_icon_paths[icon_key])
		if ItemDB._item_overlay_paths.has(icon_key):
			out.append(ItemDB._item_overlay_paths[icon_key])
	return out


# Transition fires only after all three gates close: login data, inventory
# data, and preload. Preloaded resources are in Godot's cache so the load()
# inside SceneManage.goto() hits cache instantly.
func _try_finalize() -> void:
	if _finalized:
		return
	if not is_inside_tree():
		return
	if not (_preload_done and _login_data_received and _inventory_received):
		return
	_finalized = true
	_cancel_timeout()
	if _login_ok:
		SceneManage.goto("res://scenes/app_scenes_handler.tscn")
	else:
		_restore_panel_with_error()


func _on_login_timeout() -> void:
	if _finalized or _login_data_received:
		return
	_finalized = true
	set_process(false)
	# Disconnect stale CONNECT_ONE_SHOT handlers. If the server replies after
	# the timeout fires, we don't want those stale handlers corrupting the
	# next login attempt's state when they finally run.
	_disconnect_login_signals()
	_login_error = "server_not_responding"
	_status_label.text = "Server not responding"
	_loading_panel.visible = false
	_panel.visible = true
	_btn_login.disabled = false
	_btn_create.disabled = false
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.2))


func _cancel_timeout() -> void:
	if _login_timeout_timer and _login_timeout_timer.timeout.is_connected(_on_login_timeout):
		_login_timeout_timer.timeout.disconnect(_on_login_timeout)
	_login_timeout_timer = null


func _disconnect_login_signals() -> void:
	if AccountManager.signal_LoginResult.is_connected(_on_login_result):
		AccountManager.signal_LoginResult.disconnect(_on_login_result)
	if AccountManager.signal_AccountDataReceived.is_connected(_on_login_data):
		AccountManager.signal_AccountDataReceived.disconnect(_on_login_data)
	if AccountManager.signal_InventoryReceived.is_connected(_on_inventory_received):
		AccountManager.signal_InventoryReceived.disconnect(_on_inventory_received)


func _restore_panel_with_error() -> void:
	_loading_panel.visible = false
	_panel.visible = true
	_btn_login.disabled = false
	_btn_create.disabled = false
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.2, 0.2))
	# Prefer the GameTextEn localized string for known codes. Fall back to a
	# generic "Login failed: X" for anything not yet mapped (also covers the
	# client-side synthetic "server_not_responding" code set by the timeout).
	var text: String = GameTextEn.error_texts.get(_login_error, "")
	if text == "":
		match _login_error:
			"server_not_responding":
				text = "Server not responding"
			"":
				text = "Login failed"
			_:
				text = "Login failed: " + _login_error
	_status_label.text = text
