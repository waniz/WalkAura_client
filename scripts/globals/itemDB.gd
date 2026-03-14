extends Node

var ITEM_ICONS = {
	# Equipment
	# ===== Belts
	"belt_0":            load("res://assets/equipment/belts/belt_0.png") as Texture2D,
	"belt_1":            load("res://assets/equipment/belts/belt_1.png") as Texture2D,
	"belt_2":            load("res://assets/equipment/belts/belt_2.png") as Texture2D,
	"belt_3":            load("res://assets/equipment/belts/belt_3.png") as Texture2D,
	"belt_4":            load("res://assets/equipment/belts/belt_4.png") as Texture2D,
	"belt_5":            load("res://assets/equipment/belts/belt_5.png") as Texture2D,
	"belt_6":            load("res://assets/equipment/belts/belt_6.png") as Texture2D,
	"belt_7":            load("res://assets/equipment/belts/belt_7.png") as Texture2D,
	"belt_8":            load("res://assets/equipment/belts/belt_8.png") as Texture2D,
	"belt_9":            load("res://assets/equipment/belts/belt_9.png") as Texture2D,
	"belt_10":           load("res://assets/equipment/belts/belt_10.png") as Texture2D,
	"belt_11":           load("res://assets/equipment/belts/belt_11.png") as Texture2D,
	"belt_12":           load("res://assets/equipment/belts/belt_12.png") as Texture2D,
	"belt_13":           load("res://assets/equipment/belts/belt_13.png") as Texture2D,
	"belt_14":           load("res://assets/equipment/belts/belt_14.png") as Texture2D,
	"belt_15":           load("res://assets/equipment/belts/belt_15.png") as Texture2D,
	"belt_16":           load("res://assets/equipment/belts/belt_16.png") as Texture2D,
	"belt_17":           load("res://assets/equipment/belts/belt_17.png") as Texture2D,
	"belt_18":           load("res://assets/equipment/belts/belt_18.png") as Texture2D,
	"belt_19":           load("res://assets/equipment/belts/belt_19.png") as Texture2D,
	# ===== Chests
	"chest_0":           load("res://assets/equipment/chests/chest_0.png") as Texture2D,
	"chest_1":           load("res://assets/equipment/chests/chest_1.png") as Texture2D,
	"chest_2":           load("res://assets/equipment/chests/chest_2.png") as Texture2D,
	"chest_3":           load("res://assets/equipment/chests/chest_3.png") as Texture2D,
	"chest_4":           load("res://assets/equipment/chests/chest_4.png") as Texture2D,
	"chest_5":           load("res://assets/equipment/chests/chest_5.png") as Texture2D,
	"chest_6":           load("res://assets/equipment/chests/chest_6.png") as Texture2D,
	"chest_7":           load("res://assets/equipment/chests/chest_7.png") as Texture2D,
	"chest_8":           load("res://assets/equipment/chests/chest_8.png") as Texture2D,
	"chest_9":           load("res://assets/equipment/chests/chest_9.png") as Texture2D,
	"chest_10":          load("res://assets/equipment/chests/chest_10.png") as Texture2D,
	"chest_11":          load("res://assets/equipment/chests/chest_11.png") as Texture2D,
	"chest_12":          load("res://assets/equipment/chests/chest_12.png") as Texture2D,
	"chest_13":          load("res://assets/equipment/chests/chest_13.png") as Texture2D,
	"chest_14":          load("res://assets/equipment/chests/chest_14.png") as Texture2D,
	"chest_15":          load("res://assets/equipment/chests/chest_15.png") as Texture2D,
	"chest_16":          load("res://assets/equipment/chests/chest_16.png") as Texture2D,
	"chest_17":          load("res://assets/equipment/chests/chest_17.png") as Texture2D,
	"chest_18":          load("res://assets/equipment/chests/chest_18.png") as Texture2D,
	"chest_19":          load("res://assets/equipment/chests/chest_19.png") as Texture2D,
	# ===== Cloaks
	"cloak_0":           load("res://assets/equipment/cloaks/cloak_0.png") as Texture2D,
	"cloak_1":           load("res://assets/equipment/cloaks/cloak_1.png") as Texture2D,
	"cloak_2":           load("res://assets/equipment/cloaks/cloak_2.png") as Texture2D,
	"cloak_3":           load("res://assets/equipment/cloaks/cloak_3.png") as Texture2D,
	"cloak_4":           load("res://assets/equipment/cloaks/cloak_4.png") as Texture2D,
	"cloak_5":           load("res://assets/equipment/cloaks/cloak_5.png") as Texture2D,
	"cloak_6":           load("res://assets/equipment/cloaks/cloak_6.png") as Texture2D,
	"cloak_7":           load("res://assets/equipment/cloaks/cloak_7.png") as Texture2D,
	"cloak_8":           load("res://assets/equipment/cloaks/cloak_8.png") as Texture2D,
	"cloak_9":           load("res://assets/equipment/cloaks/cloak_9.png") as Texture2D,
	"cloak_10":          load("res://assets/equipment/cloaks/cloak_10.png") as Texture2D,
	"cloak_11":          load("res://assets/equipment/cloaks/cloak_11.png") as Texture2D,
	"cloak_12":          load("res://assets/equipment/cloaks/cloak_12.png") as Texture2D,
	"cloak_13":          load("res://assets/equipment/cloaks/cloak_13.png") as Texture2D,
	"cloak_14":          load("res://assets/equipment/cloaks/cloak_14.png") as Texture2D,
	"cloak_15":          load("res://assets/equipment/cloaks/cloak_15.png") as Texture2D,
	"cloak_16":          load("res://assets/equipment/cloaks/cloak_16.png") as Texture2D,
	"cloak_17":          load("res://assets/equipment/cloaks/cloak_17.png") as Texture2D,
	"cloak_18":          load("res://assets/equipment/cloaks/cloak_18.png") as Texture2D,
	"cloak_19":          load("res://assets/equipment/cloaks/cloak_19.png") as Texture2D,
	# ===== Feet
	"feet_0":            load("res://assets/equipment/feet/feet_0.png") as Texture2D,
	"feet_1":            load("res://assets/equipment/feet/feet_1.png") as Texture2D,
	# ===== Gloves
	"gloves_0":          load("res://assets/equipment/gloves/gloves_0.png") as Texture2D,
	"gloves_1":          load("res://assets/equipment/gloves/gloves_1.png") as Texture2D,
	# ===== Heads
	"head_0":            load("res://assets/equipment/heads/head_0.png") as Texture2D,
	"head_1":            load("res://assets/equipment/heads/head_1.png") as Texture2D,
	# ===== Legs
	"legs_0":            load("res://assets/equipment/legs/legs_0.png") as Texture2D,
	"legs_1":            load("res://assets/equipment/legs/legs_1.png") as Texture2D,
	# ===== Necks
	"neck_0":            load("res://assets/equipment/necks/neck_0.png") as Texture2D,
	"neck_1":            load("res://assets/equipment/necks/neck_1.png") as Texture2D,
	# ===== Rings
	"ring_0":            load("res://assets/equipment/rings/ring_0.png") as Texture2D,
	"ring_1":            load("res://assets/equipment/rings/ring_1.png") as Texture2D,
	# ===== Shields
	"shield_0":          load("res://assets/equipment/shields/shield_0.png") as Texture2D,
	"shield_1":          load("res://assets/equipment/shields/shield_1.png") as Texture2D,
	# ===== Shoulders
	"shoulder_0":        load("res://assets/equipment/shoulders/shoulder_0.png") as Texture2D,
	"shoulder_1":        load("res://assets/equipment/shoulders/shoulder_1.png") as Texture2D,
	# ===== Trinkets
	"trinket_0":         load("res://assets/equipment/trinkets/trinket_0.png") as Texture2D,
	"trinket_1":         load("res://assets/equipment/trinkets/trinket_1.png") as Texture2D,
	# ===== Wrists
	"wrist_0":           load("res://assets/equipment/wrists/wrist_0.png") as Texture2D,
	
		# ===== MAIN_Hand
	"main_hand_sword_0":       load("res://assets/equipment/main_hand/sword/0.png") as Texture2D,
	"main_hand_sword_1":       load("res://assets/equipment/main_hand/sword/1.png") as Texture2D,
	
	"main_hand_bow_0":       load("res://assets/equipment/main_hand/bow/0.png") as Texture2D,
	"main_hand_bow_1":       load("res://assets/equipment/main_hand/bow/1.png") as Texture2D,
	
	"main_hand_axe_0":       load("res://assets/equipment/main_hand/axe/0.png") as Texture2D,
	"main_hand_axe_1":       load("res://assets/equipment/main_hand/axe/1.png") as Texture2D,
	
	"main_hand_staff_0":       load("res://assets/equipment/main_hand/staff/0.png") as Texture2D,
	"main_hand_staff_1":       load("res://assets/equipment/main_hand/staff/1.png") as Texture2D,
	
	# ===== OFF_Hand
	"off_hand_shield_0":       load("res://assets/equipment/off_hand/shield/0.png") as Texture2D,
	"off_hand_shield_1":       load("res://assets/equipment/off_hand/shield/1.png") as Texture2D,
	
	"off_hand_book_0":       load("res://assets/equipment/off_hand/book/0.png") as Texture2D,
	"off_hand_book_1":       load("res://assets/equipment/off_hand/book/1.png") as Texture2D,
		
	# Herbalism
	"dill":              load("res://assets/professions/herbalism/herb_dill.png") as Texture2D,
	"rucola":            load("res://assets/professions/herbalism/herb_rucola.png") as Texture2D,
	"basilicum":         load("res://assets/professions/herbalism/herb_basilicum.png") as Texture2D,
	"manaflower":        load("res://assets/professions/herbalism/herb_manaflower.png") as Texture2D,
	# Alchemy
	"mana_pot":          load("res://assets/professions/alchemy/alchemy_mana_pot.png") as Texture2D,
	"health_pot":        load("res://assets/professions/alchemy/alchemy_health_pot.png") as Texture2D,
	# Hunting
	"trash":             load("res://assets/professions/hunting/hunting_trash.png") as Texture2D,
	"mice_fur":          load("res://assets/professions/hunting/hunting_mice_fur.png") as Texture2D,
	"rabbit_fur":        load("res://assets/professions/hunting/hunting_rabbit_fur.png") as Texture2D,
	"snake_head":        load("res://assets/professions/hunting/hunting_snake_head.png") as Texture2D,
	# Mining
	"common_copper_ore": load("res://assets/professions/mining/common_copper_ore.png") as Texture2D,
	"common_tin_ore":    load("res://assets/professions/mining/common_tin_ore.png") as Texture2D,
	# Woodcutting
	"common_birch_log":  load("res://assets/professions/woodcutting/common_birch_log.png") as Texture2D,
	# Fishing
	"fish_0":            load("res://assets/professions/fishing/fish_0.png") as Texture2D,
	"fish_1":            load("res://assets/professions/fishing/fish_1.png") as Texture2D,
}

var ICONS = {
	# global icons
	"steps":                load("res://assets/general_icons/steps.png") as Texture2D,
	"gold_coin":            load("res://assets/general_icons/gold_coin.png") as Texture2D,
	
	# attributes icons
	"armor_penetration":    load("res://assets/general_icons/attributes/armor_penetration.png") as Texture2D,
	"attributes_luck":      load("res://assets/general_icons/attributes/attribute_luck.png") as Texture2D,
	"attributes_agility":   load("res://assets/general_icons/attributes/attribute_agility.png") as Texture2D,
	"attributes_intellect": load("res://assets/general_icons/attributes/attribute_intellect.png") as Texture2D,
	"attributes_spirit":    load("res://assets/general_icons/attributes/attribute_spirit.png") as Texture2D,
	"attributes_strength":  load("res://assets/general_icons/attributes/attribute_strength.png") as Texture2D,
	"attributes_vitality":  load("res://assets/general_icons/attributes/attribute_vitality.png") as Texture2D,
	"block_chance":         load("res://assets/general_icons/attributes/block_chance.png") as Texture2D,
	"critical_chance":      load("res://assets/general_icons/attributes/critical_chance.png") as Texture2D,
	"critical_damage":      load("res://assets/general_icons/attributes/critical_damage.png") as Texture2D,
	"damage_reduction":     load("res://assets/general_icons/attributes/damage_reduction.png") as Texture2D,
	"dodge":                load("res://assets/general_icons/attributes/dodge.png") as Texture2D,
	"haste":                load("res://assets/general_icons/attributes/haste.png") as Texture2D,
	"hit_rating":           load("res://assets/general_icons/attributes/hit_rating.png") as Texture2D,
	"magical_attack":       load("res://assets/general_icons/attributes/magical_attack.png") as Texture2D,
	"magical_defence":      load("res://assets/general_icons/attributes/magical_defence.png") as Texture2D,
	"magical_penetration":  load("res://assets/general_icons/attributes/magical_penetration.png") as Texture2D,
	"physical_attack":      load("res://assets/general_icons/attributes/physical_attack.png") as Texture2D,
	"physical_defence":     load("res://assets/general_icons/attributes/physical_defence.png") as Texture2D,
	"versatility":          load("res://assets/general_icons/attributes/versatility.png") as Texture2D,
	
	# professions icons
	"alchemy":              load("res://assets/general_icons/professions/alchemy.png") as Texture2D,
	"herbalism":            load("res://assets/general_icons/professions/herbalism.png") as Texture2D,
	"hunting":              load("res://assets/general_icons/professions/hunting.png") as Texture2D,
	"mining":               load("res://assets/general_icons/professions/mining.png") as Texture2D,
	"woodcutting":          load("res://assets/general_icons/professions/woodcutting.png") as Texture2D,
	"fishing":              load("res://assets/general_icons/professions/fishing.png") as Texture2D,
	"blacksmith":           load("res://assets/general_icons/professions/blacksmith.png") as Texture2D,
	"rift":                 load("res://assets/general_icons/professions/rift.png") as Texture2D,
	
	# talents
	"thick_skin":           load("res://assets/general_icons/passive_talents/thick_skin.png") as Texture2D,
	"brutal_strike":        load("res://assets/general_icons/passive_talents/brutal_strike.png") as Texture2D,
	"guardian_shell":       load("res://assets/general_icons/passive_talents/guardian_shell.png") as Texture2D,
	"evasion_training":     load("res://assets/general_icons/passive_talents/evasion_training.png") as Texture2D,
	
	# skills
	"buff_attack_up":       load("res://assets/skills/buffs/buff_attack_up.png") as Texture2D,
	"buff_hp_up":           load("res://assets/skills/buffs/buff_hp_up.png") as Texture2D,
	"buff_improved_shield": load("res://assets/skills/buffs/buff_improved_shield.png") as Texture2D,
	"buff_shield_regeneration": load("res://assets/skills/buffs/buff_shield_regeneration.png") as Texture2D,
	
	"mage_fireball":        load("res://assets/skills/mage/mage_fireball.png") as Texture2D,
	"mage_frostshield":     load("res://assets/skills/mage/mage_frostshield.png") as Texture2D,
	"mage_frostbolt":       load("res://assets/skills/mage/mage_frostbolt.png") as Texture2D,
	"mage_pyroblast":       load("res://assets/skills/mage/mage_pyroblast.png") as Texture2D,
	
	"paladin_minorheal":         load("res://assets/skills/paladin/paladin_minorheal.png") as Texture2D,
	"paladin_regeneration":      load("res://assets/skills/paladin/paladin_regeneration.png") as Texture2D,
	"paladin_crusader_strike":   load("res://assets/skills/paladin/paladin_crusader_strike.png") as Texture2D,
	"paladin_holy_sword":        load("res://assets/skills/paladin/paladin_holy_sword.png") as Texture2D,
	"paladin_hummer_of_justice": load("res://assets/skills/paladin/paladin_hummer_of_justice.png") as Texture2D,
	"paladin_judgement":         load("res://assets/skills/paladin/paladin_judgement.png") as Texture2D,
	"paladin_lay_of_hands":      load("res://assets/skills/paladin/paladin_lay_of_hands.png") as Texture2D,
	"paladin_wrath":             load("res://assets/skills/paladin/paladin_wrath.png") as Texture2D,
}

# ── World waypoints ──────────────────────────────────────────────────────────
# key   : unique location ID used in waypoint_pressed signal
# value : map position as ratio Vector2(x, y) in range 0.0–1.0
var WAYPOINTS: Dictionary = {
	"starter_village": Vector2(0.33, 0.42),
	"ancient_forest":  Vector2(0.38, 0.31),
	"dark_swamp":      Vector2(0.39, 0.55),
	"mountains":       Vector2(0.57, 0.26),
	"iron_mountain":   Vector2(0.68, 0.27),
	"human_village":   Vector2(0.72, 0.35),
	"tower":           Vector2(0.84, 0.56),
	"sunken_harbor":   Vector2(0.49, 0.81),
	"dragon_lair":     Vector2(0.58, 0.50),
	"ancient_place":   Vector2(0.77, 0.74),
}

# Display names for server location IDs — mirrors server LOCATION_DICT
var LOCATION_NAMES: Dictionary = {
	1:  "A little Tent location",
	2:  "Ancient Forest",
	3:  "Dark Swamp",
	4:  "The Mountains",
	5:  "Iron Mountain",
	6:  "Human Village",
	7:  "The Tower",
	8:  "Sunken Harbor",
	9:  "Dragon Lair",
	10: "Ancient Place",
}

# Maps waypoint string IDs -> server integer location IDs
var WAYPOINT_LOCATION_IDS: Dictionary = {
	"starter_village": 1,
	"ancient_forest":  2,
	"dark_swamp":      3,
	"mountains":       4,
	"iron_mountain":   5,
	"human_village":   6,
	"tower":           7,
	"sunken_harbor":   8,
	"dragon_lair":     9,
	"ancient_place":   10,
}

# Equipment rows
var slots_left: Array[String]  = ["head", "shoulder", "cloak", "chest", "wrist", "ring_left", "trinket_left", "main_hand"]
var slots_right: Array[String] = ["neck", "gloves",   "belt",  "legs",  "feet",  "ring_right", "trinket_right", "off_hand"]
var all_slots: Array[String]  = [
	"head", "shoulder", "cloak", "chest", "wrist", "ring_left", "trinket_left", "main_hand",
	"neck", "gloves",   "belt",  "legs",  "feet",  "ring_right", "trinket_right", "off_hand",
]
