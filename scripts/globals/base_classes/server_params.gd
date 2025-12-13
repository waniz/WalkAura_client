extends Node

var ACCOUNT_PROGRESSION_LEVELS
var STATS_PROGRESSION_LEVELS
var ACTIVITY_PROGRESSION_LEVELS
var SERVER_VERSION = ""

func _ready() -> void:
	AccountManager.signal_LoginParamsReceived.connect(on_login_params_received)
	

func on_login_params_received(data):
	ACCOUNT_PROGRESSION_LEVELS = data["data"]["account_progression"]
	STATS_PROGRESSION_LEVELS = data["data"]["stats_progression"]
	ACTIVITY_PROGRESSION_LEVELS = data["data"]["activity_progression"]
	SERVER_VERSION = data["data"]["server_version"]
