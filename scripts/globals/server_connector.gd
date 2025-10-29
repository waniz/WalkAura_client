extends Node

var socket := WebSocketPeer.new()
signal server_connector_message_bus(message: String)

var cryptoUtil = UserCrypto.new()

@export var websocket_url = "ws://91.98.164.230:8888/ws"

func _ready() -> void:
	connect_to_server()
	
	SignalManager.signal_CreateUser.connect(_on_user_creating)
	SignalManager.signal_LoginUser.connect(_on_user_login)
	SignalManager.signal_UserActivity.connect(_on_user_activity)
	SignalManager.signal_StepsUpdatesCheats.connect(_on_step_counter_cheat_update)
	SignalManager.signal_StepsUpdatesAndroid.connect(_on_step_counter_android_update)
	SignalManager.signal_StepsRequestLastTimestamp.connect(_on_step_counter_android_request_last_ts)


func connect_to_server() -> void:
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		server_connector_message_bus.emit("[Client] ERROR: Cannot connect to server")
		set_process(false)
	else:
		await get_tree().create_timer(1).timeout
		server_connector_message_bus.emit("[Client] Connecting to server ... OK")
		
func _process(_delta: float) -> void:
	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			server_connector_message_bus.emit(socket.get_packet().get_string_from_ascii())

# ################################
# """Signal compilator section"""
func _on_user_creating(user, password):
	var payload := {
		"cmd": "create_user",
		"payload": {
			"username": user,
			"password": password,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Requesting user creating...")

func _on_user_login(user, password):
	var payload := {
		"cmd": "login_user",
		"payload": {
			"username": user,
			"password": password,
		}
	}	
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Requesting user login...")
	
func _on_user_activity(activity, activity_site, action):
	var payload := {
		"cmd": "activity",
		"payload": {
			"activity": activity,
			"activity_site": activity_site,
			"action": action,
		}
	}	
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Requesting activity: {0}, action: {1}".format([activity, action]))

func _on_step_counter_cheat_update(amount):
	var payload := {
		"cmd": "steps_update_cheat",
		"payload": {
			"amount": amount,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending cheat steps: {0}".format([amount]))

func _on_step_counter_android_request_last_ts(is_requested):
	if not is_requested:
		return
	
	var payload := {
		"cmd": "steps_request_last_ts",
		"payload": {
			"data": true,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending android steps request last ts")
		
func _on_step_counter_android_update(data):
	var payload := {
		"cmd": "steps_update_android",
		"payload": {
			"data": data,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending android steps to server")
