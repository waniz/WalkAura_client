extends Control

@onready var body_panel: PanelContainer = $VBoxContainer/body_panel

@onready var panel_attributes: PanelContainer = $VBoxContainer/body_panel/Attributes
@onready var panel_professions: PanelContainer = $VBoxContainer/body_panel/Professions
@onready var panel_achievements: PanelContainer = $VBoxContainer/body_panel/Achievements
@onready var achievements_vbox: VBoxContainer = $VBoxContainer/body_panel/Achievements/Margin/Scroll/VBox
@onready var btn_tab_attributes: Button = $VBoxContainer/Tab_Buttons/Btn_Tab_Attributes
@onready var btn_tab_professions: Button = $VBoxContainer/Tab_Buttons/Btn_Tab_Professions
@onready var btn_tab_achievements: Button = $VBoxContainer/Tab_Buttons/Btn_Tab_Achievements

const AchievementTabScene = preload("res://scenes/secondary_scenes/achievement_tab.tscn")
const StepStatsChartScene = preload("res://scenes/secondary_scenes/step_stats_chart.tscn")
var _achievement_tab: Node = null
var _achievements_ready_ids: Array = []

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
	"Blood Spell Damage":      "blood_spell_damage",
	"Holy Resistance":         "holy_spell_damage",
	"Fire Resistance":         "fire_spell_damage",
	"Frost Resistance":        "frost_spell_damage",
	"Arcane Resistance":       "arcane_spell_damage",
	"Dark Resistance":         "dark_spell_damage",
	"Blood Resistance":        "blood_spell_damage",
}

const PRIMARY_KEYS = [
	{"k":"str_stat",      "n":"Strength",   "exp": "str_exp", "bonus": "bonus_str"},
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
	{"k":"blood_spell_dmg_rating",  "n":"Blood Spell Damage",  "p": "blood_spell_dmg"},
]

const MAGIC_RESIST_KEYS = [
	{"k":"holy_resist_rating",   "n":"Holy Resistance",   "p": "holy_resist"},
	{"k":"fire_resist_rating",   "n":"Fire Resistance",   "p": "fire_resist"},
	{"k":"frost_resist_rating",  "n":"Frost Resistance",  "p": "frost_resist"},
	{"k":"arcane_resist_rating", "n":"Arcane Resistance", "p": "arcane_resist"},
	{"k":"dark_resist_rating",   "n":"Dark Resistance",   "p": "dark_resist"},
	{"k":"blood_resist_rating",     "n":"Blood Resistance",    "p": "blood_resist"},
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

var ATTR_RING_COLORS = {}
var PROF_GROUP_RING_COLORS = {}

const PROFESSION_GROUPS = [
	{
		"name": "Gathering",
		"entries": [
			{"k":"herbalism_lvl",    "n":"Herbalism", "exp":"herbalism_xp"},
			{"k":"mining_lvl",       "n":"Mining",    "exp":"mining_xp"},
			# Forester (woodcutting) + Fishing hidden client-side — server keeps them (TODO re-enable).
		]
	},
	{
		"name": "Crafting",
		"entries": [
			{"k":"alchemy_lvl",       "n":"Alchemy",       "exp":"alchemy_xp"},
			{"k":"enchanting_lvl",    "n":"Enchanting",    "exp":"enchanting_xp"},
			{"k":"blacksmithing_lvl", "n":"Crafting", "exp":"blacksmithing_xp"},
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

const PRIMARY_TOOLTIPS = {
	"Strength":
		"Physical ATK (×3), Phys DEF (×4),\nArmor Pen (×5.1), Crit Dmg (×2),\nAGI synergy (×1.5).",
	"Agility":
		"Hit Rating (×2.8), Crit Chance (×4),\nHaste (×6), Dodge (×3),\nCrit Dmg (×2), Phys DEF (×1.5).",
	"Vitality":
		"HP pool, Shield pool,\nDmg Reduction (×2), Versatility (×3),\nSoftens incoming crits.",
	"Intellect":
		"Magic ATK (×3), Magic DEF (×4),\nMagic Pen (×5.1), Crit Dmg (×2.5),\nHaste (×0.4).",
	"Spirit":
		"MP pool, Magic DEF (×1.5),\nMagic ATK (×1.5),\nBoosts walking regeneration.",
	"Luck":
		"Crit Chance (×1), Crit Dmg (×1),\nDodge (×0.55), Hit (×0.7),\nDmg Reduction (×0.55), Phys DEF (×0.8).",
}

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
var _current_stats_mode = 0       # 0=Offensive, 1=Defensive, 2=Steps, 3=Magic
var _last_stats_dict: Dictionary = {}
var _professions_vbox: VBoxContainer = null


func _ready() -> void:
	ATTR_RING_COLORS = {
		"Strength"  : Styler.RING_COLOR_STRENGTH,
		"Agility"   : Styler.RING_COLOR_AGILITY,
		"Vitality"  : Styler.RING_COLOR_VITALITY,
		"Intellect" : Styler.RING_COLOR_INTELLECT,
		"Spirit"    : Styler.RING_COLOR_SPIRIT,
		"Luck"      : Styler.RING_COLOR_LUCK,
	}
	PROF_GROUP_RING_COLORS = {
		"Gathering" : Styler.RING_COLOR_GATHERING,
		"Crafting"  : Styler.RING_COLOR_CRAFTING,
		"Battle"    : Styler.RING_COLOR_BATTLE,
	}
	$VBoxContainer.offset_top = Styler.content_top
	$VBoxContainer.offset_bottom = Styler.content_bottom

	AccountManager.signal_AccountDataReceived.connect(_update_character_data)
	SignalManager.signal_AchievementReady.connect(set_achievement_ready_ids)

	STATS_TOTAL_TO_LEVEL = ServerParams.STATS_PROGRESSION_LEVELS
	ACTIVITY_TOTAL_TO_LEVEL = ServerParams.ACTIVITY_PROGRESSION_LEVELS
	
	Styler._apply_parchment_style(body_panel)
	Styler._apply_parchment_style(panel_attributes)
	Styler._apply_parchment_style(panel_professions)
	
	Styler.style_button(btn_tab_attributes, Color.from_rgba8(64, 180, 255))
	Styler.style_button(btn_tab_professions, Color.from_rgba8(64, 180, 255))
	Styler.style_button(btn_tab_achievements, Color.from_rgba8(64, 180, 255))
	Styler._apply_parchment_style(panel_achievements)
	_on_btn_tab_attributes_pressed()
	
	_style_section_card(primary_card, "Primary", Styler.COL_PRIMARY)
	_build_professions_section()
	off_box.visible   = false
	def_box.visible   = false
	step_card.visible = false
	_build_stats_dropdown_section()
	
	var stats = Account.to_dict()
	set_stats(stats)

func _update_character_data(_value):
	var stats = Account.to_dict()
	set_stats(stats)

func set_stats(d: Dictionary) -> void:
	_last_stats_dict = d
	_clear(primary_grid)

	# Primary cards (big numbers)
	for entry in PRIMARY_KEYS:
		var lvl = int(d.get(entry.k, 0))
		var xp = int(d.get(entry.exp, 0))
		var bonus = int(d.get(entry.bonus, 0))
		var card = _make_mini_card_primary(entry.n, lvl, xp, bonus, Color.from_rgba8(64, 180, 255))
		primary_grid.add_child(card)

	if _stats_list_vbox != null:
		_populate_stats_list(d)

	if _professions_vbox != null:
		_populate_professions(d)

# ---------- UI Builders ----------
func _create_icon_ring(icon_size: int, radius: float, thickness: float,
		pct: int, _ring_color: Color, is_max_level: bool) -> Control:
	var wrapper_size = int(radius * 2.0)
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(wrapper_size, wrapper_size)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rp = RadialProgress.new()
	rp.ring = true
	rp.radius = radius
	rp.thickness = thickness
	rp.max_value = 100.0
	rp.bg_color = Color(1.0, 1.0, 1.0, 0.15)
	rp.border_width = 1.0
	rp.border_color = Color(0, 0, 0, 0.4)
	rp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_max_level:
		rp.progress = 100.0
		rp.bar_color = Color.WHITE
	else:
		rp.progress = 0.0
		rp.bar_color = Color.WHITE
	rp.position = Vector2(radius, radius)
	wrapper.add_child(rp)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var offset = (wrapper_size - icon_size) / 2.0
	icon.position = Vector2(offset, offset)
	wrapper.add_child(icon)

	# Animate ring from 0 to actual pct (skip for max level, already at 100)
	if not is_max_level and pct > 0:
		var tween = rp.create_tween()
		tween.tween_property(rp, "progress", float(pct), 0.5).from(0.0)

	return wrapper

func _make_mini_card_primary(stat_name: String, lvl: int, xp: int, bonus: int, accent: Color) -> Control:
	# --- parse & split value into whole + fractional parts ---
	var floor_exp: int = STATS_TOTAL_TO_LEVEL.get(str(lvl),     xp)
	var next_exp:  int = STATS_TOTAL_TO_LEVEL.get(str(lvl + 1), -1)
	var lvl_current:  int = max(0, xp - floor_exp)
	var lvl_progress: int = max(1, next_exp - floor_exp) if next_exp >= 0 else 1

	var whole = int(lvl)
	var frac  = clamp(float(lvl_current) / float(lvl_progress), 0.0, 1.0)
	var pct   = int(round(frac * 100.0))   # 0 .. 100

	# --- card container ---
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var _sb = StyleBoxFlat.new()
	_sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	_sb.set_border_width_all(1)
	_sb.set_corner_radius_all(5)
	_sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", _sb)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(main_hbox)

	# --- icon with radial ring (2x size) ---
	var is_max = (next_exp < 0)
	var ring_color = ATTR_RING_COLORS.get(stat_name, accent)
	var ring_wrapper = _create_icon_ring(84, 48.0, 6.0, pct, ring_color, is_max)
	ring_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var icon_key = {
		"Strength" : "attributes_strength",
		"Agility"  : "attributes_agility",
		"Vitality" : "attributes_vitality",
		"Intellect": "attributes_intellect",
		"Spirit"   : "attributes_spirit",
		"Luck"     : "attributes_luck",
	}

	ring_wrapper.get_node("Icon").texture = ItemDB.get_icon(icon_key.get(stat_name))
	main_hbox.add_child(ring_wrapper)

	# --- name + level ---
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 2)
	main_hbox.add_child(vb)

	var n_lbl = Label.new()
	n_lbl.text = stat_name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_lbl.add_theme_font_size_override("font_size", 18)
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	vb.add_child(n_lbl)

	var v_lbl = Label.new()
	v_lbl.text = "Lv %d + %d" % [whole, bonus]
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_lbl.add_theme_font_size_override("font_size", 22)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	vb.add_child(v_lbl)

	# --- tap/click tooltip ---
	var tip_text = PRIMARY_TOOLTIPS.get(stat_name, "")
	if not tip_text.is_empty():
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_tooltip_popup(panel, stat_name, tip_text)
		)

	return panel


var _active_tooltip: Control = null

func _show_tooltip_popup(anchor: Control, title: String, body: String) -> void:
	# Dismiss any existing tooltip
	if _active_tooltip and is_instance_valid(_active_tooltip):
		_active_tooltip.queue_free()
		_active_tooltip = null

	# Full-screen dismiss layer
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 10
	get_tree().current_scene.add_child(overlay)
	_active_tooltip = overlay

	# Tap anywhere to dismiss
	overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			if _active_tooltip and is_instance_valid(_active_tooltip):
				_active_tooltip.queue_free()
				_active_tooltip = null
	)

	# Tooltip panel
	var tip_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Styler.COLOR_PARCHMENT
	sb.border_color = Color(0.0, 0.0, 0.0, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	tip_panel.add_theme_stylebox_override("panel", sb)
	tip_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(tip_panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	tip_panel.add_child(vb)

	var title_lbl = Label.new()
	title_lbl.text = title
	Styler.style_parchment_label(title_lbl, Styler.COLOR_SECTION_HDR, 18)
	vb.add_child(title_lbl)

	var body_lbl = Label.new()
	body_lbl.text = body
	Styler.style_parchment_label(body_lbl, Styler.COLOR_TEXT_DARK, 14)
	vb.add_child(body_lbl)

	# Position near the anchor
	await get_tree().process_frame
	var anchor_rect = anchor.get_global_rect()
	var vp_size = get_viewport().get_visible_rect().size
	var tip_size = tip_panel.size
	var x = clamp(anchor_rect.position.x, 8.0, vp_size.x - tip_size.x - 8.0)
	var y = anchor_rect.end.y + 4.0
	if y + tip_size.y > vp_size.y - 8.0:
		y = anchor_rect.position.y - tip_size.y - 4.0
	tip_panel.global_position = Vector2(x, y)


func _make_mini_card(stat_name: String, lvl: int, activity_exp: int, accent: Color, group_name: String = "") -> Control:
	# --- parse XP ---
	var next_exp:  int = ACTIVITY_TOTAL_TO_LEVEL.get(str(lvl + 1), -1)
	var lvl_current:  int = max(0, activity_exp)
	var lvl_progress: int = max(1, next_exp) if next_exp > 0 else 1
	var is_max = (next_exp <= 0)
	var frac  = clamp(float(lvl_current) / float(lvl_progress), 0.0, 1.0)
	var pct   = int(round(frac * 100.0))

	# --- check if this profession is currently active ---
	var prof_activity_map = {
		"Herbalism": 1, "Alchemy": 2, "Hunting": 3,
		"Mining": 4, "Crafting": 10,
		"Rift Explorer": 7, "Enchanting": 9,
	}
	var act_id = prof_activity_map.get(stat_name, -1)
	var is_active = (act_id >= 0 and Account.activity == act_id)

	# --- group accent color ---
	var ring_color = PROF_GROUP_RING_COLORS.get(group_name, accent)

	# --- card container with group-colored left border ---
	var panel = PanelContainer.new()
	var _sb = StyleBoxFlat.new()
	_sb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	if is_active:
		_sb.bg_color = Color(ring_color.r, ring_color.g, ring_color.b, 0.08)
	_sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	_sb.set_border_width_all(1)
	_sb.border_width_left = 3
	_sb.set_corner_radius_all(5)
	var left_border_col = ring_color if (is_active or lvl > 1) else Color(0.0, 0.0, 0.0, 0.20)
	_sb.border_color = left_border_col
	panel.add_theme_stylebox_override("panel", _sb)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(main_hbox)

	# --- icon with radial ring ---
	var ring_wrapper = _create_icon_ring(90, 52.0, 5.0, pct, ring_color, is_max)
	ring_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var icon_key = {
		"Herbalism": "herbalism", "Alchemy": "alchemy", "Enchanting": "enchanting",
		"Crafting": "blacksmith",
		"Hunting": "hunting", "Mining": "mining", "Forester": "woodcutting",
		"Fishing": "fishing", "Rift Explorer": "rift",
	}
	ring_wrapper.get_node("Icon").texture = ItemDB.get_icon(icon_key.get(stat_name))
	main_hbox.add_child(ring_wrapper)

	# --- info column: name, level, XP bar, active badge ---
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 3)
	main_hbox.add_child(vb)

	var n_lbl = Label.new()
	n_lbl.text = stat_name
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_font_size_override("font_size", 16)
	n_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	vb.add_child(n_lbl)

	var v_lbl = Label.new()
	v_lbl.text = "Lv %d" % int(lvl)
	v_lbl.add_theme_font_size_override("font_size", 14)
	v_lbl.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	vb.add_child(v_lbl)

	# XP progress bar
	var xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 10)
	xp_bar.show_percentage = false
	xp_bar.max_value = lvl_progress
	xp_bar.value = lvl_current
	var xb_bg = StyleBoxFlat.new()
	xb_bg.bg_color = Color(0.0, 0.0, 0.0, 0.12)
	xb_bg.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("background", xb_bg)
	var xb_fill = StyleBoxFlat.new()
	xb_fill.bg_color = ring_color
	xb_fill.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("fill", xb_fill)
	if is_max:
		xp_bar.max_value = 1
		xp_bar.value = 1
	vb.add_child(xp_bar)

	# Active badge
	if is_active:
		var badge = Label.new()
		badge.text = "ACTIVE"
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", Color.from_rgba8(60, 200, 100))
		badge.add_theme_font_override("font", Styler.QUADRAT_FONT)
		vb.add_child(badge)

	# --- chevron ---
	var chevron = Label.new()
	chevron.text = "\u203A"
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chevron.add_theme_font_size_override("font_size", 22)
	chevron.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.25))
	main_hbox.add_child(chevron)

	# --- click handler ---
	var prof_key_map = {
		"Herbalism": "herbalism", "Alchemy": "alchemy", "Enchanting": "enchanting",
		"Crafting": "blacksmithing",
		"Hunting": "hunting", "Mining": "mining", "Forester": "woodcutting",
		"Fishing": "fishing", "Rift Explorer": "rift",
	}
	var prof_key: String = prof_key_map.get(stat_name, "")
	if not prof_key.is_empty():
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				SignalManager.signal_ShowProfession.emit(prof_key)
		)

	return panel

func _make_steps_card(label_text: String, value_in: String, accent: Color) -> Control:
	var v: int = int(value_in)

	# --- card container ---
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", Styler.card_box())

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)

	# --- first line: name + value ---
	var hb = HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	var n_lbl = Label.new()
	n_lbl.text = label_text
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(n_lbl)

	var v_lbl = Label.new()
	v_lbl.text = str(v)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 16)
	v_lbl.add_theme_color_override("font_color", accent)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(v_lbl)

	return panel

func _make_steps_card_with_icon(label_text: String, value_in: String, accent: Color) -> Control:
	var v: int = int(value_in)
	
	# --- card container ---
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", Styler.card_box())
	
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.add_child(vb)
	
	var hb = HBoxContainer.new()
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
	
	var n_lbl = Label.new()
	n_lbl.text = label_text
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	n_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(n_lbl)

	var v_lbl = Label.new()
	v_lbl.text = str(v)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 20)
	v_lbl.add_theme_color_override("font_color", accent)
	v_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(v_lbl)

	return panel

func _make_row(label_text: String, value: String, percent_: String, accent: Color) -> Control:
	var hb = HBoxContainer.new()
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

	icon.texture = ItemDB.get_icon(icon_key.get(label_text))
	hb.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var val_lbl = Label.new()
	if percent_ and label_text not in ["Physical ATK", "Magic ATK"]:
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
	
func _style_section_card(card: PanelContainer, _title: String, _accent: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", sb)
	if card.get_child_count() > 0 and card.get_child(0) is GridContainer:
		var grid = card.get_child(0)
		var vb = VBoxContainer.new()
		card.remove_child(grid)
		card.add_child(vb)
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
	panel_achievements.visible = false
	_set_profile_tab_active(btn_tab_attributes)

func _on_btn_tab_professions_pressed() -> void:
	panel_attributes.visible = false
	panel_professions.visible = true
	panel_achievements.visible = false
	_set_profile_tab_active(btn_tab_professions)

func _on_btn_tab_achievements_pressed() -> void:
	panel_attributes.visible = false
	panel_professions.visible = false
	panel_achievements.visible = true
	_set_profile_tab_active(btn_tab_achievements)
	_ensure_achievement_tab_loaded()
	_clear_achievement_tab_badge()

func _ensure_achievement_tab_loaded() -> void:
	if _achievement_tab == null:
		_achievement_tab = AchievementTabScene.instantiate()
		achievements_vbox.add_child(_achievement_tab)
	if _achievement_tab.has_method("request_refresh"):
		_achievement_tab.request_refresh()

func _set_profile_tab_active(active_btn: Button) -> void:
	for btn in [btn_tab_attributes, btn_tab_professions, btn_tab_achievements]:
		var sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color.from_rgba8(64, 180, 255) if btn == active_btn else Color.from_rgba8(60, 60, 70)

# Achievements ready notification dot on the Btn_Tab_Achievements button.
# Server pushes {"cmd":"achievement_ready","data":{"ready_ids":[...]}} via
# ServerConnector. Parent/ancestor scenes listen and call these helpers.
func set_achievement_ready_ids(ids: Array) -> void:
	_achievements_ready_ids = ids.duplicate()
	_refresh_achievement_tab_badge()

func _refresh_achievement_tab_badge() -> void:
	if not btn_tab_achievements:
		return
	var has_ready = _achievements_ready_ids.size() > 0
	if has_ready and not btn_tab_achievements.text.ends_with(" ●"):
		btn_tab_achievements.text = "Achievements ●"
	elif not has_ready and btn_tab_achievements.text.ends_with(" ●"):
		btn_tab_achievements.text = "Achievements"

func _clear_achievement_tab_badge() -> void:
	_achievements_ready_ids.clear()
	_refresh_achievement_tab_badge()

# Called by the achievement_tab when the server confirms a title change.
# Visual slot for active title rendering is TBD — hook here for integration.
func set_active_title_display(active_title, titles_known: Array) -> void:
	# Placeholder: print the title name for debugging. Replace with an on-screen
	# label when the profile header title slot is added to the .tscn.
	if active_title == null:
		print("[character_profile] active title cleared")
		return
	for t in titles_known:
		if int(t.get("title_id", 0)) == int(active_title):
			print("[character_profile] active title: ", t.get("default_name", ""))
			return
	print("[character_profile] active title id: ", active_title)


# ── Stats Dropdown Section ───────────────────────────────────────────────────

func _build_stats_dropdown_section() -> void:
	var btn_row = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_theme_constant_override("separation", 0)
	_attr_vbox.add_child(btn_row)

	var labels = ["⚔ OFFENSIVE", "🛡 DEFENSIVE", "👟 STEPS", "💚 SUSTAIN"]
	for i in labels.size():
		var btn = Button.new()
		btn.text = labels[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_font_override("font", Styler.JANDA_FONT)
		btn.add_theme_font_size_override("font_size", 12)
		_apply_sub_tab_style(btn, i, i == _current_stats_mode, labels.size())
		var idx = i
		btn.pressed.connect(func(): _set_stats_mode(idx))
		btn_row.add_child(btn)
		_stats_mode_buttons.append(btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_attr_vbox.add_child(scroll)

	_stats_list_vbox = VBoxContainer.new()
	_stats_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_list_vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(_stats_list_vbox)


func _set_stats_mode(idx: int) -> void:
	_current_stats_mode = idx
	_set_stats_mode_highlight(idx)
	if not _last_stats_dict.is_empty():
		_populate_stats_list(_last_stats_dict)

func _set_stats_mode_highlight(active_idx: int) -> void:
	for i in _stats_mode_buttons.size():
		_apply_sub_tab_style(_stats_mode_buttons[i], i, i == active_idx, _stats_mode_buttons.size())


# Painted segmented sub-tab style — Offensive=red, Defensive=blue, Steps=gold,
# Sustain=green. Active tab fills with the accent color and gets a glow halo;
# inactive tabs stay dark with a thin tinted border. First/last segments get
# rounded outer corners so the row reads as one painted control.
func _apply_sub_tab_style(btn: Button, tab_idx: int, active: bool, total_tabs: int = 4) -> void:
	var accent = _sub_tab_accent(tab_idx)
	var text_active = Color.WHITE
	var text_inactive = Color.from_rgba8(60, 60, 60)
	btn.add_theme_color_override("font_color", text_active if active else text_inactive)
	btn.add_theme_color_override("font_hover_color", text_active if active else text_inactive.lightened(0.3))
	btn.add_theme_color_override("font_pressed_color", text_active if active else text_inactive)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		if active:
			sb.bg_color = accent
			sb.border_color = accent.darkened(0.25)
			sb.set_border_width_all(0)
			sb.border_width_bottom = 2
			sb.shadow_color = Color(accent, 0.45)
			sb.shadow_size = 8
		else:
			sb.bg_color = Color.from_rgba8(220, 210, 190, 200)
			sb.border_color = Color(accent, 0.35)
			sb.set_border_width_all(1)
		# Rounded outer corners on the first/last segment.
		var first: bool = tab_idx == 0
		var last: bool = tab_idx == total_tabs - 1
		var r_outer: int = 4
		sb.corner_radius_top_left = r_outer if first else 0
		sb.corner_radius_bottom_left = r_outer if first else 0
		sb.corner_radius_top_right = r_outer if last else 0
		sb.corner_radius_bottom_right = r_outer if last else 0
		btn.add_theme_stylebox_override(state_name, sb)


# Sub-tab accent color by tab index. Steps + Sustain share the success-green
# treatment (per user request — total steps + buffer values render green to
# match the sustain family).
func _sub_tab_accent(tab_idx: int) -> Color:
	match tab_idx:
		0: return Styler.COL_OFFENSE
		1: return Styler.COL_DEFENSE
		2: return Styler.COLOR_BTN_SUCCESS
		3: return Styler.COLOR_BTN_SUCCESS
	return Styler.COL_PRIMARY


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
			var chart = StepStatsChartScene.instantiate()
			chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_stats_list_vbox.add_child(chart)
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
	var accent = _sub_tab_accent(_current_stats_mode)
	var frame = PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(accent, 0.35)
	sb.set_border_width_all(0)
	sb.border_width_top = 1
	sb.set_corner_radius_all(5)
	sb.content_margin_left   = 6
	sb.content_margin_right  = 6
	sb.content_margin_top    = 6
	sb.content_margin_bottom = 4
	frame.add_theme_stylebox_override("panel", sb)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 2)
	frame.add_child(vb)

	# Gold-underlined section header matching the design spec.
	var hdr = Label.new()
	hdr.text = "✨ " + title.to_upper()
	hdr.add_theme_color_override("font_color", accent.darkened(0.2))
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_font_override("font", Styler.JANDA_FONT)
	hdr.add_theme_constant_override("outline_size", 0)
	vb.add_child(hdr)
	var rule = ColorRect.new()
	rule.color = Color(accent, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	vb.add_child(rule)

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
	var _gold = Styler.COLOR_GOLD
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.0, 0.0, 0.0, 0.15)
	style.border_color = Color(0.0, 0.0, 0.0, 0.20)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_bottom",  6)
	panel.add_child(margin)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	margin.add_child(hb)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(28, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(spacer)

	var type_lbl = Label.new()
	type_lbl.text = "Type"
	type_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	type_lbl.add_theme_font_size_override("font_size", 16)
	type_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(type_lbl)

	var amt_lbl = Label.new()
	amt_lbl.text = "Amount"
	amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amt_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	amt_lbl.add_theme_font_size_override("font_size", 16)
	amt_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(amt_lbl)

	return panel


func _make_stat_row(stat_name: String, value: String, idx: int, show_icon: bool = true) -> Control:
	# Dim rows whose primary value is exactly 0 — visual signal that the stat
	# is unallocated. Real values stay full opacity so notable stats jump out.
	var is_zero: bool = _stat_value_is_zero(value)
	var row_alpha: float = 0.55 if is_zero else 1.0

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.tooltip_text = STAT_TOOLTIPS.get(stat_name, "")
	panel.modulate.a = row_alpha
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.04 if idx % 2 == 0 else 0.09)
	style.border_color = Color(0.0, 0.0, 0.0, 0.06)
	style.set_border_width_all(0)
	# Sub-tab-color left edge — anchors the row to the current sub-tab family.
	var accent = _sub_tab_accent(_current_stats_mode)
	style.border_color = accent
	style.border_width_left = 2
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     5)
	margin.add_theme_constant_override("margin_bottom",  5)
	panel.add_child(margin)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	margin.add_child(hb)

	if show_icon:
		var icon = TextureRect.new()
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

	var name_lbl = Label.new()
	name_lbl.text = stat_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	name_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	hb.add_child(name_lbl)

	var val_lbl = Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	if is_zero:
		val_lbl.add_theme_color_override("font_color", Color(Styler.COLOR_TEXT_DARK, 0.6))
	else:
		# Non-zero values get the sub-tab accent so notable stats pop.
		val_lbl.add_theme_color_override("font_color", accent.darkened(0.15))
	hb.add_child(val_lbl)

	return panel


# Heuristic — value display strings start with "0" or "0.0..." for zero stats.
func _stat_value_is_zero(value: String) -> bool:
	var trimmed = value.strip_edges()
	if trimmed.is_empty():
		return false
	# Accept "0", "0.0", "0  (0.0%)", etc. but NOT "10" or "0.5".
	if trimmed.begins_with("0  "):
		return true
	if trimmed == "0" or trimmed == "0.0":
		return true
	return false


func _make_section_header(title: String) -> Control:
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_child(lbl)
	return margin


# ── Professions Section ────────────────────────────────────────────────────────

func _build_professions_section() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.20)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	professions_card.add_theme_stylebox_override("panel", sb)

	for c in professions_card.get_children():
		c.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	professions_card.add_child(margin)

	var outer_vb = VBoxContainer.new()
	outer_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vb.add_theme_constant_override("separation", 8)
	margin.add_child(outer_vb)

	_professions_vbox = outer_vb


func _populate_professions(d: Dictionary) -> void:
	_clear(_professions_vbox)
	for group in PROFESSION_GROUPS:
		# Group frame (like _make_magic_group)
		var frame = PanelContainer.new()
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb = StyleBoxFlat.new()
		sb.bg_color     = Color(0.0, 0.0, 0.0, 0.06)
		sb.border_color = Color(0.0, 0.0, 0.0, 0.25)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		sb.content_margin_left   = 6
		sb.content_margin_right  = 6
		sb.content_margin_top    = 4
		sb.content_margin_bottom = 4
		frame.add_theme_stylebox_override("panel", sb)

		var frame_vb = VBoxContainer.new()
		frame_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame_vb.add_theme_constant_override("separation", 6)
		frame.add_child(frame_vb)

		# Group title
		var hdr = Label.new()
		hdr.text = group.name
		hdr.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
		hdr.add_theme_font_size_override("font_size", 22)
		hdr.add_theme_font_override("font", Styler.JANDA_FONT)
		frame_vb.add_child(hdr)

		# Rows of 2 cards
		var entries = group.entries
		for row_start in range(0, entries.size(), 2):
			var row = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 6)
			frame_vb.add_child(row)

			var e1 = entries[row_start]
			var card1 = _make_mini_card(e1.n, int(d.get(e1.k, 0)), int(d.get(e1.exp, 0)), Styler.COL_PRIMARY, group.name)
			card1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(card1)

			if row_start + 1 < entries.size():
				var e2 = entries[row_start + 1]
				var card2 = _make_mini_card(e2.n, int(d.get(e2.k, 0)), int(d.get(e2.exp, 0)), Styler.COL_PRIMARY, group.name)
				card2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(card2)
			else:
				var _pad = Control.new()
				_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(_pad)

		_professions_vbox.add_child(frame)
