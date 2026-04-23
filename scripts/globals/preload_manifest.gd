extends Node
## Static manifest of resources preloaded during the login → location transition.
##
## Used by login_scene.gd: every path here is dispatched to
## ResourceLoader.load_threaded_request() when the player taps "Play". The
## progress bar counts finished loads; the scene transition fires when the
## whole list is cached AND server account data has arrived.
##
## What belongs here: ONLY resources that get touched on the first post-login
## frame. Everything else should stay lazy-loaded via ItemDB.
##
## If you add a new main screen or a first-render icon, add it below. Missing
## paths are non-fatal at runtime (THREAD_LOAD_INVALID_RESOURCE just counts as
## "done" and logs), but the point of this file is to keep the manifest honest.

const PRELOAD_SCENES: Array[String] = [
	"res://scenes/app_scenes_handler.tscn",
	"res://scenes/main_screens/character_profile.tscn",
	"res://scenes/main_screens/character_inventory.tscn",
	"res://scenes/main_screens/character_skills.tscn",
	"res://scenes/main_screens/location_hub.tscn",
	"res://scenes/hud/global_hud.tscn",
]


const PRELOAD_ICON_PATHS: Array[String] = [
	# Achievement icons are lazy — the Achievements tab is 2-3 taps deep, not
	# first-frame. `ItemDB.get_achievement_icon()` loads on demand when the
	# tab opens; first-open stutter is acceptable and avoids inflating this
	# preload bar with irrelevant work.

	# General HUD / currency — first-frame on the HUD strip
	"res://assets/general_icons/steps.png",
	"res://assets/general_icons/gold_coin.png",
	"res://assets/general_icons/hud/buttom_hud_skills.png",

	# HUD buff icons — render the instant a buff is active in the status row
	"res://assets/skills/buffs/buff_attack_up.png",
	"res://assets/skills/buffs/buff_hp_up.png",
	"res://assets/skills/buffs/buff_improved_shield.png",
	"res://assets/skills/buffs/buff_shield_regeneration.png",
	"res://assets/skills/buffs/buff_barrier.png",
	"res://assets/skills/buffs/buff_battle_fury.png",
	"res://assets/skills/buffs/buff_reflect.png",
	"res://assets/skills/buffs/buff_second_wind.png",
	"res://assets/skills/buffs/buff_fortify.png",
	"res://assets/skills/buffs/buff_iron_skin.png",
	"res://assets/skills/buffs/buff_mana_surge.png",
	"res://assets/skills/buffs/buff_meditation.png",
	"res://assets/skills/buffs/buff_adrenaline_rush.png",
	"res://assets/skills/buffs/buff_weaken.png",
	"res://assets/skills/buffs/buff_cripple.png",
	"res://assets/skills/buffs/buff_expose_weakness.png",

	# Attribute icons — primary + armor pen (shown on profile)
	"res://assets/general_icons/attributes/attribute_strength.png",
	"res://assets/general_icons/attributes/attribute_agility.png",
	"res://assets/general_icons/attributes/attribute_vitality.png",
	"res://assets/general_icons/attributes/attribute_intellect.png",
	"res://assets/general_icons/attributes/attribute_spirit.png",
	"res://assets/general_icons/attributes/attribute_luck.png",
	"res://assets/general_icons/attributes/armor_penetration.png",

	# Spell-damage icons — shown on skills screen + secondary attributes
	"res://assets/general_icons/attributes/fire.png",
	"res://assets/general_icons/attributes/frost.png",
	"res://assets/general_icons/attributes/arcane.png",
	"res://assets/general_icons/attributes/holy.png",
	"res://assets/general_icons/attributes/dark.png",
	"res://assets/general_icons/attributes/blood.png",

	# Profession icons — shown on profile Professions tab
	"res://assets/general_icons/professions/alchemy.png",
	"res://assets/general_icons/professions/herbalism.png",
	"res://assets/general_icons/professions/hunting.png",
	"res://assets/general_icons/professions/mining.png",
	"res://assets/general_icons/professions/woodcutting.png",
	"res://assets/general_icons/professions/fishing.png",
	"res://assets/general_icons/professions/blacksmith.png",
	"res://assets/general_icons/professions/rift.png",
	"res://assets/general_icons/professions/enchanting.png",

	# Passive talent icons — talent panel on profile/skills
	"res://assets/general_icons/passive_talents/thick_skin.png",
	"res://assets/general_icons/passive_talents/brutal_strike.png",
	"res://assets/general_icons/passive_talents/guardian_shell.png",
	"res://assets/general_icons/passive_talents/evasion_training.png",
	"res://assets/general_icons/passive_talents/magic_ward.png",
	"res://assets/general_icons/passive_talents/mana_flow.png",
	"res://assets/general_icons/passive_talents/regenerative_steps.png",
	"res://assets/general_icons/passive_talents/second_wind.png",
	"res://assets/general_icons/passive_talents/fortitude.png",
	"res://assets/general_icons/passive_talents/battle_rhythm.png",
	"res://assets/general_icons/passive_talents/gathering_wisdom.png",
	"res://assets/general_icons/passive_talents/step_momentum.png",
	"res://assets/general_icons/passive_talents/alchemists_touch.png",

	# Class-specific talent icons — shown on skills/talents screen
	"res://assets/skills/mage/pyromaniac.png",
	"res://assets/skills/mage/permafrost.png",
	"res://assets/skills/paladin/devotion.png",
	"res://assets/skills/dark/shadow_mastery.png",
	"res://assets/skills/arcane/arcane_mastery.png",
	"res://assets/skills/blood/blood_pact.png",

	# Location background — starter village first-open
	"res://assets/locations/starter_village/background.png",
]


## Returns the full flat list of paths the login scene should preload.
func get_manifest() -> Array[String]:
	var out: Array[String] = []
	out.append_array(PRELOAD_SCENES)
	out.append_array(PRELOAD_ICON_PATHS)
	return out


## Returns total resource count — used by login scene to size the progress bar
## without duplicating the addition in multiple places.
func total_count() -> int:
	return PRELOAD_SCENES.size() + PRELOAD_ICON_PATHS.size()
