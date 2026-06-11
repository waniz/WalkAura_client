extends Node

const TIER_NAMES = {
	1: "TIER 1 - EASY",
	2: "TIER 2 - MEDIUM",
	3: "TIER 3 - HARD",
}

var TIER_COLORS = {
	0: Color.from_rgba8(158, 158, 158),
	1: Color.from_rgba8(31, 255, 0),
	2: Color.from_rgba8(0, 112, 222),
	3: Color.from_rgba8(163, 54, 237),
}

# Keyed by location_id (= activity_site for raid rifts).
# No legacy rifts (key 1 removed — unreachable from location hub).
#
# These baked-in values are a FALLBACK/default. The server is the source of
# truth: login_params carries a "rift_catalog" (built from rift_config.py) and
# update_from_catalog() overwrites these entries on login, so server retunes
# (gates, total_steps, names, lore) propagate without editing this file. The
# defaults keep rift screens working offline / before login_params arrives.
var RIFT_TABLE = {
	2: {"name": "Forest Breach", "tier": 1,
		"req_rift_lvl": 1, "req_account_lvl": 5,
		"total_steps": 4000, "encounter_count": 4,
		"description": "A tear in reality among the ancient oaks. Nature spirits pour through, confused and aggressive.",
		"lore": "The forest weeps sap where the breach opens. What comes through still smells of green places.",
		"gear_score_range": "0–80"},
	3: {"name": "Swamp Maw", "tier": 1,
		"req_rift_lvl": 2, "req_account_lvl": 8,
		"total_steps": 4500, "encounter_count": 4,
		"description": "A festering wound in the swamp floor. Dark creatures rise from the brackish water.",
		"lore": "The swamp has always been hungry. Now it has teeth.",
		"gear_score_range": "0–100"},
	5: {"name": "Iron Crucible", "tier": 2,
		"req_rift_lvl": 4, "req_account_lvl": 12,
		"total_steps": 7000, "encounter_count": 6,
		"description": "Molten ore flows from a rift deep in the mountain. Creatures of fire and iron guard the breach.",
		"lore": "The dwarves abandoned this mine for a reason. What melts through the walls is not natural.",
		"gear_score_range": "150–250"},
	7: {"name": "Tower Ascent", "tier": 2,
		"req_rift_lvl": 5, "req_account_lvl": 14,
		"total_steps": 7500, "encounter_count": 6,
		"description": "The wizard's tower hums with unstable arcane energy. Frost and arcane creatures guard each floor.",
		"lore": "Each floor of the tower is colder than the last. The wizard left in a hurry. His experiments did not.",
		"gear_score_range": "180–280"},
	9: {"name": "Dragon's Fury", "tier": 3,
		"req_rift_lvl": 7, "req_account_lvl": 18,
		"total_steps": 10000, "encounter_count": 6,
		"description": "The dragon lair seethes with fire and rage. Dragon whelps and their priests defend the hoard.",
		"lore": "The dragons do not guard treasure. They guard what sleeps beneath it.",
		"gear_score_range": "260–430"},
	10: {"name": "The Convergence", "tier": 3,
		"req_rift_lvl": 8, "req_account_lvl": 20,
		"total_steps": 12000, "encounter_count": 5,
		"description": "The ancient place thrums with unstable energy. Creatures from every rift converge here.",
		"lore": "The barriers between rifts have shattered. What emerges is neither guardian nor sentinel, but something older. Something hungry.",
		"gear_score_range": "300–500"},
}


# Overwrite the baked-in RIFT_TABLE with the server's authoritative catalog
# (login_params.rift_catalog, serialized from rift_config.get_rift_catalog()).
# Called from AccountManager.get_login_params on every login. Missing/malformed
# input leaves the fallback defaults intact.
func update_from_catalog(catalog) -> void:
	if typeof(catalog) != TYPE_ARRAY:
		return
	for entry in catalog:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var loc_id: int = int(entry.get("location_id", 0))
		if loc_id <= 0:
			continue
		RIFT_TABLE[loc_id] = {
			"name": entry.get("name", ""),
			"tier": int(entry.get("tier", 0)),
			"req_rift_lvl": int(entry.get("req_rift_lvl", 0)),
			"req_account_lvl": int(entry.get("req_account_lvl", 0)),
			"total_steps": int(entry.get("total_steps", 0)),
			"encounter_count": int(entry.get("encounter_count", 0)),
			"description": entry.get("description", ""),
			"lore": entry.get("lore", ""),
			"gear_score_range": entry.get("gear_score_range", ""),
		}
