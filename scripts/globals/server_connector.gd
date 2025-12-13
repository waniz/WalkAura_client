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
	
	SignalManager.signal_RequestInventory.connect(_on_inventory_request)
	SignalManager.signal_UseItem.connect(_on_useitem_request)
	SignalManager.signal_EquipItem.connect(_on_equip_request)


func connect_to_server() -> void:
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		server_connector_message_bus.emit("[Client] ERROR: Cannot connect to server")
		set_process(false)
	else:
		await get_tree().create_timer(1).timeout
		server_connector_message_bus.emit("[Client] Connected to server ... ")
		
func _process(_delta: float) -> void:
	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			server_connector_message_bus.emit(socket.get_packet().get_string_from_ascii())

# ################################
# """Signal compilator section"""
func _on_user_creating(user, password) -> void:
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

func _on_user_login(user, password) -> void:
	var payload := {
		"cmd": "login_user",
		"payload": {
			"username": user,
			"password": password,
		}
	}	
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Requesting login...")
	
func _on_user_activity(activity, activity_site, action) -> void:
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

func _on_step_counter_cheat_update(amount) -> void:
	var payload := {
		"cmd": "steps_update_cheat",
		"payload": {
			"amount": amount,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending cheat steps: {0}".format([amount]))

func _on_step_counter_android_request_last_ts(is_requested) -> void:
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
		
func _on_step_counter_android_update(data) -> void:
	var payload := {
		"cmd": "steps_update_android",
		"payload": {
			"data": data,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending android steps to server")

func _on_inventory_request(action) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": action,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request Inventory: {0}".format([action]))
	
func _on_useitem_request(item_to_use) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "use_item",
			"item": item_to_use,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Use item: {0}".format([item_to_use]))

func _on_equip_request(item_to_equip) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "equip",
			"item": item_to_equip,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Equip item: {0}".format([item_to_equip]))
	
