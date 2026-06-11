class_name CharacterHUD extends Control

# WalkAura Top HUD — Phase 1 chrome redesign (2026-05-16).
# Mockup: design-mockups/index.html (top of every phone). Spec: DESIGN.md "Top HUD".
#
# Footprint: 104px tall (3-bar mode: HP / Shield / MP). Avatar 76x76 left,
# bars centre, minimap is in MapHUD (sibling scene). Activity sub-badge
# appears under bars when in an activity (Rift Explorer, etc.).

# ─── Tunables ─────────────────────────────────────────────────────────────────
const HUD_PAD: float = 10.0
const SAFE_MARGIN: float = 6.0    # screen-edge padding for rounded-corner mobiles
const HUD_SHIFT: float = 5.0      # nudge avatar/bars right + down from chrome edge
const AVATAR_SIZE: float = 130.0
const BAR_HEIGHT: float = 16.0
const BAR_WIDTH: float = 220.0    # halved from full-width so bars don't reach minimap
const BAR_GAP: float = 5.0
const NAME_HEIGHT: float = 22.0
const SUB_BADGE_HEIGHT: float = 32.0
# Right-edge reservation for the minimap (MapHUD sibling scene). Minimap
# frame is ~180px wide + ~20px outer margin = 200px total. Bars stop short.
const MINIMAP_RESERVE: float = 210.0

@onready var avatar: TextureRect = $Avatar
@onready var bars_vbox: VBoxContainer = $Avatar/MainBars
@onready var name_level: RichTextLabel = $Avatar/MainBars/Name_level
@onready var hp_bar: ProgressBar = $Avatar/MainBars/HPBar
@onready var hp_label: Label = $Avatar/MainBars/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $Avatar/MainBars/MPBar
@onready var mp_label: Label = $Avatar/MainBars/MPBar/MPLabel
@onready var shield_bar: ProgressBar = $Avatar/MainBars/ShieldBar
@onready var shield_label: Label = $Avatar/MainBars/ShieldBar/ShieldLabel
@onready var subbadge_hbox: HBoxContainer = $Avatar/MainBars/HBoxContainer
@onready var activity_label: Label = $Avatar/MainBars/HBoxContainer/ActivityLabel
@onready var texture_rect: TextureRect = $Avatar/MainBars/HBoxContainer/PanelContainer/TextureRect
@onready var panel_container: PanelContainer = $Avatar/MainBars/HBoxContainer/PanelContainer
@onready var level_badge: PanelContainer = $Avatar/LevelBadge
@onready var level_label: Label = $Avatar/LevelBadge/LevelLabel

# Deprecated by Phase 1 — kept as nil so old call sites that null-check pass.
var _shield_overlay: ProgressBar = null
var _level_ring: RadialProgress = null
var _level_ring_label: Label = null

# Chrome background panel laid down behind the avatar/bars cluster — replaces
# flat-gray placeholder bg with dark chrome gradient + gold bottom edge.
var _chrome_panel: Panel = null

# Activity capsule (tap-to-expand): the sub-badge carries a thin XP sliver;
# tapping it opens a flyout with session chips + stop. Replaces the hub's
# bottom status strip for the active-unlocked case.
const _PROF_BY_ACTIVITY = {1: "herbalism", 2: "alchemy", 3: "hunting", 4: "mining",
		5: "woodcutting", 6: "fishing", 7: "rift", 9: "enchanting", 10: "blacksmithing"}
var _capsule_xp_bar: ProgressBar = null
var _activity_flyout: PanelContainer = null
var _fly_steps_label: Label = null
var _fly_xp_label: Label = null
var _sess_steps: int = 0
var _sess_actions: int = 0
var _sess_xp: int = 0
var _sess_loot: Dictionary = {}        # item_uid -> session qty
var _sess_loot_icons: Dictionary = {}  # item_uid -> icon key
var _fly_loot_grid: GridContainer = null
var _tracked_act: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AccountManager.signal_AccountDataReceived.connect(_update_character_hud)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress_capsule)
	SignalManager.signal_AvatarChanged.connect(_on_avatar_changed)
	avatar.mouse_filter = Control.MOUSE_FILTER_STOP
	avatar.gui_input.connect(_on_avatar_gui_input)
	subbadge_hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	subbadge_hbox.gui_input.connect(_on_subbadge_gui_input)

	_build_chrome_background()
	_layout_avatar_and_bars()
	_paint_resource_bars()
	_style_avatar_frame()
	_build_level_ring()
	_style_activity_subbadge()

	# Remove the .tscn-defined LevelBadge entirely — replaced by radial XP
	# ring. Detach from tree synchronously before queueing free so it can't
	# render a stale frame.
	if is_instance_valid(level_badge):
		level_badge.visible = false
		var lb_parent = level_badge.get_parent()
		if lb_parent != null:
			lb_parent.remove_child(level_badge)
		level_badge.queue_free()

	_update_character_hud(true)


# ─── Layout (programmatic to keep .tscn small and decoupled) ──────────────────

func _build_chrome_background() -> void:
	# Full-width chrome bar behind the avatar/bars cluster, with safe-area
	# margin from screen edges (rounded-corner mobile devices).
	_chrome_panel = Panel.new()
	_chrome_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_chrome_panel.offset_top = SAFE_MARGIN
	_chrome_panel.offset_bottom = Styler.TOP_HUD_HEIGHT
	_chrome_panel.offset_left = SAFE_MARGIN
	_chrome_panel.offset_right = -SAFE_MARGIN
	add_child(_chrome_panel)
	move_child(_chrome_panel, 0)  # below avatar

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(20, 22, 30, 240)
	sb.border_width_bottom = 1
	sb.border_color = Styler.COL_GOLD_GLOW
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	_chrome_panel.add_theme_stylebox_override("panel", sb)


func _layout_avatar_and_bars() -> void:
	# Avatar: anchored top-left, with SAFE_MARGIN + HUD_PAD + HUD_SHIFT inset.
	var avatar_left: float = SAFE_MARGIN + HUD_PAD + HUD_SHIFT
	var avatar_top: float = SAFE_MARGIN + HUD_PAD + HUD_SHIFT
	avatar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	avatar.offset_left = avatar_left
	avatar.offset_top = avatar_top
	avatar.offset_right = avatar_left + AVATAR_SIZE
	avatar.offset_bottom = avatar_top + AVATAR_SIZE
	avatar.custom_minimum_size = Vector2(AVATAR_SIZE, AVATAR_SIZE)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# MainBars VBox: in the .tscn it lives under Avatar with massive negative
	# offsets that worked when the avatar was 128px wide. With the new 76px
	# avatar, those offsets push the bars off-screen. Reparent to the HUD root
	# so we can position them in HUD coordinates directly.
	var bars: VBoxContainer = bars_vbox
	bars.get_parent().remove_child(bars)
	add_child(bars)
	# Anchor bars VBox to TOP-LEFT with explicit width so bars get a stable
	# area regardless of viewport size or minimap geometry.
	var bars_left: float = SAFE_MARGIN + HUD_PAD + HUD_SHIFT + AVATAR_SIZE + HUD_PAD
	bars.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bars.offset_left = bars_left
	bars.offset_top = SAFE_MARGIN + HUD_PAD + HUD_SHIFT
	bars.offset_right = bars_left + BAR_WIDTH
	# Use full HUD height for the bars cluster (Name + 3 bars + sub-badge).
	bars.offset_bottom = Styler.TOP_HUD_HEIGHT - HUD_PAD
	bars.add_theme_constant_override("separation", int(BAR_GAP))

	# Name label — fill bars VBox width (220px) so text doesn't wrap one char
	# per line. RichTextLabel with fit_content + SHRINK_BEGIN + min_width 0
	# stacks each glyph vertically.
	name_level.custom_minimum_size = Vector2(0, NAME_HEIGHT)
	name_level.fit_content = true
	name_level.size_flags_horizontal = Control.SIZE_FILL
	name_level.add_theme_font_size_override("normal_font_size", 18)

	# Three resource bars — fill the bars VBox horizontally (which is now a
	# fixed BAR_WIDTH px). Height comes from custom_minimum_size.
	for b in [hp_bar, shield_bar, mp_bar]:
		b.custom_minimum_size = Vector2(0, BAR_HEIGHT)
		b.size_flags_horizontal = Control.SIZE_FILL
		b.show_percentage = false
		b.visible = true

	# Reorder so children stack: Name / HP / Shield / MP / SubBadge.
	bars.move_child(name_level, 0)
	bars.move_child(hp_bar, 1)
	bars.move_child(shield_bar, 2)
	bars.move_child(mp_bar, 3)
	bars.move_child(subbadge_hbox, 4)


func _paint_resource_bars() -> void:
	Styler.paint_hp_bar(hp_bar)
	Styler.paint_shield_bar(shield_bar)
	Styler.paint_mp_bar(mp_bar)

	# Bar labels: prefixed format "HP cur / max" centred in white with shadow.
	for pair in [[hp_label, "HP"], [shield_label, "SH"], [mp_label, "MP"]]:
		var lbl: Label = pair[0]
		lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.set_meta("prefix", pair[1])


func _style_avatar_frame() -> void:
	# 2px gold border + outer gold glow + inset black shadow on the avatar.
	var border = Panel.new()
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_left = -2
	border.offset_top = -2
	border.offset_right = 2
	border.offset_bottom = 2
	var sb = Styler.make_glow_stylebox(
		Color(0, 0, 0, 0),                  # transparent — frame only
		Styler.COL_PRIMARY,                 # gold border
		8,                                  # corner radius
		2,                                  # border width
		Styler.COL_GOLD_GLOW,               # outer glow color
		12                                  # glow size
	)
	border.add_theme_stylebox_override("panel", sb)
	avatar.add_child(border)
	avatar.move_child(border, 0)


func _build_level_ring() -> void:
	# Radial XP ring overlaid bottom-right of avatar. Replaces flat rectangle
	# level badge from the .tscn. Anchored relative to avatar.
	var ring_size: float = 50.0
	var ring_radius: float = 22.0
	var ring_thickness: float = 5.0

	var ring_wrapper = Control.new()
	ring_wrapper.custom_minimum_size = Vector2(ring_size, ring_size)
	ring_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_wrapper.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Centre the ring on the bottom-right corner of the avatar so it overhangs.
	ring_wrapper.offset_left = -ring_size + 6
	ring_wrapper.offset_top = -ring_size + 6
	ring_wrapper.offset_right = 6
	ring_wrapper.offset_bottom = 6
	avatar.add_child(ring_wrapper)

	# Dark disc background behind the ring (so the avatar art doesn't bleed through).
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

	# XP ring (gold, animates as XP gained).
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

	# Level number centred inside the ring.
	_level_ring_label = Label.new()
	_level_ring_label.text = "1"
	_level_ring_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_ring_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_ring_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_level_ring_label.add_theme_font_size_override("font_size", 16)
	_level_ring_label.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	_level_ring_label.size = Vector2(ring_size, ring_size)
	_level_ring_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_wrapper.add_child(_level_ring_label)


func _style_activity_subbadge() -> void:
	# Circular icon badge: 36x36 disc (corner_radius = half = 18 → perfect
	# circle) with gold border + gold glow halo. Activity label sits to the
	# RIGHT of the disc as plain gold text — not wrapped inside the badge so
	# the badge stays circular regardless of label length.
	var disc_size: int = 36
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.border_color = Styler.COL_PRIMARY
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(disc_size / 2)   # = perfect circle
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Styler.COL_GOLD_GLOW
	sb.shadow_size = 8
	panel_container.add_theme_stylebox_override("panel", sb)
	panel_container.custom_minimum_size = Vector2(disc_size, disc_size)
	panel_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Default-hide so a stray empty disc doesn't render before the first
	# _update_character_hud call assigns visibility based on Account.activity.
	panel_container.visible = false

	# Activity name: 16px JANDA gold, sits to the right of the disc.
	activity_label.add_theme_font_override("font", Styler.JANDA_FONT)
	activity_label.add_theme_font_size_override("font_size", 16)
	activity_label.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	activity_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	activity_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	activity_label.add_theme_constant_override("outline_size", 2)
	activity_label.add_theme_constant_override("shadow_offset_x", 1)
	activity_label.add_theme_constant_override("shadow_offset_y", 1)
	activity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	activity_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	activity_label.visible = false

	subbadge_hbox.custom_minimum_size = Vector2(0, SUB_BADGE_HEIGHT)
	subbadge_hbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	subbadge_hbox.add_theme_constant_override("separation", 8)
	# Icon fills the disc minus padding (36 - 8 = 28).
	texture_rect.custom_minimum_size = Vector2(28, 28)
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Drop the unused LeftSpacer node from the .tscn — it adds a 16px gap
	# at the start of the sub-badge HBox we don't want.
	var spacer = subbadge_hbox.get_node_or_null("LeftSpacer")
	if spacer != null:
		spacer.queue_free()

	# Capsule: stack the label over a thin XP sliver, right of the disc.
	# Input lands on subbadge_hbox (tap toggles the session flyout), so all
	# children pass the events through.
	panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subbadge_hbox.remove_child(activity_label)
	var cap_vbox = VBoxContainer.new()
	cap_vbox.add_theme_constant_override("separation", 2)
	cap_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subbadge_hbox.add_child(cap_vbox)
	cap_vbox.add_child(activity_label)
	_capsule_xp_bar = ProgressBar.new()
	Styler.make_painted_progressbar(_capsule_xp_bar, Styler.COL_PRIMARY, Styler.COL_PRIMARY.darkened(0.4), 3)
	_capsule_xp_bar.custom_minimum_size = Vector2(120, 6)
	_capsule_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capsule_xp_bar.visible = false
	cap_vbox.add_child(_capsule_xp_bar)


# ─── Activity capsule: progress feed, tap flyout, stop ───────────────────────

func _on_activity_progress_capsule(data: Dictionary) -> void:
	# Mirror of location_hub's unwrap: payload arrives as {data:{data:{...}}}.
	var raw = data.get("data", data)
	var d: Dictionary = raw.get("data", raw)
	if Account.activity != _tracked_act:
		_sess_steps = 0
		_sess_actions = 0
		_sess_xp = 0
		_sess_loot = {}
		_sess_loot_icons = {}
		_tracked_act = Account.activity
	# loot_counts is per-batch in every payload shape — accumulate session totals.
	var batch_loot: Dictionary = d.get("loot_counts", {}) if d.get("loot_counts") != null else {}
	var batch_mapping: Dictionary = d.get("mapping", {}) if d.get("mapping") != null else {}
	for k in batch_loot.keys():
		_sess_loot[k] = int(_sess_loot.get(k, 0)) + int(batch_loot[k])
		_sess_loot_icons[k] = str(batch_mapping.get(k, k))
	if d.has("session_steps"):
		_sess_steps = int(d["session_steps"])
		_sess_actions = int(d.get("session_actions", 0))
		_sess_xp = int(d.get("session_xp_gained", 0))
	else:
		_sess_steps += int(d.get("steps_in", 0))
		_sess_actions += int(d.get("activities_completed", 0))
		_sess_xp += int(d.get("xp_gained", 0))
	var xp_next = int(d.get("xp_to_next", 0))
	if _capsule_xp_bar != null and xp_next > 0:
		_capsule_xp_bar.visible = true
		_capsule_xp_bar.max_value = xp_next
		_capsule_xp_bar.value = int(d.get("xp_into_level", 0))
	_update_character_hud(true)
	_refresh_activity_flyout()


func _on_subbadge_gui_input(event: InputEvent) -> void:
	# Mouse-button only. With pointing emulation on (both directions in this
	# project), a single tap delivers ScreenTouch AND an emulated MouseButton —
	# handling both double-toggled the flyout (open, then instantly close).
	# The mouse event is present on desktop and device alike, so it's the one
	# stable trigger.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_activity_flyout()


func _toggle_activity_flyout() -> void:
	if _activity_flyout != null and _activity_flyout.visible:
		_hide_activity_flyout()
		return
	if int(Account.activity) == 0:
		return
	if _activity_flyout == null:
		_build_activity_flyout()
	_refresh_activity_flyout()
	_activity_flyout.visible = true


func _hide_activity_flyout() -> void:
	if _activity_flyout != null:
		_activity_flyout.visible = false


func _build_activity_flyout() -> void:
	_activity_flyout = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(16, 18, 24, 235)
	sb.set_corner_radius_all(8)
	sb.border_color = Color(Styler.COL_PRIMARY, 0.4)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 8
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_activity_flyout.add_theme_stylebox_override("panel", sb)
	_activity_flyout.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_activity_flyout.add_child(v)
	_fly_steps_label = Label.new()
	_fly_xp_label = Label.new()
	for lbl in [_fly_steps_label, _fly_xp_label]:
		lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
		v.add_child(lbl)
	_fly_loot_grid = GridContainer.new()
	_fly_loot_grid.columns = 5
	_fly_loot_grid.add_theme_constant_override("h_separation", 8)
	_fly_loot_grid.add_theme_constant_override("v_separation", 6)
	_fly_loot_grid.visible = false
	v.add_child(_fly_loot_grid)
	var stop_btn = Button.new()
	stop_btn.text = "STOP"
	stop_btn.custom_minimum_size = Vector2(0, 34)
	stop_btn.add_theme_font_override("font", Styler.JANDA_FONT)
	stop_btn.add_theme_font_size_override("font_size", 14)
	stop_btn.add_theme_color_override("font_color", Color.WHITE)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var bsb = StyleBoxFlat.new()
		bsb.bg_color = Color.from_rgba8(58, 22, 22)
		bsb.set_corner_radius_all(6)
		bsb.border_color = Color.from_rgba8(180, 60, 60)
		bsb.set_border_width_all(1)
		if state_name == "hover":
			bsb.bg_color = Color.from_rgba8(76, 28, 28)
		elif state_name == "pressed":
			bsb.bg_color = Color.from_rgba8(44, 16, 16)
		stop_btn.add_theme_stylebox_override(state_name, bsb)
	stop_btn.pressed.connect(_on_flyout_stop)
	v.add_child(stop_btn)
	# Below the sub-badge, inside the MainBars VBox — reads as HUD chrome.
	subbadge_hbox.get_parent().add_child(_activity_flyout)


func _refresh_activity_flyout() -> void:
	if _fly_steps_label == null:
		return
	_fly_steps_label.text = "Steps %s   Actions %s" % [_fmt_n(_sess_steps), _fmt_n(_sess_actions)]
	_fly_xp_label.text = "XP gained +%s" % _fmt_n(_sess_xp)
	if _fly_loot_grid == null:
		return
	for child in _fly_loot_grid.get_children():
		child.queue_free()
	_fly_loot_grid.visible = not _sess_loot.is_empty()
	for uid in _sess_loot.keys():
		var cell = VBoxContainer.new()
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon = TextureRect.new()
		icon.texture = ItemDB.get_item_icon(_sess_loot_icons.get(uid, uid), ItemDB.get_item_icon("default_bag"))
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(icon)
		var qty_lbl = Label.new()
		qty_lbl.text = "×%d" % int(_sess_loot[uid])
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_lbl.add_theme_font_size_override("font_size", 11)
		qty_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
		cell.add_child(qty_lbl)
		_fly_loot_grid.add_child(cell)


func _on_flyout_stop() -> void:
	SignalManager.signal_UserActivity.emit(Account.activity, Account.activity_site, "stop")
	_hide_activity_flyout()


func _fmt_n(n: int) -> String:
	var s = str(n)
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


# ─── Public API (unchanged behaviour for callers) ─────────────────────────────

func set_stats(hp_current: int, hp_max: int, mp_current: int, mp_max: int, shield_current: int, shield_max: int, _xp_current: int, _xp_max: int) -> void:
	_set_bar(hp_bar, hp_label, hp_current, hp_max)
	_set_bar(mp_bar, mp_label, mp_current, mp_max)
	_set_bar(shield_bar, shield_label, shield_current, max(1, shield_max))
	shield_bar.visible = shield_max > 0


func _set_bar(bar: ProgressBar, label: Label, cur: int, maxv: int) -> void:
	bar.max_value = max(1, maxv)
	var prefix: String = label.get_meta("prefix", "")
	if prefix.is_empty():
		label.text = "%d / %d" % [cur, maxv]
	else:
		label.text = "%s %d / %d" % [prefix, cur, maxv]
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
		# Max level.
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


# Apply magic-type colour to a cast bar's fill StyleBox. Used by combat scenes
# when a skill cast begins, passing the ProgressBar and the skill_effect
# dictionary returned by the server.
func apply_cast_bar_color(bar: ProgressBar, skill_effect: Dictionary) -> void:
	var bar_color = Color.WHITE
	var magic_type = skill_effect.get("magic_type", "")
	match magic_type:
		"fire": bar_color = Styler.COL_FIRE
		"frost": bar_color = Styler.COL_FROST
		"blood": bar_color = Styler.COL_BLOOD
		"holy": bar_color = Styler.COL_HOLY
		"dark": bar_color = Styler.COL_DARK
		"arcane": bar_color = Styler.COL_ARCANE
	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.shadow_color = bar_color.darkened(0.3)
	fill.shadow_size = 3
	for r in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		fill.set("corner_radius_" + r, 10)
	bar.add_theme_stylebox_override("fill", fill)


func _update_character_hud(_value):
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
	name_level.text = "[color=#ffc842]{0}[/color]".format([Account.username])
	# level_label was child of LevelBadge which is now freed; XP/level shown
	# by the radial ring instead. Skip the old text assignment.
	_update_level_ring()

	# Activity sub-badge visibility — pill under bars when activity is running.
	var current_activity_name: String = GameTextEn.activities_texts.get(Account.activity, "")
	if current_activity_name.is_empty() or current_activity_name.to_lower() == "no":
		panel_container.visible = false
		activity_label.visible = false
		activity_label.text = ""
		if _capsule_xp_bar != null:
			_capsule_xp_bar.visible = false
		_hide_activity_flyout()
		return

	panel_container.visible = true
	activity_label.visible = true
	# "Crafting" is the display name for activity 10 (blacksmithing key) → its icon
	# is still the "blacksmith" asset (rename is display-only, D6).
	var icon_key_overrides = {"Rift Explorer": "rift", "Crafting": "blacksmith"}
	var icon_key_name: String = icon_key_overrides.get(current_activity_name, current_activity_name.to_lower())
	texture_rect.texture = ItemDB.get_icon(icon_key_name, null)
	var prof_key: String = _PROF_BY_ACTIVITY.get(int(Account.activity), "")
	if prof_key != "":
		activity_label.text = "%s · %d" % [current_activity_name, int(Account.get(prof_key + "_lvl"))]
	else:
		activity_label.text = current_activity_name
