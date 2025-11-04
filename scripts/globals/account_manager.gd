extends Node

signal signal_LoginResult(result)
signal signal_AccountDataReceived(result)
signal signal_UserStepLastTSReceived(data)
signal signal_ActivityProgressReceived(data)
signal signal_InventoryReceived(data)


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
	elif json.data.cmd == "activity_progress":
		show_activity_progress(json.data)
	elif json.data.cmd == "inventory":
		update_inventory(json.data)
		

# router handlers
func check_login_result(json_msg):
	if json_msg.ok == true:
		signal_LoginResult.emit(true)
	else:
		signal_LoginResult.emit(false)
		signal_AccountDataReceived.emit(true)
		
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
	
	Account.str_exp = json_msg.data.primary_attributes.str_exp
	Account.agi_exp = json_msg.data.primary_attributes.agi_exp
	Account.vit_exp = json_msg.data.primary_attributes.vit_exp
	Account.int_exp = json_msg.data.primary_attributes.int_exp
	Account.spi_exp = json_msg.data.primary_attributes.spi_exp
	Account.luk_exp = json_msg.data.primary_attributes.luk_exp
	# primary_resources
	Account.hp = int(json_msg.data.primary_resources.hp)
	Account.mp = int(json_msg.data.primary_resources.mp)
	Account.shield = int(json_msg.data.primary_resources.shield)
	Account.hp_max = int(json_msg.data.primary_resources.hp_max)
	Account.mp_max = int(json_msg.data.primary_resources.mp_max)
	Account.shield_max = int(json_msg.data.primary_resources.shield_max)
	Account.level = int(json_msg.data.primary_resources.level)
	Account.level_exp = json_msg.data.primary_resources.level_exp
	Account.total_steps = int(json_msg.data.primary_resources.total_steps)
	Account.buffer_steps = int(json_msg.data.primary_resources.buffer_steps)
	Account.buffer_steps_max = int(json_msg.data.primary_resources.buffer_steps_max)
	Account.gold = int(json_msg.data.primary_resources.gold)
	# professions
	Account.herbalism_lvl = int(json_msg.data.professions.herbalism_lvl)
	Account.mining_lvl = int(json_msg.data.professions.mining_lvl)
	Account.woodcutting_lvl = int(json_msg.data.professions.woodcutting_lvl)
	Account.fishing_lvl = int(json_msg.data.professions.fishing_lvl)
	Account.hunting_lvl = int(json_msg.data.professions.hunting_lvl)
	Account.blacksmithing_lvl = int(json_msg.data.professions.blacksmithing_lvl)
	Account.tailoring_lvl = int(json_msg.data.professions.tailoring_lvl)
	Account.jewelcrafting_lvl = int(json_msg.data.professions.jewelcrafting_lvl)
	Account.alchemy_lvl = int(json_msg.data.professions.alchemy_lvl)
	Account.cooking_lvl = int(json_msg.data.professions.cooking_lvl)
	Account.enchanting_lvl = int(json_msg.data.professions.enchanting_lvl)
	
	Account.herbalism_xp = int(json_msg.data.professions.herbalism_xp)
	Account.mining_xp = int(json_msg.data.professions.mining_xp)
	Account.woodcutting_xp = int(json_msg.data.professions.woodcutting_xp)
	Account.fishing_xp = int(json_msg.data.professions.fishing_xp)
	Account.hunting_xp = int(json_msg.data.professions.hunting_xp)
	Account.blacksmithing_xp = int(json_msg.data.professions.blacksmithing_xp)
	Account.tailoring_xp = int(json_msg.data.professions.tailoring_xp)
	Account.jewelcrafting_xp = int(json_msg.data.professions.jewelcrafting_xp)
	Account.alchemy_xp = int(json_msg.data.professions.alchemy_xp)
	Account.cooking_xp = int(json_msg.data.professions.cooking_xp)
	Account.enchanting_xp = int(json_msg.data.professions.enchanting_xp)
	
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
	Account.activity_site = int(json_msg.data.statuses.activity_site)
	Account.account_step_carry = int(json_msg.data.statuses.account_step_carry)
	
	Account.variance = json_msg.data.internal.variance
	Account.vit_crit_soften = json_msg.data.internal.vit_crit_soften
	Account.spirit_healing_mult = json_msg.data.internal.spirit_healing_mult
	
	update_client_visuals()
	
	signal_AccountDataReceived.emit(true)
	
func update_client_visuals():
	var min_atk = snappedf(Account.atk * (1 - Account.variance), 0.1)
	var max_atk = snappedf(Account.atk * (1 + Account.variance), 0.1)
	
	var min_m_atk = snappedf(Account.m_atk * (1 - Account.variance), 0.1)
	var max_m_atk = snappedf(Account.m_atk * (1 + Account.variance), 0.1)
		
	Account.atk = str("{0} - {1}".format([min_atk, max_atk]))
	Account.m_atk = str("{0} - {1}".format([min_m_atk, max_m_atk]))
	
	Account.crit_chance *= 100
	Account.crit_damage *= 100

func update_account_steps(data):
	signal_UserStepLastTSReceived.emit(data)
	
func show_activity_progress(data):
	signal_ActivityProgressReceived.emit(data)

func update_inventory(data):
	signal_InventoryReceived.emit(data)
