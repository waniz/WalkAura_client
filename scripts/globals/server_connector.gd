extends Node

var socket := WebSocketPeer.new()
signal server_connector_message_bus(message: String)

var cryptoUtil = UserCrypto.new()

@export var websocket_url = "ws://91.98.164.230:8888/ws"

func _ready() -> void:
	connect_to_server()
	
	SignalManager.signal_CreateUser.connect(_on_user_creating)
	SignalManager.signal_LoginUser.connect(_on_user_login)

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
	#var hashed_password = cryptoUtil.hash_password(password)
	
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
	#var hashed_password = cryptoUtil.hash_password(password)
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
