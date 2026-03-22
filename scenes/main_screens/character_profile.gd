extends Control

@onready var body_panel: PanelContainer = $VBoxContainer/body_panel

@onready var panel_attributes: PanelContainer = $VBoxContainer/body_panel/Attributes
@onready var panel_professions: PanelContainer = $VBoxContainer/body_panel/Professions
@onready var btn_tab_attributes: Button = $VBoxContainer/Tab_Buttons/Btn_Tab_Attributes
@onready var btn_tab_professions: Button = $VBoxContainer/Tab_Buttons/Btn_Tab_Professions

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
	"Holy Spell Damage":       "holy_spell_damage",
	"Fire Spell Damage":       "fire_spell_damage",
	"Frost Spell Damage":      "frost_spell_damage",
	"Arcane Spell Damage":     "arcane_spell_damage",
	"Dark Spell Damage":       "dark_spell_damage",
	"Holy Resistance":         "holy_spell_damage",
	"Fire Resistance":         "fire_spell_damage",
	"Frost Resistance":        "frost_spell_damage",
	"Arcane Resistance":       "arcane_spell_damage",
	"Dark Resistance":         "dark_spell_damage",
}

const PRIMARY_KEYS = [
	{"k":"str",      "n":"Strength",   "exp": "str_exp", "bonus": "bonus_str"},
	{"k":"agi",      "n":"Agility",    "exp": "agi_exp", "bonus": "bonus_agi"},
	{"k":"vit",      "n":"Vitality",   "exp": "vit_exp", "bonus": "bonus_vit"},
	{"k":"int_stat", "n":"Intellect", "exp": "int_exp", "bonus": "bonus_int"},
	{"k":"spi",      "n":"Spirit",    "exp": "spi_exp", "bonus": "bonus_spi"},
	{"k":"luk",      "n":"Luck",      "exp": "luk_exp", "bonus": "bonus_luk"},
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

const MAGIC_DAMAGE_KEYS = [
	{"k":"holy_spell_dmg_rating",    "n":"Holy Spell Damage",    "p": "holy_spell_dmg"},
	{"k":"fire_spell_dmg_rating",    "n":"Fire Spell Damage",    "p": "fire_spell_dmg"},
	{"k":"frost_spell_dmg_rating",   "n":"Frost Spell Damage",   "p": "frost_spell_dmg"},
	{"k":"arcane_spell_dmg_rating",  "n":"Arcane Spell Damage",  "p": "arcane_spell_dmg"},
	{"k":"dark_spell_dmg_rating",    "n":"Dark Spell Damage",    "p": "dark_spell_dmg"},
]

const MAGIC_RESIST_KEYS = [
	{"k":"holy_resist_rating",   "n":"Holy Resistance",   "p": "holy_resist"},
	{"k":"fire_resist_rating",   "n":"Fire Resistance",   "p": "fire_resist"},
	{"k":"frost_resist_rating",  "n":"Frost Resistance",  "p": "frost_resist"},
	{"k":"arcane_resist_rating", "n":"Arcane Resistance", "p": "arcane_resist"},
	{"k":"dark_resist_rating",   "n":"Dark Resistance",   "p": "dark_resist"},
]

const SUSTAIN_KEYS = [
	{"k":"hp_regen_battle_rating",     "n":"HP Regen in Battle",     "p": "hp_regen_battle"},
	{"k":"mp_regen_battle_rating",     "n":"MP Regen in Battle",     "p": "mp_regen_battle"},
	{"k":"shield_regen_battle_rating", "n":"Shield Regen in Battle", "p": "shield_regen_battle"},
	{"k":"life_steal_rating",          "n":"Life Steal",             "p": "life_steal"},
	{"k":"precision_rating",           "n":"Precision",              "p": "precision"},
	{"k":"shield_absorb_bonus_rating", "n":"Shield Absorb",         "p": "shield_absorb_bonus"},
	{"k":"thorns_rating",              "n":"Thorns",                 "p": "thorns"},
	{"k":"crit_dmg_reduction_rating",  "n":"Resilience",            "p": "crit_dmg_reduction"},
	{"k":"walk_regen_bonus_rating",    "n":"Vitality Restoration",  "p": "walk_regen_bonus"},
	{"k":"healing_amp_rating",         "n":"Healing Power",         "p": "healing_amp"},
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
			{"k":"alchemy_lvl",     "n":"Alchemy",     "exp":"alchemy_xp"},
			{"k":"enchanting_lvl",  "n":"Enchanting",  "exp":"enchanting_xp"},
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

const STAT_TOOLTIPS = {
	# ── Offense ──────────────────────────────────────────────────────────────
	"Physical ATK":
		"Physical attack power used as the base for auto-attacks and physical skills.\nScales with STR (×3) and AGI (×1.5).",
	"Magic ATK":
		"Magical attack power used as the base for all magical skills.\nScales with INT (×3) and SPI (×1.5).",
	"Crit Chance Rating":
		"Chance to land a critical strike.\n142 rating = 1% crit chance.\nOn a crit, damage is multiplied by your Crit Damage.\nScales with AGI (×4) and LCK (×1).",
	"Crit Damage Rating":
		"Damage multiplier applied on a critical strike.\n142 rating = 1% bonus multiplier.\nBase crit multiplier is 1.5×. Boosted further by the Brutal Finish talent.\nScales with AGI (×2), LCK (×1), INT (×2.5), STR (×2).",
	"Hit Rating":
		"Increases your chance to hit. 142 rating = 1% hit chance.\nHit chance is capped at 99%.\nScales with AGI (×2.8) and LCK (×0.7).",
	"Armor Penetration Rating":
		"Reduces the enemy's physical defense when calculating damage.\n142 rating = 1% penetration.\nScales with STR (×5.1).",
	"Haste Rating":
		"Reduces the interval between auto-attacks (faster attack speed).\nMinimum attack interval is 2 ticks.\n142 rating = 1% haste.\nScales with AGI (×6) and INT (×0.4).",
	"Magic Penetration Rating":
		"Reduces the enemy's magical defense when calculating damage.\n142 rating = 1% penetration.\nScales with INT (×5.1).",
	"Versatility Rating":
		"Reduces all incoming damage (physical and magical) by Versatility / 2%.\nApplied before armor and resistance calculations.\n142 rating = 1% versatility.\nScales with VIT (×3), AGI (×2), LCK (×2).",
	# ── Defense ──────────────────────────────────────────────────────────────
	"Physical DEF Rating":
		"Reduces physical damage taken. Uses diminishing returns.\n3142 rating = 50% reduction. No hard cap, but gains slow at high values.\nBoosted by the Thick Skin talent (+0.5% per level).\nScales with STR (×4), AGI (×1.5), LCK (×0.8).",
	"Magic DEF Rating":
		"Reduces magical damage taken. Uses diminishing returns.\n3142 rating = 50% reduction. No hard cap, but gains slow at high values.\nScales with INT (×4), SPI (×1.5), LCK (×0.12).",
	"Block Chance Rating":
		"Chance to block an incoming attack and reduce its damage by 50%.\n142 rating = 1% block chance.\nObtained from equipment only — no primary stat contributes.",
	"Dodge Rating":
		"Chance to fully avoid an incoming attack.\n142 rating = 1% dodge chance. Minimum dodge is always 1%.\nBoosted by the Evasion Training talent (+0.5% per level).\nScales with AGI (×3) and LCK (×0.55).",
	"Damage Reduction Rating":
		"Reduces all incoming damage (physical and magical) before defenses apply.\nAlso benefits from half of your Versatility.\n142 rating = 1% damage reduction.\nScales with VIT (×2), LCK (×0.55), AGI (×0.17).",
	# ── Steps ─────────────────────────────────────────────────────────────────
	"Total Steps:":
		"Lifetime total steps recorded by the pedometer.\nEvery 25 real-world steps generate 1 game tick.",
	"Buffer Steps:":
		"Steps available to spend on activities.\nFills as you walk; capped at 15,000 + 1,000 per level above 10.\nTicks restore HP, MP, and Shield and advance activity progress.",
	# ── Magic — Spell Damage ──────────────────────────────────────────────────
	"Holy Spell Damage":
		"Amplifies Holy magical skill damage.\n142 rating = 1% bonus damage.\nObtained from equipment only.",
	"Fire Spell Damage":
		"Amplifies Fire magical skill damage.\n142 rating = 1% bonus damage.\nObtained from equipment only.",
	"Frost Spell Damage":
		"Amplifies Frost magical skill damage.\n142 rating = 1% bonus damage.\nObtained from equipment only.",
	"Arcane Spell Damage":
		"Amplifies Arcane magical skill damage.\n142 rating = 1% bonus damage.\nObtained from equipment only.",
	"Dark Spell Damage":
		"Amplifies Dark magical skill damage.\n142 rating = 1% bonus damage.\nObtained from equipment only.",
	# ── Magic — Resistances ───────────────────────────────────────────────────
	"Holy Resistance":
		"Reduces incoming Holy damage. Uses diminishing returns, capped at 75%.\n3142 rating = 50% resistance.\nObtained from equipment only.",
	"Fire Resistance":
		"Reduces incoming Fire damage. Uses diminishing returns, capped at 75%.\n3142 rating = 50% resistance.\nObtained from equipment only.",
	"Frost Resistance":
		"Reduces incoming Frost damage. Uses diminishing returns, capped at 75%.\n3142 rating = 50% resistance.\nObtained from equipment only.",
	"Arcane Resistance":
		"Reduces incoming Arcane damage. Uses diminishing returns, capped at 75%.\n3142 rating = 50% resistance.\nObtained from equipment only.",
	"Dark Resistance":
		"Reduces incoming Dark damage. Uses diminishing returns, capped at 75%.\n3142 rating = 50% resistance.\nObtained from equipment only.",
	# ── Sustain ──────────────────────────────────────────────────────────────
	"HP Regen in Battle":
		"Restores a percentage of max HP every 20 battle ticks.\nUses diminishing returns, capped at 10%.\nObtained from equipment only.",
	"MP Regen in Battle":
		"Restores a percentage of max MP every 20 battle ticks.\nUses diminishing returns, capped at 10%.\nObtained from equipment only.",
	"Shield Regen in Battle":
		"Restores a percentage of max Shield every 20 battle ticks.\nUses diminishing returns, capped at 8%.\nObtained from equipment only.",
	"Life Steal":
		"Heals you for a percentage of damage dealt to enemies.\nUses diminishing returns, capped at 15%.\nObtained from equipment only.",
	"Precision":
		"Reduces damage variance (base ±20% spread).\nUses diminishing returns, capped at 20%.\nObtained from equipment only.",
	"Shield Absorb":
		"Increases the shield absorption rate (base 33%).\nUses diminishing returns, capped at 25%.\nObtained from equipment only.",
	"Thorns":
		"Reflects a percentage of raw incoming damage back to the attacker.\nUses diminishing returns, capped at 15%.\nObtained from equipment only.",
	"Resilience":
		"Reduces incoming critical strike bonus damage.\nStacks with Vitality's natural crit softening.\nUses diminishing returns, capped at 30%.\nObtained from equipment only.",
	"Vitality Restoration":
		"Multiplier bonus to all walking regeneration (HP, MP, Shield).\nUses diminishing returns, capped at 50%.\nObtained from equipment only.",
	"Healing Power":
		"Increases all healing received (skills, HoTs, consumables).\nUses diminishing returns, capped at 30%.\nObtained from equipment only.",
}

var STATS_TOTAL_TO_LEVEL = {1: 0}
var ACTIVITY_TOTAL_TO_LEVEL = {1: 0}

var _stats_mode_buttons: Array = []
var _stats_list_vbox: VBoxContainer = null
var _current_stats_mode := 0       # 0=Offensive, 1=Defensive, 2=Steps, 3=Magic
var _last_stats_dict: Dictionary = {}
var _professions_vbox: VBoxContainer = null


func _ready() -> void:
	$VBoxContainer.offset_top = Styler.content_top
	$VBoxContainer.offset_bottom = Styler.content_bottom

	AccountManager.signal_AccountDataReceived.connect(_update_character_data)

	STATS_TOTAL_TO_LEVEL = ServerParams.STATS_PROGRESSION_LEVELS
	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS
	
	Styler._apply_parchment_style(body_panel)
	Styler._apply_parchment_style(panel_attributes)
	Styler._apply_parchment_style(panel_professions)
	
	Styler.style_button(btn_tab_attributes, Color.from_rgba8(64, 180, 255))
	Styler.style_button(btn_tab_professions, Color.from_rgba8(64, 180, 255))
	_on_btn_tab_attributes_pressed()
	
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
		var card = _make_mini_card_primary(entry.n, lvl, exp, bonus, Color.from_rgba8(64, 180, 255))
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
	panel.custom_minimum_size = Vector2(150, 60)
	var _sb := StyleBoxFlat.new()
	_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	_sb.set_border_width_all(1)
	_sb.set_corner_radius_all(5)
	_sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", _sb)

	var main_hbox := HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(main_hbox)

	# --- icon position ---
	var icon_box := VBoxContainer.new()
	icon_box.custom_minimum_size.x = 46
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
		"Intellect": "attributes_intellect",
		"Spirit"   : "attributes_spirit",
		"Luck"     : "attributes_luck",
	}

	icon.texture = ItemDB.get_icon(icon_key.get(name))
	icon_box.add_child(icon)

	# --- first line: name + value ---
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(vb)

	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	var n_lbl := Label.new()
	n_lbl.text = name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_font_size_override("font_size", 18)
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	hb.add_child(n_lbl)

	var v_lbl := Label.new()
	v_lbl.text = str(whole) + " + " + str(bonus)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 18)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(v_lbl)

	# --- second line: fractional progress bar (0..100) ---
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = 100
	pb.value = pct
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 18)
	var _pb_bg := StyleBoxFlat.new()
	_pb_bg.bg_color = Color(0, 0, 0, 0.2)
	_pb_bg.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("background", _pb_bg)
	var _pb_fill := StyleBoxFlat.new()
	_pb_fill.bg_color = accent
	_pb_fill.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", _pb_fill)
	vb.add_child(pb)

	var pct_lbl := Label.new()
	pct_lbl.text = str(pct) + "%"
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pct_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct_lbl.add_theme_font_size_override("font_size", 12)
	pct_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	pct_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	pct_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	pb.add_child(pct_lbl)

	return panel
	
func _make_mini_card(name: String, lvl: int, activity_exp: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var next_exp:  int = ACTIVITY_TOTAL_TO_LEVEL.get(str(lvl + 1), -1)
	var lvl_current:  int = max(0, activity_exp)
	var lvl_progress: int = max(1, next_exp) if next_exp > 0 else 1

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

	# --- icon (left-aligned, no expand) ---
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
		"Enchanting"   : "enchanting",
		"Hunting"      : "hunting",
		"Mining"       : "mining",
		"Forester"     : "woodcutting",
		"Fishing"      : "fishing",
		"Rift Explorer": "rift",
	}

	icon.texture = ItemDB.get_icon(icon_key.get(name))
	main_hbox.add_child(icon)

	# --- name (centered) + level + progress bar below ---
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
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	pb.custom_minimum_size = Vector2(0, 18)
	var _pb_bg := StyleBoxFlat.new()
	_pb_bg.bg_color = Color(0, 0, 0, 0.2)
	_pb_bg.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("background", _pb_bg)
	var _pb_fill := StyleBoxFlat.new()
	_pb_fill.bg_color = accent
	_pb_fill.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", _pb_fill)
	vb.add_child(pb)

	var pct_lbl := Label.new()
	pct_lbl.text = str(pct) + "%"
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pct_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct_lbl.add_theme_font_size_override("font_size", 12)
	pct_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	pct_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	pct_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	pb.add_child(pct_lbl)

	# Click handler — open profession detail overlay
	var prof_key_map := {
		"Herbalism":     "herbalism",
		"Alchemy":       "alchemy",
		"Enchanting":    "enchanting",
		"Hunting":       "hunting",
		"Mining":        "mining",
		"Forester":      "woodcutting",
		"Fishing":       "fishing",
		"Rift Explorer": "rift",
	}
	var prof_key: String = prof_key_map.get(name, "")
	if prof_key in ["herbalism", "alchemy"]:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				SignalManager.signal_ShowProfession.emit(prof_key)
		)

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
	
	icon.texture = ItemDB.get_icon("steps")
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

	icon.texture = ItemDB.get_icon(icon_key.get(name))
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


func _on_btn_tab_attributes_pressed() -> void:
	panel_attributes.visible = true
	panel_professions.visible = false
	_set_profile_tab_active(btn_tab_attributes)

func _on_btn_tab_professions_pressed() -> void:
	panel_attributes.visible = false
	panel_professions.visible = true
	_set_profile_tab_active(btn_tab_professions)

func _set_profile_tab_active(active_btn: Button) -> void:
	for btn in [btn_tab_attributes, btn_tab_professions]:
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(64, 180, 255) if btn == active_btn else Color.from_rgba8(60, 60, 70)


# ── Stats Dropdown Section ───────────────────────────────────────────────────

func _build_stats_dropdown_section() -> void:
	var btn_row := HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_theme_constant_override("separation", 4)
	_attr_vbox.add_child(btn_row)

	var labels := ["⚔ Offensive", "🛡 Defensive", "👟 Steps", "💚 Sustain"]
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
				_stats_list_vbox.add_child(_make_stat_row(entry.n, display, i, false))
			_stats_list_vbox.add_child(_make_magic_group("Damage Amplifiers", MAGIC_DAMAGE_KEYS, d))
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
				_stats_list_vbox.add_child(_make_stat_row(entry.n, display, i, false))
			_stats_list_vbox.add_child(_make_magic_group("Resistances", MAGIC_RESIST_KEYS, d))
		2:
			for i in range(STEP_KEYS.size()):
				var entry = STEP_KEYS[i]
				_stats_list_vbox.add_child(_make_stat_row(entry.n, _fmt(d.get(entry.k, 0)), i))
		3:
			for i in range(SUSTAIN_KEYS.size()):
				var entry = SUSTAIN_KEYS[i]
				var p_key = entry.get("p", 0)
				var val   = _fmt(d.get(entry.k, 0))
				var display: String
				if typeof(p_key) == TYPE_STRING:
					display = "%s  (%.1f%%)" % [val, float(d.get(p_key, 0)) * 100.0]
				else:
					display = val
				_stats_list_vbox.add_child(_make_stat_row(entry.n, display, i, false))


func _make_magic_group(title: String, keys: Array, d: Dictionary) -> Control:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left   = 6
	sb.content_margin_right  = 6
	sb.content_margin_top    = 4
	sb.content_margin_bottom = 4
	frame.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 1)
	frame.add_child(vb)

	var hdr := Label.new()
	hdr.text = title
	hdr.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_font_override("font", Styler.JANDA_FONT)
	vb.add_child(hdr)

	for i in keys.size():
		var entry = keys[i]
		var p_key = entry.get("p", 0)
		var val   = _fmt(d.get(entry.k, 0))
		var display: String
		if typeof(p_key) == TYPE_STRING:
			display = "%s  (%.1f%%)" % [val, float(d.get(p_key, 0)) * 100.0]
		else:
			display = val
		vb.add_child(_make_stat_row(entry.n, display, i))

	return frame


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


func _make_stat_row(stat_name: String, value: String, idx: int, show_icon: bool = true) -> Control:
	var row_dark  := Color(0.0, 0.0, 0.0, 0.04)
	var row_light := Color(0.0, 0.0, 0.0, 0.09)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.tooltip_text = STAT_TOOLTIPS.get(stat_name, "")
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

	if show_icon:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_key_name: String = ICON_KEY_MAP.get(stat_name, "")
		var icon_tex = null if icon_key_name.is_empty() else ItemDB.get_icon(icon_key_name)
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
		# Group frame (like _make_magic_group)
		var frame := PanelContainer.new()
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
		sb.border_color = Color(0.0, 0.0, 0.0, 0.25)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		sb.content_margin_left   = 6
		sb.content_margin_right  = 6
		sb.content_margin_top    = 4
		sb.content_margin_bottom = 4
		frame.add_theme_stylebox_override("panel", sb)

		var frame_vb := VBoxContainer.new()
		frame_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame_vb.add_theme_constant_override("separation", 6)
		frame.add_child(frame_vb)

		# Group title
		var hdr := Label.new()
		hdr.text = group.name
		hdr.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		hdr.add_theme_font_size_override("font_size", 16)
		hdr.add_theme_font_override("font", Styler.JANDA_FONT)
		frame_vb.add_child(hdr)

		# Rows of 2 cards
		var entries = group.entries
		for row_start in range(0, entries.size(), 2):
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 6)
			frame_vb.add_child(row)

			var e1 = entries[row_start]
			var card1 = _make_mini_card(e1.n, int(d.get(e1.k, 0)), int(d.get(e1.exp, 0)), Styler.COL_PRIMARY)
			card1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(card1)

			if row_start + 1 < entries.size():
				var e2 = entries[row_start + 1]
				var card2 = _make_mini_card(e2.n, int(d.get(e2.k, 0)), int(d.get(e2.exp, 0)), Styler.COL_PRIMARY)
				card2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(card2)
			else:
				var _pad := Control.new()
				_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(_pad)

		_professions_vbox.add_child(frame)
