extends Node

signal signal_LoginResult(result)
signal signal_AccountDataReceived(result)

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
		
	print(json.data)
	print("===================================")

	# router
	if json.data.cmd == "login_user":
		check_login_result(json.data)
	elif json.data.cmd == "account_attributes":
		get_account_attrs(json.data)
	elif json.data.cmd == "steps_update_cheat":
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
	# primary_resources
	Account.hp_current = json_msg.data.primary_resources.hp_current
	Account.mp_current = json_msg.data.primary_resources.mp_current
	Account.shield_current = json_msg.data.primary_resources.shield_current	
	Account.hp_max = json_msg.data.primary_resources.hp_max
	Account.mp_max = json_msg.data.primary_resources.mp_max
	Account.shield_max = json_msg.data.primary_resources.shield_max	
	Account.level = json_msg.data.primary_resources.level
	Account.total_steps = json_msg.data.primary_resources.total_steps
	Account.buffer_steps_current = json_msg.data.primary_resources.buffer_steps_current
	Account.buffer_steps_max = json_msg.data.primary_resources.buffer_steps_max
	Account.gold = json_msg.data.primary_resources.gold
	# secondary parameters
	Account.atk_power_min = json_msg.data.offensive.atk_power_min
	Account.atk_power_max = json_msg.data.offensive.atk_power_max
	Account.spell_power_min = json_msg.data.offensive.spell_power_min
	Account.spell_power_max = json_msg.data.offensive.spell_power_max
	Account.hit_rating = json_msg.data.offensive.hit_rating
	Account.crit_chance = json_msg.data.offensive.crit_chance
	Account.crit_damage = json_msg.data.offensive.crit_damage
	Account.haste = json_msg.data.offensive.haste
	Account.armor_pen = json_msg.data.offensive.armor_pen
	Account.magic_pen = json_msg.data.offensive.magic_pen
	
	Account.physical_def = json_msg.data.defensive.physical_def
	Account.magic_def = json_msg.data.defensive.magic_def
	Account.block_chance = json_msg.data.defensive.block_chance
	Account.evasion = json_msg.data.defensive.evasion
	Account.dmg_reduction = json_msg.data.defensive.dmg_reduction
	
	Account.resistance_fire = json_msg.data.resistances.resistance_fire
	Account.resistance_frost = json_msg.data.resistances.resistance_frost
	Account.resistance_lightning = json_msg.data.resistances.resistance_lightning
	Account.resistance_poison = json_msg.data.resistances.resistance_poison
	Account.resistance_death = json_msg.data.resistances.resistance_death
	Account.resistance_holy = json_msg.data.resistances.resistance_holy
	
	Account.reputations_dummy = json_msg.data.reputations.dummy
	
	# statuses
	Account.location = json_msg.data.statuses.location
	Account.activity = json_msg.data.statuses.activity
	
	signal_AccountDataReceived.emit(true)

func update_account_steps(json_msg):
	pass
