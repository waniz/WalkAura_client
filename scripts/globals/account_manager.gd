extends Node

signal signal_LoginResult(result)
signal signal_AccountDataReceived(result)

signal signal_LoginParamsReceived(data)
signal signal_UserStepLastTSReceived(data)
signal signal_ActivityProgressReceived(data)
signal signal_InventoryReceived(data)

signal signal_AllSkillsReceived(data)
signal signal_AccountSkillsReceived(data)

signal signal_RiftFightsReceived(data)


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
	if error != OK:
		printerr("JSON Parse Error: ", json.get_error_message(), " in ", message, " at line ", json.get_error_line())
		return

	# router
	if json.data.cmd == "login_user":
		check_login_result(json.data)
	elif json.data.cmd == "login_params":
		get_login_params(json.data)
	elif json.data.cmd == "account_attributes":
		get_account_attrs(json.data)
	elif json.data.cmd == "_handle_user_steps_last_ts":
		update_account_steps(json.data)
	elif json.data.cmd == "activity_progress":
		show_activity_progress(json.data)
	elif json.data.cmd == "inventory":
		update_inventory(json.data)
	elif json.data.cmd == "all_skills_list":
		update_game_skills(json.data)
	elif json.data.cmd == "skills_update":
		update_skills(json.data)
	elif json.data.cmd == "rift_fights":
		update_rift_fights(json.data)
	elif json.data.cmd == "disenchant_result":
		handle_disenchant_result(json.data)
	elif json.data.cmd == "profession_info":
		handle_profession_info(json.data)
		

# router handlers
func check_login_result(json_msg):
	if json_msg.ok == true:
		signal_LoginResult.emit(true)
	else:
		signal_LoginResult.emit(false)
		signal_AccountDataReceived.emit(true)
		
func get_login_params(data):
	signal_LoginParamsReceived.emit(data)
		
func get_account_attrs(json_msg):
	var d = json_msg.data

	# Bulk-assign groups via set() to avoid 100+ individual property lookups.
	# Each section iterates a dict of {Account_property: value}.
	_bulk_set(d.primary_attributes, [
		"str", "agi", "vit", "int_stat", "spi", "luk",
		"str_exp", "agi_exp", "vit_exp", "int_exp", "spi_exp", "luk_exp",
		"bonus_str", "bonus_agi", "bonus_vit", "bonus_int", "bonus_spi", "bonus_luk",
	])

	Account.user_uid = d.user_uid
	Account.userid = int(d.userid)
	Account.username = d.username

	_bulk_set_int(d.primary_resources, [
		"hp", "mp", "shield", "hp_max", "mp_max", "shield_max",
		"level", "total_steps", "buffer_steps", "buffer_steps_max", "gold",
	])
	Account.level_exp = d.primary_resources.level_exp

	_bulk_set_int(d.professions, [
		"herbalism_lvl", "mining_lvl", "woodcutting_lvl", "fishing_lvl",
		"hunting_lvl", "blacksmithing_lvl", "tailoring_lvl", "jewelcrafting_lvl",
		"alchemy_lvl", "cooking_lvl", "enchanting_lvl",
		"herbalism_xp", "mining_xp", "woodcutting_xp", "fishing_xp",
		"hunting_xp", "blacksmithing_xp", "tailoring_xp", "jewelcrafting_xp",
		"alchemy_xp", "cooking_xp", "enchanting_xp",
	])
	Account.rift_lvl = int(d.professions.get("rift_lvl", 1))
	Account.rift_xp = int(d.professions.get("rift_xp", 0))

	_bulk_set_int(d.passives, [
		"thick_skin_lvl", "thick_skin_xp",
		"brutal_finish_lvl", "brutal_finish_xp",
		"magic_ward_lvl", "magic_ward_xp",
		"guardian_shell_lvl", "guardian_shell_xp",
		"evasion_training_lvl", "evasion_training_xp",
		"mana_flow_lvl", "mana_flow_xp",
		"regenerative_steps_lvl", "regenerative_steps_xp",
	])

	var sa = d.secondary_attributes
	_bulk_set(sa, [
		"atk", "m_atk",
		"hit_rating", "crit_chance_rating", "crit_damage_rating", "haste_rating",
		"armor_pen_rating", "magic_pen_rating", "versatility_rating",
		"p_def_rating", "m_def_rating", "block_chance_rating",
		"dodge_rating", "dmg_reduction_rating",
		"hit", "crit_chance", "crit_damage", "haste",
		"armor_pen", "magic_pen", "versatility",
		"p_def", "m_def", "block_chance", "dodge", "dmg_reduction",
	])

	# New affix ratings (use .get with defaults for backwards-compat)
	for key in [
		"hp_regen_battle_rating", "mp_regen_battle_rating",
		"shield_regen_battle_rating", "life_steal_rating",
		"precision_rating", "shield_absorb_bonus_rating",
		"thorns_rating", "crit_dmg_reduction_rating",
		"walk_regen_bonus_rating", "healing_amp_rating",
	]:
		Account.set(key, sa.get(key, 0))

	for key in [
		"hp_regen_battle", "mp_regen_battle", "shield_regen_battle",
		"life_steal", "precision", "shield_absorb_bonus",
		"thorns", "crit_dmg_reduction", "walk_regen_bonus", "healing_amp",
	]:
		Account.set(key, sa.get(key, 0.0))

	# Statuses
	var st = d.statuses
	Account.location = int(st.location)
	Account.activity = int(st.activity)
	Account.activity_site = int(st.activity_site)

	for key in ["rift_id", "rift_steps", "rift_steps_max",
				 "rift_milestone_index", "rift_total_milestones",
				 "travel_destination", "travel_steps", "travel_steps_max",
				 "avatar_id", "crafting_steps"]:
		Account.set(key, int(st.get(key, 0)))

	Account.rift_instance_id = str(st.get("rift_instance_id", ""))
	Account.crafting_recipe_id = str(st.get("crafting_recipe_id", ""))

	Account.variance = d.internal.variance
	Account.vit_crit_soften = d.internal.vit_crit_soften
	Account.spirit_healing_mult = d.internal.spirit_healing_mult

	update_client_visuals()

	signal_AccountDataReceived.emit(true)


## Bulk helpers — reduce per-property overhead by iterating arrays
func _bulk_set(source: Dictionary, keys: Array) -> void:
	for key in keys:
		Account.set(key, source[key])

func _bulk_set_int(source: Dictionary, keys: Array) -> void:
	for key in keys:
		Account.set(key, int(source[key]))
	
func update_client_visuals():
	var min_atk = snappedf(Account.atk * (1 - Account.variance), 0.1)
	var max_atk = snappedf(Account.atk * (1 + Account.variance), 0.1)
	
	var min_m_atk = snappedf(Account.m_atk * (1 - Account.variance), 0.1)
	var max_m_atk = snappedf(Account.m_atk * (1 + Account.variance), 0.1)
		
	Account.atk = str("{0} - {1}".format([min_atk, max_atk]))
	Account.m_atk = str("{0} - {1}".format([min_m_atk, max_m_atk]))
	
func update_account_steps(data):
	signal_UserStepLastTSReceived.emit(data)
	
func show_activity_progress(data):
	signal_ActivityProgressReceived.emit(data)

func update_inventory(data):
	signal_InventoryReceived.emit(data)
	
func update_game_skills(data):
	Account.raw_structures.all_server_skills = data
	signal_AllSkillsReceived.emit(data)
	
func update_skills(data):
	Account.raw_structures.account_skills = data
	signal_AccountSkillsReceived.emit(data)

func update_rift_fights(data):
	signal_RiftFightsReceived.emit(data)

func handle_disenchant_result(json_msg) -> void:
	SignalManager.signal_DisenchantResultReceived.emit(json_msg.data)

func handle_profession_info(json_msg) -> void:
	SignalManager.signal_ProfessionInfoReceived.emit(json_msg.data)
