extends Node

var _plugin_name = "GodotAndroidPlugin"
var _android_plugin = null
var text_logs = null


#func get_steps_from_android() -> void:
	#if _android_plugin:
		#_android_plugin.getSteps(25000)

func _ready() -> void:
	pass
	
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
		
	var lines := PackedStringArray()
	for i in data.size():
		var e: Dictionary = data[i]
		lines.append(
			"Entry #%d Start: %s End: %s STEPS: %s"
			% [i, str(e.get("start")), str(e.get("end")), str(e.get("steps"))]
		)
	text_logs = "\n".join(lines)
