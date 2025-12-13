extends Node

#var ITEM_DEFS = {
	## Equipment codes
	#"noob_head":      {"name":"default_head",      "descr":"Default Head",     "category": "equipment", "slot_type": "head",     "quality": 1, "stackable":false, "max_stack":1, "attrs": {"STR": "+1"}},
	#"noob_neck":      {"name":"default_neck",      "descr":"Default Neck",     "category": "equipment", "slot_type": "neck",     "quality": 2, "stackable":false, "max_stack":1, "attrs": {"VIT": "+1"}},
	#"noob_shoulder":  {"name":"default_shoulder",  "descr":"Default Shoulder", "category": "equipment", "slot_type": "shoulder", "quality": 3, "stackable":false, "max_stack":1, "attrs": {"VIT": "+1"}},
	#"noob_cloak":     {"name":"default_cloak",     "descr":"Default Cloak",    "category": "equipment", "slot_type": "cloak",    "quality": 4, "stackable":false, "max_stack":1, "attrs": {"INT": "+1"}},
	#"noob_chest":     {"name":"default_chest",     "descr":"Default Chest",    "category": "equipment", "slot_type": "chest",    "quality": 5, "stackable":false, "max_stack":1, "attrs": {"VIT": "+1"}},
	#"noob_wrist":     {"name":"default_wrist",     "descr":"Default Wrist",    "category": "equipment", "slot_type": "wrist",    "quality": 6, "stackable":false, "max_stack":1, "attrs": {"AGI": "+1"}},
	#"test_ring":      {"name":"noob_ring_left",    "descr":"Default Ring 1",   "category": "equipment", "slot_type": "ring_left","quality": 3, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_trinket":   {"name":"noob_trinket_left", "descr":"Default Trinket 1","category": "equipment", "slot_type": "trinket_left","quality": 4, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_staff":     {"name":"noob_staff",        "descr":"Default Staff",    "category": "equipment", "slot_type": "main_hand","quality": 5, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_gloves":    {"name":"noob_gloves",        "descr":"Default Gloves",   "category": "equipment", "slot_type": "gloves",       "quality": 6, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_belt":      {"name":"noob_belt",          "descr":"Default Belt",     "category": "equipment", "slot_type": "belt",         "quality": 5, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_legs":      {"name":"noob_legs",          "descr":"Default Legs",     "category": "equipment", "slot_type": "legs",         "quality": 4, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_feet":      {"name":"noob_feet",          "descr":"Default Feet",     "category": "equipment", "slot_type": "feet",         "quality": 3, "stackable":false, "max_stack":1, "attrs": {}},
	#"test_shield":    {"name":"noob_shield",        "descr":"Default Shield",   "category": "equipment", "slot_type": "off_hand",     "quality": 0, "stackable":false, "max_stack":1, "attrs": {}},
#
	## Herbalism codes
	#"dill":           {"name":"Dill",         "descr":"Fresh Dill",       "category": "material", "slot_type": null, "quality": 0, "stackable":true, "max_stack":1000, "attrs": {}},
	#"rucola":         {"name":"Rucola",       "descr":"Fresh Rucola",     "category": "material", "slot_type": null, "quality": 0, "stackable":true, "max_stack":1000, "attrs": {}},
	#"basilicum":      {"name":"Basilicum",    "descr":"Fresh Basilicum",  "category": "material", "slot_type": null, "quality": 1, "stackable":true, "max_stack":1000, "attrs": {}},
	#"manaflower":     {"name":"Manaflower",   "descr":"Fresh Manaflower", "category": "material", "slot_type": null, "quality": 2, "stackable":true, "max_stack":1000, "attrs": {}},
	#
	## Alchemy codes
	#"mana_pot":       {"name":"mana_pot",   "descr":"Mana Recovery Pot",   "category": "material", "slot_type": null, "quality": 1,  "stackable":true, "max_stack":1000, "attrs": {"MP": 10}},
	#"health_pot":     {"name":"health_pot", "descr":"Health Recovery Pot", "category": "material", "slot_type": null, "quality": 1,  "stackable":true, "max_stack":1000, "attrs": {"HP": 20}},
	#
	## Hunting codes
	#"trash":          {"name":"trash",      "descr":"Trash",                     "category": "material", "slot_type": null, "quality": 1,  "stackable":true, "max_stack":1000, "attrs": {}},
	#"mice_fur":       {"name":"mice_fur",   "descr":"Small piece of mice fur",   "category": "material", "slot_type": null, "quality": 1,  "stackable":true, "max_stack":1000, "attrs": {}},
	#"rabbit_fur":     {"name":"rabbit_fur", "descr":"Small piece of rabbit fur", "category": "material", "slot_type": null, "quality": 1,  "stackable":true, "max_stack":1000, "attrs": {}},
	#"snake_head":     {"name":"snake_head", "descr":"The head from snake",       "category": "material", "slot_type": null, "quality": 1,  "stackable":true, "max_stack":1000, "attrs": {}},
#}


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
}

# Equipment rows
var slots_left: Array[String]  = ["head", "shoulder", "cloak", "chest", "wrist", "ring_left", "trinket_left", "main_hand"]
var slots_right: Array[String] = ["neck", "gloves",   "belt",  "legs",  "feet",  "ring_right", "trinket_right", "off_hand"]
