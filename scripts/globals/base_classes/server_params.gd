extends Node

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
