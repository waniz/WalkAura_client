extends Node

signal signal_LoginResult(result)
signal signal_AccountDataReceived(result)
signal signal_UserStepLastTSReceived(data)


func _ready() -> void:
	ServerConnector.server_connector_message_bus.connect(parse_message)


func parse_message(message):
	if "[Client]" in message:
		return
		
	if "{" not in message:
		return
		
	message = message.substr(9)
	
	var json = JSON.new()
	var error = json.parse(message)
	if error == OK:
		pass
	else:
		printerr("JSON Parse Error: ", json.get_error_message(), " in ", message, " at line ", json.get_error_line())

	# router
	if json.data.cmd == "login_user":
		check_login_result(json.data)
	elif json.data.cmd == "account_attributes":
		get_account_attrs(json.data)
	elif json.data.cmd == "_handle_user_steps_last_ts":
		update_account_steps(json.data)
		

# router handlers
func check_login_result(json_msg):
	if json_msg.ok == true:
		signal_LoginResult.emit(true)
	else:
		signal_LoginResult.emit(false)
		
func get_account_attrs(json_msg):
	Account.user_uid = json_msg.data.user_uid
	Account.userid = int(json_msg.data.userid)
	Account.username = json_msg.data.username
	# primary parameters
	Account.str = json_msg.data.primary_attributes.str
	Account.agi = json_msg.data.primary_attributes.agi
	Account.vit = json_msg.data.primary_attributes.vit
	Account.int_stat = json_msg.data.primary_attributes.int_stat
	Account.spi = json_msg.data.primary_attributes.spi
	Account.luk = json_msg.data.primary_attributes.luk
	# primary_resources
	Account.hp = int(json_msg.data.primary_resources.hp)
	Account.mp = int(json_msg.data.primary_resources.mp)
	Account.shield = int(json_msg.data.primary_resources.shield)
	Account.hp_max = int(json_msg.data.primary_resources.hp_max)
	Account.mp_max = int(json_msg.data.primary_resources.mp_max)
	Account.shield_max = int(json_msg.data.primary_resources.shield_max)
	Account.level = int(json_msg.data.primary_resources.level)
	Account.total_steps = int(json_msg.data.primary_resources.total_steps)
	Account.buffer_steps = int(json_msg.data.primary_resources.buffer_steps)
	Account.buffer_steps_max = int(json_msg.data.primary_resources.buffer_steps_max)
	Account.gold = int(json_msg.data.primary_resources.gold)
	# secondary parameters
	Account.atk = json_msg.data.offensive.atk
	Account.m_atk = json_msg.data.offensive.m_atk
	Account.hit_rating = json_msg.data.offensive.hit_rating
	Account.crit_chance = json_msg.data.offensive.crit_chance
	Account.crit_damage = json_msg.data.offensive.crit_damage
	Account.haste = json_msg.data.offensive.haste
	Account.armor_pen = json_msg.data.offensive.armor_pen
	Account.magic_pen = json_msg.data.offensive.magic_pen
	
	Account.p_def = json_msg.data.defensive.p_def
	Account.m_def = json_msg.data.defensive.m_def
	Account.block_chance = json_msg.data.defensive.block_chance
	Account.evasion = json_msg.data.defensive.evasion
	Account.dmg_reduction = json_msg.data.defensive.dmg_reduction
	
	Account.res_fire = json_msg.data.resistances.res_fire
	Account.res_frost = json_msg.data.resistances.res_frost
	Account.res_lightning = json_msg.data.resistances.res_lightning
	Account.res_poison = json_msg.data.resistances.res_poison
	Account.res_death = json_msg.data.resistances.res_death
	Account.res_holy = json_msg.data.resistances.res_holy
	
	# statuses
	Account.location = int(json_msg.data.statuses.location)
	Account.activity = int(json_msg.data.statuses.activity)
	
	signal_AccountDataReceived.emit(true)

func update_account_steps(data):
	signal_UserStepLastTSReceived.emit(data)
