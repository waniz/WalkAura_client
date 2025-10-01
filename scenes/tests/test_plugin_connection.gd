extends Node2D
@onready var steps_data_logs: RichTextLabel = $GetStepsDataVBox/StepsDataLogs
@onready var connect_logs: RichTextLabel = $ConnectVBox2/connectLogs

var _plugin_name = "GodotAndroidPlugin"
var _android_plugin = null

var socket := WebSocketPeer.new()
@export var websocket_url = "ws://91.98.164.230:8888/ws"


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
	
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		await get_tree().create_timer(1).timeout
		socket.send_text("Test packet")
		
func _process(_delta: float) -> void:
	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			connect_logs.text = socket.get_packet().get_string_from_ascii()

	
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
