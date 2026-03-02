extends Node

var _plugin_name = "GodotAndroidPlugin"
var _android_plugin = null

func _ready() -> void:
	connect_to_mobile()
	var timer := Timer.new()
	timer.wait_time = 30.0
	timer.autostart = true
	timer.timeout.connect(func(): SignalManager.signal_StepsRequestLastTimestamp.emit(true))
	add_child(timer)
	
func connect_to_mobile():
	if Engine.has_singleton(_plugin_name):
		_android_plugin = Engine.get_singleton(_plugin_name)
		
		if _android_plugin.checkRequiredPermissions() != 0:
			_android_plugin.requestRequiredPermissions()
			
		_android_plugin.subscribeToFitnessData()
		_android_plugin.connect("total_steps_retrieved", _total_steps_retrieved)
	else:
		printerr("Could not connect")
	
func _total_steps_retrieved(json_text: String) -> void:
	var data = JSON.parse_string(json_text)
		
	#var lines := PackedStringArray()
	var server_steps_returned: int = 0
	for i in data.size():
		var e: Dictionary = data[i]
		server_steps_returned += int(e.get("steps"))
		#lines.append(
			#"Entry #%d Start: %s End: %s STEPS: %s"
			#% [i, str(e.get("start")), str(e.get("end")), str(e.get("steps"))]
		#)
	SignalManager.signal_StepsReceivedFromServer.emit(server_steps_returned)
