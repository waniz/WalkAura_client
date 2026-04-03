extends Node

var _plugin_name = "GodotAndroidPlugin"
var _android_plugin = null


func _ready() -> void:
	connect_to_mobile()
	AccountManager.signal_UserStepLastTSReceived.connect(_on_step_counter_android_update)
	var timer = Timer.new()
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


func _on_step_counter_android_update(data) -> void:
	var delta = int(data.get("data", {}).get("delta", 0))
	if _android_plugin:
		_android_plugin.getSteps(delta)


func _total_steps_retrieved(json_text: String) -> void:
	var data = JSON.parse_string(json_text)
	if data == null:
		printerr("Pedometer: failed to parse steps JSON")
		return

	# Client display path
	var server_steps_returned: int = 0
	for i in data.size():
		var e: Dictionary = data[i]
		server_steps_returned += int(e.get("steps"))
	SignalManager.signal_StepsReceivedFromServer.emit(server_steps_returned)

	# Server reporting path (previously in cheat_panel.gd)
	SignalManager.signal_StepsUpdatesAndroid.emit(data)
