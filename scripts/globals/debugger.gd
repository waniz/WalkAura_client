extends Node

signal signalLogUpdated(log: String)

var log = ""

func _ready() -> void:
	ServerConnector.server_connector_message_bus.connect(_on_message)
	
func _on_message(message):
	if "ERROR" in message:
		log += "\n" + "[color=red]" + message + "[/color]"
	elif "Client" in message:
		log += "\n" + "[color=yellow]" + message + "[/color]"
	elif "SERVER" in message:
		log += "\n" + "[color=green]" + message + "[/color]"
	else:
		log += "\n" + message
	log += "\n" + "-----------------"
	signalLogUpdated.emit(log)
