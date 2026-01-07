extends Node

var ACCOUNT_PROGRESSION_LEVELS
var STATS_PROGRESSION_LEVELS
var ACTIVITY_PROGRESSION_LEVELS
var PASSIVE_TOTAL_TO_LEVEL
var ACTIVITIES_SITES
var GATHERING_ACTIVITIES
var CRAFTING_ACTIVITIES
var BATTLE_ACTIVITIES
var SERVER_VERSION = ""

func _ready() -> void:
	AccountManager.signal_LoginParamsReceived.connect(on_login_params_received)
	

func on_login_params_received(data):
	ACCOUNT_PROGRESSION_LEVELS = data["data"]["account_progression"]
	STATS_PROGRESSION_LEVELS = data["data"]["stats_progression"]
	ACTIVITY_PROGRESSION_LEVELS = data["data"]["activity_progression"]
	PASSIVE_TOTAL_TO_LEVEL = data["data"]["passive_progression"]
	
	ACTIVITIES_SITES = data["data"]["activities_sites"]
	GATHERING_ACTIVITIES = data["data"]["gathering_activities"]
	CRAFTING_ACTIVITIES = data["data"]["crafting_activities"]
	BATTLE_ACTIVITIES = data["data"]["battle_activities"]
	
	SERVER_VERSION = data["data"]["server_version"]
