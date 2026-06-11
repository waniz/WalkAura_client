extends Control

## Pre-entry rift detail screen (AAA dark panel style).
## Shows rift portal art placeholder, tier badge, name, description,
## requirements, summary, lore, and enter/history buttons.

const HISTORY_SCREEN = preload("res://scenes/secondary_scenes/rift_history_screen.gd")

var location_id: int = 0

var _enter_btn: Button
var _enter_timer: SceneTreeTimer = null
var _transitioning: bool = false


func _ready() -> void:
	_build_ui()
	AccountManager.signal_AccountDataReceived.connect(_on_account_data)


func _build_ui() -> void:
	anchor_left = 0.0; anchor_top = 0.0
	anchor_right = 1.0; anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	# Dark overlay behind modal
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Rift data
	var cfg = RiftData.RIFT_TABLE.get(location_id, {})
	var tier = int(cfg.get("tier", 0))
	var tier_color = RiftData.TIER_COLORS.get(tier, Color.WHITE)

	# Dark panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_dark_panel_style(panel, tier_color)
	add_child(panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	panel.add_child(root_vbox)

	# --- Rift portal art (40-45% of panel height) ---
	var art_area = ColorRect.new()
	art_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_area.size_flags_stretch_ratio = 0.42
	art_area.custom_minimum_size = Vector2(0, 120)
	art_area.color = Color(tier_color, 0.15)
	art_area.clip_contents = true
	root_vbox.add_child(art_area)

	if ItemDB.has_rift_icon(location_id):
		var banner = TextureRect.new()
		banner.texture = ItemDB.get_rift_icon(location_id)
		banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_area.add_child(banner)
	else:
		# Fallback glow placeholder
		var glow = ColorRect.new()
		glow.custom_minimum_size = Vector2(80, 80)
		glow.color = Color(tier_color, 0.3)
		glow.set_anchors_preset(Control.PRESET_CENTER)
		glow.grow_horizontal = Control.GROW_DIRECTION_BOTH
		glow.grow_vertical = Control.GROW_DIRECTION_BOTH
		art_area.add_child(glow)

	# Close button overlaid on art area
	var close_btn = Button.new()
	close_btn.text = "X"
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.pressed.connect(queue_free)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -52
	close_btn.offset_right = -8
	close_btn.offset_top = 8
	close_btn.offset_bottom = 52
	art_area.add_child(close_btn)

	# --- Content area with solid dark background (remaining ~58%) ---
	var content_panel = PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_stretch_ratio = 0.58
	var cp_sb = StyleBoxFlat.new()
	cp_sb.bg_color = Color.from_rgba8(16, 18, 24, 255)
	cp_sb.content_margin_left = 16
	cp_sb.content_margin_right = 16
	cp_sb.content_margin_top = 12
	cp_sb.content_margin_bottom = 14
	content_panel.add_theme_stylebox_override("panel", cp_sb)
	root_vbox.add_child(content_panel)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_panel.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	if cfg.is_empty():
		var fallback = Label.new()
		fallback.text = "No rift data available."
		fallback.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
		content.add_child(fallback)
		return

	# Tier badge
	var tier_label = Label.new()
	tier_label.text = RiftData.TIER_NAMES.get(tier, "UNKNOWN TIER")
	tier_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	tier_label.add_theme_font_size_override("font_size", 13)
	tier_label.add_theme_color_override("font_color", tier_color)
	content.add_child(tier_label)

	# Rift name
	var name_lbl = Label.new()
	name_lbl.text = cfg.get("name", "Unknown Rift")
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", tier_color)
	content.add_child(name_lbl)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = cfg.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 200, 200))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	content.add_child(desc_lbl)

	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_color_override("separator", Color(1, 1, 1, 0.08))
	content.add_child(sep1)

	# --- Requirements as card boxes ---
	var rift_lvl = int(Account.rift_lvl) if Account.rift_lvl != null else 1
	var account_lvl = int(Account.level) if Account.level != null else 1
	var req_rift = int(cfg.get("req_rift_lvl", 1))
	var req_account = int(cfg.get("req_account_lvl", 1))
	var rift_met = rift_lvl >= req_rift
	var account_met = account_lvl >= req_account
	var all_met = rift_met and account_met

	var req_row = HBoxContainer.new()
	req_row.add_theme_constant_override("separation", 10)
	content.add_child(req_row)

	req_row.add_child(_build_req_card("RIFT LV", str(req_rift), rift_met))
	req_row.add_child(_build_req_card("ACCT LV", str(req_account), account_met))

	# Summary line
	var summary = Label.new()
	summary.text = "%d encounters  ·  %d steps" % [
		int(cfg.get("encounter_count", 0)),
		int(cfg.get("total_steps", 0)),
	]
	summary.add_theme_color_override("font_color", Color.from_rgba8(180, 180, 180))
	summary.add_theme_font_size_override("font_size", 14)
	content.add_child(summary)

	# Gear score
	var gs_range = str(cfg.get("gear_score_range", ""))
	if gs_range != "":
		var gs_lbl = Label.new()
		gs_lbl.text = "Gear Score: %s" % gs_range
		gs_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
		gs_lbl.add_theme_font_size_override("font_size", 14)
		content.add_child(gs_lbl)

	# Separator
	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("separator", Color(1, 1, 1, 0.08))
	content.add_child(sep2)

	# Lore text in inset panel
	var lore_text = str(cfg.get("lore", ""))
	if lore_text != "":
		var lore_panel = PanelContainer.new()
		var lore_sb = StyleBoxFlat.new()
		lore_sb.bg_color = Color(1, 1, 1, 0.03)
		lore_sb.set_corner_radius_all(4)
		lore_sb.content_margin_left = 10
		lore_sb.content_margin_right = 10
		lore_sb.content_margin_top = 8
		lore_sb.content_margin_bottom = 8
		lore_panel.add_theme_stylebox_override("panel", lore_sb)
		content.add_child(lore_panel)

		var lore_lbl = Label.new()
		lore_lbl.text = lore_text
		lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore_lbl.add_theme_color_override("font_color", Color.from_rgba8(140, 130, 110))
		lore_lbl.add_theme_font_size_override("font_size", 14)
		lore_panel.add_child(lore_lbl)

	# --- Action buttons ---
	_enter_btn = Button.new()
	_enter_btn.custom_minimum_size = Vector2(0, 56)
	_enter_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enter_btn.add_theme_font_override("font", Styler.JANDA_FONT)
	_enter_btn.add_theme_font_size_override("font_size", 20)
	if all_met:
		_enter_btn.text = "▸ ENTER RIFT"
		_style_tier_emboss_button(_enter_btn, tier_color)
		_enter_btn.pressed.connect(_on_enter_pressed)
	else:
		_enter_btn.text = "🔒 LOCKED"
		_enter_btn.disabled = true
		_style_locked_button(_enter_btn)
	content.add_child(_enter_btn)

	var history_btn = Button.new()
	history_btn.text = "Rift History"
	history_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button_small(history_btn, Color.from_rgba8(60, 50, 80))
	history_btn.add_theme_color_override("font_color", Color.from_rgba8(180, 160, 220))
	history_btn.add_theme_color_override("font_hover_color", Color.from_rgba8(200, 180, 240))
	history_btn.pressed.connect(_on_history_pressed)
	content.add_child(history_btn)


func _build_req_card(label_text: String, value_text: String, met: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.2)
	sb.set_corner_radius_all(6)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	if met:
		sb.border_color = Color.from_rgba8(60, 200, 100, 180)
	else:
		sb.border_color = Color.from_rgba8(220, 80, 80, 180)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.from_rgba8(150, 150, 150))
	label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label)

	var val_row = HBoxContainer.new()
	val_row.alignment = BoxContainer.ALIGNMENT_CENTER
	val_row.add_theme_constant_override("separation", 6)
	vbox.add_child(val_row)

	var val_lbl = Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 20)
	val_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	if met:
		val_lbl.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100))
	else:
		val_lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 80, 80))
	val_row.add_child(val_lbl)

	var indicator = Label.new()
	if met:
		indicator.text = "✓"
		indicator.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100))
	else:
		indicator.text = "✗"
		indicator.add_theme_color_override("font_color", Color.from_rgba8(220, 80, 80))
	indicator.add_theme_font_size_override("font_size", 16)
	val_row.add_child(indicator)

	return card


func _on_enter_pressed() -> void:
	_enter_btn.disabled = true
	_enter_btn.text = "Starting..."
	SignalManager.signal_UserActivity.emit(7, location_id, "start")
	_enter_timer = get_tree().create_timer(3.0)
	_enter_timer.timeout.connect(_on_enter_timeout)


func _on_enter_timeout() -> void:
	if is_instance_valid(_enter_btn) and _enter_btn.disabled:
		_enter_btn.disabled = false
		_enter_btn.text = "ENTER RIFT"
		SignalManager.signal_GameNotification.emit(
			"Could not enter rift", Color.from_rgba8(255, 100, 100))


func _on_account_data(_ok) -> void:
	if _transitioning:
		return
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	if rift_id > 0:
		_transitioning = true
		_enter_timer = null
		var loc = location_id
		tree_exited.connect(func(): SignalManager.signal_ShowRift.emit(loc), CONNECT_ONE_SHOT)
		queue_free()


func _on_history_pressed() -> void:
	var screen = HISTORY_SCREEN.new()
	add_child(screen)


# Tier-colored embossed ENTER button — primary CTA per P5.4 spec.
func _style_tier_emboss_button(btn: Button, tier_color: Color) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	btn.add_theme_constant_override("outline_size", 2)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = tier_color
		sb.set_corner_radius_all(6)
		sb.border_color = tier_color.lightened(0.3)
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 2
		sb.shadow_color = Color(tier_color, 0.55)
		sb.shadow_size = 14
		match state_name:
			"hover":
				sb.bg_color = tier_color.lightened(0.1)
				sb.shadow_size = 20
			"pressed":
				sb.bg_color = tier_color.darkened(0.08)
				sb.shadow_size = 6
				sb.content_margin_top = 2
		btn.add_theme_stylebox_override(state_name, sb)


# Disabled / locked button — muted gray with red lock cue.
func _style_locked_button(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	btn.add_theme_constant_override("outline_size", 2)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color.from_rgba8(40, 40, 50)
		sb.set_corner_radius_all(6)
		sb.border_color = Color(Styler.COL_OFFENSE, 0.4)
		sb.set_border_width_all(1)
		btn.add_theme_stylebox_override(state_name, sb)
