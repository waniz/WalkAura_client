extends Control

var _plugin_name = "GodotAndroidPlugin"
var _android_plugin = null

func _ready() -> void:

	if Engine.has_singleton(_plugin_name):
		_android_plugin = Engine.get_singleton(_plugin_name)
		
		if _android_plugin.checkRequiredPermissions() != 0:
			_android_plugin.requestRequiredPermissions()
			
		_android_plugin.subscribeToFitnessData()
		_android_plugin.connect("total_steps_retrieved", _total_steps_retrieved)
	else:
		printerr("Could not connect")
		

func _on_cheat_100_button_button_down() -> void:
	SignalManager.signal_StepsUpdatesCheats.emit(100)


func _on_cheat_500_button_button_down() -> void:
	SignalManager.signal_StepsUpdatesCheats.emit(500)


func _on_cheat_1000_button_button_down() -> void:
	SignalManager.signal_StepsUpdatesCheats.emit(1000)


func _on_cheat_10000_button_button_down() -> void:
	SignalManager.signal_StepsUpdatesCheats.emit(10000)


func _on_pedometer_plugin_button_button_down() -> void:
	if _android_plugin:
		_android_plugin.getSteps(3600)


func _total_steps_retrieved(json_text: String) -> void:
	var data = JSON.parse_string(json_text)
	SignalManager.signal_StepsUpdatesAndroid.emit(data)
	
