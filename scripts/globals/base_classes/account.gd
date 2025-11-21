extends Node

# main identifiers
var user_uid
var userid
var username

# primary parameters
var str
var agi
var vit
var int_stat
var spi
var luk

var str_exp
var agi_exp
var vit_exp
var int_exp
var spi_exp
var luk_exp

var bonus_str
var bonus_agi
var bonus_vit
var bonus_int
var bonus_spi
var bonus_luk

# primary_resources
var hp
var mp
var shield
var hp_max
var mp_max
var shield_max
var level
var level_exp
var total_steps
var buffer_steps
var buffer_steps_max
var gold

# professions
var herbalism_lvl
var mining_lvl
var woodcutting_lvl
var fishing_lvl
var hunting_lvl
var blacksmithing_lvl
var tailoring_lvl
var jewelcrafting_lvl
var alchemy_lvl
var cooking_lvl
var enchanting_lvl

var herbalism_xp
var mining_xp
var woodcutting_xp
var fishing_xp
var hunting_xp
var blacksmithing_xp
var tailoring_xp
var jewelcrafting_xp
var alchemy_xp
var cooking_xp
var enchanting_xp

# secondary parameters
var atk
var m_atk
var hit_rating
var crit_chance
var crit_damage
var haste
var armor_pen
var magic_pen

var p_def
var m_def
var block_chance
var evasion
var dmg_reduction

var res_fire
var res_frost
var res_lightning
var res_poison
var res_death
var res_holy

var location
var activity
var activity_site
var account_step_carry

var variance
var vit_crit_soften
var spirit_healing_mult

func to_dict() -> Dictionary:
	# export everything (flat), matching server keys
	var out := {}
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			var name = p.name
			# skip signals/constants/methods
			if has_method(name): continue
			out[name] = get(name)
	return out
