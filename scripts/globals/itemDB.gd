extends Node

var ITEM_ICONS = {
	# Equipment
	"test_head":         load("res://assets/equipment/heads/default_helm.png") as Texture2D,
	"test_neck":         load("res://assets/equipment/necks/default_necklare.png") as Texture2D,
	"test_shoulder":     load("res://assets/equipment/shoulders/default_shoulder.png") as Texture2D,
	"test_cloak":        load("res://assets/equipment/cloaks/default_cloak.png") as Texture2D,
	"test_chest":        load("res://assets/equipment/chests/default_chest.png") as Texture2D,
	"test_wrist":        load("res://assets/equipment/wrists/default_wrist.png") as Texture2D,
	"test_ring":         load("res://assets/equipment/rings/default_ring.png") as Texture2D,
	"test_trinket":      load("res://assets/equipment/trinkets/default_trinket.png") as Texture2D,
	"test_staff":        load("res://assets/equipment/staffs/default_staff.png") as Texture2D,
	"test_gloves":       load("res://assets/equipment/gloves/default_gloves.png") as Texture2D,
	"test_belt":         load("res://assets/equipment/belts/default_belt.png") as Texture2D,
	"test_legs":         load("res://assets/equipment/legs/default_legs.png") as Texture2D,
	"test_feet":         load("res://assets/equipment/feet/default_feet.png") as Texture2D,
	"test_shield":       load("res://assets/equipment/shields/default_shield.png") as Texture2D,
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
	"evasion":              load("res://assets/general_icons/attributes/evasion.png") as Texture2D,
	"haste":                load("res://assets/general_icons/attributes/haste.png") as Texture2D,
	"hit_rating":           load("res://assets/general_icons/attributes/hit_rating.png") as Texture2D,
	"magical_attack":       load("res://assets/general_icons/attributes/magical_attack.png") as Texture2D,
	"magical_defence":      load("res://assets/general_icons/attributes/magical_defence.png") as Texture2D,
	"magical_penetration":  load("res://assets/general_icons/attributes/magical_penetration.png") as Texture2D,
	"physical_attack":      load("res://assets/general_icons/attributes/physical_attack.png") as Texture2D,
	"physical_defence":     load("res://assets/general_icons/attributes/physical_defence.png") as Texture2D,
	
	# professions icons
	"alchemy":              load("res://assets/general_icons/professions/alchemy.png") as Texture2D,
	"herbalism":            load("res://assets/general_icons/professions/herbalism.png") as Texture2D,
	"hunting":              load("res://assets/general_icons/professions/hunting.png") as Texture2D,
	"mining":               load("res://assets/general_icons/professions/mining.png") as Texture2D,
	"woodcutting":          load("res://assets/general_icons/professions/woodcutting.png") as Texture2D,
	"fishing":              load("res://assets/general_icons/professions/fishing.png") as Texture2D,
	
	# talents
	"thick_skin":           load("res://assets/general_icons/passive_talents/thick_skin.png") as Texture2D,
	"brutal_strike":        load("res://assets/general_icons/passive_talents/brutal_strike.png") as Texture2D,
	"guardian_shell":       load("res://assets/general_icons/passive_talents/guardian_shell.png") as Texture2D,
	"evasion_training":     load("res://assets/general_icons/passive_talents/evasion_training.png") as Texture2D,
}

# Equipment rows
var slots_left: Array[String]  = ["head", "shoulder", "cloak", "chest", "wrist", "ring_left", "trinket_left", "main_hand"]
var slots_right: Array[String] = ["neck", "gloves",   "belt",  "legs",  "feet",  "ring_right", "trinket_right", "off_hand"]
