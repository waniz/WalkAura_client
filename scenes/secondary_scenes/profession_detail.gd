extends Control

const ACTIVITY_ALCHEMY = 2
const ACTIVITY_ENCHANTING = 9
const CONFIRMATION_DIALOG = preload("res://scenes/secondary_scenes/confirmation_dialog.tscn")

var _profession_name: String = ""
var _confirm_dialog: Control = null
var _loading_label: Label
var _xp_bar: ProgressBar
var _xp_pct_label: Label
var _details_xp_label: Label
var _details_xp_next_label: Label
var _details_total_steps_label: Label
var _level_label: Label
var _scroll_content: VBoxContainer
var _craft_progress_container: VBoxContainer
var _craft_progress_bar: ProgressBar
var _craft_progress_label: Label
var _craft_header_label: Label
var _craft_stop_btn: Button
var _last_crafting_steps_max: int = 0


func set_profession(prof_name: String) -> void:
	_profession_name = prof_name


func _ready() -> void:
	_build_ui()
	SignalManager.signal_ProfessionInfoReceived.connect(_on_profession_info)
	AccountManager.signal_ActivityProgressReceived.connect(_on_activity_progress)
	AccountManager.signal_AccountDataReceived.connect(_on_account_data)
	# Request data from server
	SignalManager.signal_RequestProfessionInfo.emit(_profession_name)


func _build_ui() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	# Main panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_parchment_style(panel)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title = Label.new()
	title.text = _profession_name.to_upper()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	Styler.style_button_small(close_btn, Color.from_rgba8(180, 60, 60))
	close_btn.custom_minimum_size = Vector2(44, 44)
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	var sep = HSeparator.new()
	root_vbox.add_child(sep)

	# Level + XP on the left, Overall Details frame on the right
	var top_row = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(top_row)

	# Left column: level label + xp bar stacked
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.0
	left_col.add_theme_constant_override("separation", 6)
	top_row.add_child(left_col)

	_level_label = Label.new()
	_level_label.text = "Level: ..."
	Styler.style_parchment_label(_level_label, Styler.COLOR_GOLD, 18)
	left_col.add_child(_level_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 24)
	_xp_bar.show_percentage = false
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.0, 0.0, 0.0, 0.2)
	pb_bg.set_corner_radius_all(8)
	_xp_bar.add_theme_stylebox_override("background", pb_bg)
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = Styler.COL_PRIMARY
	pb_fill.shadow_color = Color(0, 0, 0, 0.25)
	pb_fill.shadow_size = 2
	pb_fill.set_corner_radius_all(8)
	_xp_bar.add_theme_stylebox_override("fill", pb_fill)
	left_col.add_child(_xp_bar)

	_xp_pct_label = Label.new()
	_xp_pct_label.text = "0%"
	_xp_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_pct_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_pct_label.add_theme_font_size_override("font_size", 12)
	_xp_pct_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_xp_pct_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	_xp_pct_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_xp_bar.add_child(_xp_pct_label)

	# Right column: Overall Details frame (aligned with top of Level label)
	var details_panel = PanelContainer.new()
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	details_panel.size_flags_stretch_ratio = 2.0
	var dp_sb = StyleBoxFlat.new()
	dp_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	dp_sb.border_color = Color(0.0, 0.0, 0.0, 0.15)
	dp_sb.set_border_width_all(1)
	dp_sb.set_corner_radius_all(5)
	dp_sb.content_margin_left = 8
	dp_sb.content_margin_right = 8
	dp_sb.content_margin_top = 4
	dp_sb.content_margin_bottom = 4
	details_panel.add_theme_stylebox_override("panel", dp_sb)
	top_row.add_child(details_panel)

	var details_vbox = VBoxContainer.new()
	details_vbox.add_theme_constant_override("separation", 2)
	details_panel.add_child(details_vbox)

	_details_xp_label = Label.new()
	_details_xp_label.text = "XP: ..."
	Styler.style_parchment_label(_details_xp_label, Styler.COLOR_TEXT_DARK)
	details_vbox.add_child(_details_xp_label)

	_details_xp_next_label = Label.new()
	_details_xp_next_label.text = "XP to next: ..."
	Styler.style_parchment_label(_details_xp_next_label, Styler.COLOR_TEXT_DARK)
	details_vbox.add_child(_details_xp_next_label)

	_details_total_steps_label = Label.new()
	_details_total_steps_label.text = "Total steps: ..."
	Styler.style_parchment_label(_details_total_steps_label, Styler.COLOR_TEXT_DARK)
	details_vbox.add_child(_details_total_steps_label)

	# Crafting progress section (hidden by default)
	_craft_progress_container = VBoxContainer.new()
	_craft_progress_container.visible = false
	_craft_progress_container.add_theme_constant_override("separation", 6)
	root_vbox.add_child(_craft_progress_container)

	_craft_header_label = Label.new()
	_craft_header_label.text = "Crafting in Progress"
	Styler.style_parchment_label(_craft_header_label, Styler.COLOR_GOLD)
	_craft_progress_container.add_child(_craft_header_label)

	_craft_progress_bar = ProgressBar.new()
	_craft_progress_bar.custom_minimum_size = Vector2(0, 20)
	_craft_progress_bar.show_percentage = false
	var cpb_bg = StyleBoxFlat.new()
	cpb_bg.bg_color = Color(0.0, 0.0, 0.0, 0.2)
	cpb_bg.set_corner_radius_all(6)
	_craft_progress_bar.add_theme_stylebox_override("background", cpb_bg)
	var cpb_fill = StyleBoxFlat.new()
	cpb_fill.bg_color = Color.from_rgba8(80, 200, 120)
	cpb_fill.set_corner_radius_all(6)
	_craft_progress_bar.add_theme_stylebox_override("fill", cpb_fill)
	_craft_progress_container.add_child(_craft_progress_bar)

	_craft_progress_label = Label.new()
	_craft_progress_label.text = ""
	Styler.style_parchment_label(_craft_progress_label, Styler.COLOR_TEXT_DARK)
	_craft_progress_container.add_child(_craft_progress_label)

	_craft_stop_btn = Button.new()
	_craft_stop_btn.text = "STOP CRAFTING"
	Styler.style_button(_craft_stop_btn, Color.from_rgba8(180, 60, 60))
	_craft_stop_btn.pressed.connect(_on_stop_craft)
	_craft_progress_container.add_child(_craft_stop_btn)

	# Scrollable content
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_scroll_content = VBoxContainer.new()
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_scroll_content)

	# Loading state
	_loading_label = Label.new()
	_loading_label.text = "Loading..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(_loading_label, Styler.COLOR_TEXT_DARK)
	_scroll_content.add_child(_loading_label)

	_update_craft_progress()


func _on_profession_info(data: Dictionary) -> void:
	if data.get("profession", "") != _profession_name:
		return

	if is_instance_valid(_loading_label):
		_loading_label.visible = false

	var lvl: int = int(data.get("level", 1))
	var xp: int = int(data.get("xp", 0))
	var xp_to_next = data.get("xp_to_next", null)

	_level_label.text = "Level %d" % lvl

	if xp_to_next != null and int(xp_to_next) > 0:
		_xp_bar.max_value = int(xp_to_next)
		_xp_bar.value = xp
		_details_xp_label.text = "XP: %d" % xp
		_details_xp_next_label.text = "XP to next: %d" % int(xp_to_next)
		var pct = int(round(float(xp) / float(int(xp_to_next)) * 100.0))
		_xp_pct_label.text = str(pct) + "%"
	else:
		_xp_bar.value = _xp_bar.max_value
		_details_xp_label.text = "XP: MAX"
		_details_xp_next_label.text = "Max level reached"
		_xp_pct_label.text = "100%"

	var total_steps: int = int(data.get("total_profession_steps", 0))
	_details_total_steps_label.text = "Total steps: %d" % total_steps

	# Clear previous content (except loading label)
	for child in _scroll_content.get_children():
		child.queue_free()

	if _profession_name == "herbalism":
		_build_herbalism_content(data)
	elif _profession_name == "alchemy":
		_build_alchemy_content(data)
	elif _profession_name == "enchanting":
		_build_enchanting_content(data)


func _build_herbalism_content(data: Dictionary) -> void:
	var herbs: Array = data.get("herbs", [])
	var req_skill: int = int(data.get("req_skill", 0))
	var prof_lvl: int = int(data.get("level", 1))
	var activity_name: String = data.get("activity_name", "")
	var herb_loot_counts: Dictionary = data.get("herb_loot_counts", {})

	if req_skill > prof_lvl:
		var locked_lbl = Label.new()
		locked_lbl.text = "Requires Herbalism Level %d" % req_skill
		Styler.style_parchment_label(locked_lbl, Color.from_rgba8(200, 80, 80))
		_scroll_content.add_child(locked_lbl)
		return

	# Activity name — bigger, gold, JANDA_FONT
	if not activity_name.is_empty():
		var act_lbl = Label.new()
		act_lbl.text = activity_name
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		act_lbl.add_theme_font_size_override("font_size", 18)
		act_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		act_lbl.add_theme_color_override("font_color", Styler.COLOR_GOLD)
		_scroll_content.add_child(act_lbl)

	# Two-column layout: Activity Details (left) + Loot (right)
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
	Styler.style_parchment_label(details_header, Styler.COLOR_GOLD)
	left_vbox.add_child(details_header)

	var steps_lbl = Label.new()
	steps_lbl.text = "Steps: %d" % int(data.get("activity_steps", 0))
	Styler.style_parchment_label(steps_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(steps_lbl)

	var cycles_lbl = Label.new()
	cycles_lbl.text = "Cycles: %d" % int(data.get("activity_cycles", 0))
	Styler.style_parchment_label(cycles_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(cycles_lbl)

	var spc_lbl = Label.new()
	spc_lbl.text = "Steps/cycle: %d" % int(data.get("base_steps", 0))
	Styler.style_parchment_label(spc_lbl, Styler.COLOR_TEXT_DARK)
	left_vbox.add_child(spc_lbl)

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
	Styler.style_parchment_label(loot_header, Styler.COLOR_GOLD)
	right_vbox.add_child(loot_header)

	if herbs.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No herbs available."
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		right_vbox.add_child(empty_lbl)
		return

	for herb in herbs:
		var row = _build_herb_row(herb, herb_loot_counts)
		right_vbox.add_child(row)


func _build_herb_row(herb: Dictionary, loot_counts: Dictionary = {}) -> PanelContainer:
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

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_tex = ItemDB.get_icon(herb.get("icon", ""))
	if icon_tex:
		icon.texture = icon_tex
	hbox.add_child(icon)

	# Name
	var quality: int = int(herb.get("quality", 0))
	var quality_color = _quality_color(quality)
	var name_lbl = Label.new()
	name_lbl.text = str(herb.get("name", "")).replace("_", " ").capitalize()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", quality_color)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(name_lbl)

	# Times looted
	var herb_uid: String = str(herb.get("uid", ""))
	var times_looted: int = int(loot_counts.get(herb_uid, 0))
	var count_lbl = Label.new()
	count_lbl.text = "x%d" % times_looted
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	count_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(count_lbl)

	# Drop chance (2 decimal places)
	var pct_lbl = Label.new()
	pct_lbl.text = "%.2f%%" % float(herb.get("drop_pct", 0))
	pct_lbl.add_theme_font_size_override("font_size", 12)
	pct_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	pct_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hbox.add_child(pct_lbl)

	return panel


func _build_alchemy_content(data: Dictionary) -> void:
	var recipes: Array = data.get("recipes", [])

	# Update craft header and restore progress max from recipe data if currently crafting
	if Account.activity == ACTIVITY_ALCHEMY and not Account.crafting_recipe_id.is_empty():
		for recipe in recipes:
			if recipe.get("recipe_id", "") == Account.crafting_recipe_id:
				_craft_header_label.text = "Crafting: %s" % recipe.get("name", "Unknown")
				if _last_crafting_steps_max == 0:
					_last_crafting_steps_max = int(recipe.get("base_steps", 0))
					_update_craft_progress()
				break

	var header_lbl = Label.new()
	header_lbl.text = "Recipes"
	Styler.style_parchment_label(header_lbl, Styler.COLOR_GOLD)
	_scroll_content.add_child(header_lbl)

	if recipes.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No recipes available."
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		_scroll_content.add_child(empty_lbl)
		return

	for recipe in recipes:
		var card = _build_recipe_card(recipe)
		_scroll_content.add_child(card)


func _build_enchanting_content(data: Dictionary) -> void:
	var recipes: Array = data.get("recipes", [])

	# Update craft header and restore progress max from recipe data if currently crafting
	if Account.activity == ACTIVITY_ENCHANTING and not Account.crafting_recipe_id.is_empty():
		for recipe in recipes:
			if recipe.get("recipe_id", "") == Account.crafting_recipe_id:
				_craft_header_label.text = "Enchanting: %s" % recipe.get("name", "Unknown")
				if _last_crafting_steps_max == 0:
					_last_crafting_steps_max = int(recipe.get("base_steps", 0))
					_update_craft_progress()
				break

	var header_lbl = Label.new()
	header_lbl.text = "Enchanting Scrolls"
	Styler.style_parchment_label(header_lbl, Styler.COLOR_GOLD)
	_scroll_content.add_child(header_lbl)

	if recipes.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No enchanting recipes available."
		Styler.style_parchment_label(empty_lbl, Styler.COLOR_TEXT_DARK)
		_scroll_content.add_child(empty_lbl)
		return

	for recipe in recipes:
		var card = _build_recipe_card(recipe)
		_scroll_content.add_child(card)


func _build_recipe_card(recipe: Dictionary) -> PanelContainer:
	var unlocked: bool = recipe.get("unlocked", false)
	var can_craft: bool = recipe.get("can_craft", false)

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	if not unlocked:
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.12)
		sb.border_color = Color(0.4, 0.4, 0.4, 0.3)
	elif can_craft:
		sb.bg_color = Color(0.1, 0.3, 0.1, 0.10)
		sb.border_color = Color.from_rgba8(60, 160, 80, 180)
	else:
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
		sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Recipe header: name + output icon + req level
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(header_hbox)

	# Output icon
	var out_icon = TextureRect.new()
	out_icon.custom_minimum_size = Vector2(32, 32)
	out_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	out_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	out_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var out_tex = ItemDB.get_item_icon(recipe.get("output_icon", ""))
	if out_tex:
		out_icon.texture = out_tex
	header_hbox.add_child(out_icon)

	var name_lbl = Label.new()
	name_lbl.text = recipe.get("name", "Unknown")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_color = Styler.COLOR_TEXT_DARK if unlocked else Color(0.5, 0.5, 0.5)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", name_color)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	header_hbox.add_child(name_lbl)

	if not unlocked:
		var lock_lbl = Label.new()
		lock_lbl.text = "Lvl %d" % int(recipe.get("req_level", 0))
		lock_lbl.add_theme_font_size_override("font_size", 12)
		lock_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 80, 80))
		lock_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		header_hbox.add_child(lock_lbl)

	# Ingredients row
	var ing_hbox = HBoxContainer.new()
	ing_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(ing_hbox)

	var ing_label = Label.new()
	ing_label.text = "Needs:"
	ing_label.add_theme_font_size_override("font_size", 11)
	ing_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	ing_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	ing_hbox.add_child(ing_label)

	var ingredients: Array = recipe.get("ingredients", [])
	for ing in ingredients:
		var ing_item = HBoxContainer.new()
		ing_item.add_theme_constant_override("separation", 2)
		ing_hbox.add_child(ing_item)

		var ing_icon = TextureRect.new()
		ing_icon.custom_minimum_size = Vector2(20, 20)
		ing_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ing_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ing_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ing_tex = ItemDB.get_item_icon(ing.get("icon", ""))
		if ing_tex:
			ing_icon.texture = ing_tex
		ing_item.add_child(ing_icon)

		var ing_name_lbl = Label.new()
		ing_name_lbl.text = str(ing.get("name", "")).replace("_", " ").capitalize()
		ing_name_lbl.add_theme_font_size_override("font_size", 11)
		ing_name_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		ing_name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		ing_item.add_child(ing_name_lbl)

		var qty_have: int = int(ing.get("qty_have", 0))
		var qty_need: int = int(ing.get("qty_needed", 0))
		var qty_color = Color.from_rgba8(60, 160, 80) if qty_have >= qty_need else Color.from_rgba8(200, 80, 80)
		var qty_lbl = Label.new()
		qty_lbl.text = "%d/%d" % [qty_have, qty_need]
		qty_lbl.add_theme_font_size_override("font_size", 11)
		qty_lbl.add_theme_color_override("font_color", qty_color)
		qty_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
		ing_item.add_child(qty_lbl)

	# Output + steps info
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(info_hbox)

	var out_lbl = Label.new()
	out_lbl.text = "Makes: %dx %s" % [int(recipe.get("output_qty", 1)), recipe.get("output_name", "?")]
	out_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	out_lbl.add_theme_font_size_override("font_size", 11)
	out_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	out_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	info_hbox.add_child(out_lbl)

	var steps_lbl = Label.new()
	steps_lbl.text = "%d steps  %d XP" % [int(recipe.get("base_steps", 0)), int(recipe.get("base_xp", 0))]
	steps_lbl.add_theme_font_size_override("font_size", 11)
	steps_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	steps_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	info_hbox.add_child(steps_lbl)

	# Craft button (for crafting professions: alchemy, enchanting)
	if _profession_name in ["alchemy", "enchanting"]:
		var current_craft_activity = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
		var craft_btn = Button.new()
		if not unlocked:
			craft_btn.text = "LOCKED"
			craft_btn.disabled = true
			Styler.style_button_small(craft_btn, Color.from_rgba8(160, 155, 150))
		elif not can_craft:
			craft_btn.text = "MISSING INGREDIENTS"
			craft_btn.disabled = true
			Styler.style_button_small(craft_btn, Color.from_rgba8(200, 160, 100))
		elif Account.activity == current_craft_activity:
			craft_btn.text = "BUSY"
			craft_btn.disabled = true
			Styler.style_button_small(craft_btn, Color.from_rgba8(180, 170, 160))
		else:
			craft_btn.text = "CRAFT"
			Styler.style_button_small(craft_btn, Color.from_rgba8(60, 130, 70))
			var rid: String = recipe.get("recipe_id", "")
			var rname: String = recipe.get("name", "Unknown")
			craft_btn.pressed.connect(func(): _on_craft_pressed(rid, rname))
		vbox.add_child(craft_btn)

	return panel


func _on_craft_pressed(recipe_id: String, recipe_name: String) -> void:
	if _confirm_dialog and is_instance_valid(_confirm_dialog):
		return
	var act = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	var text: String
	if Account.activity:
		var current_name: String = GameTextEn.activities_texts.get(Account.activity, "Activity")
		text = "Stop %s and Craft %s?" % [current_name, recipe_name]
	else:
		text = "Craft %s?" % recipe_name
	_confirm_dialog = CONFIRMATION_DIALOG.instantiate()
	_confirm_dialog.setup(text)
	add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(func():
		SignalManager.signal_StartCraftActivity.emit(act, Account.location, recipe_id)
	)
	_confirm_dialog.tree_exited.connect(func(): _confirm_dialog = null, CONNECT_ONE_SHOT)


func _on_stop_craft() -> void:
	var act = ACTIVITY_ENCHANTING if _profession_name == "enchanting" else ACTIVITY_ALCHEMY
	SignalManager.signal_UserActivity.emit(act, Account.activity_site, "stop")


func _on_activity_progress(data: Dictionary) -> void:
	# Extract crafting_steps_max from progress data for progress bar
	var raw = data.get("data", data)
	var d: Dictionary = raw.get("data", raw)
	if d.has("crafting_steps_max"):
		_last_crafting_steps_max = int(d["crafting_steps_max"])
	_update_craft_progress()
	# Refresh recipe data to update ingredient counts
	var craft_active = (
		(_profession_name == "alchemy" and Account.activity == ACTIVITY_ALCHEMY) or
		(_profession_name == "enchanting" and Account.activity == ACTIVITY_ENCHANTING)
	)
	if craft_active:
		SignalManager.signal_RequestProfessionInfo.emit(_profession_name)


func _on_account_data(_ok) -> void:
	_update_craft_progress()


func _update_craft_progress() -> void:
	var is_crafting = Account.activity in [ACTIVITY_ALCHEMY, ACTIVITY_ENCHANTING] and not Account.crafting_recipe_id.is_empty()
	_craft_progress_container.visible = is_crafting

	if not is_crafting:
		return

	var steps: int = Account.crafting_steps
	if _last_crafting_steps_max > 0:
		_craft_progress_bar.max_value = _last_crafting_steps_max
		_craft_progress_bar.value = steps
		_craft_progress_label.text = "Steps: %d / %d" % [steps, _last_crafting_steps_max]
	else:
		_craft_progress_label.text = "Steps: %d" % steps


func _quality_color(quality: int) -> Color:
	match quality:
		0: return Styler.COLOR_TEXT_DARK                   # Common
		1: return Color.from_rgba8(30, 180, 30)            # Uncommon
		2: return Color.from_rgba8(50, 100, 220)           # Rare
		3: return Color.from_rgba8(160, 50, 200)           # Epic
		4: return Color.from_rgba8(220, 150, 30)           # Legendary
		5: return Color.from_rgba8(230, 70, 70)            # Mythic
		_: return Styler.COLOR_TEXT_DARK
