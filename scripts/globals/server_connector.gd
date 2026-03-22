extends Node

var socket := WebSocketPeer.new()
signal server_connector_message_bus(message: String)

var cryptoUtil = UserCrypto.new()

@export var websocket_url = "ws://91.98.164.230:8888/ws"

var _is_connected = false

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
		_is_connected = true
		while socket.get_available_packet_count():
			server_connector_message_bus.emit(socket.get_packet().get_string_from_ascii())
			
	elif state == WebSocketPeer.STATE_CLOSED:
		if _is_connected:
			_is_connected = false
			print("Disconnected. Code: %d, Reason: %s" % [socket.get_close_code(), socket.get_close_reason()])

			await get_tree().create_timer(3.0).timeout
			connect_to_server()

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
