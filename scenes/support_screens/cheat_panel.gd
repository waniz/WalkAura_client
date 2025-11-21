extends Control

var _plugin_name = "GodotAndroidPlugin"
var _android_plugin = null

@onready var panel: Panel = $Panel
@onready var cheat_100_button: Button = $Panel/VBoxContainer/Cheat_100_button
@onready var cheat_500_button: Button = $Panel/VBoxContainer/Cheat_500_button
@onready var cheat_1000_button: Button = $Panel/VBoxContainer/Cheat_1000_button
@onready var cheat_10000_button: Button = $Panel/VBoxContainer/Cheat_10000_button
@onready var pedometer_plugin_button: Button = $Panel/PedometerPluginButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AccountManager.signal_UserStepLastTSReceived.connect(_on_step_counter_android_update)
	
	Styler.style_panel(panel, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))
	Styler.style_button(cheat_100_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(cheat_500_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(cheat_1000_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(cheat_10000_button,  Color.from_rgba8(64,180,255))
	Styler.style_button(pedometer_plugin_button,  Color.from_rgba8(64,180,255))
	
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
	SignalManager.signal_StepsRequestLastTimestamp.emit(true)


func _on_step_counter_android_update(data) -> void:
	var delta = int(data["data"]["delta"])
	if _android_plugin:
		_android_plugin.getSteps(delta)


func _total_steps_retrieved(json_text: String) -> void:
	var data = JSON.parse_string(json_text)
	SignalManager.signal_StepsUpdatesAndroid.emit(data)
	
