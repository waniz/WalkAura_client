extends Control

const CREATE_USER_UI = preload("uid://d1bmiemb8yjfl")

var _panel: PanelContainer
var _username_edit: LineEdit
var _password_edit: LineEdit
var _status_label: Label
var _btn_login: Button
var _btn_create: Button
var _version_label: Label

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

# 15-second timeout safety net for flaky networks. If the server never
# responds, the timer fires and restores the panel with an error instead of
# leaving the user stuck watching a full progress bar.
const _LOGIN_TIMEOUT_SEC: float = 15.0
var _login_timeout_timer: SceneTreeTimer = null


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


func _on_version_blocked(_info: Dictionary) -> void:
	if _btn_login:
		_btn_login.disabled = true
	if _btn_create:
		_btn_create.disabled = true


func _build_ui() -> void:
	# Center container for the card
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Parchment card
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	_apply_login_panel_style(_panel)
	center.add_child(_panel)

	# Margin inside card
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# Game title
	var title = Label.new()
	title.text = "WalkAura"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.13, 0.37, 0.13))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Walk. Explore. Grow."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", Styler.QUADRAT_FONT)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	vbox.add_child(subtitle)

	# Separator
	var sep = HSeparator.new()
	sep.modulate = Color(0, 0, 0, 0.2)
	vbox.add_child(sep)

	# Username field
	var username_label = Label.new()
	username_label.text = "Username"
	Styler.style_parchment_label(username_label, Styler.COLOR_TEXT_DARK)
	vbox.add_child(username_label)

	_username_edit = LineEdit.new()
	_username_edit.placeholder_text = "Enter username"
	_username_edit.text = "test_user"
	_username_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_username_edit.add_theme_font_size_override("font_size", 18)
	_style_parchment_line_edit(_username_edit)
	vbox.add_child(_username_edit)

	# Password field
	var password_label = Label.new()
	password_label.text = "Password"
	Styler.style_parchment_label(password_label, Styler.COLOR_TEXT_DARK)
	vbox.add_child(password_label)

	_password_edit = LineEdit.new()
	_password_edit.placeholder_text = "Enter password"
	_password_edit.text = "1234"
	_password_edit.secret = true
	_password_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_password_edit.add_theme_font_size_override("font_size", 18)
	_style_parchment_line_edit(_password_edit)
	vbox.add_child(_password_edit)

	# Status label (errors)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color.from_rgba8(200, 40, 40))
	vbox.add_child(_status_label)

	# Buttons
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_box)

	_btn_login = Button.new()
	_btn_login.text = "Play"
	_btn_login.custom_minimum_size = Vector2(0, 48)
	Styler.style_button(_btn_login, Color(0.24, 0.51, 0.27))
	_btn_login.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_btn_login.add_theme_font_size_override("font_size", 20)
	Styler.wire_button_anim(_btn_login)
	_btn_login.pressed.connect(_on_login_pressed)
	btn_box.add_child(_btn_login)

	_btn_create = Button.new()
	_btn_create.text = "Create New Account"
	_btn_create.custom_minimum_size = Vector2(0, 40)
	Styler.style_button(_btn_create, Color(0.55, 0.53, 0.50))
	_btn_create.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_btn_create.add_theme_font_size_override("font_size", 16)
	Styler.wire_button_anim(_btn_create)
	_btn_create.pressed.connect(_on_create_pressed)
	btn_box.add_child(_btn_create)

	# Version label at bottom of screen
	_version_label = Label.new()
	_version_label.text = ""
	_version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_version_label.offset_left = 8
	_version_label.offset_top = -24
	_version_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
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
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(Styler.COLOR_PARCHMENT, 0.7)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Styler.COLOR_BORDER
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.4)
	panel.add_theme_stylebox_override("panel", sb)


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
	SignalManager.signal_LoginUser.emit(_username_edit.text, _password_edit.text)

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
	var done: int = 0
	var failed: int = 0
	for path in _preload_manifest:
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				done += 1
				# Claim the Resource and hold a strong ref. Prevents Godot's
				# cache from evicting the entry between now and the later
				# SceneManage.goto() that relies on the cache hit.
				var res = ResourceLoader.load_threaded_get(path)
				if res and not _preloaded_refs.has(res):
					_preloaded_refs.append(res)
			ResourceLoader.THREAD_LOAD_FAILED:
				failed += 1
				done += 1
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				failed += 1
				done += 1
			# THREAD_LOAD_IN_PROGRESS → not counted
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
