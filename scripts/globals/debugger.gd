extends Node

signal signalLogUpdated(log: String)

var _log = ""

func _ready() -> void:
	ServerConnector.server_connector_message_bus.connect(_on_message)
	
func _on_message(message):
	if "ERROR" in message:
		_log = "[color=red]" + message + "[/color]"
	elif "Client" in message:
		_log = "[color=yellow]" + message + "[/color]"
	elif "SERVER" in message:
		_log = "[color=green]" + message.substr(0, 142) + "[/color]"
	else:
		_log = message
	#_log = "\n" + "-----------------"
	signalLogUpdated.emit(_log)
