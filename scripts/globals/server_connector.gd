extends Node

var socket := WebSocketPeer.new()
signal server_connector_message_bus(message: String)

var cryptoUtil = UserCrypto.new()

@export var websocket_url = "ws://91.98.164.230:8888/ws"

var _is_connected = false

# Part A: Credential storage
var _saved_username: String = ""
var _saved_password: String = ""
var _was_authenticated: bool = false

# Part B: Heartbeat constants and state
const HEARTBEAT_INTERVAL := 15.0
const HEARTBEAT_TIMEOUT := 10.0
var _heartbeat_timer: float = 0.0
var _heartbeat_pending: bool = false
var _heartbeat_timeout_timer: float = 0.0
var _connection_healthy: bool = true
var _auto_login_in_progress: bool = false
var suppress_reconnect_overlay: bool = false

# Part C: Reconnection overlay
var _reconnect_overlay: CanvasLayer = null

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
	SignalManager.signal_UnequipItem.connect(_on_unequip_request)
	SignalManager.signal_SellItem.connect(_on_sell_item_request)
	SignalManager.signal_SellItems.connect(_on_sell_items_request)
	SignalManager.signal_DisenchantItem.connect(_on_disenchant_item_request)

	SignalManager.signal_EquipSkill.connect(_on_equip_skill_request)
	SignalManager.signal_UnEquipSkill.connect(_on_unequip_skill_request)

	SignalManager.signal_RequestRiftFights.connect(_on_request_rift_fights)
	SignalManager.signal_RequestRiftFightLog.connect(_on_request_rift_fight_log)
	SignalManager.signal_TravelRequest.connect(_on_travel_request)
	SignalManager.signal_AvatarChanged.connect(_on_avatar_changed)
	SignalManager.signal_RequestProfessionInfo.connect(_on_request_profession_info)
	SignalManager.signal_StartCraftActivity.connect(_on_start_craft_activity)


func connect_to_server() -> void:
	# --- FIX: Increase Buffer Size ---
	# Default is often 64KB (65536). Let's set it to 10MB to be safe.
	socket.inbound_buffer_size = 1 * 1024 * 1024
	# ---------------------------------

	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		server_connector_message_bus.emit("[Client] ERROR: Cannot connect to server")
		set_process(false)
	else:
		await get_tree().create_timer(1).timeout
		server_connector_message_bus.emit("[Client] Connected to server ... ")

func _process(_delta: float) -> void:
	socket.poll()

	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _is_connected:
			_is_connected = true
			# Reset heartbeat state on fresh connection
			_heartbeat_timer = 0.0
			_heartbeat_pending = false
			_heartbeat_timeout_timer = 0.0
			# Auto-login if we were previously authenticated
			if _was_authenticated and _saved_username != "" and _saved_password != "":
				_auto_login()

		while socket.get_available_packet_count():
			var raw_msg = socket.get_packet().get_string_from_ascii()
			# Server messages are prefixed with "[SERVER] " (9 chars)
			if raw_msg.begins_with("[SERVER] "):
				var json_str = raw_msg.substr(9)
				var parsed = JSON.parse_string(json_str)
				if parsed != null and parsed is Dictionary and parsed.get("cmd") == "heartbeat_ack":
					_heartbeat_pending = false
					_heartbeat_timeout_timer = 0.0
					if not _connection_healthy:
						_connection_healthy = true
						_hide_reconnect_overlay()
					continue
			server_connector_message_bus.emit(raw_msg)

		# Heartbeat timer logic
		_heartbeat_timer += _delta
		if _heartbeat_timer >= HEARTBEAT_INTERVAL:
			var hb_payload = JSON.stringify({"cmd": "heartbeat", "payload": {}})
			socket.send_text(hb_payload)
			_heartbeat_pending = true
			_heartbeat_timer = 0.0

		if _heartbeat_pending:
			_heartbeat_timeout_timer += _delta
			if _heartbeat_timeout_timer >= HEARTBEAT_TIMEOUT and _connection_healthy:
				_connection_healthy = false
				if _was_authenticated:
					_show_reconnect_overlay()

	elif state == WebSocketPeer.STATE_CLOSED:
		if _is_connected:
			_is_connected = false
			# Reset heartbeat state
			_heartbeat_pending = false
			_heartbeat_timeout_timer = 0.0
			_heartbeat_timer = 0.0
			print("Disconnected. Code: %d, Reason: %s" % [socket.get_close_code(), socket.get_close_reason()])
			if _was_authenticated:
				_show_reconnect_overlay()

			await get_tree().create_timer(3.0).timeout
			connect_to_server()

# Part C: Reconnection overlay methods
func _show_reconnect_overlay() -> void:
	if _reconnect_overlay != null or suppress_reconnect_overlay:
		return
	_reconnect_overlay = CanvasLayer.new()
	_reconnect_overlay.layer = 200
	add_child(_reconnect_overlay)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reconnect_overlay.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reconnect_overlay.add_child(center)

	var label = Label.new()
	label.text = "Reconnecting..."
	label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
	center.add_child(label)

func _hide_reconnect_overlay() -> void:
	if _reconnect_overlay:
		_reconnect_overlay.queue_free()
		_reconnect_overlay = null

# Part D: Auto-login after reconnect
var _auto_login_ok := false

func _auto_login() -> void:
	if _auto_login_in_progress:
		return
	if _saved_username == "" or _saved_password == "":
		return
	_auto_login_in_progress = true
	_auto_login_ok = false
	AccountManager.signal_LoginResult.connect(_on_auto_login_result, CONNECT_ONE_SHOT)
	AccountManager.signal_AccountDataReceived.connect(_on_auto_login_data, CONNECT_ONE_SHOT)
	_on_user_login(_saved_username, _saved_password)


func _on_auto_login_result(result: bool, _error: String) -> void:
	_auto_login_ok = result


func _on_auto_login_data(_result) -> void:
	_auto_login_in_progress = false
	if _auto_login_ok:
		_connection_healthy = true
		_hide_reconnect_overlay()
	else:
		clear_credentials()
		_hide_reconnect_overlay()
		SceneManage.goto("res://scenes/login_screen/login_scene.tscn")

# Part A: Credential helper methods
func clear_credentials() -> void:
	_saved_username = ""
	_saved_password = ""
	_was_authenticated = false

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
	# Part A: Save credentials on login
	_saved_username = user
	_saved_password = password
	_was_authenticated = true

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

func _on_useitem_request(item_to_use, qty: int) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "use_item",
			"item_uid": item_to_use,
			"qty": qty,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Use item: {0} x{1}".format([item_to_use, qty]))

func _on_equip_request(item_to_equip, slot_type) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "equip",
			"item_uid": item_to_equip,
			"slot": slot_type,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Equip item: {0} for slot: {1}".format([item_to_equip, slot_type]))

func _on_unequip_request(_slot_name) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "unequip",
			"slot": _slot_name,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Unequip item from slot: {0}".format([_slot_name]))

func _on_sell_item_request(item_to_sell) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "sell",
			"item_uid": item_to_sell,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Sell item {0}".format([item_to_sell]))

func _on_disenchant_item_request(item_uid: String) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "disenchant",
			"item_uid": item_uid,
		}
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Request to Disenchant item %s" % item_uid)

func _on_sell_items_request(item_uids: Array) -> void:
	var payload := {
		"cmd": "inventory",
		"payload": {
			"action": "sell_batch",
			"item_uids": item_uids,
		}
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Request to Sell %d items" % item_uids.size())

func _on_equip_skill_request(idx, skill_id):
	var payload := {
		"cmd": "skills",
		"payload": {
			"action": "equip",
			"slot": idx,
			"skill_id": skill_id,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Equip skill {0}".format([skill_id]))

func _on_unequip_skill_request(idx):
	var payload := {
		"cmd": "skills",
		"payload": {
			"action": "unequip",
			"slot": idx,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request to Unequip skill from {0}".format([idx]))

func _on_request_rift_fights(rift_instance_id: String) -> void:
	var payload := {
		"cmd": "rift_fights",
		"payload": {
			"rift_instance_id": rift_instance_id,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Requesting rift fights for: {0}".format([rift_instance_id]))

func _on_request_rift_fight_log(rift_instance_id: String, fight_uid: String) -> void:
	var payload := {
		"cmd": "rift_fights",
		"payload": {"rift_instance_id": rift_instance_id, "fight_uid": fight_uid},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting fight log for fight: {0}".format([fight_uid]))

func _on_travel_request(location_id: int) -> void:
	var payload := {
		"cmd": "travel",
		"payload": {"location": location_id},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting travel to location: %d" % location_id)

func _on_avatar_changed(avatar_id: int) -> void:
	var payload := {"cmd": "set_avatar", "payload": {"avatar_id": avatar_id}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Set avatar: " + str(avatar_id))

func _on_request_profession_info(profession: String) -> void:
	var payload := {
		"cmd": "profession_info",
		"payload": {"profession": profession},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting profession info: %s" % profession)

func _on_start_craft_activity(activity: int, activity_site: int, recipe_id: String) -> void:
	var payload := {
		"cmd": "activity",
		"payload": {
			"activity": activity,
			"activity_site": activity_site,
			"action": "start",
			"recipe_id": recipe_id,
		}
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Starting craft: %s" % recipe_id)
