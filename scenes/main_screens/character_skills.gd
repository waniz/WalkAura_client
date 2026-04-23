extends Control

# Talent config loaded from server
var talent_config: Array = []    # set from ServerParams on login
var talent_data: Dictionary = {} # current talent allocations/ranks from server
var synergy_config: Array = []   # synergy definitions from server

var PASSIVE_TOTAL_TO_LEVEL = {1: 0}
var _active_slots: Array = [null, null, null, null, null, null]
var _known_skills: Array = []

# --- Node refs (from scene tree) ---
@onready var _vbox_root = %VBoxRoot
@onready var btn_tab_skills = %BtnTabSkills
@onready var btn_tab_talents = %BtnTabTalents
@onready var skill_panel = %SkillPanel
@onready var talents_panel = %TalentsPanel
@onready var v_box_skills = %VBoxSkills
@onready var title_active_skills = %TitleActiveSkills
@onready var active_container = %ActiveContainer
@onready var h_separator = %Separator
@onready var title_spellbook = %TitleSpellbook
@onready var h_box_btn_control = %HBoxBtnControl
@onready var btn_skills_mage = %BtnSkillsMage
@onready var btn_skills_paladin = %BtnSkillsPaladin
@onready var btn_skills_buffs = %BtnSkillsBuffs
@onready var btn_skills_blood = %BtnSkillsBlood
@onready var btn_skills_dark = %BtnSkillsDark
@onready var btn_skills_arcane = %BtnSkillsArcane
@onready var spellbook_panel_base = %SpellbookPanelBase
@onready var mage_panel = %MagePanel
@onready var paladin_panel = %PaladinPanel
@onready var buffs_panel = %BuffsPanel
@onready var blood_panel = %BloodPanel
@onready var dark_panel = %DarkPanel
@onready var arcane_panel = %ArcanePanel
@onready var mage_grid_spellbook = %MageGridSpellbook
@onready var paladin_grid_spellbook = %PaladinGridSpellbook
@onready var buffs_grid_spellbook = %BuffsGridSpellbook
@onready var blood_grid_spellbook = %BloodGridSpellbook
@onready var dark_grid_spellbook = %DarkGridSpellbook
@onready var arcane_grid_spellbook = %ArcaneGridSpellbook
@onready var _talent_header_points_label = %TalentHeaderPointsLabel
@onready var _talent_header_streak_label = %TalentHeaderStreakLabel
@onready var _talent_bottom_used_label = %TalentBottomUsedLabel
@onready var _title_label = %TitleLabel
@onready var _respec_btn = %RespecBtn

var TALENT_WHEEL_SCRIPT = null
var TALENT_OVERLAY_SCRIPT = null

var _talent_wheel = null
var _talent_overlay = null
var _zoom_level: float = 1.8
var _overlay_visible: bool = false
var _overlay_talent_id: String = ""
var _zoom_label: Label = null
var _pan_offset: Vector2 = Vector2.ZERO
var _touch_points: Dictionary = {}  # finger_index -> position
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 1.0
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_offset: Vector2 = Vector2.ZERO
var _is_dragging: bool = false


func _ready() -> void:
	PASSIVE_TOTAL_TO_LEVEL = ServerParams.PASSIVE_TOTAL_TO_LEVEL

	# Dynamic offsets from Styler
	_vbox_root.offset_top = Styler.content_top
	_vbox_root.offset_bottom = Styler.content_bottom

	# Connect signals
	AccountManager.signal_AllSkillsReceived.connect(_update_game_skills)
	AccountManager.signal_AccountSkillsReceived.connect(_update_skills)
	AccountManager.signal_TalentsConfigReceived.connect(_on_talents_config)
	AccountManager.signal_TalentsDataReceived.connect(_on_talents_data)

	btn_tab_skills.pressed.connect(_on_btn_tab_skills_pressed)
	btn_tab_talents.pressed.connect(_on_btn_tab_talents_pressed)
	btn_skills_mage.pressed.connect(_on_btn_skills_mage_pressed)
	btn_skills_paladin.pressed.connect(_on_btn_skills_paladin_pressed)
	btn_skills_buffs.pressed.connect(_on_btn_skills_buffs_pressed)
	btn_skills_blood.pressed.connect(_on_btn_skills_blood_pressed)
	btn_skills_dark.pressed.connect(_on_btn_skills_dark_pressed)
	btn_skills_arcane.pressed.connect(_on_btn_skills_arcane_pressed)
	_respec_btn.pressed.connect(_on_respec_pressed)

	# Load talent scripts at runtime (not preload) to avoid parse-order issues
	TALENT_WHEEL_SCRIPT = load("res://scripts/components/talent_wheel.gd")
	TALENT_OVERLAY_SCRIPT = load("res://scripts/components/talent_detail_overlay.gd")

	# Build astrolabe wheel (replaces old card-based talent list)
	_setup_talent_wheel()

	# Apply Styler-dependent theme overrides
	_apply_theme()

	if Account.raw_structures.all_server_skills != null and not Account.raw_structures.all_server_skills.is_empty():
		_update_game_skills(Account.raw_structures.all_server_skills)

	if Account.raw_structures.account_skills != null and not Account.raw_structures.account_skills.is_empty():
		_update_skills(Account.raw_structures.account_skills)

	if Account.raw_structures.talents_config != null and not Account.raw_structures.talents_config.is_empty():
		_on_talents_config(Account.raw_structures.talents_config)

	if Account.raw_structures.talents_data != null and not Account.raw_structures.talents_data.is_empty():
		_on_talents_data(Account.raw_structures.talents_data)

	_setup_skill_panel_structure()
	_refresh_skills_ui()
	_refresh_talents()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _vbox_root != null:
		_vbox_root.offset_right = size.x


func _setup_talent_wheel() -> void:
	# Clip zoomed content to stay inside the panel
	talents_panel.clip_contents = true

	# Wheel lives directly in the panel. Zoom via scale property, no ScrollContainer.
	_talent_wheel = Control.new()
	_talent_wheel.set_script(TALENT_WHEEL_SCRIPT)
	_talent_wheel.name = "TalentWheel"
	_talent_wheel.mouse_filter = Control.MOUSE_FILTER_PASS
	talents_panel.add_child(_talent_wheel)
	# Move wheel to index 0 so it draws BEHIND the existing layout (header, bottom bar)
	talents_panel.move_child(_talent_wheel, 0)

	# Connect wheel signals
	_talent_wheel.talent_tapped.connect(_on_wheel_talent_tapped)
	_talent_wheel.talent_allocate.connect(_on_wheel_talent_allocate)

	# Zoom buttons added to BottomHBox next to Respec
	var bottom_hbox = talents_panel.get_node_or_null("TalentMargin/TalentOuterVBox/BottomHBox")
	if bottom_hbox != null:
		var btn_out = Button.new()
		btn_out.text = "-"
		btn_out.custom_minimum_size = Vector2(36, 36)
		btn_out.add_theme_font_size_override("font_size", 16)
		btn_out.pressed.connect(_on_zoom_out)
		Styler.style_button_small(btn_out, Color(0.7, 0.23, 0.23))
		bottom_hbox.add_child(btn_out)

		_zoom_label = Label.new()
		_zoom_label.custom_minimum_size = Vector2(44, 36)
		_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_zoom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_zoom_label.add_theme_font_size_override("font_size", 9)
		_zoom_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		_zoom_label.text = "Zoom"
		bottom_hbox.add_child(_zoom_label)

		var btn_in = Button.new()
		btn_in.text = "+"
		btn_in.custom_minimum_size = Vector2(36, 36)
		btn_in.add_theme_font_size_override("font_size", 16)
		btn_in.pressed.connect(_on_zoom_in)
		Styler.style_button_small(btn_in, Color(0.7, 0.23, 0.23))
		bottom_hbox.add_child(btn_in)

	# Detail overlay — added to scene root (not talents_panel) so PanelContainer auto-sizes
	_talent_overlay = PanelContainer.new()
	_talent_overlay.set_script(TALENT_OVERLAY_SCRIPT)
	_talent_overlay.name = "TalentDetailOverlay"
	add_child(_talent_overlay)
	_talent_overlay.allocate_pressed.connect(_on_wheel_talent_allocate)
	_talent_overlay.dismissed.connect(_on_overlay_dismissed)

	talents_panel.resized.connect(_on_talents_panel_resized)
	# Apply initial zoom after a frame so layout has settled
	call_deferred("_apply_zoom_and_pan")


func _on_talents_panel_resized() -> void:
	if _talent_wheel == null:
		return
	if talents_panel.size.x < 1 or talents_panel.size.y < 1:
		return
	_talent_wheel.size = talents_panel.size
	_talent_wheel.pivot_offset = talents_panel.size * 0.5
	_apply_zoom_and_pan()


func _on_zoom_in() -> void:
	_set_zoom(min(_zoom_level + 0.2, 3.0))


func _on_zoom_out() -> void:
	_set_zoom(max(_zoom_level - 0.2, 0.75))
	if _zoom_level <= 1.0:
		_pan_offset = Vector2.ZERO


func _set_zoom(new_zoom: float) -> void:
	_zoom_level = new_zoom
	_clamp_pan()
	_apply_zoom_and_pan()


func _apply_zoom_and_pan() -> void:
	if _talent_wheel == null:
		return
	_talent_wheel.pivot_offset = talents_panel.size * 0.5
	_talent_wheel.scale = Vector2(_zoom_level, _zoom_level)
	_talent_wheel.position = _pan_offset


func _clamp_pan() -> void:
	# Limit pan so the wheel center stays roughly visible
	var max_pan = talents_panel.size * (_zoom_level - 1.0) * 0.5
	_pan_offset.x = clamp(_pan_offset.x, -max_pan.x, max_pan.x)
	_pan_offset.y = clamp(_pan_offset.y, -max_pan.y, max_pan.y)
	# At zoom <= 1.0, no panning needed
	if _zoom_level <= 1.0:
		_pan_offset = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if not talents_panel.visible:
		return

	# Dismiss tooltip on tap outside
	if _overlay_visible and (event is InputEventScreenTouch or event is InputEventMouseButton):
		if event.pressed and _touch_points.size() <= 1:
			if _talent_overlay != null and _talent_overlay.visible:
				var overlay_rect = Rect2(_talent_overlay.global_position, _talent_overlay.size)
				var tap_pos = event.position if event is InputEventScreenTouch else event.global_position
				if not overlay_rect.has_point(tap_pos):
					_on_overlay_dismissed()

	# Mouse wheel zoom (desktop/emulator)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_on_zoom_in()
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_on_zoom_out()
			get_viewport().set_input_as_handled()
			return

	# Touch: track fingers for pinch-to-zoom + drag-to-pan
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() == 2:
				var pts = _touch_points.values()
				_pinch_start_dist = pts[0].distance_to(pts[1])
				_pinch_start_zoom = _zoom_level
				_is_dragging = false
			elif _touch_points.size() == 1:
				_drag_start_pos = event.position
				_drag_start_offset = _pan_offset
				_is_dragging = false  # only becomes true after movement threshold
		else:
			_touch_points.erase(event.index)
			if _touch_points.size() < 2:
				_pinch_start_dist = 0.0
			if _touch_points.size() == 0:
				_is_dragging = false

	if event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() >= 2:
			# Pinch zoom — always consume to prevent scroll/swipe
			var pts = _touch_points.values()
			var dist = pts[0].distance_to(pts[1])
			if _pinch_start_dist > 10.0:
				var ratio = dist / _pinch_start_dist
				_set_zoom(clamp(_pinch_start_zoom * ratio, 0.75, 3.0))
			get_viewport().set_input_as_handled()
		elif _touch_points.size() == 1 and _zoom_level > 1.05:
			# Single finger drag to pan when zoomed in
			var delta = event.position - _drag_start_pos
			if not _is_dragging and delta.length() > 12.0:
				_is_dragging = true
			if _is_dragging:
				_pan_offset = _drag_start_offset + delta
				_clamp_pan()
				_apply_zoom_and_pan()
				get_viewport().set_input_as_handled()


func _on_wheel_talent_tapped(talent_id: String) -> void:
	var alloc_info = talent_data.get("talents", {}).get(talent_id, {}).duplicate()
	alloc_info["_unspent"] = talent_data.get("unspent", 0)
	# Merge config info (tier descriptions etc)
	for t in talent_config:
		if str(t.get("id", "")) == talent_id:
			for key in ["tier1_desc", "tier2_desc", "tier3_desc", "per_level", "name", "type"]:
				if t.has(key) and not alloc_info.has(key):
					alloc_info[key] = t[key]
			break

	var config_by_id = {}
	for t in talent_config:
		config_by_id[str(t.get("id", ""))] = t

	# Get tapped node's global position for tooltip placement
	var tap_global = get_viewport().get_visible_rect().size * 0.5
	if _talent_wheel != null and _talent_wheel._node_map.has(talent_id):
		var node_ctrl = _talent_wheel._node_map[talent_id]
		var node_size = node_ctrl.size * _zoom_level
		tap_global = node_ctrl.global_position + node_size * 0.5

	_talent_overlay._tap_global_pos = tap_global
	_talent_overlay._panel_rect = talents_panel.get_global_rect()
	_talent_overlay.show_talent(
		talent_id, alloc_info, synergy_config,
		talent_data.get("talents", {}), config_by_id
	)
	_overlay_visible = true
	_overlay_talent_id = talent_id


func _on_overlay_dismissed() -> void:
	_overlay_visible = false
	_overlay_talent_id = ""
	_talent_overlay.hide_overlay()


func _on_wheel_talent_allocate(talent_id: String) -> void:
	SignalManager.signal_TalentAllocate.emit(talent_id)


func _refresh_open_tooltip() -> void:
	if not _overlay_visible or _overlay_talent_id == "":
		return
	# Re-show the tooltip with updated data, keeping the same position
	var old_pos = _talent_overlay._tap_global_pos
	_on_wheel_talent_tapped(_overlay_talent_id)
	_talent_overlay._tap_global_pos = old_pos
	call_deferred("_reposition_tooltip")


func _reposition_tooltip() -> void:
	if _talent_overlay != null:
		_talent_overlay._position_tooltip()


func _apply_theme() -> void:
	# Tab buttons
	Styler.style_button(btn_tab_skills, Color.from_rgba8(64, 180, 255))
	Styler.style_button(btn_tab_talents, Color.from_rgba8(64, 180, 255))
	_set_skills_tab_active(btn_tab_skills)

	# Skill class buttons
	Styler.style_button(btn_skills_blood, Styler.COL_BLOOD)
	Styler.style_button(btn_skills_dark, Styler.COL_DARK)
	Styler.style_button(btn_skills_arcane, Styler.COL_ARCANE)
	Styler.style_button(btn_skills_mage, Styler.COL_FIRE.lerp(Styler.COL_FROST, 0.5))
	Styler.style_button(btn_skills_paladin, Styler.COL_HOLY)
	Styler.style_button(btn_skills_buffs, Styler.COL_UTILITY)

	# Talents title label (Styler font)
	_title_label.add_theme_font_override("font", Styler.GROBOLT_FONT)
	_title_label.add_theme_font_size_override("font_size", Styler.FONT_SECTION)
	_title_label.add_theme_color_override("font_color", Color.BLACK)

	# Parchment theme for talents panel
	var talents_sb = StyleBoxFlat.new()
	talents_sb.bg_color = Styler.COLOR_PARCHMENT
	talents_sb.set_corner_radius_all(4)
	talents_sb.border_width_left = 4
	talents_sb.border_width_right = 4
	talents_sb.border_width_top = 4
	talents_sb.border_width_bottom = 4
	talents_sb.border_color = Styler.COLOR_BORDER
	talents_sb.shadow_size = 4
	talents_sb.shadow_color = Color(0, 0, 0, 0.3)
	talents_panel.add_theme_stylebox_override("panel", talents_sb)

	# Respec button
	Styler.style_button_small(_respec_btn, Color(0.7, 0.23, 0.23))
	_respec_btn.add_theme_color_override("font_color", Color.WHITE)

	# Green badge for spent points (matching red PointsBadge style)
	var spent_badge = talents_panel.get_node_or_null("TalentMargin/TalentOuterVBox/BottomHBox/SpentBadge")
	if spent_badge != null:
		var sb_green = StyleBoxFlat.new()
		sb_green.bg_color = Color(0.24, 0.78, 0.31, 1.0)
		sb_green.corner_radius_top_left = 12
		sb_green.corner_radius_top_right = 12
		sb_green.corner_radius_bottom_left = 12
		sb_green.corner_radius_bottom_right = 12
		sb_green.content_margin_left = 10.0
		sb_green.content_margin_right = 10.0
		sb_green.content_margin_top = 4.0
		sb_green.content_margin_bottom = 4.0
		spent_badge.add_theme_stylebox_override("panel", sb_green)


func _on_btn_tab_skills_pressed() -> void:
	skill_panel.visible = true
	talents_panel.visible = false
	_set_skills_tab_active(btn_tab_skills)


func _on_btn_tab_talents_pressed() -> void:
	skill_panel.visible = false
	talents_panel.visible = true
	_set_skills_tab_active(btn_tab_talents)


func _set_skills_tab_active(active_btn: Button) -> void:
	for btn in [btn_tab_skills, btn_tab_talents]:
		var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(64, 180, 255) if btn == active_btn else Color.from_rgba8(60, 60, 70)


# ==============================================================================
# DATA CALLBACKS
# ==============================================================================
func _update_game_skills(server_json) -> void:
	_known_skills = server_json["data"]["all_skills"]


func _update_skills(server_json) -> void:
	var skills_data = server_json["data"]["skills"]
	if len(skills_data) > 0:
		for key in skills_data.keys():
			_active_slots[int(skills_data[key]["slot"])] = int(skills_data[key]["skill_id"])


func _refresh_talents() -> void:
	var total_spent: int = talent_data.get("total_points_spent", 0)
	var unspent: int = talent_data.get("unspent", 0)
	var streak: int = talent_data.get("walking_streak", 0)

	# Update header badges
	_talent_header_points_label.text = str(unspent) + " pts"
	if streak > 0:
		_talent_header_streak_label.text = str(streak) + "-day streak"
		_talent_header_streak_label.visible = true
	else:
		_talent_header_streak_label.visible = false

	# Update bottom label (no cap)
	_talent_bottom_used_label.text = str(total_spent) + " spent"

	# Setup wheel with config (first time) or update data
	if _talent_wheel != null:
		if talent_config.size() > 0 and _talent_wheel._talent_config.size() == 0:
			_talent_wheel.setup(talent_config, synergy_config)
		_talent_wheel.update_talents(talent_data)


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()




func _on_respec_pressed() -> void:
	SignalManager.signal_TalentRespec.emit()


# ==============================================================================
# SERVER MESSAGE HANDLERS (talent system)
# ==============================================================================
func _on_server_message(msg: Dictionary) -> void:
	var cmd = msg.get("cmd", "")
	if cmd == "talents_config":
		_on_talents_config(msg["data"])
	elif cmd == "talents_data":
		_on_talents_data(msg["data"])
	elif cmd == "talent_allocate":
		_on_talent_allocate(msg["data"])
	elif cmd == "talent_respec":
		_on_talent_respec(msg["data"])
	elif cmd == "talent_points_earned":
		_on_talent_points_earned(msg["data"])


func _on_talents_config(data: Dictionary) -> void:
	talent_config = data.get("registry", [])
	synergy_config = data.get("synergies", [])
	_refresh_talents()


func _on_talents_data(data: Dictionary) -> void:
	talent_data = data
	_refresh_talents()
	_refresh_open_tooltip()


func _on_talent_allocate(data: Dictionary) -> void:
	# Update local talent_data with the server response
	talent_data = data
	_refresh_talents()


func _on_talent_respec(data: Dictionary) -> void:
	talent_data = data
	_refresh_talents()


func _on_talent_points_earned(data: Dictionary) -> void:
	talent_data = data
	_refresh_talents()


# ==============================================================================
# SKILLS UI STRUCTURE BUILDER
# ==============================================================================
func _setup_skill_panel_structure() -> void:
	var main_sb = StyleBoxFlat.new()
	main_sb.bg_color = Styler.COLOR_PARCHMENT
	main_sb.border_width_left = 4
	main_sb.border_width_right = 4
	main_sb.border_width_top = 4
	main_sb.border_width_bottom = 4
	main_sb.border_color = Styler.COLOR_BORDER
	main_sb.set_corner_radius_all(4)
	skill_panel.add_theme_stylebox_override("panel", main_sb)

	v_box_skills.add_theme_constant_override("separation", 15)

	title_active_skills.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_active_skills.add_theme_font_size_override("font_size", 22)
	title_active_skills.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

	active_container.alignment = BoxContainer.ALIGNMENT_CENTER
	active_container.add_theme_constant_override("separation", 8)

	h_separator.modulate = Color(0, 0, 0, 0.3)

	title_spellbook.add_theme_font_override("font", Styler.GROBOLT_FONT)
	title_spellbook.add_theme_font_size_override("font_size", 22)
	title_spellbook.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

	mage_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mage_grid_spellbook.add_theme_constant_override("separation", 20)

	paladin_grid_spellbook.columns = 2
	paladin_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paladin_grid_spellbook.add_theme_constant_override("h_separation", 20)
	paladin_grid_spellbook.add_theme_constant_override("v_separation", 10)

	buffs_grid_spellbook.columns = 2
	buffs_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buffs_grid_spellbook.add_theme_constant_override("h_separation", 20)
	buffs_grid_spellbook.add_theme_constant_override("v_separation", 10)

	blood_grid_spellbook.columns = 2
	blood_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blood_grid_spellbook.add_theme_constant_override("h_separation", 20)
	blood_grid_spellbook.add_theme_constant_override("v_separation", 10)

	dark_grid_spellbook.columns = 2
	dark_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dark_grid_spellbook.add_theme_constant_override("h_separation", 20)
	dark_grid_spellbook.add_theme_constant_override("v_separation", 10)

	arcane_grid_spellbook.columns = 2
	arcane_grid_spellbook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arcane_grid_spellbook.add_theme_constant_override("h_separation", 20)
	arcane_grid_spellbook.add_theme_constant_override("v_separation", 10)


# ==============================================================================
# SKILLS LOGIC & RENDERING
# ==============================================================================
func _refresh_skills_ui() -> void:
	_render_active_bar()
	_render_spellbook_lists()


func _render_active_bar() -> void:
	for c in active_container.get_children():
		c.queue_free()

	for i in range(6):
		var skill_id = _active_slots[i]

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		btn.toggle_mode = false
		btn.focus_mode = Control.FOCUS_NONE

		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.2)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Styler.COLOR_GOLD
		sb.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

		if skill_id != null:
			var skill_instance = {}
			for inst in _known_skills:
				if skill_id == int(inst["skill_id"]):
					skill_instance = inst
			btn.icon = ItemDB.get_icon(skill_instance["skill_icon"])
			btn.expand_icon = true
			btn.tooltip_text = skill_instance["name"] + "\n(Click to Unequip)"
		else:
			btn.text = ""
			btn.tooltip_text = "Empty Slot"

		btn.pressed.connect(_on_active_slot_clicked.bind(i))
		active_container.add_child(btn)


func _render_spellbook_lists() -> void:
	for c in mage_grid_spellbook.get_children():
		c.queue_free()
	for c in paladin_grid_spellbook.get_children():
		c.queue_free()
	for c in buffs_grid_spellbook.get_children():
		c.queue_free()
	for c in blood_grid_spellbook.get_children():
		c.queue_free()
	for c in dark_grid_spellbook.get_children():
		c.queue_free()
	for c in arcane_grid_spellbook.get_children():
		c.queue_free()

	# Separate mage skills by magic_type for section headers
	var fire_skills = []
	var frost_skills = []
	var other_mage_skills = []
	for skill_instance in _known_skills:
		if skill_instance["skill_type"] == "mage":
			var effect_data = skill_instance.get("effect", {})
			if typeof(effect_data) == TYPE_STRING:
				effect_data = JSON.parse_string(effect_data)
				if effect_data == null:
					effect_data = {}
			var magic_type = ""
			if typeof(effect_data) == TYPE_DICTIONARY:
				magic_type = effect_data.get("magic_type", "")
			var skill_name = skill_instance.get("skill_name", "")
			var is_frost = magic_type == "frost" or skill_name in [
				"mage_frostshield", "mage_ice_barrier", "mage_icy_veins"
			]
			if is_frost:
				frost_skills.append(skill_instance)
			elif magic_type == "fire":
				fire_skills.append(skill_instance)
			else:
				other_mage_skills.append(skill_instance)

	# Build mage columns: Fire (left) / Frost (right)
	var fire_vbox = VBoxContainer.new()
	fire_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fire_vbox.add_theme_constant_override("separation", 10)
	mage_grid_spellbook.add_child(fire_vbox)

	var frost_vbox = VBoxContainer.new()
	frost_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frost_vbox.add_theme_constant_override("separation", 10)
	mage_grid_spellbook.add_child(frost_vbox)

	var fire_header = Label.new()
	fire_header.text = "── Fire ──"
	fire_header.add_theme_color_override("font_color", Styler.COL_FIRE)
	fire_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	fire_header.add_theme_font_size_override("font_size", 18)
	fire_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire_vbox.add_child(fire_header)

	for skill_instance in fire_skills:
		fire_vbox.add_child(_make_skill_row_btn(skill_instance))

	for skill_instance in other_mage_skills:
		fire_vbox.add_child(_make_skill_row_btn(skill_instance))

	var frost_header = Label.new()
	frost_header.text = "── Frost ──"
	frost_header.add_theme_color_override("font_color", Styler.COL_FROST)
	frost_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	frost_header.add_theme_font_size_override("font_size", 18)
	frost_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frost_vbox.add_child(frost_header)

	for skill_instance in frost_skills:
		frost_vbox.add_child(_make_skill_row_btn(skill_instance))

	# Build remaining grids
	var holy_header = Label.new()
	holy_header.text = "── Holy ──"
	holy_header.add_theme_color_override("font_color", Styler.COL_HOLY)
	holy_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	holy_header.add_theme_font_size_override("font_size", 18)
	holy_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paladin_grid_spellbook.add_child(holy_header)
	paladin_grid_spellbook.add_child(Control.new())

	var dark_header = Label.new()
	dark_header.text = "── Dark ──"
	dark_header.add_theme_color_override("font_color", Styler.COL_DARK)
	dark_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	dark_header.add_theme_font_size_override("font_size", 18)
	dark_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dark_grid_spellbook.add_child(dark_header)
	dark_grid_spellbook.add_child(Control.new())

	var arcane_header = Label.new()
	arcane_header.text = "── Arcane ──"
	arcane_header.add_theme_color_override("font_color", Styler.COL_ARCANE)
	arcane_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	arcane_header.add_theme_font_size_override("font_size", 18)
	arcane_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arcane_grid_spellbook.add_child(arcane_header)
	arcane_grid_spellbook.add_child(Control.new())

	var utility_header = Label.new()
	utility_header.text = "── Utility ──"
	utility_header.add_theme_color_override("font_color", Styler.COL_UTILITY)
	utility_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	utility_header.add_theme_font_size_override("font_size", 18)
	utility_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buffs_grid_spellbook.add_child(utility_header)
	buffs_grid_spellbook.add_child(Control.new())

	var blood_header = Label.new()
	blood_header.text = "── Blood ──"
	blood_header.add_theme_color_override("font_color", Styler.COL_BLOOD)
	blood_header.add_theme_font_override("font", Styler.GROBOLT_FONT)
	blood_header.add_theme_font_size_override("font_size", 18)
	blood_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blood_grid_spellbook.add_child(blood_header)
	blood_grid_spellbook.add_child(Control.new())

	for skill_instance in _known_skills:
		if skill_instance["skill_type"] == "paladin":
			paladin_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "buff":
			buffs_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "blood":
			blood_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "dark":
			dark_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))
		elif skill_instance["skill_type"] == "arcane":
			arcane_grid_spellbook.add_child(_make_skill_row_btn(skill_instance))


func _make_skill_row_btn(skill_instance: Dictionary) -> Button:
	var row_btn = Button.new()
	row_btn.custom_minimum_size = Vector2(320, 96)

	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0, 0, 0, 0.05)
	sb_norm.set_corner_radius_all(4)
	row_btn.add_theme_stylebox_override("normal", sb_norm)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.position = Vector2(5, 5)
	row_btn.add_child(hbox)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(96, 96)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.texture = ItemDB.get_icon(skill_instance["skill_icon"])
	hbox.add_child(icon_rect)

	var vbox_info = VBoxContainer.new()
	vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_info)

	var lbl_name = Label.new()
	lbl_name.text = skill_instance["name"]
	# TODO: Get rank from Account when skill_usage data is available
	# For now, just display the base name
	# When rank data is available:
	# var rank = Account.get_skill_rank(skill_instance["skill_name"])
	# if rank >= 2:
	#     var numerals = {2: " II", 3: " III", 4: " IV"}
	#     lbl_name.text += numerals.get(rank, "")
	lbl_name.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	lbl_name.add_theme_font_size_override("font_size", 16)
	vbox_info.add_child(lbl_name)

	row_btn.tooltip_text = skill_instance["descr"]

	var mp_hbox = HBoxContainer.new()
	mp_hbox.add_theme_constant_override("separation", 8)
	mp_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_info.add_child(mp_hbox)

	# Check for HP cost skills
	var effect_data = skill_instance.get("effect", {})
	if typeof(effect_data) == TYPE_STRING:
		effect_data = JSON.parse_string(effect_data)
		if effect_data == null:
			effect_data = {}
	var hp_cost = 0
	if typeof(effect_data) == TYPE_DICTIONARY:
		hp_cost = int(effect_data.get("HP Cost", 0))

	var lbl_mana = Label.new()
	if hp_cost > 0:
		lbl_mana.text = "HP: " + str(hp_cost)
		lbl_mana.add_theme_color_override("font_color", Styler.COLOR_TEXT_ERROR)
	else:
		lbl_mana.text = "Mana: " + _fmt(skill_instance["mp_cost"])
		lbl_mana.add_theme_color_override("font_color", Color.from_rgba8(64, 180, 255))
	lbl_mana.add_theme_font_size_override("font_size", 14)
	mp_hbox.add_child(lbl_mana)

	var lbl_cast = Label.new()
	lbl_cast.text = "Cast: " + _fmt(float(skill_instance["cast_time"]) / 10) + "s"
	lbl_cast.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	lbl_cast.add_theme_font_size_override("font_size", 14)
	mp_hbox.add_child(lbl_cast)

	var lbl_cd = Label.new()
	lbl_cd.text = "CD: " + _fmt(float(skill_instance["cooldown"]) / 10) + "s"
	lbl_cd.add_theme_color_override("font_color", Color.GREEN)
	lbl_cd.add_theme_font_size_override("font_size", 14)
	mp_hbox.add_child(lbl_cd)

	var effect = _parse_effects(skill_instance)
	var lbl_effect = Label.new()
	lbl_effect.text = effect
	lbl_effect.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	lbl_effect.add_theme_font_size_override("font_size", 12)
	vbox_info.add_child(lbl_effect)

	row_btn.pressed.connect(_on_spellbook_clicked.bind(skill_instance))
	return row_btn


# ==============================================================================
# INTERACTION
# ==============================================================================
func _on_active_slot_clicked(index: int) -> void:
	if _active_slots[index] != null:
		_active_slots[index] = null
		SignalManager.signal_UnEquipSkill.emit(index)
		_refresh_skills_ui()


func _on_spellbook_clicked(skill_instance: Dictionary) -> void:
	var skill_id = int(skill_instance["skill_id"])
	if skill_id in _active_slots:
		return
	var idx = _active_slots.find(null)
	if idx != -1:
		_active_slots[idx] = skill_id
		SignalManager.signal_EquipSkill.emit(idx, str(skill_id))
		_refresh_skills_ui()
	else:
		print("No empty slots!")


func _on_btn_skills_mage_pressed() -> void:
	mage_panel.visible = true
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_paladin_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = true
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_buffs_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = true
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_blood_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = true
	dark_panel.visible = false
	arcane_panel.visible = false


func _on_btn_skills_dark_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = true
	arcane_panel.visible = false


func _on_btn_skills_arcane_pressed() -> void:
	mage_panel.visible = false
	paladin_panel.visible = false
	buffs_panel.visible = false
	blood_panel.visible = false
	dark_panel.visible = false
	arcane_panel.visible = true


func _fmt(v) -> String:
	if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
		var is_whole = is_equal_approx(v, float(int(v)))
		if is_whole:
			return str(int(v))
		else:
			return "%0.1f" % v
	return str(v)


func _parse_effects(skill_instance) -> String:
	var stats_line = ""
	var duration_line = ""
	var keys = skill_instance["effect"].keys()
	if "Magical Damage" in keys:
		var value = int(skill_instance["effect"]["Magical Damage"])
		stats_line += "Magic Damage: " + str(value) + " "
	if "DOT Damage" in keys:
		var value = int(skill_instance["effect"]["DOT Damage"])
		stats_line += "DOT Damage: " + str(value) + " "
	if "Max MP" in keys:
		var value = (float(skill_instance["effect"]["Max MP"]) - 1) * 100
		stats_line += "Max MP: +" + _fmt(value) + "% "
	if "Physical Attack" in keys:
		var value = (float(skill_instance["effect"]["Physical Attack"]) - 1) * 100
		stats_line += "Physical Attack: +" + _fmt(value) + "% "
	if "Max Health" in keys:
		var value = (float(skill_instance["effect"]["Max Health"]) - 1) * 100
		stats_line += "Max Health: +" + _fmt(value) + "% "
	if "DMG multi" in keys:
		var value = (float(skill_instance["effect"]["DMG multi"]) - 1) * 100
		stats_line += "Damage: +" + _fmt(value) + "% from Magic ATK "
	if "HEAL multi" in keys:
		var value = (float(skill_instance["effect"]["HEAL multi"]) - 1) * 100
		stats_line += "Healing: +" + _fmt(value) + "% "
	if "Max Shield" in keys:
		var value = (float(skill_instance["effect"]["Max Shield"]) - 1) * 100
		stats_line += "Max Shield: +" + _fmt(value) + "% "
	if "Recovery HP" in keys:
		var value = float(skill_instance["effect"]["Recovery HP"])
		stats_line += "Recovery HP: +" + _fmt(value) + "HP "
	if "All Spell DMG" in keys:
		var value = float(skill_instance["effect"]["All Spell DMG"]) * 100
		stats_line += "Spell Damage: +" + _fmt(value) + "% "
	if "Physical Attack Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Physical Attack Reduce"])) * 100
		stats_line += "ATK Reduce: -" + _fmt(value) + "% "
	if "Attack Speed Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Attack Speed Reduce"])) * 100
		stats_line += "Slow: -" + _fmt(value) + "% "
	if "Shield Restore" in keys:
		stats_line += "Restores Shield "
	if "Incoming Damage Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Incoming Damage Reduce"])) * 100
		stats_line += "DMG Taken: -" + _fmt(value) + "% "
	if "DMG Output Reduce" in keys:
		var value = (1.0 - float(skill_instance["effect"]["DMG Output Reduce"])) * 100
		stats_line += "Enemy DMG: -" + _fmt(value) + "% "
	if "Magic Resist Reduce" in keys:
		var value = float(skill_instance["effect"]["Magic Resist Reduce"]) * 100
		stats_line += "Magic Resist: -" + _fmt(value) + "% "
	if "P Def Boost" in keys:
		var value = float(skill_instance["effect"]["P Def Boost"]) * 100
		stats_line += "P.Def: +" + _fmt(value) + "% "
	if "Recovery MP" in keys:
		var value = float(skill_instance["effect"]["Recovery MP"])
		stats_line += "MP Regen: +" + _fmt(value) + " "
	if "Thorns Buff" in keys:
		var value = float(skill_instance["effect"]["Thorns Buff"]) * 100
		stats_line += "Thorns: " + _fmt(value) + "% "
	if "P Def Reduce" in keys:
		var value = float(skill_instance["effect"]["P Def Reduce"]) * 100
		stats_line += "P.Def Reduce: -" + _fmt(value) + "% "
	if "Crit Chance Reduce" in keys:
		var value = float(skill_instance["effect"]["Crit Chance Reduce"]) * 100
		stats_line += "Crit Reduce: -" + _fmt(value) + "% "
	if "Haste" in keys:
		var value = (1.0 - float(skill_instance["effect"]["Haste"])) * 100
		duration_line += "Haste: +" + _fmt(value) + "% "
	if "apply_each" in keys:
		var value = float(skill_instance["effect"]["apply_each"])
		if value > 0:
			duration_line += "every: " + _fmt(value / 10) + "s "
	if "active_ticks" in keys:
		var value = float(skill_instance["effect"]["active_ticks"])
		if value > 0:
			duration_line += "Active for: " + _fmt(value / 10) + "s "
	var output = " " + stats_line.strip_edges()
	if duration_line != "":
		output += "\n " + duration_line.strip_edges()
	return output
