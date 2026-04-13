class_name CharacterHUD extends Control

@onready var avatar: TextureRect = $Avatar
@onready var name_level: RichTextLabel = $Avatar/MainBars/Name_level
@onready var hp_bar: ProgressBar = $Avatar/MainBars/HPBar
@onready var hp_label: Label = $Avatar/MainBars/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $Avatar/MainBars/MPBar
@onready var mp_label: Label = $Avatar/MainBars/MPBar/MPLabel
@onready var shield_bar: ProgressBar = $Avatar/MainBars/ShieldBar
@onready var shield_label: Label = $Avatar/MainBars/ShieldBar/ShieldLabel
@onready var activity_label: Label = $Avatar/MainBars/HBoxContainer/ActivityLabel
@onready var texture_rect: TextureRect = $Avatar/MainBars/HBoxContainer/PanelContainer/TextureRect
@onready var panel_container: PanelContainer = $Avatar/MainBars/HBoxContainer/PanelContainer
@onready var level_badge: PanelContainer = $Avatar/LevelBadge
@onready var level_label: Label = $Avatar/LevelBadge/LevelLabel

var _shield_overlay: ProgressBar = null
var _level_ring: RadialProgress = null
var _level_ring_label: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AccountManager.signal_AccountDataReceived.connect(_update_character_hud)
	SignalManager.signal_AvatarChanged.connect(_on_avatar_changed)
	avatar.mouse_filter = Control.MOUSE_FILTER_STOP
	avatar.gui_input.connect(_on_avatar_gui_input)

	# Make bars look "splendid": rounded, shadowed, colored
	Styler.style_bar(hp_bar, Color.from_rgba8(220, 60, 60), Color.from_rgba8(40, 20, 20))
	Styler.style_bar(mp_bar, Color.from_rgba8(70, 120, 255), Color.from_rgba8(20, 30, 60))

	# Hide the old standalone shield bar — replaced by overlay
	shield_bar.visible = false

	# ── Shield overlay on top of HP bar ──────────────────────────────────────
	_shield_overlay = ProgressBar.new()
	_shield_overlay.show_percentage = false
	_shield_overlay.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	_shield_overlay.visible         = false
	hp_bar.add_child(_shield_overlay)
	# Keep overlay behind HPLabel (HPLabel is already child idx 0 → push overlay under it)
	hp_bar.move_child(_shield_overlay, 0)
	# Extend ~2x vertically beyond the HP bar (shield "aura" overflows above and below)
	_shield_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shield_overlay.offset_top    = -1
	_shield_overlay.offset_bottom =  1

	# Transparent trough — only the filled portion is visible
	var sh_bg = StyleBoxFlat.new()
	sh_bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	for r in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sh_bg.set("corner_radius_" + r, 10)
	_shield_overlay.add_theme_stylebox_override("background", sh_bg)

	# WoW mana-shield: bright icy blue, semi-transparent with a glow shadow
	var sh_fill = StyleBoxFlat.new()
	sh_fill.bg_color     = Color.from_rgba8(100, 200, 255, 190)
	sh_fill.shadow_color = Color.from_rgba8(160, 230, 255, 120)
	sh_fill.shadow_size  = 5
	for r in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sh_fill.set("corner_radius_" + r, 10)
	_shield_overlay.add_theme_stylebox_override("fill", sh_fill)

	Styler.style_name_label(activity_label, Color.from_rgba8(255, 128, 128))
	Styler.style_panel_no_margins(panel_container, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))

	# ── Avatar border: dark frame matching the level badge border ─────────
	var border_panel = Panel.new()
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_panel.offset_left = -5
	border_panel.offset_top = -5
	border_panel.offset_right = 5
	border_panel.offset_bottom = 5
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_color = Color.from_rgba8(60, 50, 40, 255)
	border_style.set_border_width_all(5)
	border_style.set_corner_radius_all(30)
	border_panel.add_theme_stylebox_override("panel", border_style)
	avatar.add_child(border_panel)
	avatar.move_child(border_panel, 0)

	# ── Level badge: replace rectangle with circular radial ring ──────────
	level_badge.visible = false

	var ring_size = 50
	var ring_radius = 24.0
	var ring_thickness = 6.0

	var ring_wrapper = Control.new()
	ring_wrapper.custom_minimum_size = Vector2(ring_size, ring_size)
	ring_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_wrapper.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ring_wrapper.offset_left = -30
	ring_wrapper.offset_top = -30
	ring_wrapper.offset_right = 20
	ring_wrapper.offset_bottom = 20
	avatar.add_child(ring_wrapper)

	# Dark circular background behind the ring
	var bg_circle = Control.new()
	bg_circle.position = Vector2(ring_size / 2.0, ring_size / 2.0)
	bg_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_circle.set_script(null)
	ring_wrapper.add_child(bg_circle)
	# Draw dark circle via _draw override - use a simple RadialProgress for this
	var bg_disc = RadialProgress.new()
	bg_disc.ring = false
	bg_disc.radius = ring_radius + 2.0
	bg_disc.thickness = ring_radius + 2.0
	bg_disc.max_value = 100.0
	bg_disc.progress = 100.0
	bg_disc.bg_color = Color.from_rgba8(16, 18, 24, 255)
	bg_disc.bar_color = Color.from_rgba8(16, 18, 24, 255)
	bg_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_disc.position = Vector2(ring_size / 2.0, ring_size / 2.0)
	ring_wrapper.add_child(bg_disc)

	# XP progress ring
	_level_ring = RadialProgress.new()
	_level_ring.ring = true
	_level_ring.radius = ring_radius
	_level_ring.thickness = ring_thickness
	_level_ring.max_value = 100.0
	_level_ring.progress = 0.0
	_level_ring.bg_color = Color(1, 1, 1, 0.15)
	_level_ring.bar_color = Styler.COL_PRIMARY
	_level_ring.border_width = 1.0
	_level_ring.border_color = Color(0, 0, 0, 0.5)
	_level_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_ring.position = Vector2(ring_size / 2.0, ring_size / 2.0)
	ring_wrapper.add_child(_level_ring)

	# Level number label centered
	_level_ring_label = Label.new()
	_level_ring_label.text = "1"
	_level_ring_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_ring_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_ring_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_level_ring_label.add_theme_font_size_override("font_size", 14)
	_level_ring_label.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	_level_ring_label.size = Vector2(ring_size, ring_size)
	_level_ring_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_wrapper.add_child(_level_ring_label)

	_update_character_hud(true)


func set_stats(hp_current: int, hp_max: int, mp_current: int, mp_max: int, shield_current: int, _shield_max: int, _xp_current: int, _xp_max: int) -> void:
	_set_bar(hp_bar, hp_label, hp_current, hp_max)
	_set_bar(mp_bar, mp_label, mp_current, mp_max)

	# Shield overlay: coverage = min(shield, hp_max) / hp_max
	if _shield_overlay != null:
		var capped = min(shield_current, hp_max)
		_shield_overlay.max_value = max(1, hp_max)
		_shield_overlay.visible   = shield_current > 0
		var tw_sh = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_sh.tween_property(_shield_overlay, "value", float(capped), 0.25)
		hp_bar.tooltip_text = "Shield: %d" % shield_current if shield_current > 0 else ""
	
func _set_bar(bar: ProgressBar, label: Label, cur: int, maxv: int) -> void:
	bar.max_value = max(1, maxv)
	label.text = "%d / %d" % [cur, maxv]
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "value", clamp(cur, 0, maxv), 0.25)
	
func _update_level_ring() -> void:
	if _level_ring == null:
		return
	var lvl = int(Account.level)
	var xp = int(Account.level_exp) if Account.level_exp != null else 0
	_level_ring_label.text = str(lvl)

	var table = ServerParams.ACCOUNT_PROGRESSION_LEVELS
	if table == null:
		_level_ring.progress = 0.0
		return

	var floor_xp = int(table.get(str(lvl), 0))
	var next_xp = int(table.get(str(lvl + 1), -1))
	if next_xp <= 0:
		# Max level
		_level_ring.progress = 100.0
		_level_ring.bar_color = Styler.COL_PRIMARY
		return

	var current = max(0, xp - floor_xp)
	var needed = max(1, next_xp - floor_xp)
	var pct = clamp(float(current) / float(needed) * 100.0, 0.0, 100.0)

	var tween = _level_ring.create_tween()
	tween.tween_property(_level_ring, "progress", pct, 0.4).from(_level_ring.progress)

func _on_avatar_changed(id: int) -> void:
	var tex = ItemDB.AVATARS.get(str(id), ItemDB.AVATARS.get("0"))
	if tex != null:
		avatar.texture = tex


func _on_avatar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SignalManager.signal_ShowAvatars.emit()
	elif event is InputEventScreenTouch and event.pressed:
		SignalManager.signal_ShowAvatars.emit()


## Apply magic-type colour to a cast bar's fill StyleBox.
## Call this whenever a skill cast begins, passing the ProgressBar and the
## skill_effect dictionary returned by the server.
func apply_cast_bar_color(bar: ProgressBar, skill_effect: Dictionary) -> void:
	# When setting up the cast bar for a skill
	var bar_color = Color.WHITE
	var magic_type = skill_effect.get("magic_type", "")
	match magic_type:
		"fire": bar_color = Styler.COL_FIRE
		"frost": bar_color = Styler.COL_FROST
		"blood": bar_color = Styler.COL_BLOOD
		"holy": bar_color = Styler.COL_HOLY
		"dark": bar_color = Styler.COL_DARK
		"arcane": bar_color = Styler.COL_ARCANE
	# Apply bar_color to the cast bar fill style
	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.shadow_color = bar_color.darkened(0.3)
	fill.shadow_size = 3
	for r in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		fill.set("corner_radius_" + r, 10)
	bar.add_theme_stylebox_override("fill", fill)


func _update_character_hud(_value):
	# print("_update_character_hud: {0}".format([value]))
	var av_tex = ItemDB.AVATARS.get(str(Account.avatar_id), ItemDB.AVATARS.get("0"))
	if av_tex != null:
		avatar.texture = av_tex
	set_stats(
		Account.hp,
		Account.hp_max,
		Account.mp,
		Account.mp_max,
		Account.shield,
		Account.shield_max,
		Account.buffer_steps,
		Account.buffer_steps_max,
	)
	name_level.text = "[color=orange]{0}[/color]".format([Account.username])
	level_label.text = str(Account.level)
	_update_level_ring()
	var current_activity_name: String = GameTextEn.activities_texts.get(Account.activity, "")
	if current_activity_name.is_empty():
		panel_container.visible = false
		activity_label.text = ""
		return

	if current_activity_name.to_lower() == "no":
		panel_container.visible = false
		activity_label.text = ""
	else:
		panel_container.visible = true
		var icon_key_overrides = {"Rift Explorer": "rift"}
		var icon_key_name: String = icon_key_overrides.get(current_activity_name, current_activity_name.to_lower())
		texture_rect.texture = ItemDB.get_icon(icon_key_name, null)
		activity_label.text = current_activity_name
	
