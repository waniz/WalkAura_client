extends Control

# ── Constants ──────────────────────────────────────────────────────────────────
const ACTIVITY_ALCHEMY = 2
const ACTIVITY_ENCHANTING = 9
const CONFIRMATION_DIALOG = preload("res://scenes/secondary_scenes/confirmation_dialog.tscn")

const PROF_ICON_KEY = {
	"herbalism"   : "herbalism",
	"alchemy"     : "alchemy",
	"enchanting"  : "enchanting",
	"hunting"     : "hunting",
	"mining"      : "mining",
	"woodcutting" : "woodcutting",
	"fishing"     : "fishing",
	"rift"        : "rift",
}

var PROF_ACCENT = {
	"alchemy"    : Color.from_rgba8(60, 130, 70),
	"enchanting" : Color.from_rgba8(163, 54, 237),
	"rift"       : Color.from_rgba8(255, 120, 90),
}

const TIER_LEVEL_BREAKS = [1, 5, 10, 15, 20]


# ── State ──────────────────────────────────────────────────────────────────────
var _profession_name: String = ""
var _active_tier: int = -1          # -1 = ALL, 0–4 = tier index
var _expanded_recipe_id: String = ""
var _last_recipes: Array = []
var _last_prof_level: int = 0
var _confirm_dialog: Control = null
var _accent: Color = Styler.COL_PRIMARY
var _is_dark: bool = false
var _last_crafting_steps_max: int = 0
var _last_crafting_target_qty: int = 0
var _last_crafting_batch_done: int = 0


# ── UI References ──────────────────────────────────────────────────────────────
var _radial_progress: Node
var _level_label: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _craft_banner: PanelContainer
var _craft_banner_icon: TextureRect
var _craft_banner_name_lbl: Label
var _craft_banner_bar: ProgressBar
var _craft_banner_steps_lbl: Label
var _craft_banner_batch_lbl: Label
var _tier_tabs: HBoxContainer
var _tier_btns: Array = []
var _scroll_content: VBoxContainer
var _loading_label: Label


# ── Lifecycle ──────────────────────────────────────────────────────────────────

func set_profession(prof_name: String) -> void:
	_profession_name = prof_name
	_accent = PROF_ACCENT.get(prof_name, Styler.COL_PRIMARY)
	_is_dark = (prof_name == "rift")


func _ready() -> void:
	_build_ui()
	if _profession_name == "rift":
		# Rift uses client-side data, no server request needed
		AccountManager.signal_AccountDataReceived.connect(_on_account_data)
		_build_rift_content()
	else:
		SignalManager.signal_ProfessionInfoReceived.connect(_on_profession_info)
		AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)
		AccountManager.signal_AccountDataReceived.connect(_on_account_data)
		SignalManager.signal_RequestProfessionInfo.emit(_profession_name)


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	if _is_dark:
		var dark_sb = StyleBoxFlat.new()
		dark_sb.bg_color = Styler.COL_PANEL_BG
		dark_sb.border_color = Color(1.0, 1.0, 1.0, 0.12)
		dark_sb.set_border_width_all(1)
		dark_sb.set_corner_radius_all(4)
		dark_sb.shadow_size = 4
		dark_sb.shadow_color = Color(0, 0, 0, 0.5)
		panel.add_theme_stylebox_override("panel", dark_sb)
	else:
		Styler._apply_parchment_style(panel)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	_build_header(root_vbox)

	var sep = HSeparator.new()
	root_vbox.add_child(sep)

	_build_craft_banner(root_vbox)

	if _profession_name in ["alchemy", "enchanting"]:
		_build_tier_tabs(root_vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_scroll_content = VBoxContainer.new()
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_theme_constant_override("separation", 6)
	scroll.add_child(_scroll_content)

	_loading_label = Label.new()
	_loading_label.text = "Loading..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var load_col = Color(0.6, 0.6, 0.6) if _is_dark else Styler.COLOR_TEXT_DARK
	_loading_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_loading_label.add_theme_font_size_override("font_size", 14)
	_loading_label.add_theme_color_override("font_color", load_col)
	_scroll_content.add_child(_loading_label)

	_update_craft_banner()


# ── Header ─────────────────────────────────────────────────────────────────────

func _build_header(parent: VBoxContainer) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(header)

	# Profession icon with radial XP ring
	var ring_radius = 38.0
	var ring_size = int(ring_radius * 2.0)
	var ring_wrapper = Control.new()
	ring_wrapper.custom_minimum_size = Vector2(ring_size, ring_size)
	ring_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(ring_wrapper)

	_radial_progress = RadialProgress.new()
	_radial_progress.ring = true
	_radial_progress.radius = ring_radius
	_radial_progress.thickness = 5.0
	_radial_progress.max_value = 100.0
	_radial_progress.progress = 0.0
	_radial_progress.bg_color = Color(1.0, 1.0, 1.0, 0.15)
	_radial_progress.bar_color = _accent
	_radial_progress.border_width = 1.0
	_radial_progress.border_color = Color(0, 0, 0, 0.4)
	_radial_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radial_progress.position = Vector2(ring_radius, ring_radius)
	ring_wrapper.add_child(_radial_progress)

	var prof_icon = TextureRect.new()
	prof_icon.custom_minimum_size = Vector2(56, 56)
	prof_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prof_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prof_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_offset = (ring_size - 56) / 2.0
	prof_icon.position = Vector2(icon_offset, icon_offset)
	var icon_id = PROF_ICON_KEY.get(_profession_name, "")
	if not icon_id.is_empty():
		prof_icon.texture = ItemDB.get_icon(icon_id)
	ring_wrapper.add_child(prof_icon)

	# Name + Level + XP bar
	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_col.add_theme_constant_override("separation", 2)
	header.add_child(info_col)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info_col.add_child(name_row)

	var title = Label.new()
	title.text = _profession_name.to_upper()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", _accent)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	name_row.add_child(title)

	_level_label = Label.new()
	_level_label.text = "..."
	_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if _is_dark else Styler.COLOR_SECTION_HDR)
	_level_label.add_theme_font_size_override("font_size", 16)
	_level_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_row.add_child(_level_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 20)
	_xp_bar.show_percentage = false
	var xp_bg = StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.0, 0.0, 0.0, 0.15)
	xp_bg.set_corner_radius_all(6)
	_xp_bar.add_theme_stylebox_override("background", xp_bg)
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = _accent
	xp_fill.set_corner_radius_all(6)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	info_col.add_child(_xp_bar)

	_xp_text = Label.new()
	_xp_text.text = "..."
	_xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var xp_text_col = Color(0.6, 0.6, 0.6) if _is_dark else Styler.COLOR_TEXT_DARK
	_xp_text.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_xp_text.add_theme_font_size_override("font_size", 12)
	_xp_text.add_theme_color_override("font_color", xp_text_col)
	info_col.add_child(_xp_text)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "X"
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)


# ── Craft Banner ───────────────────────────────────────────────────────────────

func _build_craft_banner(parent: VBoxContainer) -> void:
	_craft_banner = PanelContainer.new()
	_craft_banner.visible = false
	_craft_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.08)
	sb.border_color = _accent
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 10
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_craft_banner.add_theme_stylebox_override("panel", sb)
	parent.add_child(_craft_banner)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	_craft_banner.add_child(hbox)

	_craft_banner_icon = TextureRect.new()
	_craft_banner_icon.custom_minimum_size = Vector2(32, 32)
	_craft_banner_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_craft_banner_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_craft_banner_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_craft_banner_icon)

	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 2)
	hbox.add_child(info_col)

	_craft_banner_name_lbl = Label.new()
	_craft_banner_name_lbl.text = "Crafting..."
	Styler.style_parchment_label(_craft_banner_name_lbl, Styler.COLOR_SECTION_HDR, 14)
	info_col.add_child(_craft_banner_name_lbl)

	_craft_banner_bar = ProgressBar.new()
	_craft_banner_bar.custom_minimum_size = Vector2(0, 14)
	_craft_banner_bar.show_percentage = false
	var cb_bg = StyleBoxFlat.new()
	cb_bg.bg_color = Color(0.0, 0.0, 0.0, 0.15)
	cb_bg.set_corner_radius_all(4)
	_craft_banner_bar.add_theme_stylebox_override("background", cb_bg)
	var cb_fill = StyleBoxFlat.new()
	cb_fill.bg_color = _accent
	cb_fill.set_corner_radius_all(4)
	_craft_banner_bar.add_theme_stylebox_override("fill", cb_fill)
	info_col.add_child(_craft_banner_bar)

	var steps_row = HBoxContainer.new()
	steps_row.add_theme_constant_override("separation", 8)
	info_col.add_child(steps_row)

	_craft_banner_steps_lbl = Label.new()
	_craft_banner_steps_lbl.text = ""
	Styler.style_parchment_label(_craft_banner_steps_lbl, Styler.COLOR_TEXT_DARK, 12)
	steps_row.add_child(_craft_banner_steps_lbl)

	_craft_banner_batch_lbl = Label.new()
	_craft_banner_batch_lbl.text = ""
	Styler.style_parchment_label(_craft_banner_batch_lbl, Styler.COLOR_GOLD, 12)
	steps_row.add_child(_craft_banner_batch_lbl)

	var stop_btn = Button.new()
	stop_btn.text = "STOP"
	Styler.style_button_small(stop_btn, Color.from_rgba8(180, 60, 60))
	stop_btn.custom_minimum_size = Vector2(60, 36)
	stop_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stop_btn.pressed.connect(_on_stop_craft)
	hbox.add_child(stop_btn)


# ── Tier Tabs ──────────────────────────────────────────────────────────────────

func _build_tier_tabs(parent: VBoxContainer) -> void:
	_tier_tabs = HBoxContainer.new()
	_tier_tabs.add_theme_constant_override("separation", 4)
	_tier_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_tier_tabs)

	_tier_btns.clear()
	var all_btn = _make_tier_tab("ALL", -1)
	_tier_tabs.add_child(all_btn)
	_tier_btns.append(all_btn)

	for i in range(5):
		var btn = _make_tier_tab("T%d" % (i + 1), i)
		_tier_tabs.add_child(btn)
		_tier_btns.append(btn)

	_update_tier_tab_styles()


func _make_tier_tab(text: String, tier_index: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(44, 32)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		_active_tier = tier_index
		_update_tier_tab_styles()
		_rebuild_recipe_list()
	)
	return btn


func _update_tier_tab_styles() -> void:
	for i in range(_tier_btns.size()):
		var btn: Button = _tier_btns[i]
		var tier_idx = i - 1
		var is_active = (tier_idx == _active_tier)
		var is_locked = false
		if tier_idx >= 0 and tier_idx < TIER_LEVEL_BREAKS.size():
			is_locked = _last_prof_level < TIER_LEVEL_BREAKS[tier_idx]

		var sb = StyleBoxFlat.new()
		if is_active:
			sb.bg_color = Color(0.0, 0.0, 0.0, 0.08)
			sb.border_color = _accent
			sb.border_width_bottom = 3
		else:
			sb.bg_color = Color(0.0, 0.0, 0.0, 0.03)
			sb.border_color = Color(0.0, 0.0, 0.0, 0.1)
			sb.border_width_bottom = 1
		sb.set_corner_radius_all(4)
		sb.corner_radius_bottom_left = 0
		sb.corner_radius_bottom_right = 0
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

		var text_color: Color
		if is_active:
			text_color = _accent
		elif is_locked:
			text_color = Color(0.5, 0.5, 0.5, 0.5)
		else:
			text_color = Styler.COLOR_TEXT_DARK
		btn.add_theme_color_override("font_color", text_color)
		btn.add_theme_color_override("font_hover_color", text_color)
		btn.add_theme_color_override("font_pressed_color", text_color)
		btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
		btn.add_theme_font_size_override("font_size", 14)


# ── Data Handlers ──────────────────────────────────────────────────────────────

func _on_profession_info(data: Dictionary) -> void:
	if data.get("profession", "") != _profession_name:
		return

	if is_instance_valid(_loading_label):
		_loading_label.visible = false

	var lvl: int = int(data.get("level", 1))
	var xp: int = int(data.get("xp", 0))
	var xp_to_next = data.get("xp_to_next", null)
	_last_prof_level = lvl

	_level_label.text = "Lv %d" % lvl

	if xp_to_next != null and int(xp_to_next) > 0:
		var xp_next = int(xp_to_next)
		var pct = int(round(float(xp) / float(xp_next) * 100.0))
		_xp_bar.max_value = xp_next
		_xp_bar.value = xp
		_xp_text.text = "%d / %d XP" % [xp, xp_next]
		var tween = _radial_progress.create_tween()
		tween.tween_property(_radial_progress, "progress", float(pct), 0.5).from(0.0)
	else:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_text.text = "MAX LEVEL"
		_radial_progress.progress = 100.0

	if _profession_name in ["alchemy", "enchanting"]:
		_update_tier_tab_styles()

	for child in _scroll_content.get_children():
		child.queue_free()

	if _profession_name in ["herbalism", "mining", "woodcutting", "fishing", "hunting"]:
		_build_gathering_content(data)
	elif _profession_name in ["alchemy", "enchanting"]:
		_build_crafting_content(data)


func _on_activity_progress(data: Dictionary) -> void:
	var raw = data.get("data", data)
	var d: Dictionary = raw.get("data", raw)
	if d.has("crafting_steps_max"):
		_last_crafting_steps_max = int(d["crafting_steps_max"])
	if d.has("crafting_target_qty"):
		_last_crafting_target_qty = int(d["crafting_target_qty"])
	if d.has("crafting_batch_done"):
		_last_crafting_batch_done = int(d["crafting_batch_done"])
	_update_craft_banner()
	var craft_active = (
		(_profession_name == "alchemy" and Account.activity == ACTIVITY_ALCHEMY) or
		(_profession_name == "enchanting" and Account.activity == ACTIVITY_ENCHANTING)
	)
	if craft_active:
		SignalManager.signal_RequestProfessionInfo.emit(_profession_name)


func _on_account_data(_ok) -> void:
	if _profession_name == "rift":
		_build_rift_content()
		return
	_update_craft_banner()
	SignalManager.signal_RequestProfessionInfo.emit(_profession_name)


# ── Crafting Content ───────────────────────────────────────────────────────────

func _build_crafting_content(data: Dictionary) -> void:
	_last_recipes = data.get("recipes", [])

	var current_act = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	if Account.activity == current_act and not Account.crafting_recipe_id.is_empty():
		for recipe in _last_recipes:
			if recipe.get("recipe_id", "") == Account.crafting_recipe_id:
				_craft_banner_name_lbl.text = "Crafting: %s" % recipe.get("name", "Unknown")
				var icon_tex = ItemDB.get_item_icon(recipe.get("output_icon", ""))
				if icon_tex:
					_craft_banner_icon.texture = icon_tex
				if _last_crafting_steps_max == 0:
					_last_crafting_steps_max = int(recipe.get("base_steps", 0))
					_last_crafting_target_qty = Account.crafting_target_qty
					_last_crafting_batch_done = Account.crafting_batch_done
					_update_craft_banner()
				break

	_rebuild_recipe_list()


func _rebuild_recipe_list() -> void:
	for child in _scroll_content.get_children():
		child.queue_free()

	if _last_recipes.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No recipes available."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		_scroll_content.add_child(empty_lbl)
		return

	var filtered: Array = []
	for recipe in _last_recipes:
		if _active_tier == -1:
			filtered.append(recipe)
		else:
			var tier = _get_recipe_tier(int(recipe.get("req_level", 1)))
			if tier == _active_tier:
				filtered.append(recipe)

	filtered.sort_custom(func(a, b):
		var a_craft = a.get("can_craft", false)
		var b_craft = b.get("can_craft", false)
		var a_unlock = a.get("unlocked", false)
		var b_unlock = b.get("unlocked", false)
		var a_pri = 0 if a_craft else (1 if a_unlock else 2)
		var b_pri = 0 if b_craft else (1 if b_unlock else 2)
		if a_pri != b_pri:
			return a_pri < b_pri
		return int(a.get("req_level", 0)) < int(b.get("req_level", 0))
	)

	if filtered.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No recipes in this tier."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		_scroll_content.add_child(empty_lbl)
		return

	var expanded_in_filter = false
	for recipe in filtered:
		if recipe.get("recipe_id", "") == _expanded_recipe_id:
			expanded_in_filter = true
			break
	if not expanded_in_filter:
		_expanded_recipe_id = ""

	for recipe in filtered:
		var rid = recipe.get("recipe_id", "")
		if rid == _expanded_recipe_id:
			_scroll_content.add_child(_build_expanded_recipe(recipe))
		else:
			_scroll_content.add_child(_build_compact_recipe_card(recipe))


# ── Compact Recipe Card ────────────────────────────────────────────────────────

func _build_compact_recipe_card(recipe: Dictionary) -> PanelContainer:
	var unlocked: bool = recipe.get("unlocked", false)
	var can_craft: bool = recipe.get("can_craft", false)
	var rid: String = recipe.get("recipe_id", "")

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.04)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if can_craft:
		sb.border_color = Color.from_rgba8(60, 160, 80, 200)
	elif unlocked:
		sb.border_color = Color.from_rgba8(200, 160, 60, 200)
	else:
		sb.border_color = Color(0.4, 0.4, 0.4, 0.3)
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", sb)

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_expanded_recipe_id = rid
			_rebuild_recipe_list()
	)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	# Output icon with frame
	var icon_frame = PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(52, 52)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var if_sb = StyleBoxFlat.new()
	if_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	if_sb.border_color = _accent if unlocked else Color(0.4, 0.4, 0.4, 0.3)
	if_sb.set_border_width_all(1)
	if_sb.set_corner_radius_all(4)
	if_sb.content_margin_left = 2
	if_sb.content_margin_right = 2
	if_sb.content_margin_top = 2
	if_sb.content_margin_bottom = 2
	icon_frame.add_theme_stylebox_override("panel", if_sb)
	hbox.add_child(icon_frame)

	var out_icon = TextureRect.new()
	out_icon.custom_minimum_size = Vector2(48, 48)
	out_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	out_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	out_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var out_tex = ItemDB.get_item_icon(recipe.get("output_icon", ""))
	if out_tex:
		out_icon.texture = out_tex
	icon_frame.add_child(out_icon)

	# Center: name + status
	var center_col = VBoxContainer.new()
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.add_theme_constant_override("separation", 2)
	center_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(center_col)

	var name_lbl = Label.new()
	name_lbl.text = recipe.get("name", "Unknown")
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK if unlocked else Color(0.5, 0.5, 0.5))
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	center_col.add_child(name_lbl)

	var badge = Label.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if can_craft:
		badge.text = "READY"
		badge.add_theme_color_override("font_color", Color.from_rgba8(60, 160, 80))
	elif unlocked:
		badge.text = "MISSING"
		badge.add_theme_color_override("font_color", Color.from_rgba8(200, 160, 60))
	else:
		badge.text = "LOCKED Lv %d" % int(recipe.get("req_level", 0))
		badge.add_theme_color_override("font_color", Color.from_rgba8(200, 80, 80))
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_font_override("font", Styler.QUADRAT_FONT)
	center_col.add_child(badge)

	# Right: ingredient thumbnails
	var ing_row = HBoxContainer.new()
	ing_row.add_theme_constant_override("separation", 3)
	ing_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ing_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(ing_row)

	var ingredients: Array = recipe.get("ingredients", [])
	for ing in ingredients:
		var ing_wrapper = VBoxContainer.new()
		ing_wrapper.add_theme_constant_override("separation", 0)
		ing_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ing_row.add_child(ing_wrapper)

		var ing_icon = TextureRect.new()
		ing_icon.custom_minimum_size = Vector2(24, 24)
		ing_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ing_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ing_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ing_tex = ItemDB.get_item_icon(ing.get("icon", ""))
		if ing_tex:
			ing_icon.texture = ing_tex
		ing_wrapper.add_child(ing_icon)

		var qty_have: int = int(ing.get("qty_have", 0))
		var qty_need: int = int(ing.get("qty_needed", 0))
		var qty_color = Color.from_rgba8(60, 160, 80) if qty_have >= qty_need else Color.from_rgba8(200, 80, 80)
		var qty_lbl = Label.new()
		qty_lbl.text = "%d/%d" % [qty_have, qty_need]
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		qty_lbl.add_theme_font_size_override("font_size", 10)
		qty_lbl.add_theme_color_override("font_color", qty_color)
		qty_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		ing_wrapper.add_child(qty_lbl)

	return panel


# ── Expanded Recipe Detail ─────────────────────────────────────────────────────

func _build_expanded_recipe(recipe: Dictionary) -> PanelContainer:
	var unlocked: bool = recipe.get("unlocked", false)
	var can_craft: bool = recipe.get("can_craft", false)
	var rid: String = recipe.get("recipe_id", "")

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = _accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Collapse header row (tap to close)
	var collapse_row = HBoxContainer.new()
	collapse_row.add_theme_constant_override("separation", 10)
	collapse_row.mouse_filter = Control.MOUSE_FILTER_STOP
	collapse_row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_expanded_recipe_id = ""
			_rebuild_recipe_list()
	)
	vbox.add_child(collapse_row)

	# Large output icon
	var icon_frame = PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(68, 68)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var if_sb = StyleBoxFlat.new()
	if_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	if_sb.border_color = _accent
	if_sb.set_border_width_all(2)
	if_sb.set_corner_radius_all(6)
	if_sb.content_margin_left = 2
	if_sb.content_margin_right = 2
	if_sb.content_margin_top = 2
	if_sb.content_margin_bottom = 2
	icon_frame.add_theme_stylebox_override("panel", if_sb)
	collapse_row.add_child(icon_frame)

	var out_icon = TextureRect.new()
	out_icon.custom_minimum_size = Vector2(64, 64)
	out_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	out_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	out_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var out_tex = ItemDB.get_item_icon(recipe.get("output_icon", ""))
	if out_tex:
		out_icon.texture = out_tex
	icon_frame.add_child(out_icon)

	# Name + effects
	var name_col = VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 2)
	name_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	collapse_row.add_child(name_col)

	var name_lbl = Label.new()
	name_lbl.text = recipe.get("name", "Unknown")
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", _accent)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_col.add_child(name_lbl)

	var descr = recipe.get("output_descr", "")
	if descr is String and not descr.is_empty():
		var descr_lbl = Label.new()
		descr_lbl.text = descr
		descr_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Styler.style_parchment_label(descr_lbl, Styler.COLOR_TEXT_DARK, 13)
		descr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_col.add_child(descr_lbl)

	var effects = recipe.get("output_effects")
	if effects != null and effects is Dictionary and effects.size() > 0:
		var parts: PackedStringArray = []
		for eff_name in effects:
			parts.append("%s: +%s" % [eff_name, str(effects[eff_name])])
		var eff_lbl = Label.new()
		eff_lbl.text = "  ".join(parts)
		eff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		eff_lbl.add_theme_font_size_override("font_size", 14)
		eff_lbl.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 80))
		eff_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		name_col.add_child(eff_lbl)

	# Collapse arrow
	var arrow_lbl = Label.new()
	arrow_lbl.text = "▲"
	arrow_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	arrow_lbl.add_theme_font_size_override("font_size", 16)
	arrow_lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	collapse_row.add_child(arrow_lbl)

	# Separator
	vbox.add_child(HSeparator.new())

	# Ingredients section
	var ing_header = Label.new()
	ing_header.text = "Ingredients"
	Styler.style_parchment_label(ing_header, Styler.COLOR_SECTION_HDR, 14)
	vbox.add_child(ing_header)

	var ing_grid = HBoxContainer.new()
	ing_grid.add_theme_constant_override("separation", 8)
	ing_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(ing_grid)

	var ingredients: Array = recipe.get("ingredients", [])
	for ing in ingredients:
		ing_grid.add_child(_build_ingredient_slot(ing))

	# Stats row
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	vbox.add_child(stats_row)

	var r_eff = int(recipe.get("base_steps", 0))
	var r_orig = int(recipe.get("base_steps_original", r_eff))
	var r_xp = int(recipe.get("base_xp", 0))

	var steps_text: String
	if r_orig > r_eff and r_orig > 0:
		var r_pct = int(round((1.0 - float(r_eff) / float(r_orig)) * 100.0))
		steps_text = "%d steps (-%d%%)" % [r_eff, r_pct]
	else:
		steps_text = "%d steps" % r_eff

	var steps_lbl = Label.new()
	steps_lbl.text = steps_text
	Styler.style_parchment_label(steps_lbl, Styler.COLOR_TEXT_DARK, 13)
	stats_row.add_child(steps_lbl)

	var xp_lbl = Label.new()
	xp_lbl.text = "%d XP" % r_xp
	Styler.style_parchment_label(xp_lbl, Styler.COLOR_GOLD, 13)
	stats_row.add_child(xp_lbl)

	var output_qty = int(recipe.get("output_qty", 1))
	if output_qty > 1:
		var makes_lbl = Label.new()
		makes_lbl.text = "Makes %dx" % output_qty
		Styler.style_parchment_label(makes_lbl, Styler.COLOR_TEXT_DARK, 13)
		stats_row.add_child(makes_lbl)

	# Craft controls
	vbox.add_child(HSeparator.new())

	var current_craft_activity = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	var max_qty: int = _compute_max_craft_qty(ingredients)

	var craft_btn = Button.new()
	craft_btn.custom_minimum_size = Vector2(0, 44)
	craft_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if not unlocked:
		craft_btn.text = "LOCKED"
		craft_btn.disabled = true
		Styler.style_button(craft_btn, Color.from_rgba8(160, 155, 150))
		vbox.add_child(craft_btn)
	elif not can_craft:
		craft_btn.text = "MISSING INGREDIENTS"
		craft_btn.disabled = true
		Styler.style_button(craft_btn, Color.from_rgba8(200, 160, 100))
		vbox.add_child(craft_btn)
	elif Account.activity == current_craft_activity:
		craft_btn.text = "CRAFTING..."
		craft_btn.disabled = true
		Styler.style_button(craft_btn, Color.from_rgba8(180, 170, 160))
		vbox.add_child(craft_btn)
	else:
		# Quantity controls row
		var qty_row = HBoxContainer.new()
		qty_row.add_theme_constant_override("separation", 6)
		qty_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		qty_row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(qty_row)

		var minus_btn = Button.new()
		minus_btn.text = "−"
		minus_btn.custom_minimum_size = Vector2(44, 44)
		Styler.style_button(minus_btn, Styler.COLOR_GOLD)
		qty_row.add_child(minus_btn)

		var qty_edit = LineEdit.new()
		qty_edit.text = "1"
		qty_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_edit.custom_minimum_size = Vector2(64, 44)
		qty_edit.add_theme_color_override("font_color", Styler.COLOR_GOLD)
		qty_edit.add_theme_font_override("font", Styler.QUADRAT_FONT)
		qty_edit.add_theme_font_size_override("font_size", 18)
		qty_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		qty_row.add_child(qty_edit)

		var plus_btn = Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(44, 44)
		Styler.style_button(plus_btn, Styler.COLOR_GOLD)
		qty_row.add_child(plus_btn)

		var max_btn = Button.new()
		max_btn.text = "MAX"
		max_btn.custom_minimum_size = Vector2(60, 44)
		Styler.style_button(max_btn, Styler.COLOR_GOLD)
		qty_row.add_child(max_btn)

		var disable_qty = max_qty <= 0

		var clamp_qty = func(n: int) -> int:
			if max_qty <= 0:
				return 1
			return clampi(n, 1, max_qty)

		minus_btn.pressed.connect(func():
			qty_edit.text = str(clamp_qty.call(int(qty_edit.text) - 1))
		)
		plus_btn.pressed.connect(func():
			qty_edit.text = str(clamp_qty.call(int(qty_edit.text) + 1))
		)
		max_btn.pressed.connect(func():
			qty_edit.text = str(maxi(1, max_qty))
		)
		qty_edit.text_submitted.connect(func(_s: String):
			qty_edit.text = str(clamp_qty.call(int(qty_edit.text)))
			qty_edit.release_focus()
		)
		qty_edit.focus_exited.connect(func():
			qty_edit.text = str(clamp_qty.call(int(qty_edit.text)))
		)

		minus_btn.disabled = disable_qty
		plus_btn.disabled = disable_qty
		max_btn.disabled = disable_qty or max_qty == 0
		qty_edit.editable = not disable_qty

		# CRAFT button
		craft_btn.text = "CRAFT"
		Styler.style_button(craft_btn, _accent)
		var rname: String = recipe.get("name", "Unknown")
		craft_btn.pressed.connect(func():
			var q: int = clamp_qty.call(int(qty_edit.text))
			_on_craft_pressed(rid, rname, q)
		)
		vbox.add_child(craft_btn)

	return panel


# ── Ingredient Slot ────────────────────────────────────────────────────────────

func _build_ingredient_slot(ing: Dictionary) -> VBoxContainer:
	var wrapper = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 2)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var qty_have: int = int(ing.get("qty_have", 0))
	var qty_need: int = int(ing.get("qty_needed", 0))
	var has_enough: bool = qty_have >= qty_need

	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(48, 48)
	var f_sb = StyleBoxFlat.new()
	f_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	if has_enough:
		f_sb.border_color = Color.from_rgba8(60, 160, 80, 180)
	else:
		f_sb.border_color = Color.from_rgba8(200, 80, 80, 180)
	f_sb.set_border_width_all(2)
	f_sb.set_corner_radius_all(5)
	f_sb.content_margin_left = 2
	f_sb.content_margin_right = 2
	f_sb.content_margin_top = 2
	f_sb.content_margin_bottom = 2
	frame.add_theme_stylebox_override("panel", f_sb)
	wrapper.add_child(frame)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex = ItemDB.get_item_icon(ing.get("icon", ""))
	if tex:
		icon.texture = tex
	frame.add_child(icon)

	var name_text = str(ing.get("name", "")).replace("_", " ").capitalize()
	var name_lbl = Label.new()
	name_lbl.text = name_text
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_lbl.clip_text = true
	wrapper.add_child(name_lbl)

	var qty_lbl = Label.new()
	qty_lbl.text = "%d / %d" % [qty_have, qty_need]
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var qty_color = Color.from_rgba8(60, 160, 80) if has_enough else Color.from_rgba8(200, 80, 80)
	qty_lbl.add_theme_font_size_override("font_size", 12)
	qty_lbl.add_theme_color_override("font_color", qty_color)
	qty_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	wrapper.add_child(qty_lbl)

	return wrapper


# ── Rift Content ───────────────────────────────────────────────────────────────

func _build_rift_content() -> void:
	# Hide loading label
	if is_instance_valid(_loading_label):
		_loading_label.visible = false

	# Update header from client-side data
	var lvl = int(Account.rift_lvl) if Account.rift_lvl != null else 1
	var xp = int(Account.rift_xp) if Account.rift_xp != null else 0
	var xp_table = ServerParams.ACTIVITY_PROGRESSION_LEVELS
	var next_exp = int(xp_table.get(str(lvl + 1), -1)) if xp_table else -1

	_level_label.text = "Lv %d" % lvl

	if next_exp > 0:
		var pct = int(round(float(xp) / float(next_exp) * 100.0))
		_xp_bar.max_value = next_exp
		_xp_bar.value = xp
		_xp_text.text = "%d / %d XP" % [xp, next_exp]
		var tween = _radial_progress.create_tween()
		tween.tween_property(_radial_progress, "progress", float(pct), 0.5).from(0.0)
	else:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_text.text = "MAX LEVEL"
		_radial_progress.progress = 100.0

	# Clear scroll content
	for child in _scroll_content.get_children():
		child.queue_free()

	# Active rift banner
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	if rift_id > 0 and RiftData.RIFT_TABLE.has(rift_id):
		_build_active_rift_banner(rift_id)

	# Rift cards grouped by tier
	var tiers = {1: [], 2: [], 3: []}
	for loc_id in RiftData.RIFT_TABLE:
		var cfg = RiftData.RIFT_TABLE[loc_id]
		var tier = int(cfg.get("tier", 1))
		if tiers.has(tier):
			tiers[tier].append({"loc_id": loc_id, "cfg": cfg})

	var tier_labels = {1: "TIER 1 · EASY", 2: "TIER 2 · MEDIUM", 3: "TIER 3 · HARD"}
	for tier in [1, 2, 3]:
		if tiers[tier].is_empty():
			continue

		var tier_color = RiftData.TIER_COLORS.get(tier, Color.WHITE)

		# Tier header
		var hdr = Label.new()
		hdr.text = tier_labels[tier]
		hdr.add_theme_font_override("font", Styler.QUADRAT_FONT)
		hdr.add_theme_font_size_override("font_size", 13)
		hdr.add_theme_color_override("font_color", tier_color)
		_scroll_content.add_child(hdr)

		# 2-column grid
		var entries = tiers[tier]
		for row_start in range(0, entries.size(), 2):
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_scroll_content.add_child(row)

			var card1 = _build_rift_card(entries[row_start].loc_id, entries[row_start].cfg)
			card1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(card1)

			if row_start + 1 < entries.size():
				var card2 = _build_rift_card(entries[row_start + 1].loc_id, entries[row_start + 1].cfg)
				card2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(card2)
			else:
				var pad = Control.new()
				pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(pad)


func _build_active_rift_banner(rift_id: int) -> void:
	var cfg = RiftData.RIFT_TABLE[rift_id]
	var tier = int(cfg.get("tier", 1))
	var tier_color = RiftData.TIER_COLORS.get(tier, Color.WHITE)

	var banner = PanelContainer.new()
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	sb.border_color = tier_color
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	banner.add_theme_stylebox_override("panel", sb)
	_scroll_content.add_child(banner)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	banner.add_child(hbox)

	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 4)
	hbox.add_child(info_col)

	var name_lbl = Label.new()
	name_lbl.text = "Active: %s" % cfg.get("name", "Unknown")
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", tier_color)
	info_col.add_child(name_lbl)

	# Progress bar
	var steps = int(Account.rift_steps) if Account.rift_steps != null else 0
	var steps_max = int(Account.rift_steps_max) if Account.rift_steps_max != null else 1
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(0, 14)
	pbar.show_percentage = false
	pbar.max_value = maxi(1, steps_max)
	pbar.value = steps
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.0, 0.0, 0.0, 0.3)
	pb_bg.set_corner_radius_all(4)
	pbar.add_theme_stylebox_override("background", pb_bg)
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = tier_color
	pb_fill.set_corner_radius_all(4)
	pbar.add_theme_stylebox_override("fill", pb_fill)
	info_col.add_child(pbar)

	# Stats row
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	info_col.add_child(stats_row)

	var steps_lbl = Label.new()
	steps_lbl.text = "%d / %d steps" % [steps, steps_max]
	steps_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	steps_lbl.add_theme_font_size_override("font_size", 12)
	steps_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	stats_row.add_child(steps_lbl)

	var milestone = int(Account.rift_milestone_index) if Account.rift_milestone_index != null else 0
	var total_ms = int(Account.rift_total_milestones) if Account.rift_total_milestones != null else 0
	var ms_lbl = Label.new()
	ms_lbl.text = "Milestone %d / %d" % [milestone, total_ms]
	ms_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	ms_lbl.add_theme_font_size_override("font_size", 12)
	ms_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	stats_row.add_child(ms_lbl)

	# Continue button
	var cont_btn = Button.new()
	cont_btn.text = "CONTINUE"
	Styler.style_button(cont_btn, tier_color)
	cont_btn.custom_minimum_size = Vector2(100, 44)
	cont_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cont_btn.pressed.connect(func():
		SignalManager.signal_ShowRift.emit(rift_id)
		queue_free()
	)
	hbox.add_child(cont_btn)


func _build_rift_card(location_id: int, cfg: Dictionary) -> PanelContainer:
	var tier = int(cfg.get("tier", 1))
	var tier_color = RiftData.TIER_COLORS.get(tier, Color.WHITE)
	var rift_lvl = int(Account.rift_lvl) if Account.rift_lvl != null else 1
	var account_lvl = int(Account.level) if Account.level != null else 1
	var req_rift = int(cfg.get("req_rift_lvl", 1))
	var req_account = int(cfg.get("req_account_lvl", 1))
	var rift_met = rift_lvl >= req_rift
	var account_met = account_lvl >= req_account
	var all_met = rift_met and account_met

	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.04)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	if all_met:
		sb.border_color = tier_color
	else:
		sb.border_color = Color(0.4, 0.4, 0.4, 0.3)
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", sb)

	# Tappable
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			SignalManager.signal_ShowRift.emit(location_id)
			queue_free()
	)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	# Left: info column
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var info_margin = MarginContainer.new()
	info_margin.add_theme_constant_override("margin_top", 8)
	info_margin.add_theme_constant_override("margin_bottom", 8)
	info_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_margin.add_child(vbox)
	hbox.add_child(info_margin)

	# Rift name
	var name_lbl = Label.new()
	name_lbl.text = cfg.get("name", "Unknown")
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", tier_color if all_met else Color(0.5, 0.5, 0.5))
	vbox.add_child(name_lbl)

	# Requirements row
	var req_row = HBoxContainer.new()
	req_row.add_theme_constant_override("separation", 6)
	req_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(req_row)

	var rift_req = Label.new()
	rift_req.text = "%sLv%d" % ["\u2713" if rift_met else "\u2717", req_rift]
	rift_req.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rift_req.add_theme_font_override("font", Styler.QUADRAT_FONT)
	rift_req.add_theme_font_size_override("font_size", 12)
	rift_req.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100) if rift_met else Color.from_rgba8(220, 80, 80))
	req_row.add_child(rift_req)

	var acct_req = Label.new()
	acct_req.text = "%sAcct%d" % ["\u2713" if account_met else "\u2717", req_account]
	acct_req.mouse_filter = Control.MOUSE_FILTER_IGNORE
	acct_req.add_theme_font_override("font", Styler.QUADRAT_FONT)
	acct_req.add_theme_font_size_override("font_size", 12)
	acct_req.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100) if account_met else Color.from_rgba8(220, 80, 80))
	req_row.add_child(acct_req)

	# Stats
	var enc_count = int(cfg.get("encounter_count", 0))
	var total_steps = int(cfg.get("total_steps", 0))
	var stats_lbl = Label.new()
	stats_lbl.text = "%d enc · %d steps" % [enc_count, total_steps]
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(stats_lbl)

	# Gear score
	var gs = cfg.get("gear_score_range", "")
	if not gs.is_empty():
		var gs_lbl = Label.new()
		gs_lbl.text = "GS: %s" % gs
		gs_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gs_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		gs_lbl.add_theme_font_size_override("font_size", 11)
		gs_lbl.add_theme_color_override("font_color", Styler.COLOR_GOLD)
		vbox.add_child(gs_lbl)

	# Right: rift banner art (16:9 ratio)
	var rift_tex = ItemDB.get_rift_icon(location_id)
	if rift_tex:
		var art_width = 125
		var art_height = int(art_width * 9.0 / 16.0)
		var art_clip = Control.new()
		art_clip.custom_minimum_size = Vector2(art_width, art_height)
		art_clip.clip_contents = true
		art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_clip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(art_clip)

		var art = TextureRect.new()
		art.texture = rift_tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate.a = 0.7 if not all_met else 1.0
		art_clip.add_child(art)

	return panel


# ── Gathering Content (preserved) ──────────────────────────────────────────────

func _build_gathering_content(data: Dictionary) -> void:
	var loot_items: Array = data.get("loot_table", [])
	var req_skill: int = int(data.get("req_skill", 0))
	var prof_lvl: int = int(data.get("level", 1))
	var activity_name: String = data.get("activity_name", "")
	var loot_counts: Dictionary = data.get("loot_counts", {})

	if req_skill > prof_lvl:
		var locked_lbl = Label.new()
		locked_lbl.text = "Requires Level %d" % req_skill
		Styler.style_parchment_label(locked_lbl, Color.from_rgba8(200, 80, 80))
		_scroll_content.add_child(locked_lbl)
		return

	if not activity_name.is_empty():
		var act_lbl = Label.new()
		act_lbl.text = activity_name
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		act_lbl.add_theme_font_size_override("font_size", 18)
		act_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		act_lbl.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)
		_scroll_content.add_child(act_lbl)

	var columns = HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 8)
	_scroll_content.add_child(columns)

	# Left — Activity Details frame
	var left_panel = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var left_sb = StyleBoxFlat.new()
	left_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	left_sb.border_color = Color(0.0, 0.0, 0.0, 0.15)
	left_sb.set_border_width_all(1)
	left_sb.set_corner_radius_all(5)
	left_sb.content_margin_left = 8
	left_sb.content_margin_right = 8
	left_sb.content_margin_top = 6
	left_sb.content_margin_bottom = 6
	left_panel.add_theme_stylebox_override("panel", left_sb)
	columns.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 4)
	left_panel.add_child(left_vbox)

	var details_header = Label.new()
	details_header.text = "Activity Details"
	Styler.style_parchment_label(details_header, Styler.COLOR_SECTION_HDR)
	left_vbox.add_child(details_header)

	var steps_lbl = Label.new()
	steps_lbl.text = "Steps: %d" % int(data.get("activity_steps", 0))
	Styler.style_parchment_label(steps_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(steps_lbl)

	var cycles_lbl = Label.new()
	cycles_lbl.text = "Actions: %d" % int(data.get("activity_cycles", 0))
	Styler.style_parchment_label(cycles_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(cycles_lbl)

	var spc_lbl = Label.new()
	var eff_steps = int(data.get("base_steps", 0))
	var orig_steps = int(data.get("base_steps_original", eff_steps))
	if orig_steps > eff_steps and orig_steps > 0:
		var pct = int(round((1.0 - float(eff_steps) / float(orig_steps)) * 100.0))
		spc_lbl.text = "Steps per action: %d  [-%d%% from stats, base %d]" % [eff_steps, pct, orig_steps]
	else:
		spc_lbl.text = "Steps per action: %d" % eff_steps
	Styler.style_parchment_label(spc_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(spc_lbl)

	var overall_header = Label.new()
	overall_header.text = "Overall"
	Styler.style_parchment_label(overall_header, Styler.COLOR_SECTION_HDR)
	left_vbox.add_child(overall_header)

	var total_actions_lbl = Label.new()
	total_actions_lbl.text = "Total Actions: %d" % int(data.get("total_profession_actions", 0))
	Styler.style_parchment_label(total_actions_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(total_actions_lbl)

	var total_steps_lbl = Label.new()
	total_steps_lbl.text = "Total Steps: %d" % int(data.get("total_profession_steps", 0))
	Styler.style_parchment_label(total_steps_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(total_steps_lbl)

	# Right — Loot frame
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var right_sb = StyleBoxFlat.new()
	right_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	right_sb.border_color = Color(0.0, 0.0, 0.0, 0.15)
	right_sb.set_border_width_all(1)
	right_sb.set_corner_radius_all(5)
	right_sb.content_margin_left = 8
	right_sb.content_margin_right = 8
	right_sb.content_margin_top = 6
	right_sb.content_margin_bottom = 6
	right_panel.add_theme_stylebox_override("panel", right_sb)
	columns.add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 4)
	right_panel.add_child(right_vbox)

	var loot_header = Label.new()
	loot_header.text = "Loot"
	Styler.style_parchment_label(loot_header, Styler.COLOR_SECTION_HDR)
	right_vbox.add_child(loot_header)

	if loot_items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No loot available."
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		right_vbox.add_child(empty_lbl)
		return

	for item in loot_items:
		var row = _build_loot_row(item, loot_counts)
		right_vbox.add_child(row)


func _build_loot_row(herb: Dictionary, loot_counts: Dictionary = {}) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.15)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_tex = ItemDB.get_item_icon(herb.get("icon", ""))
	if icon_tex:
		icon.texture = icon_tex
	hbox.add_child(icon)

	var quality: int = int(herb.get("quality", 0))
	var quality_color = _quality_color(quality)
	var name_lbl = Label.new()
	name_lbl.text = str(herb.get("name", "")).replace("_", " ").capitalize()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", quality_color)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(name_lbl)

	var herb_uid: String = str(herb.get("uid", ""))
	var times_looted: int = int(loot_counts.get(herb_uid, 0))
	var count_lbl = Label.new()
	count_lbl.text = "x%d" % times_looted
	count_lbl.add_theme_font_size_override("font_size", 15)
	count_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	count_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(count_lbl)

	var pct_lbl = Label.new()
	pct_lbl.text = "%.2f%%" % float(herb.get("drop_pct", 0))
	pct_lbl.add_theme_font_size_override("font_size", 15)
	pct_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	pct_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(pct_lbl)

	return panel


# ── Craft Actions ──────────────────────────────────────────────────────────────

func _on_craft_pressed(recipe_id: String, recipe_name: String, target_qty: int = 1) -> void:
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	var act = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	var qty: int = maxi(1, target_qty)
	var qty_name: String = ("%dx %s" % [qty, recipe_name]) if qty > 1 else recipe_name
	var text: String
	if Account.activity:
		var current_name: String = GameTextEn.activities_texts.get(Account.activity, "Activity")
		text = "Stop %s and Craft %s?" % [current_name, qty_name]
	else:
		text = "Craft %s?" % qty_name
	_confirm_dialog = CONFIRMATION_DIALOG.instantiate()
	_confirm_dialog.setup(text)
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		SignalManager.signal_StartCraftActivity.emit(act, Account.location, recipe_id, qty)
	)
	_confirm_dialog.tree_exited.connect(func(): _confirm_dialog = null, CONNECT_ONE_SHOT)


func _on_stop_craft() -> void:
	var act = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	SignalManager.signal_UserActivity.emit(act, Account.activity_site, "stop")


# ── Craft Banner Progress ─────────────────────────────────────────────────────

func _update_craft_banner() -> void:
	var current_act = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	var is_crafting = Account.activity == current_act and not Account.crafting_recipe_id.is_empty()
	_craft_banner.visible = is_crafting

	if not is_crafting:
		return

	var steps: int = Account.crafting_steps
	if _last_crafting_steps_max > 0:
		_craft_banner_bar.max_value = _last_crafting_steps_max
		_craft_banner_bar.value = steps
		_craft_banner_steps_lbl.text = "Steps: %d / %d" % [steps, _last_crafting_steps_max]
	else:
		_craft_banner_steps_lbl.text = "Steps: %d" % steps

	if _last_crafting_target_qty > 1:
		_craft_banner_batch_lbl.text = "Batch: %d / %d" % [_last_crafting_batch_done, _last_crafting_target_qty]
	else:
		_craft_banner_batch_lbl.text = ""


# ── Helpers ────────────────────────────────────────────────────────────────────

func _get_recipe_tier(req_level: int) -> int:
	for i in range(TIER_LEVEL_BREAKS.size() - 1, -1, -1):
		if req_level >= TIER_LEVEL_BREAKS[i]:
			return i
	return 0


func _compute_max_craft_qty(ingredients: Array) -> int:
	if ingredients.is_empty():
		return 0
	var result: int = 999999
	for ing in ingredients:
		var have: int = int(ing.get("qty_have", 0))
		var need: int = int(ing.get("qty_needed", 1))
		if need <= 0:
			continue
		@warning_ignore("integer_division")
		result = mini(result, have / need)
	if result < 0:
		result = 0
	return result


func _quality_color(quality: int) -> Color:
	match quality:
		0: return Styler.COLOR_TEXT_DARK
		1: return Color.from_rgba8(30, 180, 30)
		2: return Color.from_rgba8(50, 100, 220)
		3: return Color.from_rgba8(160, 50, 200)
		4: return Color.from_rgba8(220, 150, 30)
		5: return Color.from_rgba8(230, 70, 70)
		_: return Styler.COLOR_TEXT_DARK
