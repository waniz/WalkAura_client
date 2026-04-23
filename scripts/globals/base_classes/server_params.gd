extends Node

# Fallback URL shown by the "Update Now" button in the version-mismatch modal.
# Flip this to the Play Store listing once it goes live; one-line change.
const UPDATE_URL = "https://walkaura.app/download"

# Fetched lazily in client_version() so we don't pay the ProjectSettings read
# on every send. ProjectSettings.get_setting() is cheap but it's still a dict
# lookup we can memoize.
var _client_version_cache: String = ""

var ACCOUNT_PROGRESSION_LEVELS
var STATS_PROGRESSION_LEVELS
var ACTIVITY_PROGRESSION_LEVELS
var PASSIVE_TOTAL_TO_LEVEL
var LOCATIONS: Dictionary = {}
var ACTIVITIES_SITES
var GATHERING_ACTIVITIES
var CRAFTING_ACTIVITIES
var BATTLE_ACTIVITIES
var LINEAR_CONSTANT
var DIMINISHING_CONSTANT
var SERVER_VERSION = ""


# The app version declared in project.godot's config/version. Memoized on
# first call. Shape is typically "0.2.5.169" (major.minor.patch.build).
func client_version() -> String:
	if _client_version_cache == "":
		_client_version_cache = str(ProjectSettings.get_setting("application/config/version", ""))
	return _client_version_cache


# True when client's first 3 dotted version segments match server's. Mirrors
# walkaura_server/version.py::compatible exactly so contract drift is a
# contract-test failure, not a runtime bug.
func version_compatible() -> bool:
	var c = client_version().split(".")
	var s = SERVER_VERSION.split(".")
	if c.size() < 3 or s.size() < 3:
		return false
	return c[0] == s[0] and c[1] == s[1] and c[2] == s[2]

# Talent system config (loaded from talents_config message)
var TALENT_REGISTRY: Array = []
var TALENT_SYNERGIES: Array = []
var TIER_2_THRESHOLD: int = 16
var TIER_3_THRESHOLD: int = 31
var MAX_RANK: int = 50
var MAX_ALLOCATED: int = 100
var POINTS_PER_STEPS: int = 500

func _ready() -> void:
	AccountManager.signal_LoginParamsReceived.connect(on_login_params_received)
	

func on_login_params_received(data):
	ACCOUNT_PROGRESSION_LEVELS = data["data"]["account_progression"]
	STATS_PROGRESSION_LEVELS = data["data"]["stats_progression"]
	ACTIVITY_PROGRESSION_LEVELS = data["data"]["activity_progression"]
	PASSIVE_TOTAL_TO_LEVEL = data["data"]["passive_progression"]
	
	LOCATIONS = data["data"].get("locations", {})
	ACTIVITIES_SITES = data["data"]["activities_sites"]
	GATHERING_ACTIVITIES = data["data"]["gathering_activities"]
	CRAFTING_ACTIVITIES = data["data"]["crafting_activities"]
	BATTLE_ACTIVITIES = data["data"]["battle_activities"]
	
	LINEAR_CONSTANT = data["data"]["item_generation_constants"]["linear"]
	DIMINISHING_CONSTANT = data["data"]["item_generation_constants"]["diminishing"]
	
	SERVER_VERSION = data["data"]["server_version"]
