extends Node

var cached_rift_pending_monster: Dictionary = {}
const OFFLINE_PROGRESS_VIEW = preload("res://scenes/secondary_scenes/offline_progress.gd")

# Active-activity id -> profession name, for patching ServerParams.profession_levels
# from activity_progress ticks. Mirrors location_hub.gd's ACTIVITY_PROF_NAME.
const _PROGRESS_ACTIVITY_PROF = {
	1: "herbalism",
	2: "alchemy",
	3: "hunting",
	4: "mining",
	5: "woodcutting",
	6: "fishing",
	7: "rift",
}

signal signal_LoginResult(ok: bool, error: String)
signal signal_AccountDataReceived(result)
signal signal_CreateUserResult(ok: bool, error: String)
# Emitted when the server's client_hello reply says our version is out of
# date. Payload is a Dictionary with keys: server_version, required,
# client_version. Listened to by login_scene to show the update modal.
signal signal_VersionMismatch(info: Dictionary)
# Emitted when the server acknowledges our client_hello handshake. ServerConnector
# waits for this before sending any auth command (auto-login), so login_token is
# never sent before the handshake completes — sending early gets the socket closed
# with a version_mismatch (4000).
signal signal_HandshakeAck

signal signal_LoginParamsReceived(data)
signal signal_UserStepLastTSReceived(data)
signal signal_ActivityProgressReceived(data)
signal signal_InventoryReceived(data)

signal signal_AllSkillsReceived(data)
signal signal_AccountSkillsReceived(data)

signal signal_RiftFightsReceived(data)
signal signal_RiftHistoryReceived(data)

signal signal_TalentsConfigReceived(data)
signal signal_TalentsDataReceived(data)


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
	var cmd: String = json.data.cmd
	if cmd == "login_user":
		check_login_result(json.data)
	elif cmd == "login_token":
		check_login_result(json.data)
	elif cmd == "login_google":
		check_login_result(json.data)
	elif cmd == "create_user":
		_handle_create_user_result(json.data)
	elif cmd == "login_params":
		get_login_params(json.data)
	elif cmd == "account_attributes":
		get_account_attrs(json.data)
	elif cmd == "_handle_user_steps_last_ts":
		update_account_steps(json.data)
	elif cmd == "activity_progress":
		# Diagnostic: surface activity_progress arrivals + key data fields.
		var _ap_inner = json.data.get("data", {}).get("data", {})
		print("[diag] activity_progress arrived: steps_in=%s xp_gained=%s loot_counts=%s" % [
			_ap_inner.get("steps_in", "?"),
			_ap_inner.get("xp_gained", "?"),
			_ap_inner.get("loot_counts", "?"),
		])
		# Keep the world-map availability data fresh: the progress tick carries
		# the active profession's current level. Patch our level map so the map
		# tooltip reflects in-session level-ups without a reconnect.
		var _prof = _PROGRESS_ACTIVITY_PROF.get(Account.activity, "")
		var _prof_lvl = int(_ap_inner.get("level", 0))
		if _prof != "" and _prof_lvl > 0:
			ServerParams.profession_levels[_prof] = _prof_lvl
		show_activity_progress(json.data)
	elif cmd == "offline_progress":
		var summary = json.data.get("data", {})
		print("[diag] offline_progress arrived: steps=%s xp=%s" % [
			summary.get("steps", "?"), summary.get("xp_gained", "?")])
		var view = OFFLINE_PROGRESS_VIEW.new()
		view.data = summary
		# Root, NOT current scene: survives login→hub transition and stays
		# out of app_scenes_handler's swipe pager.
		get_tree().root.add_child(view)
	elif cmd in ["steps_update_cheat", "steps_update_android"]:
		var steps_amount = int(json.data.get("data", {}).get("steps", 0))
		print("[diag] %s arrived: steps=%s Account.activity=%s" % [cmd, steps_amount, Account.activity])
		if steps_amount > 0 and Account.activity == 0:
			SignalManager.signal_StepToastUpdate.emit(steps_amount, {}, {}, [])
	elif cmd == "inventory":
		update_inventory(json.data)
	elif cmd == "all_skills_list":
		update_game_skills(json.data)
	elif cmd == "skills_update":
		update_skills(json.data)
	elif cmd == "rift_pending_info":
		var info = json.data.get("data", {})
		cached_rift_pending_monster = info.get("pending_monster", {})
		# Also emit for any already-connected listeners
		var wrapped = {"data": {"data": info}}
		signal_ActivityProgressReceived.emit(wrapped)
	elif cmd == "rift_fights":
		update_rift_fights(json.data)
	elif cmd == "rift_history":
		signal_RiftHistoryReceived.emit(json.data)
	elif cmd == "disenchant_result":
		handle_disenchant_result(json.data)
	elif cmd == "profession_info":
		handle_profession_info(json.data)
	elif cmd == "use_recipe_scroll":
		# Fold the learned recipe into Account.known_recipes so the next
		# profession_info request renders the recipe normally instead of as
		# a locked placeholder. Server is the source of truth; this just
		# avoids a stale cache moment between learn and the next refresh.
		var _scroll_data = json.data.get("data", {}) if json.data is Dictionary else {}
		if _scroll_data.get("status", "") == "learned":
			var rid = _scroll_data.get("recipe_id", "")
			if rid != "" and not Account.known_recipes.has(rid):
				Account.known_recipes.append(rid)
		SignalManager.signal_RecipeScrollResult.emit(_scroll_data)
	elif cmd == "achievements":
		SignalManager.signal_AchievementsReceived.emit(json.data.get("data", {}))
	elif cmd == "achievement_claimed":
		SignalManager.signal_AchievementClaimed.emit(json.data.get("data", {}))
	elif cmd == "achievement_ready":
		var _ar = json.data.get("data", {})
		if not (_ar is Dictionary): _ar = {}
		SignalManager.signal_AchievementReady.emit(_ar.get("ready_ids", []))
	elif cmd == "active_title_set":
		var _at = json.data.get("data", {})
		if not (_at is Dictionary): _at = {}
		SignalManager.signal_ActiveTitleSet.emit(_at.get("active_title"))
	elif cmd == "step_stats":
		SignalManager.signal_StepStatsReceived.emit(json.data.get("data", {}))
	elif cmd == "talents_config":
		Account.raw_structures.talents_config = json.data.data
		signal_TalentsConfigReceived.emit(json.data.data)
	elif cmd in ["talents_data", "talent_allocate", "talent_respec", "talent_points_earned"]:
		Account.raw_structures.talents_data = json.data.data
		signal_TalentsDataReceived.emit(json.data.data)
	elif cmd == "travel_cost":
		var data = json.data.get("data", {})
		SignalManager.signal_TravelCostReceived.emit(
			int(data.get("location", 0)),
			int(data.get("steps", 0))
		)
	elif cmd == "travel_passing_through":
		_handle_travel_passing_through(json.data)
	elif cmd == "quests":
		QuestManager.ingest_quests(json.data.get("data", {}))
	elif cmd == "quest_accepted":
		QuestManager.ingest_quest_accepted(json.data.get("data", {}))
	elif cmd == "quest_turned_in":
		var _tdata = json.data.get("data", {})
		QuestManager.ingest_quest_turned_in(_tdata)
		SignalManager.signal_QuestTurnedIn.emit(_tdata)
	elif cmd == "quest_progress":
		QuestManager.ingest_progress(json.data.get("data", {}))
	elif cmd == "quest_completed_toast":
		var _cdata = json.data.get("data", {})
		QuestManager.request_quests()
		SignalManager.signal_QuestCompletedToast.emit(_cdata)
	elif cmd == "npc_dialogue":
		SignalManager.signal_NpcDialogueReceived.emit(json.data.get("data", {}))
	elif cmd == "location_opened_ack":
		pass
	elif cmd == "location_npcs":
		SignalManager.signal_LocationNpcsReceived.emit(json.data.get("data", {}))
	elif cmd == "available_quests":
		QuestManager.ingest_available_quests(json.data.get("data", {}))
	elif cmd == "version_mismatch":
		_handle_version_mismatch(json.data)
	elif cmd == "client_hello_ack":
		# Handshake confirmed. Tell ServerConnector it may now auto-login.
		signal_HandshakeAck.emit()
	elif cmd.begins_with("error:"):
		_handle_server_error(json.data)
		

# router handlers
func check_login_result(json_msg):
	# Server now returns failures as {ok:false, cmd:"login_user", data:{code, message, ...}}.
	# Legacy fallback reads `error` in case an older build is connected.
	# Emits the raw error code (not display text) — consumers format it via
	# GameTextEn.error_texts so the server contract stays machine-readable.
	if json_msg.get("ok", false) == true:
		# Persist the session token (if the server minted one) so the next app
		# launch can auto-login without the password.
		var tok = json_msg.get("data", {}).get("auth_token", "")
		if tok != "":
			ServerConnector._save_token(tok)
		signal_LoginResult.emit(true, "")
		return
	var data = json_msg.get("data", {})
	var code: String = data.get("code", json_msg.get("error", "server_error"))
	if json_msg.get("cmd", "") == "login_token":
		if code == "rate_limited":
			# Transient IP throttle, not a bad token — keep the token and
			# back off auto-login. Wiping here logged users out whenever a
			# flaky mobile network made the reconnect loop burn the 5/min
			# auth budget.
			ServerConnector.notify_login_rate_limited(int(data.get("retry_after_seconds", 0)))
		else:
			# A rejected token (expired/unknown): wipe the stored token so
			# the next launch falls back to the manual login screen.
			ServerConnector.clear_credentials()
	signal_LoginResult.emit(false, code)
	signal_AccountDataReceived.emit(true)


func _handle_create_user_result(json_msg) -> void:
	if json_msg.get("ok", false) == true:
		signal_CreateUserResult.emit(true, "")
		return
	var data = json_msg.get("data", {})
	var code: String = data.get("code", "registration_failed")
	signal_CreateUserResult.emit(false, code)


func _handle_version_mismatch(json_msg) -> void:
	var data = json_msg.get("data", {})
	var info = {
		"server_version": data.get("server_version", ""),
		"required": data.get("required", ""),
		"client_version": data.get("client_version", ""),
	}
	signal_VersionMismatch.emit(info)


# Dispatch table for server error codes to client behavior. Kept as a flat
# dict so a future code is one line to wire up. Unknown codes fall through to
# a generic toast so nothing gets swallowed silently.
const _ERROR_TOAST_CODES = {
	"inventory_full":   Color(1.0, 0.39, 0.39),
	"skill_too_low":    Color(0.9, 0.55, 0.35),
	"server_error":     Color(1.0, 0.39, 0.39),
	"bad_request":      Color(1.0, 0.39, 0.39),
	# Active spell slot validation. duplicate_skill is legitimate feedback;
	# the other two indicate client/server drift and should also be logged.
	"duplicate_skill":  Color(0.9, 0.55, 0.35),
	"unknown_skill":    Color(1.0, 0.39, 0.39),
	"slot_out_of_range": Color(1.0, 0.39, 0.39),
	"internal_error":   Color(1.0, 0.39, 0.39),
}

func _handle_server_error(json_msg) -> void:
	var data = json_msg.get("data", {})
	var code: String = data.get("code", "")
	var display: String = _display_for_error(code, data)
	# Login/register failure responses route through their dedicated cmd
	# handlers above — this path is for codes that arrive via the generic
	# "error: ..." channel (rate limit, server error, inventory full, etc.).
	if code == "rate_limited":
		# Per-handler throttle on background requests (quest refresh bursts,
		# step stats). The request retries naturally; a toast here reads
		# like an account problem to the player — log it and stay silent.
		print("[diag] rate_limited (silent): ", data.get("message", ""))
	elif code in _ERROR_TOAST_CODES:
		SignalManager.signal_GameNotification.emit(display, _ERROR_TOAST_CODES[code])
	elif code == "version_mismatch":
		_handle_version_mismatch(json_msg)
	else:
		# Unknown code — still show something so the user isn't left guessing.
		SignalManager.signal_GameNotification.emit(display, Color(1.0, 0.5, 0.5))


func _display_for_error(code: String, data: Dictionary) -> String:
	# Prefer the localized string keyed by `code`. Fall back to the server
	# message text, then to "Unknown error" so we never render an empty toast.
	var text: String = GameTextEn.error_texts.get(code, "")
	if text == "":
		text = data.get("message", "Unknown error")
	# Optional reason subcode overlay (e.g., username_invalid + too_short).
	var reason: String = data.get("reason", "")
	if reason != "" and GameTextEn.error_reason_texts.has(reason):
		text = "%s %s" % [text, GameTextEn.error_reason_texts[reason]]
	# Rate-limit specifically gets the countdown appended.
	var retry_after = data.get("retry_after_seconds", 0)
	if code == "rate_limited" and int(retry_after) > 0:
		text = "%s (wait %ds)" % [text, int(retry_after)]
	return text
		
func get_login_params(data):
	# `data` is the full WS envelope {ok, cmd, data}; the login params live under
	# data["data"] (same nesting ServerParams.on_login_params_received reads).
	# Server is the source of truth for rift metadata; overwrite RiftData's
	# baked-in fallback so server retunes propagate without editing the client.
	var params = data.get("data", {})
	RiftData.update_from_catalog(params.get("rift_catalog", []))
	signal_LoginParamsReceived.emit(data)
		
func get_account_attrs(json_msg):
	var d = json_msg.data

	# Bulk-assign groups via set() to avoid 100+ individual property lookups.
	# Each section iterates a dict of {Account_property: value}.
	Account.str_stat = d.primary_attributes["str"]
	_bulk_set(d.primary_attributes, [
		"agi", "vit", "int_stat", "spi", "luk",
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

	# Seed the world-map availability map {profession: level} from the account's
	# profession levels. login_params is pre-auth static data and carries no
	# account state, so this is the canonical seed point (runs on every login,
	# manual or token). Patched live afterwards from activity_progress ticks.
	ServerParams.profession_levels.clear()
	for prof_key in d.professions:
		var key_str = str(prof_key)
		if key_str.ends_with("_lvl"):
			ServerParams.profession_levels[key_str.trim_suffix("_lvl")] = int(d.professions[prof_key])

	_bulk_set_int(d.passives, [
		"thick_skin_lvl", "thick_skin_xp",
		"brutal_finish_lvl", "brutal_finish_xp",
		"magic_ward_lvl", "magic_ward_xp",
		"guardian_shell_lvl", "guardian_shell_xp",
		"evasion_training_lvl", "evasion_training_xp",
		"mana_flow_lvl", "mana_flow_xp",
		"regenerative_steps_lvl", "regenerative_steps_xp",
	])
	Account.pyromaniac_lvl = int(d.passives.get("pyromaniac_lvl", 0))
	Account.pyromaniac_xp = int(d.passives.get("pyromaniac_xp", 0))
	Account.permafrost_lvl = int(d.passives.get("permafrost_lvl", 0))
	Account.permafrost_xp = int(d.passives.get("permafrost_xp", 0))
	Account.devotion_lvl = int(d.passives.get("devotion_lvl", 0))
	Account.devotion_xp = int(d.passives.get("devotion_xp", 0))
	Account.shadow_mastery_lvl = int(d.passives.get("shadow_mastery_lvl", 0))
	Account.shadow_mastery_xp = int(d.passives.get("shadow_mastery_xp", 0))
	Account.arcane_mastery_lvl = int(d.passives.get("arcane_mastery_lvl", 0))
	Account.arcane_mastery_xp = int(d.passives.get("arcane_mastery_xp", 0))

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
				 "travel_route_index", "travel_current_hop_steps", "travel_current_hop_max",
				 "avatar_id", "crafting_steps", "crafting_target_qty", "crafting_batch_done"]:
		Account.set(key, int(st.get(key, 0)))
	if int(st.get("rift_id", 0)) > 0:
		print("[RIFT DEBUG] account_manager parse: activity=%s rift_steps=%s/%s from server statuses=%s" % [
			st.activity, st.get("rift_steps", "?"), st.get("rift_steps_max", "?"),
			{"rift_id": st.get("rift_id"), "rift_steps": st.get("rift_steps"), "rift_steps_max": st.get("rift_steps_max"), "activity": st.activity}])
	Account.travel_route = st.get("travel_route", [])

	Account.rift_instance_id = str(st.get("rift_instance_id", ""))
	Account.rift_pending_fight = bool(st.get("rift_pending_fight", false))
	Account.rift_pending_monster = str(st.get("rift_pending_monster", ""))
	Account.rift_pending_milestone = int(st.get("rift_pending_milestone", 0))
	Account.crafting_recipe_id = str(st.get("crafting_recipe_id", ""))

	Account.variance = d.internal.variance
	Account.vit_crit_soften = d.internal.vit_crit_soften
	Account.spirit_healing_mult = d.internal.spirit_healing_mult

	Account.active_buffs = d.get("active_buffs", {})

	Account.max_active_spell_slots = int(d.get("max_active_spell_slots", 7))

	# known_recipes: scroll-learned blacksmith (and future) recipes.
	# Server sends a sorted list; client keeps it as Array for set-style
	# membership checks via has().
	Account.known_recipes = d.get("known_recipes", [])

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

func _handle_travel_passing_through(json_msg) -> void:
	var data = json_msg.get("data", {})
	var loc_name = data.get("location_name", "")
	if loc_name != "":
		SignalManager.signal_TravelPassingThrough.emit(loc_name)
