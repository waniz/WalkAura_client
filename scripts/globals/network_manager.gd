extends Node

signal connected
signal disconnected
signal data_received(data)

var socket = WebSocketPeer.new()
var websocket_url = "ws://127.0.0.1:8888/ws" # Or your wss:// domain
var _is_connected = false

# Timer to poll the socket repeatedly
var _poll_timer = Timer.new()

func _ready():
	_poll_timer.wait_time = 0.1 # Check 10 times a second
	_poll_timer.timeout.connect(_process_socket)
	add_child(_poll_timer)
	_poll_timer.start()
	
	connect_to_server()

func connect_to_server():
	print("Attempting connection to: " + websocket_url)
	socket.close() # Clean up old sockets
	socket.connect_to_url(websocket_url)
	_is_connected = false

func _process_socket():
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not _is_connected:
			_is_connected = true
			print("Connected to Server!")
			emit_signal("connected")
			
		# Process incoming messages
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			var data_str = packet.get_string_from_utf8()
			if data_str:
				var json = JSON.parse_string(data_str)
				# Filter out raw strings (like simple PONGs if you implemented custom ones)
				if json: 
					emit_signal("data_received", json)
					
	elif state == WebSocketPeer.STATE_CLOSED:
		if _is_connected:
			_is_connected = false
			print("Disconnected. Code: %d, Reason: %s" % [socket.get_close_code(), socket.get_close_reason()])
			emit_signal("disconnected")
			
			# OPTIONAL: Auto-Reconnect logic
			await get_tree().create_timer(3.0).timeout
			connect_to_server()

	elif state == WebSocketPeer.STATE_CLOSING:
		pass # Waiting for close to finish
