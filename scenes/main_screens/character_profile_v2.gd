extends Control

@onready var body_panel: PanelContainer = $VBoxContainer/body_panel

@onready var panel_attributes: PanelContainer = $VBoxContainer/body_panel/Attributes
@onready var panel_professions: PanelContainer = $VBoxContainer/body_panel/Professions
@onready var panel_archivements: PanelContainer = $VBoxContainer/body_panel/Archivements
@onready var panel_reputations: PanelContainer = $VBoxContainer/body_panel/Reputations

@onready var primary_card: PanelContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/PrimaryCard
@onready var primary_grid: GridContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/PrimaryCard/PrimaryGrid
@onready var off_box: HBoxContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/OFFBox
@onready var off_card: PanelContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/OFFBox/OffCard
@onready var off_grid: GridContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/OFFBox/OffCard/OffGrid
@onready var def_box: HBoxContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/DEFBox
@onready var def_card: PanelContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/DEFBox/DefCard
@onready var deff_grid: GridContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/DEFBox/DefCard/DeffGrid
@onready var step_card: PanelContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/StepCard
@onready var steps_grid: GridContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox/StepCard/StepsGrid

@onready var professions_card: PanelContainer = $VBoxContainer/body_panel/Professions/Margin/VBox/ProfessionsCard
@onready var professions_grid_level_1: GridContainer = $VBoxContainer/body_panel/Professions/Margin/VBox/ProfessionsCard/HBoxContainer/ProfessionsGrid_Level1
@onready var professions_grid_level_2: GridContainer = $VBoxContainer/body_panel/Professions/Margin/VBox/ProfessionsCard/HBoxContainer/ProfessionsGrid_Level2

@onready var btn_attributes: Button = $VBoxContainer/Buttons_Container/Btn_attributes
@onready var btn_professions: Button = $VBoxContainer/Buttons_Container/Btn_professions
@onready var btn_archivements: Button = $VBoxContainer/Buttons_Container/Btn_archivements
@onready var btn_reputations: Button = $VBoxContainer/Buttons_Container/Btn_reputations

const STEP_KEYS = [
	{"k":"total_steps", "n":"Total Steps:"},
	{"k":"buffer_steps", "n":"Buffer Steps:"},
]

const PRIMARY_KEYS = [
	{"k":"str",      "n":"Strength",   "exp": "str_exp", "bonus": "bonus_str"},
	{"k":"agi",      "n":"Agility",    "exp": "agi_exp", "bonus": "bonus_agi"},
	{"k":"vit",      "n":"Vitality",   "exp": "vit_exp", "bonus": "bonus_vit"},
	{"k":"int_stat", "n":"Intellect   ",  "exp": "int_exp", "bonus": "bonus_int"},
	{"k":"spi",      "n":"Spirit   ",     "exp": "spi_exp", "bonus": "bonus_spi"},
	{"k":"luk",      "n":"Luck       ",       "exp": "luk_exp", "bonus": "bonus_luk"},
]

const OFFENSE_KEYS = [
	{"k":"atk", "n":"Physical ATK"},
	{"k":"crit_chance","n":"Crit Chance"},
	{"k":"m_atk","n":"Magic ATK"},
	{"k":"crit_damage","n":"Crit Damage"},
	{"k":"hit_rating","n":"Hit Rating"},
	{"k":"armor_pen","n":"Armor Penetration"},
	{"k":"haste","n":"Haste Rating"},
	{"k":"magic_pen","n":"Magic Penetration"},
]

const DEFENSE_KEYS = [
	{"k":"p_def","n":"Physical DEF"},
	{"k":"block_chance","n":"Block Chance"},
	{"k":"m_def","n":"Magic DEF"},
	{"k":"evasion","n":"Evasion"},
	{"k":"dmg_reduction","n":"Damage Reduction"},
]

const PROFESSIONS_KEYS1 = [
	{"k":"herbalism_lvl","n":"Herbalism", "exp": "herbalism_xp"},
	{"k":"hunting_lvl","n":"Hunting", "exp": "hunting_xp"},	
	{"k":"mining_lvl","n":"Mining", "exp": "mining_xp"},
	{"k":"woodcutting_lvl","n":"Forester", "exp": "woodcutting_xp"},
	{"k":"fishing_lvl","n":"Fishing", "exp": "fishing_xp"},

	#{"k":"blacksmithing_lvl","n":"Blacksmithing", "exp": "blacksmithing_xp"},
	#{"k":"tailoring_lvl","n":"Tailoring", "exp": "tailoring_xp"},
	#{"k":"jewelcrafting_lvl","n":"Jewelcrafting", "exp": "jewelcrafting_xp"},
	#{"k":"cooking_lvl","n":"Cooking", "exp": "cooking_xp"},
	#{"k":"enchanting_lvl","n":"Enchanting", "exp": "enchanting_xp"},
]
const PROFESSIONS_KEYS2 = [
	{"k":"alchemy_lvl","n":"Alchemy", "exp": "alchemy_xp"},
]

var STATS_TOTAL_TO_LEVEL = {1: 0}
var ACTIVITY_TOTAL_TO_LEVEL = {1: 0}


func _ready() -> void:
	AccountManager.signal_AccountDataReceived.connect(_update_character_data)

	STATS_TOTAL_TO_LEVEL = ServerParams.STATS_PROGRESSION_LEVELS
	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS
	
	Styler.style_panel(body_panel, Styler.COL_PANEL_GRAY, Styler.COL_PANEL_BR)
	Styler.style_panel(panel_attributes, Styler.COL_PANEL_BG, Styler.COL_PANEL_BR)
	Styler.style_panel(panel_professions, Styler.COL_PANEL_BG, Styler.COL_PANEL_BR)
	Styler.style_panel(panel_archivements, Styler.COL_PANEL_BG, Styler.COL_PANEL_BR)
	Styler.style_panel(panel_reputations, Styler.COL_PANEL_BG, Styler.COL_PANEL_BR)
	
	Styler.style_button(btn_attributes, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_professions, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_archivements, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_reputations, Color.from_rgba8(64,180,255))
	
	_style_section_card(step_card,    "Steps Stats", Styler.COL_PRIMARY)
	_style_section_card(primary_card, "Primary", Styler.COL_PRIMARY)
	_style_section_card(off_card,     "Offense", Styler.COL_OFFENSE)
	_style_section_card(def_card,     "Defense", Styler.COL_DEFENSE)
	_style_section_card(professions_card, "Professions", Styler.COL_PRIMARY)
	
	var stats = Account.to_dict()
	set_stats(stats)

func _update_character_data(value):
	var stats = Account.to_dict()
	set_stats(stats)

func set_stats(d: Dictionary) -> void:
	_clear(steps_grid);
	_clear(primary_grid);
	_clear(off_grid);
	_clear(deff_grid)
	_clear(professions_grid_level_1)
	_clear(professions_grid_level_2)
	
	for entry in STEP_KEYS:
		var val = d.get(entry.k, 0)
		if entry.k == "total_steps":
			var card = _make_steps_card_with_icon(entry.n, _fmt(val), Styler.COL_PRIMARY)
			steps_grid.add_child(card)
		elif entry.k == "buffer_steps":
			var card = _make_steps_card_with_icon(entry.n, _fmt(val), Styler.COL_PRIMARY)
			steps_grid.add_child(card)

	# Primary cards (big numbers)
	for entry in PRIMARY_KEYS:
		var lvl = int(d.get(entry.k, 0))
		var exp = int(d.get(entry.exp, 0))
		var bonus = int(d.get(entry.bonus, 0))
		var card = _make_mini_card_primary(entry.n, lvl, exp, bonus, Styler.COL_PRIMARY)
		primary_grid.add_child(card)

	# Offense/Defense rows (compact)
	for entry in OFFENSE_KEYS:
		off_grid.add_child(_make_row(entry.n, _fmt(d.get(entry.k, 0)), Styler.COL_OFFENSE))
	for entry in DEFENSE_KEYS:
		deff_grid.add_child(_make_row(entry.n, _fmt(d.get(entry.k, 0)), Styler.COL_DEFENSE))
		
	_equalize_off_def_size(380.0)  # tweak width (e.g., 360–420)
	
	# Profession grid
	for entry in PROFESSIONS_KEYS1:
		var val = int(d.get(entry.k, 0))
		var activity_exp = int(d.get(entry.exp, 0))
		var card = _make_mini_card(entry.n, val, activity_exp, Styler.COL_PRIMARY)
		professions_grid_level_1.add_child(card)
		
	for entry in PROFESSIONS_KEYS2:
		var val = int(d.get(entry.k, 0))
		var activity_exp = int(d.get(entry.exp, 0))
		var card = _make_mini_card(entry.n, val, activity_exp, Styler.COL_PRIMARY)
		professions_grid_level_2.add_child(card)

# ---------- UI Builders ----------
func _make_mini_card_primary(name: String, lvl: int, exp: int, bonus: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	
	var lvl_current = exp - STATS_TOTAL_TO_LEVEL[str(lvl)]
	var lvl_progress = STATS_TOTAL_TO_LEVEL[str(lvl + 1)] - STATS_TOTAL_TO_LEVEL[str(lvl)]
	
	var whole = int(lvl)
	var frac  = float(lvl_current) / float(lvl_progress)         # 0.0 .. 1.0
	var pct   = int(round(frac * 100.0))   # 0 .. 100
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", Styler.card_box())
	
	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(main_hbox)
	
	# --- icon position ---
	var icon_box := VBoxContainer.new()
	icon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_box.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(icon_box)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_key = {
		"Strength" : "attributes_strength",
		"Agility"  : "attributes_agility",
		"Vitality" : "attributes_vitality",
		"Intellect   ": "attributes_intellect",
		"Spirit   "   : "attributes_spirit",
		"Luck       "     : "attributes_luck",
	}

	icon.texture = ItemDB.ICONS.get(icon_key.get(name))
	icon_box.add_child(icon)
	
	# --- first line: name + value ---
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(vb)
	
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
	v_lbl.text = str(whole) + " + " + str(bonus)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 20)
	v_lbl.add_theme_color_override("font_color", accent)
	hb.add_child(v_lbl)
#
	## --- second line: fractional progress bar (0..100) ---
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)   # height of the bar
	Styler.style_mini_progress(pb, accent)          # style below
	vb.add_child(pb)

	return panel
	
func _make_mini_card(name: String, lvl: int, activity_exp: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var lvl_current = activity_exp - ACTIVITY_TOTAL_TO_LEVEL[str(lvl)]
	var lvl_progress = ACTIVITY_TOTAL_TO_LEVEL[str(lvl + 1)]

	var whole = int(lvl)
	var frac  = float(lvl_current) / float(lvl_progress)
	var pct   = int(round(frac * 100.0))   # 0 .. 100
	
	# --- card container ---
	var panel := PanelContainer.new()
	#panel.custom_minimum_size = Vector2(180, 60)
	panel.add_theme_stylebox_override("panel", Styler.card_box())
	
	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(main_hbox)
	
	# --- icon position ---
	var icon_box := VBoxContainer.new()
	icon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_box.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(icon_box)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(96, 96)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_key = {
		"Herbalism"    : "herbalism",
		"Alchemy"      : "alchemy",
		"Hunting"      : "hunting",
		"Mining"       : "mining",
		"Forester"     : "woodcutting",
		"Fishing"      : "fishing",
	}

	icon.texture = ItemDB.ICONS.get(icon_key.get(name))
	icon_box.add_child(icon)
	
	# --- first line: name + value ---
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(vb)
	
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
	Styler.style_mini_progress(pb, accent)          # style below
	vb.add_child(pb)

	return panel
	
func _make_steps_card(name: String, value_in: String, accent: Color) -> Control:
	var v: int = int(value_in)
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", Styler.card_box())
	
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

func _make_steps_card_with_icon(name: String, value_in: String, accent: Color) -> Control:
	var v: int = int(value_in)
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", Styler.card_box())
	
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)
	
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER	
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	icon.texture = ItemDB.ICONS["steps"]
	hb.add_child(icon)
	
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
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER	
	icon.name = "Icon"
	icon.anchor_left = 0
	icon.anchor_top = 0
	icon.anchor_right = 1
	icon.anchor_bottom = 1
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_key = {
		"Physical DEF": "physical_defence",
		"Magical DEF": "magical_defence",
		"Damage Reduction": "damage_reduction",
		"Block Chance": "block_chance",
		"Evasion": "evasion",
		"Physical ATK": "physical_attack",
		"Crit Chance": "critical_chance",
		"Magic ATK": "magical_attack",
		"Crit Damage": "critical_damage",
		"Hit Rating": "hit_rating",
		"Armor Penetration": "armor_penetration",
		"Haste Rating": "haste",
		"Magic Penetration": "magical_penetration",
		"Magic DEF": "magical_defence",		
	}

	icon.texture = ItemDB.ICONS.get(icon_key.get(name))
	hb.add_child(icon)

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
	card.add_theme_stylebox_override("panel", Styler.card_box())
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


func _on_btn_attributes_pressed() -> void:
	panel_attributes.visible = true
	panel_professions.visible = false
	panel_archivements.visible = false
	panel_reputations.visible = false


func _on_btn_professions_pressed() -> void:
	panel_attributes.visible = false
	panel_professions.visible = true
	panel_archivements.visible = false
	panel_reputations.visible = false


func _on_btn_archivements_pressed() -> void:
	panel_attributes.visible = false
	panel_professions.visible = false
	panel_archivements.visible = true
	panel_reputations.visible = false


func _on_btn_reputations_pressed() -> void:
	panel_attributes.visible = false
	panel_professions.visible = false
	panel_archivements.visible = false
	panel_reputations.visible = true
