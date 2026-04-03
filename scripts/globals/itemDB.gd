extends Node

# ── Lazy-loaded texture registries ──────────────────────────────────────────
# Paths are stored at startup; actual Texture2D objects are loaded on first access
# and cached for subsequent lookups.  This avoids loading 200+ textures into RAM
# at boot and reduces startup time / baseline memory on mobile.

var _item_icon_paths = {
	# Equipment
	# ===== Belts
	"belt_0":            "res://assets/equipment/belts/belt_0.png",
	"belt_1":            "res://assets/equipment/belts/belt_1.png",
	"belt_2":            "res://assets/equipment/belts/belt_2.png",
	"belt_3":            "res://assets/equipment/belts/belt_3.png",
	"belt_4":            "res://assets/equipment/belts/belt_4.png",
	"belt_5":            "res://assets/equipment/belts/belt_5.png",
	"belt_6":            "res://assets/equipment/belts/belt_6.png",
	"belt_7":            "res://assets/equipment/belts/belt_7.png",
	"belt_8":            "res://assets/equipment/belts/belt_8.png",
	"belt_9":            "res://assets/equipment/belts/belt_9.png",
	"belt_10":           "res://assets/equipment/belts/belt_10.png",
	"belt_11":           "res://assets/equipment/belts/belt_11.png",
	"belt_12":           "res://assets/equipment/belts/belt_12.png",
	"belt_13":           "res://assets/equipment/belts/belt_13.png",
	"belt_14":           "res://assets/equipment/belts/belt_14.png",
	"belt_15":           "res://assets/equipment/belts/belt_15.png",
	"belt_16":           "res://assets/equipment/belts/belt_16.png",
	"belt_17":           "res://assets/equipment/belts/belt_17.png",
	"belt_18":           "res://assets/equipment/belts/belt_18.png",
	"belt_19":           "res://assets/equipment/belts/belt_19.png",
	# ===== Chests
	"chest_0":           "res://assets/equipment/chests/chest_0.png",
	"chest_1":           "res://assets/equipment/chests/chest_1.png",
	"chest_2":           "res://assets/equipment/chests/chest_2.png",
	"chest_3":           "res://assets/equipment/chests/chest_3.png",
	"chest_4":           "res://assets/equipment/chests/chest_4.png",
	"chest_5":           "res://assets/equipment/chests/chest_5.png",
	"chest_6":           "res://assets/equipment/chests/chest_6.png",
	"chest_7":           "res://assets/equipment/chests/chest_7.png",
	"chest_8":           "res://assets/equipment/chests/chest_8.png",
	"chest_9":           "res://assets/equipment/chests/chest_9.png",
	"chest_10":          "res://assets/equipment/chests/chest_10.png",
	"chest_11":          "res://assets/equipment/chests/chest_11.png",
	"chest_12":          "res://assets/equipment/chests/chest_12.png",
	"chest_13":          "res://assets/equipment/chests/chest_13.png",
	"chest_14":          "res://assets/equipment/chests/chest_14.png",
	"chest_15":          "res://assets/equipment/chests/chest_15.png",
	"chest_16":          "res://assets/equipment/chests/chest_16.png",
	"chest_17":          "res://assets/equipment/chests/chest_17.png",
	"chest_18":          "res://assets/equipment/chests/chest_18.png",
	"chest_19":          "res://assets/equipment/chests/chest_19.png",
	# ===== Cloaks
	"cloak_0":           "res://assets/equipment/cloaks/cloak_0.png",
	"cloak_1":           "res://assets/equipment/cloaks/cloak_1.png",
	"cloak_2":           "res://assets/equipment/cloaks/cloak_2.png",
	"cloak_3":           "res://assets/equipment/cloaks/cloak_3.png",
	"cloak_4":           "res://assets/equipment/cloaks/cloak_4.png",
	"cloak_5":           "res://assets/equipment/cloaks/cloak_5.png",
	"cloak_6":           "res://assets/equipment/cloaks/cloak_6.png",
	"cloak_7":           "res://assets/equipment/cloaks/cloak_7.png",
	"cloak_8":           "res://assets/equipment/cloaks/cloak_8.png",
	"cloak_9":           "res://assets/equipment/cloaks/cloak_9.png",
	"cloak_10":          "res://assets/equipment/cloaks/cloak_10.png",
	"cloak_11":          "res://assets/equipment/cloaks/cloak_11.png",
	"cloak_12":          "res://assets/equipment/cloaks/cloak_12.png",
	"cloak_13":          "res://assets/equipment/cloaks/cloak_13.png",
	"cloak_14":          "res://assets/equipment/cloaks/cloak_14.png",
	"cloak_15":          "res://assets/equipment/cloaks/cloak_15.png",
	"cloak_16":          "res://assets/equipment/cloaks/cloak_16.png",
	"cloak_17":          "res://assets/equipment/cloaks/cloak_17.png",
	"cloak_18":          "res://assets/equipment/cloaks/cloak_18.png",
	"cloak_19":          "res://assets/equipment/cloaks/cloak_19.png",
	# ===== Feet
	"feet_0":            "res://assets/equipment/feet/feet_0.png",
	"feet_1":            "res://assets/equipment/feet/feet_1.png",
	# ===== Gloves
	"gloves_0":          "res://assets/equipment/gloves/gloves_0.png",
	"gloves_1":          "res://assets/equipment/gloves/gloves_1.png",
	# ===== Heads
	"head_0":            "res://assets/equipment/heads/head_0.png",
	"head_1":            "res://assets/equipment/heads/head_1.png",
	# ===== Legs
	"legs_0":            "res://assets/equipment/legs/legs_0.png",
	"legs_1":            "res://assets/equipment/legs/legs_1.png",
	# ===== Necks
	"neck_0":            "res://assets/equipment/necks/neck_0.png",
	"neck_1":            "res://assets/equipment/necks/neck_1.png",
	# ===== Rings
	"ring_0":            "res://assets/equipment/rings/ring_0.png",
	"ring_1":            "res://assets/equipment/rings/ring_1.png",
	# ===== Shields
	"shield_0":          "res://assets/equipment/shields/shield_0.png",
	"shield_1":          "res://assets/equipment/shields/shield_1.png",
	# ===== Shoulders
	"shoulder_0":        "res://assets/equipment/shoulders/shoulder_0.png",
	"shoulder_1":        "res://assets/equipment/shoulders/shoulder_1.png",
	# ===== Trinkets
	"trinket_0":         "res://assets/equipment/trinkets/trinket_0.png",
	"trinket_1":         "res://assets/equipment/trinkets/trinket_1.png",
	# ===== Wrists
	"wrist_0":           "res://assets/equipment/wrists/wrist_0.png",

		# ===== MAIN_Hand
	"main_hand_sword_0":       "res://assets/equipment/main_hand/sword/0.png",
	"main_hand_sword_1":       "res://assets/equipment/main_hand/sword/1.png",

	"main_hand_bow_0":       "res://assets/equipment/main_hand/bow/0.png",
	"main_hand_bow_1":       "res://assets/equipment/main_hand/bow/1.png",

	"main_hand_axe_0":       "res://assets/equipment/main_hand/axe/0.png",
	"main_hand_axe_1":       "res://assets/equipment/main_hand/axe/1.png",

	"main_hand_staff_0":       "res://assets/equipment/main_hand/staff/0.png",
	"main_hand_staff_1":       "res://assets/equipment/main_hand/staff/1.png",

	# ===== OFF_Hand
	"off_hand_shield_0":       "res://assets/equipment/off_hand/shield/0.png",
	"off_hand_shield_1":       "res://assets/equipment/off_hand/shield/1.png",

	"off_hand_book_0":       "res://assets/equipment/off_hand/book/0.png",
	"off_hand_book_1":       "res://assets/equipment/off_hand/book/1.png",

	# Herbalism
	"dill":              "res://assets/professions/herbalism/herb_dill.png",
	"rucola":            "res://assets/professions/herbalism/herb_rucola.png",
	"basilicum":         "res://assets/professions/herbalism/herb_basilicum.png",
	"manaflower":        "res://assets/professions/herbalism/herb_manaflower.png",
	"fadeleaf":          "res://assets/professions/herbalism/herb_fadeleaf.png",
	"silverleaf":        "res://assets/professions/herbalism/herb_silverleaf.png",
	"earthroot":         "res://assets/professions/herbalism/herb_earthroot.png",
	# TODO: missing icon assets
	"goldthorn":         "res://assets/professions/herbalism/herb_goldthorn.png",
	"swampcap":          "res://assets/professions/herbalism/herb_swampcap.png",
	"plaguebloom":       "res://assets/professions/herbalism/herb_plaguebloom.png",
	"ghost_mushroom":    "res://assets/professions/herbalism/herb_ghost_mushroom.png",
	"nightshade":        "res://assets/professions/herbalism/herb_nightshade.png",
	"mountain_sage":     "res://assets/professions/herbalism/herb_mountain_sage.png",
	"icecap":            "res://assets/professions/herbalism/herb_icecap.png",
	"stormvine":         "res://assets/professions/herbalism/herb_stormvine.png",
	"dreamfoil":         "res://assets/professions/herbalism/herb_dreamfoil.png",
	"gromsblood":        "res://assets/professions/herbalism/herb_gromsblood.png",
	"starbloom":         "res://assets/professions/herbalism/herb_starbloom.png",
	"voidpetal":         "res://assets/professions/herbalism/herb_voidpetal.png",
	
	# Alchemy
	"mana_pot":          "res://assets/professions/alchemy/alchemy_mana_pot.png",
	"health_pot":        "res://assets/professions/alchemy/alchemy_health_pot.png",
	"greater_health_pot":"res://assets/professions/alchemy/alchemy_greater_health_pot.png",
	"greater_mana_pot":  "res://assets/professions/alchemy/alchemy_greater_mana_pot.png",
	"superior_health_pot":"res://assets/professions/alchemy/alchemy_superior_health_pot.png",
	"superior_mana_pot": "res://assets/professions/alchemy/alchemy_superior_mana_pot.png",
	"shield_pot":        "res://assets/professions/alchemy/alchemy_shield_pot.png",
	"greater_shield_pot":"res://assets/professions/alchemy/alchemy_greater_shield_pot.png",
	"superior_shield_pot":"res://assets/professions/alchemy/alchemy_superior_shield_pot.png",
	"haste_elixir":      "res://assets/professions/alchemy/alchemy_haste_elixir.png",
	"crit_elixir":       "res://assets/professions/alchemy/alchemy_crit_elixir.png",
	"defense_elixir":    "res://assets/professions/alchemy/alchemy_defense_elixir.png",
	"elixir_of_power":   "res://assets/professions/alchemy/alchemy_elixir_of_power.png",
	"flask_of_titans":   "res://assets/professions/alchemy/alchemy_flask_of_titans.png",
	
	# Hunting
	"trash":             "res://assets/professions/hunting/hunting_trash.png",
	"mice_fur":          "res://assets/professions/hunting/hunting_mice_fur.png",
	"rabbit_fur":        "res://assets/professions/hunting/hunting_rabbit_fur.png",
	"snake_head":        "res://assets/professions/hunting/hunting_snake_head.png",
	# TODO: missing icon assets
	"wolf_pelt":         "res://assets/professions/hunting/hunting_wolf_pelt.png",
	"bear_hide":         "res://assets/professions/hunting/hunting_bear_hide.png",
	"toad_skin":         "res://assets/professions/hunting/hunting_toad_skin.png",
	"goat_horn":         "res://assets/professions/hunting/hunting_goat_horn.png",
	"whelp_scale":       "res://assets/professions/hunting/hunting_whelp_scale.png",
	# Mining
	"common_copper_ore": "res://assets/professions/mining/common_copper_ore.png",
	"common_tin_ore":    "res://assets/professions/mining/common_tin_ore.png",
	# TODO: missing icon assets
	"iron_ore":          "res://assets/professions/mining/iron_ore.png",
	"mithril_ore":       "res://assets/professions/mining/mithril_ore.png",
	"dragonscale_ore":   "res://assets/professions/mining/dragonscale_ore.png",
	# Woodcutting
	"common_birch_log":  "res://assets/professions/woodcutting/common_birch_log.png",
	# TODO: missing icon assets
	"oak_log":           "res://assets/professions/woodcutting/oak_log.png",
	"pine_log":          "res://assets/professions/woodcutting/pine_log.png",
	"maple_log":         "res://assets/professions/woodcutting/maple_log.png",
	"tower_timber":      "res://assets/professions/woodcutting/tower_timber.png",
	"enchanted_log":     "res://assets/professions/woodcutting/enchanted_log.png",
	# Fishing
	"fish_0":            "res://assets/professions/fishing/fish_0.png",
	"fish_1":            "res://assets/professions/fishing/fish_1.png",
	# TODO: missing icon assets
	"swamp_eel":         "res://assets/professions/fishing/swamp_eel.png",
	"river_trout":       "res://assets/professions/fishing/river_trout.png",
	"deep_sea_fish":     "res://assets/professions/fishing/deep_sea_fish.png",
	"arcane_fish":       "res://assets/professions/fishing/arcane_fish.png",
	# Enchanting materials
	"arcane_dust":       "res://assets/professions/enchanting/arcane_dust.jpg",
	"mystic_essence":    "res://assets/professions/enchanting/mystic_essence.jpg",
	"enc_soul_shard":    "res://assets/professions/enchanting/enc_soul_shard.jpg",
	"void_crystal":      "res://assets/professions/enchanting/void_crystal.jpg",
}
var _item_icon_cache = {}

var _icon_paths = {
	# global icons
	"steps":                "res://assets/general_icons/steps.png",
	"gold_coin":            "res://assets/general_icons/gold_coin.png",

	# attributes icons
	"armor_penetration":    "res://assets/general_icons/attributes/armor_penetration.png",
	"attributes_luck":      "res://assets/general_icons/attributes/attribute_luck.png",
	"attributes_agility":   "res://assets/general_icons/attributes/attribute_agility.png",
	"attributes_intellect": "res://assets/general_icons/attributes/attribute_intellect.png",
	"attributes_spirit":    "res://assets/general_icons/attributes/attribute_spirit.png",
	"attributes_strength":  "res://assets/general_icons/attributes/attribute_strength.png",
	"attributes_vitality":  "res://assets/general_icons/attributes/attribute_vitality.png",
	"block_chance":         "res://assets/general_icons/attributes/block_chance.png",
	"critical_chance":      "res://assets/general_icons/attributes/critical_chance.png",
	"critical_damage":      "res://assets/general_icons/attributes/critical_damage.png",
	"damage_reduction":     "res://assets/general_icons/attributes/damage_reduction.png",
	"dodge":                "res://assets/general_icons/attributes/dodge.png",
	"haste":                "res://assets/general_icons/attributes/haste.png",
	"hit_rating":           "res://assets/general_icons/attributes/hit_rating.png",
	"magical_attack":       "res://assets/general_icons/attributes/magical_attack.png",
	"magical_defence":      "res://assets/general_icons/attributes/magical_defence.png",
	"magical_penetration":  "res://assets/general_icons/attributes/magical_penetration.png",
	"physical_attack":      "res://assets/general_icons/attributes/physical_attack.png",
	"physical_defence":     "res://assets/general_icons/attributes/physical_defence.png",
	"versatility":          "res://assets/general_icons/attributes/versatility.png",

	"fire_spell_damage":    "res://assets/general_icons/attributes/fire.png",
	"frost_spell_damage":   "res://assets/general_icons/attributes/frost.png",
	"arcane_spell_damage":  "res://assets/general_icons/attributes/arcane.png",
	"holy_spell_damage":    "res://assets/general_icons/attributes/holy.png",
	"dark_spell_damage":    "res://assets/general_icons/attributes/dark.png",

	# professions icons
	"alchemy":              "res://assets/general_icons/professions/alchemy.png",
	"herbalism":            "res://assets/general_icons/professions/herbalism.png",
	"hunting":              "res://assets/general_icons/professions/hunting.png",
	"mining":               "res://assets/general_icons/professions/mining.png",
	"woodcutting":          "res://assets/general_icons/professions/woodcutting.png",
	"fishing":              "res://assets/general_icons/professions/fishing.png",
	"blacksmith":           "res://assets/general_icons/professions/blacksmith.png",
	"rift":                 "res://assets/general_icons/professions/rift.png",
	"enchanting":           "res://assets/general_icons/professions/enchanting.png",

	# talents — general
	"thick_skin":           "res://assets/general_icons/passive_talents/thick_skin.png",
	"brutal_strike":        "res://assets/general_icons/passive_talents/brutal_strike.png",
	"brutal_finish":        "res://assets/general_icons/passive_talents/brutal_strike.png",
	"guardian_shell":       "res://assets/general_icons/passive_talents/guardian_shell.png",
	"evasion_training":     "res://assets/general_icons/passive_talents/evasion_training.png",
	"magic_ward":           "res://assets/general_icons/passive_talents/magic_ward.png",
	"mana_flow":            "res://assets/general_icons/passive_talents/mana_flow.png",
	"regenerative_steps":   "res://assets/general_icons/passive_talents/regenerative_steps.png",
	# TODO: missing passive talent icon assets
	"second_wind":          "res://assets/general_icons/passive_talents/second_wind.png",
	"fortitude":            "res://assets/general_icons/passive_talents/fortitude.png",
	"battle_rhythm":        "res://assets/general_icons/passive_talents/battle_rhythm.png",
	"gathering_wisdom":     "res://assets/general_icons/passive_talents/gathering_wisdom.png",
	"step_momentum":        "res://assets/general_icons/passive_talents/step_momentum.png",
	"alchemists_touch":     "res://assets/general_icons/passive_talents/alchemists_touch.png",

	# talents — class-specific (assets live in skills/<class>/ folders)
	"pyromaniac":           "res://assets/skills/mage/pyromaniac.png",
	"permafrost":           "res://assets/skills/mage/permafrost.png",
	"devotion":             "res://assets/skills/paladin/devotion.png",
	"shadow_mastery":       "res://assets/skills/dark/shadow_mastery.png",
	"arcane_mastery":       "res://assets/skills/arcane/arcane_mastery.png",
	"blood_pact":           "res://assets/skills/blood/blood_pact.png",

	# resistance icons (reuse elemental icons for spell damage; blood needs its own)
	# TODO: missing blood resistance icon asset
	"blood_spell_damage":   "res://assets/general_icons/attributes/blood.png",

	# HUD icons
	# TODO: missing skills HUD button icon asset
	"buttom_hud_skills":    "res://assets/general_icons/hud/buttom_hud_skills.png",

	# default / fallback
	# TODO: missing default bag icon asset
	"default_bag":          "res://assets/general_icons/default_bag.png",

	# ===== Skills — Buffs =====
	"buff_attack_up":           "res://assets/skills/buffs/buff_attack_up.png",
	"buff_hp_up":               "res://assets/skills/buffs/buff_hp_up.png",
	"buff_improved_shield":     "res://assets/skills/buffs/buff_improved_shield.png",
	"buff_shield_regeneration": "res://assets/skills/buffs/buff_shield_regeneration.png",
	"buff_barrier":             "res://assets/skills/buffs/buff_barrier.png",
	"buff_battle_fury":         "res://assets/skills/buffs/buff_battle_fury.png",
	"buff_reflect":             "res://assets/skills/buffs/buff_reflect.png",
	"buff_second_wind":         "res://assets/skills/buffs/buff_second_wind.png",
	"buff_fortify":             "res://assets/skills/buffs/buff_fortify.png",
	"buff_iron_skin":           "res://assets/skills/buffs/buff_iron_skin.png",
	"buff_mana_surge":          "res://assets/skills/buffs/buff_mana_surge.png",
	"buff_meditation":          "res://assets/skills/buffs/buff_meditation.png",
	"buff_adrenaline_rush":     "res://assets/skills/buffs/buff_adrenaline_rush.png",
	"buff_weaken":              "res://assets/skills/buffs/buff_weaken.png",
	"buff_cripple":             "res://assets/skills/buffs/buff_cripple.png",
	"buff_expose_weakness":     "res://assets/skills/buffs/buff_expose_weakness.png",

	# ===== Skills — Mage =====
	"mage_fireball":            "res://assets/skills/mage/mage_fireball.png",
	"mage_frostshield":         "res://assets/skills/mage/mage_frostshield.png",
	"mage_frostbolt":           "res://assets/skills/mage/mage_frostbolt.png",
	"mage_pyroblast":           "res://assets/skills/mage/mage_pyroblast.png",
	"mage_scorch":              "res://assets/skills/mage/mage_scorch.png",
	"mage_meteor":              "res://assets/skills/mage/mage_meteor.png",
	"mage_ignite":              "res://assets/skills/mage/mage_ignite.png",
	"mage_combustion":          "res://assets/skills/mage/mage_combustion.png",
	"mage_cauterize":           "res://assets/skills/mage/mage_cauterize.png",
	"mage_ice_lance":           "res://assets/skills/mage/mage_ice_lance.png",
	"mage_blizzard":            "res://assets/skills/mage/mage_blizzard.png",
	"mage_glacial_spike":       "res://assets/skills/mage/mage_glacial_spike.png",
	"mage_ice_barrier":         "res://assets/skills/mage/mage_ice_barrier.png",
	"mage_icy_veins":           "res://assets/skills/mage/mage_icy_veins.png",
	"mage_frost_nova":          "res://assets/skills/mage/mage_frost_nova.png",
	"mage_arcane_intellect":    "res://assets/skills/mage/mage_arcane_intellect.png",

	# ===== Skills — Paladin =====
	"paladin_minorheal":             "res://assets/skills/paladin/paladin_minorheal.png",
	"paladin_regeneration":          "res://assets/skills/paladin/paladin_regeneration.png",
	"paladin_crusader_strike":       "res://assets/skills/paladin/paladin_crusader_strike.png",
	"paladin_holy_sword":            "res://assets/skills/paladin/paladin_holy_sword.png",
	"paladin_hammer_of_justice":     "res://assets/skills/paladin/paladin_hammer_of_justice.png",
	"paladin_judgement":             "res://assets/skills/paladin/paladin_judgement.png",
	"paladin_lay_of_hands":          "res://assets/skills/paladin/paladin_lay_of_hands.png",
	"paladin_wrath":                 "res://assets/skills/paladin/paladin_wrath.png",
	"paladin_divine_shield":         "res://assets/skills/paladin/paladin_divine_shield.png",
	"paladin_blessing_of_protection":"res://assets/skills/paladin/paladin_blessing_of_protection.png",
	"paladin_consecration":          "res://assets/skills/paladin/paladin_consecration.png",
	"paladin_seal_of_justice":       "res://assets/skills/paladin/paladin_seal_of_justice.png",
	"paladin_beacon_of_light":       "res://assets/skills/paladin/paladin_beacon_of_light.png",
	"paladin_repentance":            "res://assets/skills/paladin/paladin_repentance.png",

	# ===== Skills — Dark =====
	"dark_shadow_bolt":         "res://assets/skills/dark/dark_shadow_bolt.png",
	"dark_shadow_strike":       "res://assets/skills/dark/dark_shadow_strike.png",
	"dark_pulse":               "res://assets/skills/dark/dark_pulse.png",
	"dark_void_blast":          "res://assets/skills/dark/dark_void_blast.png",
	"dark_corruption":          "res://assets/skills/dark/dark_corruption.png",
	"dark_curse_of_weakness":   "res://assets/skills/dark/dark_curse_of_weakness.png",
	"dark_curse_of_shadows":    "res://assets/skills/dark/dark_curse_of_shadows.png",
	"dark_soul_drain":          "res://assets/skills/dark/dark_soul_drain.png",
	"dark_shadow_ward":         "res://assets/skills/dark/dark_shadow_ward.png",
	"dark_mending":             "res://assets/skills/dark/dark_mending.png",
	"dark_shadow_embrace":      "res://assets/skills/dark/dark_shadow_embrace.png",
	"dark_void_armor":          "res://assets/skills/dark/dark_void_armor.png",

	# ===== Skills — Arcane =====
	"arcane_blast":             "res://assets/skills/arcane/arcane_blast.png",
	"arcane_barrage":           "res://assets/skills/arcane/arcane_barrage.png",
	"arcane_missiles":          "res://assets/skills/arcane/arcane_missiles.png",
	"arcane_explosion":         "res://assets/skills/arcane/arcane_explosion.png",
	"arcane_mana_burn":         "res://assets/skills/arcane/arcane_mana_burn.png",
	"arcane_vulnerability":     "res://assets/skills/arcane/arcane_vulnerability.png",
	"arcane_temporal_chains":   "res://assets/skills/arcane/arcane_temporal_chains.png",
	"arcane_shield":            "res://assets/skills/arcane/arcane_shield.png",
	"arcane_restoration":       "res://assets/skills/arcane/arcane_restoration.png",
	"arcane_power":             "res://assets/skills/arcane/arcane_power.png",
	"arcane_time_warp":         "res://assets/skills/arcane/arcane_time_warp.png",
	"arcane_brilliance":        "res://assets/skills/arcane/arcane_brilliance.png",

	# ===== Skills — Blood Magic =====
	"blood_strike":             "res://assets/skills/blood/blood_strike.png",
	"blood_heart_strike":       "res://assets/skills/blood/blood_heart_strike.png",
	"blood_boil":               "res://assets/skills/blood/blood_boil.png",
	"blood_death_strike":       "res://assets/skills/blood/blood_death_strike.png",
	"blood_soul_reaper":        "res://assets/skills/blood/blood_soul_reaper.png",
	"blood_vampiric_blood":     "res://assets/skills/blood/blood_vampiric_blood.png",
	"blood_shield":             "res://assets/skills/blood/blood_shield.png",
	"blood_death_pact":         "res://assets/skills/blood/blood_death_pact.png",
	"blood_frenzy":             "res://assets/skills/blood/blood_frenzy.png",
	"blood_crimson_fortitude":  "res://assets/skills/blood/blood_crimson_fortitude.png",
	"blood_presence":           "res://assets/skills/blood/blood_presence.png",
	"blood_plague":             "res://assets/skills/blood/blood_plague.png",
}
var _icon_cache = {}

# Avatars are only 6 textures — keep them eagerly loaded (always needed)
var AVATARS: Dictionary = {
	"0": load("res://assets/avatars/pirat.png") as Texture2D,
	"1": load("res://assets/avatars/1.png") as Texture2D,
	"2": load("res://assets/avatars/2.png") as Texture2D,
	"3": load("res://assets/avatars/3.png") as Texture2D,
	"4": load("res://assets/avatars/4.png") as Texture2D,
	"5": load("res://assets/avatars/5.png") as Texture2D,
}

# ── Lazy-loading public API ─────────────────────────────────────────────────
# Replaces the old eager ITEM_ICONS / ICONS dictionaries.
# Textures are loaded on first access and cached for subsequent lookups.
func get_item_icon(key: String, default = null):
	if _item_icon_cache.has(key):
		return _item_icon_cache[key]
	if _item_icon_paths.has(key):
		var tex = load(_item_icon_paths[key]) as Texture2D
		_item_icon_cache[key] = tex
		return tex
	return default

func has_item_icon(key: String) -> bool:
	return _item_icon_paths.has(key)

func get_icon(key: String, default = null):
	if _icon_cache.has(key):
		return _icon_cache[key]
	if _icon_paths.has(key):
		var tex = load(_icon_paths[key]) as Texture2D
		_icon_cache[key] = tex
		return tex
	return default

func has_icon(key: String) -> bool:
	return _icon_paths.has(key)

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
