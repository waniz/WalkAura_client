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

# passives
var thick_skin_lvl
var thick_skin_xp
var brutal_finish_lvl
var brutal_finish_xp
var magic_ward_lvl
var magic_ward_xp
var guardian_shell_lvl
var guardian_shell_xp
var evasion_training_lvl
var evasion_training_xp
var mana_flow_lvl
var mana_flow_xp
var regenerative_steps_lvl
var regenerative_steps_xp

# secondary parameters
var atk
var m_atk
var hit_rating
var crit_chance_rating
var crit_damage_rating
var haste_rating
var armor_pen_rating
var magic_pen_rating
var p_def_rating
var m_def_rating
var block_chance_rating
var dodge_rating
var dmg_reduction_rating
var versatility_rating
var hit
var crit_chance
var crit_damage
var haste
var armor_pen
var magic_pen
var p_def
var m_def
var block_chance
var dodge
var dmg_reduction
var versatility

var location
var activity
var activity_site
var account_step_carry

# rift statuses
var rift_id
var rift_steps
var rift_steps_max
var rift_milestone_index
var rift_total_milestones
var rift_instance_id
var rift_lvl
var rift_xp

var variance
var vit_crit_soften
var spirit_healing_mult

# structures to keep autoloaded
var raw_structures = {
	"all_server_skills": null,
	"account_skills": null,
}

func to_dict() -> Dictionary:
	# export everything (flat), matching server keys
	var out := {}
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			var name = p.name
			# skip signals/constants/methods
			if has_method(name):
				continue
			if p.name == "raw_structures":
				continue
			out[name] = get(name)
	return out
