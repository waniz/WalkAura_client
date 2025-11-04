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
		message = message.substr(9)
		var json = JSON.new()
		var error = json.parse(message)
		if error == OK:
			pass
		else:
			printerr("JSON Parse Error: ", json.get_error_message(), " in ", message, " at line ", json.get_error_line())

		_log = "[color=green][SERVER] OK: {0} CMD: {1} [/color]".format([json.data.ok, json.data.cmd])
	else:
		_log = message
	#_log = "\n" + "-----------------"
	signalLogUpdated.emit(_log)
