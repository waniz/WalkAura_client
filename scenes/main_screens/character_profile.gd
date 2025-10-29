extends Control

@onready var character_hud: CharacterHUD = $CharacterHUD
@onready var character_stats: PanelContainer = $TabContainer/CharacterStats

@onready var step_card: PanelContainer = $TabContainer/CharacterStats/Margin/VBox/StepCard
@onready var steps_grid: GridContainer = $TabContainer/CharacterStats/Margin/VBox/StepCard/StepsGrid
@onready var primary_card: PanelContainer = $TabContainer/CharacterStats/Margin/VBox/PrimaryCard
@onready var primary_grid: GridContainer = $TabContainer/CharacterStats/Margin/VBox/PrimaryCard/PrimaryGrid
@onready var off_box: HBoxContainer = $TabContainer/CharacterStats/Margin/VBox/OFFBox
@onready var def_box: HBoxContainer = $TabContainer/CharacterStats/Margin/VBox/DEFBox
@onready var off_card: PanelContainer = $TabContainer/CharacterStats/Margin/VBox/OFFBox/OffCard
@onready var off_grid: GridContainer = $TabContainer/CharacterStats/Margin/VBox/OFFBox/OffCard/OffGrid
@onready var def_card: PanelContainer = $TabContainer/CharacterStats/Margin/VBox/DEFBox/DefCard
@onready var deff_grid: GridContainer = $TabContainer/CharacterStats/Margin/VBox/DEFBox/DefCard/DeffGrid
@onready var tab_container: TabContainer = $TabContainer

@onready var professions_card: PanelContainer = $TabContainer/ProfessionsStats/Margin/VBox/ProfessionsCard
@onready var professions_grid: GridContainer = $TabContainer/ProfessionsStats/Margin/VBox/ProfessionsCard/ProfessionsGrid

const ACTIVITY_PROGRESS_SCENE = preload("uid://bjvtquos2r8cj")
var overlay = null

# Colors
var COL_PRIMARY  = Color.from_rgba8(255, 200, 66)
var COL_OFFENSE  = Color.from_rgba8(255, 120, 90)
var COL_DEFENSE  = Color.from_rgba8(64, 180, 255)
var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)

const STEP_KEYS = [
	{"k":"total_steps", "n":"Total Steps:"},
	{"k":"buffer_steps", "n":"Buffer Steps:"},
]

const PRIMARY_KEYS = [
	{"k":"str", "n":"STR"},
	{"k":"agi", "n":"AGI"},
	{"k":"vit", "n":"VIT"},
	{"k":"int_stat", "n":"INT"},
	{"k":"spi", "n":"SPI"},
	{"k":"luk", "n":"LUK"},	
]

const OFFENSE_KEYS = [
	{"k":"atk", "n":"ATK"},
	{"k":"crit_chance","n":"Crit %"},
	{"k":"m_atk","n":"M.ATK"},
	{"k":"crit_damage","n":"Crit Dmg %"},
	{"k":"hit_rating","n":"Hit"},
	{"k":"armor_pen","n":"Armor Pen"},	
	{"k":"haste","n":"Haste"},	
	{"k":"magic_pen","n":"Magic Pen"},
]

const DEFENSE_KEYS = [
	{"k":"p_def","n":"P.DEF"},
	{"k":"block_chance","n":"Block"},
	{"k":"m_def","n":"M.DEF"},	
	{"k":"evasion","n":"Evasion"},
	{"k":"dmg_reduction","n":"D.Reduction"},
]

const PROFESSIONS_KEYS = [
	{"k":"herbalism_lvl","n":"Herbalism"},
	{"k":"mining_lvl","n":"Mining"},
	{"k":"woodcutting_lvl","n":"Woodcutting"},	
	{"k":"fishing_lvl","n":"Fishing"},
	{"k":"hunting_lvl","n":"Hunting"},
	{"k":"blacksmithing_lvl","n":"Blacksmithing"},
	{"k":"tailoring_lvl","n":"Tailoring"},
	{"k":"jewelcrafting_lvl","n":"Jewelcrafting"},
	{"k":"alchemy_lvl","n":"Alchemy"},
	{"k":"cooking_lvl","n":"Cooking"},
	{"k":"enchanting_lvl","n":"Enchanting"},
]


func _ready() -> void:
	AccountManager.signal_AccountDataReceived.connect(_update_character_data)
	AccountManager.signal_ActivityProgressReceived.connect(_show_progress_hud)
		
	Styler.style_panel(character_stats, COL_PANEL_BG, COL_PANEL_BR)
	
	_style_section_card(step_card, "Steps Stats", COL_PRIMARY)
	_style_section_card(primary_card, "Primary", COL_PRIMARY)
	_style_section_card(off_card, "Offense", COL_OFFENSE)
	_style_section_card(def_card, "Defense", COL_DEFENSE)
	
	_style_section_card(professions_card, "Professions", COL_PRIMARY)
	
	var stats = Account.to_dict()
	set_stats(stats)
	
	for i in tab_container.get_tab_count():
		var n = tab_container.get_tab_control(i).name
		if n == "CharacterStats": tab_container.set_tab_title(i, "Character")
		if n == "ProfessionsStats": tab_container.set_tab_title(i, "Professions")
		if n == "Talents": tab_container.set_tab_title(i, "Passive Talents")
	
func _update_character_data(value):
	var stats = Account.to_dict()
	set_stats(stats)
	
# ------ Handle global update window
func _show_progress_hud(payload):
	tab_container.visible = false

	overlay = ACTIVITY_PROGRESS_SCENE.instantiate()
	add_child(overlay)
	
	overlay.apply_activity_progress(payload["data"]["data"])
	overlay.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)

func _on_child_closed() -> void:
	tab_container.visible = true
	overlay = null
	
func set_stats(d: Dictionary) -> void:
	_clear(steps_grid);
	_clear(primary_grid);
	_clear(off_grid);
	_clear(deff_grid)
	_clear(professions_grid)
	
	for entry in STEP_KEYS:
		var val = d.get(entry.k, 0)
		if entry.k == "total_steps":
			var card = _make_steps_card(entry.n, _fmt(val), COL_PRIMARY)
			steps_grid.add_child(card)
		elif entry.k == "buffer_steps":
			var card = _make_steps_card(entry.n, _fmt(val), COL_PRIMARY)
			steps_grid.add_child(card)

	# Primary cards (big numbers)
	for entry in PRIMARY_KEYS:
		var val = d.get(entry.k, 0)
		var card = _make_mini_card(entry.n, _fmt(val), COL_PRIMARY)
		primary_grid.add_child(card)

	# Offense/Defense rows (compact)
	for entry in OFFENSE_KEYS:
		off_grid.add_child(_make_row(entry.n, _fmt(d.get(entry.k, 0)), COL_OFFENSE))
	for entry in DEFENSE_KEYS:
		deff_grid.add_child(_make_row(entry.n, _fmt(d.get(entry.k, 0)), COL_DEFENSE))
		
	_equalize_off_def_size(380.0)  # tweak width (e.g., 360–420)
	
	# Profession grid
	for entry in PROFESSIONS_KEYS:
		var val = d.get(entry.k, 0)
		var card = _make_mini_card(entry.n, _fmt(val), COL_PRIMARY)
		professions_grid.add_child(card)

# ---------- UI Builders ----------
func _make_mini_card(name: String, value_in: String, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var v: float = float(value_in)

	var whole = int(floor(v))
	var frac  = clamp(v - float(whole), 0.0, 1.0)       # 0.0 .. 1.0
	var pct   = int(round(frac * 100.0))                # 0 .. 100
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", _card_box())  # reuse your _card_box()
	
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)
	
	# --- first line: name + value ---
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
		
	var n_lbl := Label.new()
	n_lbl.text = name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(whole)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 20)
	v_lbl.add_theme_color_override("font_color", accent)
	hb.add_child(v_lbl)

	# --- second line: fractional progress bar (0..100) ---
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)   # height of the bar
	_style_mini_progress(pb, accent)          # style below
	vb.add_child(pb)

	return panel
	
func _make_steps_card(name: String, value_in: String, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var v: int = int(value_in)
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", _card_box())  # reuse your _card_box()
	
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)
	
	# --- first line: name + value ---
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
		
	var n_lbl := Label.new()
	n_lbl.text = name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(v)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 20)
	v_lbl.add_theme_color_override("font_color", accent)
	hb.add_child(v_lbl)

	return panel

func _make_row(name: String, value: String, accent: Color) -> Control:
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(36, 36)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", accent)
	val_lbl.add_theme_font_size_override("font_size", 20)
	val_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END

	hb.add_child(name_lbl)
	hb.add_child(val_lbl)
	return hb
	
func _style_section_card(card: PanelContainer, title: String, accent: Color) -> void:
	card.add_theme_stylebox_override("panel", _card_box())
	if card.get_child_count() > 0 and card.get_child(0) is GridContainer:
		var grid := card.get_child(0)
		var vb := VBoxContainer.new()
		card.remove_child(grid)
		card.add_child(vb)
		var hdr := Label.new()
		hdr.text = title
		hdr.add_theme_color_override("font_color", accent)
		hdr.add_theme_font_size_override("font_size", 20)
		vb.add_child(hdr)
		vb.add_child(grid)
		
func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
		
func _card_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.from_rgba8(28,30,40,255)
	box.border_color = COL_PANEL_BR
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 16
	box.corner_radius_top_right = 16
	box.corner_radius_bottom_left = 16
	box.corner_radius_bottom_right = 16
	box.shadow_color = Color(0,0,0,0.25)
	box.shadow_size = 4
	box.content_margin_left = 10; box.content_margin_right = 10
	box.content_margin_top = 12;   box.content_margin_bottom = 10
	return box
	
func _style_mini_progress(bar: ProgressBar, accent: Color) -> void:
	# Track/background
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color.from_rgba8(28, 30, 40, 255)
	bg.border_color = Color.from_rgba8(255, 255, 255, 30)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6

	# Fill/foreground
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.shadow_color = Color(0, 0, 0, 0.20)
	fill.shadow_size = 2
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

func _fmt(v) -> String:
	# Format numbers nicely: show integer if whole, else 1–2 decimals; add % for percenty keys
	if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
		var is_whole = is_equal_approx(v, float(int(v)))
		if is_whole:
			return str(int(v))
		else:
			return "%0.2f" % v
	return str(v)

func _equalize_off_def_size(make_wider_px = 300.0) -> void:
	# 1) Make both cards share width equally in the HBox
	off_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	def_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	off_card.size_flags_stretch_ratio = 1.0
	def_card.size_flags_stretch_ratio = 1.0

	# Let the grids expand inside their cards
	off_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	def_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 2) Make them slightly wider (baseline minimum so they don’t look cramped)
	off_card.custom_minimum_size.x = make_wider_px
	def_card.custom_minimum_size.x = make_wider_px
