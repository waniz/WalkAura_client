extends Node

var socket = WebSocketPeer.new()
signal server_connector_message_bus(message: String)

var cryptoUtil = UserCrypto.new()

@export var websocket_url = "wss://api.walkaura.app/ws"

var _is_connected = false

# Part A: Credential storage
var _saved_username: String = ""
var _saved_password: String = ""
var _was_authenticated: bool = false
# Persistent session token (auto-login on app entry). Minted by the server on
# successful login, stored on disk in user://, re-sent via login_token on the
# next launch. The password is never persisted — only this token is.
var _saved_token: String = ""
const AUTH_FILE := "user://auth.cfg"

# Part B: Heartbeat constants and state
# App-level liveness probe. Distinct from Tornado's protocol ping/pong
# (websocket_ping_interval=30 server-side, which handles SERVER-side dead-socket
# cleanup). This heartbeat exists for CLIENT-side fast dead-detection: STATE_CLOSED
# lags on silent mobile network drops, so we probe and time out to trigger the
# reconnect overlay. Interval matched to the server ping cadence (30s) to minimise
# foreground-idle radio wakeups (battery) while keeping worst-case detection ~40s.
const HEARTBEAT_INTERVAL = 30.0
const HEARTBEAT_TIMEOUT = 10.0
var _heartbeat_timer: float = 0.0
var _heartbeat_pending: bool = false
var _heartbeat_timeout_timer: float = 0.0
var _connection_healthy: bool = true
var _auto_login_in_progress: bool = false
var suppress_reconnect_overlay: bool = false

# Part C: Reconnection overlay
var _reconnect_overlay: CanvasLayer = null

# Part E: Version mismatch state. Set when the server rejects our
# client_hello. When true we stop auto-reconnecting — retrying would just
# bounce against the same version gate forever.
var _version_blocked: bool = false
var _update_overlay: CanvasLayer = null

func _ready() -> void:

	# Load any persisted session token before connecting so the STATE_OPEN
	# handler can auto-login as soon as the socket opens.
	_load_token()

	connect_to_server()

	SignalManager.signal_CreateUser.connect(_on_user_creating)
	SignalManager.signal_LoginUser.connect(_on_user_login)
	SignalManager.signal_LoginToken.connect(_on_token_login)
	SignalManager.signal_LoginGoogle.connect(_on_google_login)
	# Handshake failure stops auto-reconnect and shows the update modal.
	AccountManager.signal_VersionMismatch.connect(_on_version_mismatch)
	# Handshake success gates auto-login: we only send login_token AFTER the
	# server acks client_hello. Sending it earlier (same frame as the hello)
	# made the server close the socket with version_mismatch (code 4000).
	AccountManager.signal_HandshakeAck.connect(_on_handshake_ack)

	SignalManager.signal_UserActivity.connect(_on_user_activity)

	SignalManager.signal_StepsUpdatesCheats.connect(_on_step_counter_cheat_update)
	SignalManager.signal_StepsSimulateOffline.connect(_on_steps_simulate_offline)
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
	SignalManager.signal_RequestRiftHistory.connect(_on_request_rift_history)
	SignalManager.signal_TravelRequest.connect(_on_travel_request)
	SignalManager.signal_TravelCostRequest.connect(_on_travel_cost_request)
	SignalManager.signal_AvatarChanged.connect(_on_avatar_changed)
	SignalManager.signal_RequestProfessionInfo.connect(_on_request_profession_info)
	SignalManager.signal_UseRecipeScroll.connect(_on_use_recipe_scroll)
	SignalManager.signal_StartCraftActivity.connect(_on_start_craft_activity)
	SignalManager.signal_TalentAllocate.connect(_on_talent_allocate_request)
	SignalManager.signal_TalentRespec.connect(_on_talent_respec_request)
	SignalManager.signal_TalentCheatPoints.connect(_on_talent_cheat_points_request)
	SignalManager.signal_RequestAchievements.connect(_on_request_achievements)
	SignalManager.signal_ClaimAchievement.connect(_on_claim_achievement)
	SignalManager.signal_SetActiveTitle.connect(_on_set_active_title)
	SignalManager.signal_RequestStepStats.connect(_on_request_step_stats)


func connect_to_server() -> void:
	# --- FIX: Increase Buffer Size ---
	# Default is often 64KB (65536). Let's set it to 10MB to be safe.
	socket.inbound_buffer_size = 1 * 1024 * 1024
	# ---------------------------------

	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		server_connector_message_bus.emit("[Client] ERROR: Cannot connect to server")
		set_process(false)

func _drain_pending_packets() -> void:
	# Drain buffered frames. Run BEFORE any state-specific handling so
	# messages arriving just before the server closes (e.g., version_mismatch
	# immediately followed by close()) are still parsed. Without this the
	# 3s reconnect timer beats _on_version_mismatch to _version_blocked and
	# the client bounces against the version gate forever.
	while socket.get_available_packet_count():
		var raw_msg = socket.get_packet().get_string_from_ascii()
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

func _process(_delta: float) -> void:
	socket.poll()

	var state = socket.get_ready_state()

	# Drain packets regardless of state so close-followed-by-data is safe.
	_drain_pending_packets()

	if state == WebSocketPeer.STATE_OPEN:
		if not _is_connected:
			_is_connected = true
			server_connector_message_bus.emit("[Client] Connected to server ... ")
			# Reset heartbeat state on fresh connection
			_heartbeat_timer = 0.0
			_heartbeat_pending = false
			_heartbeat_timeout_timer = 0.0
			# Handshake: must be the first client->server frame. Server gates
			# every other command behind this, so any later send (auto-login,
			# heartbeat, etc.) would close the socket with version_mismatch.
			# Auto-login is deferred to _on_handshake_ack — sending login_token
			# here (before the ack) is exactly what triggered the 4000 close.
			_send_client_hello()

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
			# Reset auto-login state. If the socket closed mid-flight (e.g. a 4000
			# close races the login_token round-trip), _on_auto_login_data never
			# fires, so _auto_login_in_progress would stay true and suppress the
			# next connection's auto-login — leaving the reconnect overlay stuck.
			_auto_login_in_progress = false
			_auto_login_ok = false
			if AccountManager.signal_LoginResult.is_connected(_on_auto_login_result):
				AccountManager.signal_LoginResult.disconnect(_on_auto_login_result)
			if AccountManager.signal_AccountDataReceived.is_connected(_on_auto_login_data):
				AccountManager.signal_AccountDataReceived.disconnect(_on_auto_login_data)
			print("Disconnected. Code: %d, Reason: %s" % [socket.get_close_code(), socket.get_close_reason()])
			if _was_authenticated:
				_show_reconnect_overlay()

			await get_tree().create_timer(3.0).timeout
			if _version_blocked:
				# Client is out of date. Reconnecting would loop forever
				# against the version gate — stop the process entirely.
				return
			connect_to_server()

# When the OS backgrounds the app, Godot freezes _process, so heartbeat timers
# freeze mid-flight (a heartbeat may be left pending). On resume, clear that stale
# state so the very first post-resume frame doesn't instantly trip HEARTBEAT_TIMEOUT
# and flash the reconnect overlay before the socket is even re-evaluated.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_heartbeat_timer = 0.0
		_heartbeat_pending = false
		_heartbeat_timeout_timer = 0.0
		_connection_healthy = true

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
var _auto_login_ok = false

# Fired when the server acks our client_hello. Only now is it safe to send an
# auth command. Covers both first connect and reconnect; the in-progress guard
# inside _auto_login() makes a duplicate ack a no-op.
func _on_handshake_ack() -> void:
	if Time.get_unix_time_from_system() < _auto_login_blocked_until:
		return
	if _was_authenticated and _saved_token != "":
		_auto_login()


# Auth attempts are IP-rate-limited server-side (5/min). When a login_token
# reply comes back rate_limited, AccountManager calls this instead of wiping
# the token: block auto-login for the server-provided window, then retry once.
var _auto_login_blocked_until: float = 0.0

func notify_login_rate_limited(retry_after: int) -> void:
	var wait = maxi(retry_after, 10)
	# The failed attempt consumed its one-shot signals; clear the in-progress
	# latch so the post-window retry isn't a no-op on a still-open socket.
	_auto_login_in_progress = false
	_auto_login_blocked_until = Time.get_unix_time_from_system() + wait
	get_tree().create_timer(wait + 1.0).timeout.connect(func():
		if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_on_handshake_ack()
	)

func _auto_login() -> void:
	if _auto_login_in_progress:
		return
	if _saved_token == "":
		return
	_auto_login_in_progress = true
	_auto_login_ok = false
	AccountManager.signal_LoginResult.connect(_on_auto_login_result, CONNECT_ONE_SHOT)
	AccountManager.signal_AccountDataReceived.connect(_on_auto_login_data, CONNECT_ONE_SHOT)
	_on_token_login(_saved_token)


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
	# Best-effort: tell the server to invalidate the persistent token so it
	# can't be reused. Local wipe happens regardless of socket state.
	if _saved_token != "" and _is_socket_open():
		socket.send_text(JSON.stringify({"cmd": "logout", "payload": {}}))
	_saved_username = ""
	_saved_password = ""
	_saved_token = ""
	_was_authenticated = false
	if FileAccess.file_exists(AUTH_FILE):
		DirAccess.remove_absolute(AUTH_FILE)

func has_saved_token() -> bool:
	return _saved_token != ""

# Persist a server-minted session token to disk for auto-login on next launch.
# Called by AccountManager when a login_user / login_token response carries one.
func _save_token(token: String) -> void:
	if token == "":
		return
	_saved_token = token
	_was_authenticated = true
	var cfg = ConfigFile.new()
	cfg.set_value("auth", "token", token)
	cfg.save(AUTH_FILE)

func _load_token() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(AUTH_FILE) != OK:
		return
	var token = cfg.get_value("auth", "token", "")
	if typeof(token) == TYPE_STRING and token != "":
		_saved_token = token
		_was_authenticated = true

# Token-based login (auto-login + reconnect). Payload-wrapped per WS contract.
func _on_token_login(token) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	_was_authenticated = true
	var payload = {
		"cmd": "login_token",
		"payload": {"token": token},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting token login...")

# Google login: send the Google ID token for server-side verification. On
# success the server mints + returns our session token (persisted like any
# other login). Payload-wrapped per WS contract.
func _on_google_login(id_token) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	_was_authenticated = true
	var payload = {
		"cmd": "login_google",
		"payload": {"id_token": id_token},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting Google login...")

# ################################
# """Signal compilator section"""

func _is_socket_open() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func send_message(data: Dictionary) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	socket.send_text(JSON.stringify(data))

# Sent unconditionally as the first frame after socket OPEN. Server rejects
# every other command until it sees this; the response is either
# client_hello_ack (we can proceed) or cmd=version_mismatch followed by a
# socket close (client is out of date).
func _send_client_hello() -> void:
	var payload = {
		"cmd": "client_hello",
		"payload": {
			"client_version": str(ProjectSettings.get_setting("application/config/version", "")),
		}
	}
	socket.send_text(JSON.stringify(payload))

func _on_user_creating(user, password) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	var payload = {
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
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	# Part A: Save credentials on login
	_saved_username = user
	_saved_password = password
	_was_authenticated = true

	var payload = {
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
	var payload = {
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
	var payload = {
		"cmd": "steps_update_cheat",
		"payload": {
			"amount": amount,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending cheat steps: {0}".format([amount]))

func _on_steps_simulate_offline(amount) -> void:
	var payload = {
		"cmd": "steps_update_cheat",
		"payload": {
			"amount": amount,
			"simulate_offline": true,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Simulate offline login: {0} steps".format([amount]))

func _on_step_counter_android_request_last_ts(is_requested) -> void:
	if not is_requested or not _was_authenticated:
		return

	var payload = {
		"cmd": "steps_request_last_ts",
		"payload": {
			"data": true,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending android steps request last ts")

func _on_step_counter_android_update(data) -> void:
	var payload = {
		"cmd": "steps_update_android",
		"payload": {
			"data": data,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Sending android steps to server")

func _on_inventory_request(action) -> void:
	var payload = {
		"cmd": "inventory",
		"payload": {
			"action": action,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Request Inventory: {0}".format([action]))

func _on_useitem_request(item_to_use, qty: int) -> void:
	var payload = {
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
	var payload = {
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
	var payload = {
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
	var payload = {
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
	var payload = {
		"cmd": "inventory",
		"payload": {
			"action": "disenchant",
			"item_uid": item_uid,
		}
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Request to Disenchant item %s" % item_uid)

func _on_sell_items_request(item_uids: Array) -> void:
	var payload = {
		"cmd": "inventory",
		"payload": {
			"action": "sell_batch",
			"item_uids": item_uids,
		}
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Request to Sell %d items" % item_uids.size())

func _on_equip_skill_request(idx, skill_id):
	var payload = {
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
	var payload = {
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
	var payload = {
		"cmd": "rift_fights",
		"payload": {
			"rift_instance_id": rift_instance_id,
		}
	}
	var server_request = JSON.stringify(payload)
	socket.send_text(server_request)
	server_connector_message_bus.emit("[Client] Requesting rift fights for: {0}".format([rift_instance_id]))

func _on_request_rift_history() -> void:
	socket.send_text(JSON.stringify({"cmd": "rift_history", "payload": {}}))
	server_connector_message_bus.emit("[Client] Requesting rift history")

func _on_request_rift_fight_log(rift_instance_id: String, fight_uid: String) -> void:
	var payload = {
		"cmd": "rift_fights",
		"payload": {"rift_instance_id": rift_instance_id, "fight_uid": fight_uid},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting fight log for fight: {0}".format([fight_uid]))

func _on_travel_cost_request(location_id: int) -> void:
	var payload = {
		"cmd": "travel_cost",
		"payload": {"location": location_id},
	}
	socket.send_text(JSON.stringify(payload))

func _on_travel_request(location_id: int) -> void:
	var payload = {
		"cmd": "travel",
		"payload": {"location": location_id},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting travel to location: %d" % location_id)

func _on_avatar_changed(avatar_id: int) -> void:
	var payload = {"cmd": "set_avatar", "payload": {"avatar_id": avatar_id}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Set avatar: " + str(avatar_id))

func _on_request_profession_info(profession: String) -> void:
	var payload = {
		"cmd": "profession_info",
		"payload": {"profession": profession},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting profession info: %s" % profession)


func _on_use_recipe_scroll(recipe_id: String, item_uid: String) -> void:
	var payload = {
		"cmd": "use_recipe_scroll",
		"payload": {
			"recipe_id": recipe_id,
			"item_uid": item_uid,
		},
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit(
		"[Client] use_recipe_scroll: %s via %s" % [recipe_id, item_uid]
	)


func _on_start_craft_activity(activity: int, activity_site: int, recipe_id: String, target_qty: int) -> void:
	var payload = {
		"cmd": "activity",
		"payload": {
			"activity": activity,
			"activity_site": activity_site,
			"action": "start",
			"recipe_id": recipe_id,
			"target_qty": target_qty,
		}
	}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Starting craft: %s x%d" % [recipe_id, target_qty])

func _on_talent_allocate_request(talent_id: String) -> void:
	var payload = {"cmd": "talents", "payload": {"action": "allocate", "talent_id": talent_id}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Allocating talent point: %s" % talent_id)

func _on_talent_respec_request() -> void:
	var payload = {"cmd": "talents", "payload": {"action": "respec"}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting talent respec")

func _on_talent_cheat_points_request(points: int) -> void:
	var payload = {"cmd": "talents", "payload": {"action": "cheat_points", "points": points}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Cheat: adding %d talent points" % points)

func _on_request_achievements() -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	var payload = {"cmd": "get_achievements", "payload": {}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting achievements")

func _on_request_step_stats(period: String) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	var payload = {"cmd": "get_step_stats", "payload": {"period": period}}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Requesting step stats: %s" % period)

func _on_claim_achievement(achievement_id: int, chosen_attr) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	var body = {"achievement_id": achievement_id}
	if chosen_attr != null and chosen_attr != "":
		body["chosen_attr"] = chosen_attr
	var payload = {"cmd": "claim_achievement", "payload": body}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Claiming achievement %d" % achievement_id)

func _on_set_active_title(title_id) -> void:
	if not _is_socket_open():
		server_connector_message_bus.emit("[Client] ERROR: Not connected to server")
		return
	var body = {"title_id": title_id}   # null to clear
	var payload = {"cmd": "set_active_title", "payload": body}
	socket.send_text(JSON.stringify(payload))
	server_connector_message_bus.emit("[Client] Setting active title %s" % str(title_id))


# Part E: Version mismatch overlay
func _on_version_mismatch(info: Dictionary) -> void:
	_version_blocked = true
	# Hide the "Reconnecting..." overlay if it's up — the update modal takes
	# over as the authoritative message. Also suppress the reconnect overlay
	# so no later close/reopen cycle flashes it.
	_hide_reconnect_overlay()
	suppress_reconnect_overlay = true
	_show_update_overlay(info)

func _show_update_overlay(info: Dictionary) -> void:
	if _update_overlay != null:
		return
	_update_overlay = CanvasLayer.new()
	_update_overlay.layer = 300  # above reconnect overlay
	add_child(_update_overlay)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_overlay.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Update Required"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var body = Label.new()
	body.text = GameTextEn.error_texts.get("version_mismatch", "Your game version is out of date.")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(380, 0)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(body)

	var versions = Label.new()
	versions.text = "Your version: %s\nRequired: %s" % [
		str(info.get("client_version", ServerParams.client_version())),
		str(info.get("required", "")),
	]
	versions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versions.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(versions)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var btn_update = Button.new()
	btn_update.text = "Update Now"
	btn_update.pressed.connect(_on_update_now_pressed)
	row.add_child(btn_update)

	var btn_close = Button.new()
	btn_close.text = "Close Game"
	btn_close.pressed.connect(_on_close_game_pressed)
	row.add_child(btn_close)

func _on_update_now_pressed() -> void:
	OS.shell_open(ServerParams.UPDATE_URL)

func _on_close_game_pressed() -> void:
	get_tree().quit()
