class_name ActivityProgressView extends Control

var _card_box_ref: Callable = Callable() # call to get StyleBox for panel
var _item_name_resolver: Callable = Callable() # (id:String)->String

@onready var _panel: PanelContainer = $PanelContainer
@onready var _title: Label = $PanelContainer/VBoxContainer/Title
@onready var close_button: Button = $PanelContainer/VBoxContainer/Close
@onready var _grid: GridContainer = $PanelContainer/VBoxContainer/GridContainer
@onready var _steps_label: Label = $PanelContainer/VBoxContainer/GridContainer/stepsLabel
@onready var _xp_label: Label = $PanelContainer/VBoxContainer/GridContainer/xpLabel
@onready var loot_title: Label = $PanelContainer/VBoxContainer/GridContainer/LootTitle
@onready var _xp_bar: ProgressBar = $PanelContainer/VBoxContainer/GridContainer/ProgressBar
@onready var _loot_list: VBoxContainer = $PanelContainer/VBoxContainer/GridContainer/LootList
@onready var root: VBoxContainer = $PanelContainer/VBoxContainer

var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)

var bg_color = Color.from_rgba8(28, 30, 40, 255)
var border_color = Color.from_rgba8(255, 255, 255, 30)


func _ready() -> void:
	_build_ui()
	
	Styler.style_panel(_panel, COL_PANEL_BG, COL_PANEL_BR)
	Styler.style_title(_title)
	Styler.style_title(loot_title)
	Styler.style_button(close_button, Color.from_rgba8(255,200,66))
	Styler.wire_button_anim(close_button)
	Styler.style_name_label(_steps_label, Color.from_rgba8(255, 215, 128))
	Styler.style_name_label(_xp_label, Color.from_rgba8(255, 215, 128))
	Styler.style_bar(_xp_bar, bg_color, border_color)


func set_card_box(card_box_callable: Callable) -> void:
	_card_box_ref = card_box_callable
	if is_instance_valid(_panel) and _card_box_ref.is_valid():
		var sb = _card_box_ref.call()
		if typeof(sb) == TYPE_OBJECT:
			_panel.add_theme_stylebox_override("panel", sb)


func set_item_name_resolver(resolver: Callable) -> void:
	_item_name_resolver = resolver
	
# ------------------ Public API ------------------
func apply_activity_progress(d: Dictionary) -> void:
	var activities_completed: int = int(d.get("activities_completed", 0))
	var steps_in: int = int(d.get("steps_in", 0))
	var xp_gained: int = int(d.get("xp_gained", 0))
	var lvl: int = int(d.get("level", 1))
	var lvl_prev: int = int(d.get("level_before", lvl))
	var lvls_gained: int = int(d.get("levels_gained", 0))
	var xp_into: int = int(d.get("xp_into_level", 0))
	var xp_to_next = d.get("xp_to_next", null)
	var req_skill: int = int(d.get("req_skill", 1))
	var loot_summary = d.get("loot", d.get("loot_summary", {}))
	if typeof(loot_summary) == TYPE_DICTIONARY and loot_summary.has("summary"):
		loot_summary = loot_summary["summary"]
		
	# Title / header
	var title = "Activity Progress"
	if d.has("locked") and d["locked"]:
		title += " — Locked: requires %d" % req_skill
	elif lvls_gained > 0:
		title += " — Level Up x%d!" % lvls_gained
	_title.text = title
	
	# Steps progress
	_steps_label.text = "Progress: (+%d steps, %d  activities finishes)" % [steps_in, activities_completed]
	
	# XP progress (if xp_to_next is null → max level)
	_xp_bar.max_value = max(1, int(xp_to_next))
	_xp_bar.value = clamp(xp_into, 0, _xp_bar.max_value)
	_xp_label.text = "Activity Level %d (%d → %d) XP: +%d" % [lvl, lvl_prev, lvl, xp_gained]
	
	loot_title.text = "Loot:"

	# Loot
	_render_loot(loot_summary)
		
# ------------------ UI building ------------------
func _build_ui() -> void:
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_panel.name = "Card"
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Style hook
	if _card_box_ref.is_valid():
		var sb = _card_box_ref.call()
		if typeof(sb) == TYPE_OBJECT:
			_panel.add_theme_stylebox_override("panel", sb)

	root.name = "Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
#
	# Header
	_title.text = "Activity Progress"
	_title.add_theme_font_size_override("font_size", 18)
#
	# Stats Grid
	_grid.columns = 1
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 6)
#
	# XP row
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.min_value = 0; _xp_bar.max_value = 100; _xp_bar.value = 0
	_xp_bar.tooltip_text = "XP into current level"
	_grid.add_child(_mk_spacer())
#
	# Loot section title
	loot_title.text = "Loot"
	loot_title.add_theme_font_size_override("font_size", 16)
#
	# Loot scroll list
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
#
	_loot_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_loot_list)
	
func _mk_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l

func _mk_spacer() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(1, 1)
	return c
	
# ------------------ Loot rendering ------------------
func _render_loot(summary) -> void:
	for c in _loot_list.get_children():
		c.queue_free()

	if summary == null:
		return
		
	for id in summary[0].keys():
		var qty = int(summary[0][id])
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		var name = id
		if _item_name_resolver.is_valid():
			name = str(_item_name_resolver.call(id))

		var left := Label.new()
		left.text = name
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var right := Label.new()
		right.text = "x%d" % qty
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		row.add_child(left)
		row.add_child(right)
		_loot_list.add_child(row)


func _on_close_pressed() -> void:
	queue_free()
