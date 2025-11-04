extends Node

var ITEM_DEFS = {
	# Equipment
	"default_head":      {"name":"default_head",     "quality": 4, "descr":"Default Head",    "slot": "head", "stackable":false, "max_stack":1, "attrs": {"STR": "+1"}},
	"default_neck":      {"name":"default_neck",     "quality": 4, "descr":"Default Neck",    "slot": "neck", "stackable":false, "max_stack":1, "attrs": {"VIT": "+1"}},
	"default_shoulder":  {"name":"default_shoulder", "quality": 4, "descr":"Default Shoulder","slot": "shoulder", "stackable":false, "max_stack":1, "attrs": {"VIT": "+1"}},
	"default_cloak":     {"name":"default_cloak",    "quality": 4, "descr":"Default Cloak",   "slot": "cloak", "stackable":false, "max_stack":1, "attrs": {"INT": "+1"}},
	"default_chest":     {"name":"default_chest",    "quality": 4, "descr":"Default Chest",   "slot": "chest", "stackable":false, "max_stack":1, "attrs": {"VIT": "+1"}},
	"default_wrist":     {"name":"default_wrist",    "quality": 4, "descr":"Default Wrist",   "slot": "wrist", "stackable":false, "max_stack":1, "attrs": {"AGI": "+1"}},

	# Herbalism
	"dill":          {"name":"Dill",        "quality": 1, "descr":"Fresh herb",      "stackable":true, "max_stack":999, "attrs": {"loot": "Herbalism"}},
	"rucola":        {"name":"Rucola",      "quality": 2, "descr":"Gleaming bloom",  "stackable":true, "max_stack":999, "attrs": {"loot": "Herbalism"}},
	"basilicum":     {"name":"Basilicum",   "quality": 3, "descr":"Gleaming bloom",  "stackable":true, "max_stack":999, "attrs": {"loot": "Herbalism"}},
	"manaflower":    {"name":"Manaflower",  "quality": 4, "descr":"Gleaming bloom",  "stackable":true, "max_stack":999, "attrs": {"loot": "Herbalism"}},
	# Alchemy
	"mana_pot":      {"name":"Mana pot",    "quality": 5, "descr":"Mana Recovery Pot",    "stackable":true, "max_stack":999, "attrs": {"loot": "Alchemy", "MP": 10}},
	"health_pot":    {"name":"Health pot",  "quality": 6, "descr":"Health Recovery Pot",  "stackable":true, "max_stack":999, "attrs": {"loot": "Alchemy", "HP": 20}},
}
	
var ITEM_ICONS = {
	# Equipment
	"default_head":      load("res://assets/equipment/head/default_helm.png") as Texture2D,
	"default_neck":      load("res://assets/equipment/neck/default_necklare.png") as Texture2D,
	"default_shoulder":  load("res://assets/equipment/shoulder/default_shoulder.png") as Texture2D,
	"default_cloak":     load("res://assets/equipment/cloak/default_cloak.png") as Texture2D,
	"default_chest":     load("res://assets/equipment/chest/default_chest.png") as Texture2D,
	"default_wrist":     load("res://assets/equipment/wrist/default_wrist.png") as Texture2D,
	# Herbalism
	"dill":          load("res://assets/professions/herbalism/herb_dill.png") as Texture2D,
	"rucola":        load("res://assets/professions/herbalism/herb_rucola.png") as Texture2D,
	"basilicum":     load("res://assets/professions/herbalism/herb_basilicum.png") as Texture2D,
	"manaflower":    load("res://assets/professions/herbalism/herb_manaflower.png") as Texture2D,
	# Alchemy
	"mana_pot":      load("res://assets/professions/alchemy/alchemy_mana_pot.png") as Texture2D,
	"health_pot":    load("res://assets/professions/alchemy/alchemy_health_pot.png") as Texture2D,
}


@export var slots_left: Array[String]  = ["Head","Neck","Shoulder","Back","Chest","Wrist"]
@export var slots_right: Array[String] = ["Gloves","Belt","Legs","Feet","Ring1","Ring2","Trinket1","Trinket2"]

# NEW: bottom weapon row
@export var slots_bottom: Array[String] = ["MainHand","OffHand"]
