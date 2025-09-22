extends Node2D
@onready var steps_data_logs: RichTextLabel = $GetStepsDataVBox/StepsDataLogs
@onready var connect_logs: RichTextLabel = $ConnectVBox2/connectLogs

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

func _on_get_steps_button_pressed() -> void:
	if _android_plugin:
		_android_plugin.getSteps(25000)
		
func _on_connect_button_pressed() -> void:
	connect_logs.text = "Connecting ..."
	
func _total_steps_retrieved(json_text: String) -> void:
	var data = JSON.parse_string(json_text)
	
	var lines := PackedStringArray()
	for i in data.size():
		var e: Dictionary = data[i]
		lines.append(
			"Entry #%d Start: %s End: %s STEPS: %s"
			% [i, str(e.get("start")), str(e.get("end")), str(e.get("steps"))]
		)
	steps_data_logs.text = "\n".join(lines)
