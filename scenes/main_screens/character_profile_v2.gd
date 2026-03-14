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
@onready var _attr_vbox: VBoxContainer = $VBoxContainer/body_panel/Attributes/Margin/VBox

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

const ICON_KEY_MAP = {
	"Physical DEF Rating":     "physical_defence",
	"Magic DEF Rating":        "magical_defence",
	"Damage Reduction Rating": "damage_reduction",
	"Block Chance Rating":     "block_chance",
	"Dodge Rating":            "dodge",
	"Physical ATK":            "physical_attack",
	"Crit Chance Rating":      "critical_chance",
	"Magic ATK":               "magical_attack",
	"Crit Damage Rating":      "critical_damage",
	"Hit Rating":              "hit_rating",
	"Armor Penetration Rating":"armor_penetration",
	"Haste Rating":            "haste",
	"Magic Penetration Rating":"magical_penetration",
	"Versatility Rating":      "versatility",
	"Total Steps:":            "steps",
	"Buffer Steps:":           "steps",
}

const PRIMARY_KEYS = [
	{"k":"str",      "n":"Strength",   "exp": "str_exp", "bonus": "bonus_str"},
	{"k":"agi",      "n":"Agility",    "exp": "agi_exp", "bonus": "bonus_agi"},
	{"k":"vit",      "n":"Vitality",   "exp": "vit_exp", "bonus": "bonus_vit"},
	{"k":"int_stat", "n":"Intellect   ",  "exp": "int_exp", "bonus": "bonus_int"},
	{"k":"spi",      "n":"Spirit   ",     "exp": "spi_exp", "bonus": "bonus_spi"},
	{"k":"luk",      "n":"Luck       ",       "exp": "luk_exp", "bonus": "bonus_luk"},
]

const OFFENSE_KEYS = [
	{"k":"atk",                "n":"Physical ATK",       "p": 0},
	{"k":"m_atk",              "n":"Magic ATK",          "p": 0},
	{"k":"crit_chance_rating", "n":"Crit Chance Rating", "p": "crit_chance"},
	{"k":"crit_damage_rating", "n":"Crit Damage Rating", "p": "crit_damage"},
	{"k":"hit_rating",         "n":"Hit Rating",         "p": "hit"},
	{"k":"armor_pen_rating",   "n":"Armor Penetration Rating", "p": "armor_pen"},
	{"k":"haste_rating",       "n":"Haste Rating",       "p": "haste"},
	{"k":"magic_pen_rating",   "n":"Magic Penetration Rating", "p": "magic_pen"},
	{"k":"versatility_rating", "n":"Versatility Rating", "p": "versatility"},
]

const DEFENSE_KEYS = [
	{"k":"p_def_rating",          "n":"Physical DEF Rating",     "p": "p_def"},
	{"k":"block_chance_rating",   "n":"Block Chance Rating",     "p": "block_chance"},
	{"k":"m_def_rating",          "n":"Magic DEF Rating",        "p": "m_def"},
	{"k":"dodge_rating",          "n":"Dodge Rating",            "p": "dodge"},
	{"k":"dmg_reduction_rating",  "n":"Damage Reduction Rating", "p": "dmg_reduction"},
]

const PROFESSION_GROUPS = [
	{
		"name": "Gathering",
		"entries": [
			{"k":"herbalism_lvl",    "n":"Herbalism", "exp":"herbalism_xp"},
			{"k":"mining_lvl",       "n":"Mining",    "exp":"mining_xp"},
			{"k":"woodcutting_lvl",  "n":"Forester",  "exp":"woodcutting_xp"},
			{"k":"fishing_lvl",      "n":"Fishing",   "exp":"fishing_xp"},
		]
	},
	{
		"name": "Crafting",
		"entries": [
			{"k":"alchemy_lvl", "n":"Alchemy", "exp":"alchemy_xp"},
		]
	},
	{
		"name": "Battle",
		"entries": [
			{"k":"hunting_lvl", "n":"Hunting",       "exp":"hunting_xp"},
			{"k":"rift_lvl",    "n":"Rift Explorer", "exp":"rift_xp"},
		]
	},
]

var STATS_TOTAL_TO_LEVEL = {1: 0}
var ACTIVITY_TOTAL_TO_LEVEL = {1: 0}

var _stats_mode_buttons: Array = []
var _stats_list_vbox: VBoxContainer = null
var _current_stats_mode := 0       # 0=Offensive, 1=Defensive, 2=Steps
var _last_stats_dict: Dictionary = {}
var _professions_vbox: VBoxContainer = null


func _ready() -> void:
	AccountManager.signal_AccountDataReceived.connect(_update_character_data)

	STATS_TOTAL_TO_LEVEL = ServerParams.STATS_PROGRESSION_LEVELS
	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS
	
	Styler._apply_parchment_style(body_panel)
	Styler._apply_parchment_style(panel_attributes)
	Styler._apply_parchment_style(panel_professions)
	Styler._apply_parchment_style(panel_archivements)
	Styler._apply_parchment_style(panel_reputations)
	
	Styler.style_button(btn_attributes, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_professions, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_archivements, Color.from_rgba8(64,180,255))
	Styler.style_button(btn_reputations, Color.from_rgba8(64,180,255))
	
	_style_section_card(primary_card, "Primary", Styler.COL_PRIMARY)
	_build_professions_section()
	off_box.visible   = false
	def_box.visible   = false
	step_card.visible = false
	_build_stats_dropdown_section()
	
	var stats = Account.to_dict()
	set_stats(stats)

func _update_character_data(value):
	var stats = Account.to_dict()
	set_stats(stats)

func set_stats(d: Dictionary) -> void:
	_last_stats_dict = d
	_clear(primary_grid)

	# Primary cards (big numbers)
	for entry in PRIMARY_KEYS:
		var lvl = int(d.get(entry.k, 0))
		var exp = int(d.get(entry.exp, 0))
		var bonus = int(d.get(entry.bonus, 0))
		var card = _make_mini_card_primary(entry.n, lvl, exp, bonus, Styler.COL_PRIMARY)
		primary_grid.add_child(card)

	if _stats_list_vbox != null:
		_populate_stats_list(d)

	if _professions_vbox != null:
		_populate_professions(d)

# ---------- UI Builders ----------
func _make_mini_card_primary(name: String, lvl: int, exp: int, bonus: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var floor_exp: int = STATS_TOTAL_TO_LEVEL.get(str(lvl),     exp)
	var next_exp:  int = STATS_TOTAL_TO_LEVEL.get(str(lvl + 1), -1)
	var lvl_current:  int = max(0, exp - floor_exp)
	var lvl_progress: int = max(1, next_exp - floor_exp) if next_exp >= 0 else 1

	var whole = int(lvl)
	var frac  = clamp(float(lvl_current) / float(lvl_progress), 0.0, 1.0)
	var pct   = int(round(frac * 100.0))   # 0 .. 100
	
	# --- card container ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	var _sb := StyleBoxFlat.new()
	_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	_sb.set_border_width_all(1)
	_sb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", _sb)

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
	icon.custom_minimum_size = Vector2(42, 42)
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
	n_lbl.add_theme_font_size_override("font_size", 16)
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(whole) + " + " + str(bonus)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 20)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(v_lbl)

	# --- second line: fractional progress bar (0..100) ---
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 8)
	var _pb_bg := StyleBoxFlat.new()
	_pb_bg.bg_color = Color(0, 0, 0, 0.2)
	_pb_bg.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", _pb_bg)
	var _pb_fill := StyleBoxFlat.new()
	_pb_fill.bg_color = accent
	_pb_fill.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("fill", _pb_fill)
	vb.add_child(pb)

	return panel
	
func _make_mini_card(name: String, lvl: int, activity_exp: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var floor_exp: int = ACTIVITY_TOTAL_TO_LEVEL.get(str(lvl),     activity_exp)
	var next_exp:  int = ACTIVITY_TOTAL_TO_LEVEL.get(str(lvl + 1), -1)
	var lvl_current:  int = max(0, activity_exp - floor_exp)
	var lvl_progress: int = max(1, next_exp - floor_exp) if next_exp >= 0 else 1

	var whole = int(lvl)
	var frac  = clamp(float(lvl_current) / float(lvl_progress), 0.0, 1.0)
	var pct   = int(round(frac * 100.0))   # 0 .. 100
	
	# --- card container ---
	var panel := PanelContainer.new()
	var _sb := StyleBoxFlat.new()
	_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	_sb.set_border_width_all(1)
	_sb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", _sb)

	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(main_hbox)

	# --- icon position ---
	var icon_box := VBoxContainer.new()
	icon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_box.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(icon_box)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(52, 52)
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
		"Rift Explorer": "rift",
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
	n_lbl.add_theme_font_size_override("font_size", 18)
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(whole)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 22)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(v_lbl)

	# --- second line: fractional progress bar (0..100) ---
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 8)
	var _pb_bg := StyleBoxFlat.new()
	_pb_bg.bg_color = Color(0, 0, 0, 0.2)
	_pb_bg.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", _pb_bg)
	var _pb_fill := StyleBoxFlat.new()
	_pb_fill.bg_color = accent
	_pb_fill.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("fill", _pb_fill)
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
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(v)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 16)
	v_lbl.add_theme_color_override("font_color", accent)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
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
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(n_lbl)
		
	var v_lbl := Label.new()
	v_lbl.text = str(v)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 20)
	v_lbl.add_theme_color_override("font_color", accent)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(v_lbl)

	return panel

func _make_row(name: String, value: String, percent_: String, accent: Color) -> Control:
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(36, 36)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
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
		"Physical DEF Rating": "physical_defence",
		"Magical DEF": "magical_defence",
		"Damage Reduction Rating": "damage_reduction",
		"Block Chance Rating": "block_chance",
		"Dodge Rating": "dodge",
		"Physical ATK": "physical_attack",
		"Crit Chance Rating": "critical_chance",
		"Magic ATK": "magical_attack",
		"Crit Damage Rating": "critical_damage",
		"Hit Rating": "hit_rating",
		"Armor Penetration Rating": "armor_penetration",
		"Haste Rating": "haste",
		"Magic Penetration Rating": "magical_penetration",
		"Magic DEF Rating": "magical_defence",
		"Versatility Rating": "versatility",
	}

	icon.texture = ItemDB.ICONS.get(icon_key.get(name))
	hb.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var val_lbl := Label.new()
	if percent_ and name not in ["Physical ATK", "Magic ATK"]:
		val_lbl.text = value + " ({0}%)".format([float(percent_) * 100])
	else:
		val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", accent)
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	val_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END

	hb.add_child(name_lbl)
	hb.add_child(val_lbl)
	return hb
	
func _style_section_card(card: PanelContainer, title: String, accent: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", sb)
	if card.get_child_count() > 0 and card.get_child(0) is GridContainer:
		var grid := card.get_child(0)
		var vb := VBoxContainer.new()
		card.remove_child(grid)
		card.add_child(vb)
		var hdr := Label.new()
		hdr.text = title
		hdr.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		hdr.add_theme_font_size_override("font_size", 22)
		hdr.add_theme_font_override("font", Styler.JANDA_FONT)
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
			return "%0.4f" % v
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


# ── Stats Dropdown Section ───────────────────────────────────────────────────

func _build_stats_dropdown_section() -> void:
	var btn_row := HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_theme_constant_override("separation", 4)
	_attr_vbox.add_child(btn_row)

	var labels := ["⚔ Offensive", "🛡 Defensive", "👟 Steps"]
	for i in labels.size():
		var btn := Button.new()
		btn.text = labels[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 18)
		Styler.style_button_small(btn, Color.from_rgba8(255, 200, 66))
		var idx := i
		btn.pressed.connect(func(): _set_stats_mode(idx))
		btn_row.add_child(btn)
		_stats_mode_buttons.append(btn)

	_set_stats_mode_highlight(_current_stats_mode)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_attr_vbox.add_child(scroll)

	_stats_list_vbox = VBoxContainer.new()
	_stats_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_list_vbox.add_theme_constant_override("separation", 1)
	scroll.add_child(_stats_list_vbox)


func _set_stats_mode(idx: int) -> void:
	_current_stats_mode = idx
	_set_stats_mode_highlight(idx)
	if not _last_stats_dict.is_empty():
		_populate_stats_list(_last_stats_dict)

func _set_stats_mode_highlight(active_idx: int) -> void:
	for i in _stats_mode_buttons.size():
		var btn = _stats_mode_buttons[i]
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(255, 200, 66) if i == active_idx else Color.from_rgba8(90, 90, 90)


func _populate_stats_list(d: Dictionary) -> void:
	_clear(_stats_list_vbox)
	_stats_list_vbox.add_child(_make_stat_header())
	match _current_stats_mode:
		0:
			for i in range(OFFENSE_KEYS.size()):
				var entry = OFFENSE_KEYS[i]
				var p_key = entry.get("p", 0)
				var val   = _fmt(d.get(entry.k, 0))
				var display: String
				if typeof(p_key) == TYPE_STRING:
					display = "%s  (%.1f%%)" % [val, float(d.get(p_key, 0)) * 100.0]
				else:
					display = val
				_stats_list_vbox.add_child(_make_stat_row(entry.n, display, i))
		1:
			for i in range(DEFENSE_KEYS.size()):
				var entry = DEFENSE_KEYS[i]
				var p_key = entry.get("p", 0)
				var val   = _fmt(d.get(entry.k, 0))
				var display: String
				if typeof(p_key) == TYPE_STRING:
					display = "%s  (%.1f%%)" % [val, float(d.get(p_key, 0)) * 100.0]
				else:
					display = val
				_stats_list_vbox.add_child(_make_stat_row(entry.n, display, i))
		2:
			for i in range(STEP_KEYS.size()):
				var entry = STEP_KEYS[i]
				_stats_list_vbox.add_child(_make_stat_row(entry.n, _fmt(d.get(entry.k, 0)), i))


func _make_stat_header() -> Control:
	var gold := Styler.COLOR_GOLD
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.0, 0.0, 0.0, 0.15)
	style.border_color = Color(0.0, 0.0, 0.0, 0.20)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_bottom",  6)
	panel.add_child(margin)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	margin.add_child(hb)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(28, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(spacer)

	var type_lbl := Label.new()
	type_lbl.text = "Type"
	type_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	type_lbl.add_theme_font_size_override("font_size", 16)
	type_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(type_lbl)

	var amt_lbl := Label.new()
	amt_lbl.text = "Amount"
	amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amt_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	amt_lbl.add_theme_font_size_override("font_size", 16)
	amt_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(amt_lbl)

	return panel


func _make_stat_row(stat_name: String, value: String, idx: int) -> Control:
	var row_dark  := Color(0.0, 0.0, 0.0, 0.04)
	var row_light := Color(0.0, 0.0, 0.0, 0.09)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color     = row_dark if idx % 2 == 0 else row_light
	style.border_color = Color(0.0, 0.0, 0.0, 0.08)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     5)
	margin.add_theme_constant_override("margin_bottom",  5)
	panel.add_child(margin)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	margin.add_child(hb)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_key_name: String = ICON_KEY_MAP.get(stat_name, "")
	var icon_tex = null if icon_key_name.is_empty() else ItemDB.ICONS.get(icon_key_name)
	if icon_tex != null:
		icon.texture = icon_tex
	hb.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = stat_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	val_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(val_lbl)

	return panel


# ── Professions Section ────────────────────────────────────────────────────────

func _build_professions_section() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	professions_card.add_theme_stylebox_override("panel", sb)

	for c in professions_card.get_children():
		c.queue_free()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	professions_card.add_child(margin)

	var outer_vb := VBoxContainer.new()
	outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vb.add_theme_constant_override("separation", 8)
	margin.add_child(outer_vb)

	_professions_vbox = outer_vb


func _populate_professions(d: Dictionary) -> void:
	_clear(_professions_vbox)
	for group in PROFESSION_GROUPS:
		# Group header — full-width separator-style label
		var grp_panel := PanelContainer.new()
		grp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var grp_sb := StyleBoxFlat.new()
		grp_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.10)
		grp_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
		grp_sb.set_border_width_all(1)
		grp_sb.set_corner_radius_all(4)
		grp_panel.add_theme_stylebox_override("panel", grp_sb)

		var grp_lbl := Label.new()
		grp_lbl.text = group.name.to_upper()
		grp_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		grp_lbl.add_theme_font_size_override("font_size", 20)
		grp_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		grp_lbl.add_theme_constant_override("margin_left", 8)
		grp_panel.add_child(grp_lbl)
		_professions_vbox.add_child(grp_panel)

		# Rows of 2 cards with proportional margins:
		# 5% left | 39% card | 12% gap | 39% card | 5% right
		var entries = group.entries
		for row_start in range(0, entries.size(), 2):
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 0)
			_professions_vbox.add_child(row)

			var _l := Control.new()
			_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_l.size_flags_stretch_ratio = 5.0
			_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(_l)

			var e1 = entries[row_start]
			var card1 = _make_mini_card(e1.n, int(d.get(e1.k, 0)), int(d.get(e1.exp, 0)), Styler.COL_PRIMARY)
			card1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card1.size_flags_stretch_ratio = 39.0
			row.add_child(card1)

			var _m := Control.new()
			_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_m.size_flags_stretch_ratio = 12.0
			_m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(_m)

			if row_start + 1 < entries.size():
				var e2 = entries[row_start + 1]
				var card2 = _make_mini_card(e2.n, int(d.get(e2.k, 0)), int(d.get(e2.exp, 0)), Styler.COL_PRIMARY)
				card2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				card2.size_flags_stretch_ratio = 39.0
				row.add_child(card2)
			else:
				var _pad := Control.new()
				_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_pad.size_flags_stretch_ratio = 39.0
				_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(_pad)

			var _r := Control.new()
			_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_r.size_flags_stretch_ratio = 5.0
			_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(_r)

			# Row gap when not the last row
			if row_start + 2 < entries.size():
				var _vsep := Control.new()
				_vsep.custom_minimum_size = Vector2(0, 6)
				_vsep.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_professions_vbox.add_child(_vsep)
