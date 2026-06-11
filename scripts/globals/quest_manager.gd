extends Node

# QuestManager — real quest data layer (replaces the P3 QuestStub).
#
# Source of truth is the server (see WalkAura_client/QUEST_PROTOCOL.md). This
# autoload:
#   - sends the quest RPCs (get_quests / accept_quest / turn_in_quest /
#     resolve_npc_dialogue / location_opened) via ServerConnector,
#   - ingests the server responses + push events (routed here by AccountManager),
#   - maps the server QuestView shape into the UI dict shape the quest log +
#     detail screens already consume, and re-emits signal_QuestsUpdated.
#
# Tracking is client-local (the server has no tracking concept). Abandon is NOT
# supported server-side, so abandon() is intentionally a no-op.

signal signal_QuestsUpdated
signal signal_QuestObjectiveProgress(quest_id: String, objective_idx: int, progress: int, total: int)
signal signal_QuestReadyToTurnIn(quest_id: String)
signal signal_AvailableQuestsUpdated

# UI-shape quest dicts (see _map_quest). Populated from server data.
var quests: Array = []

# NPC-grouped offers for the "Available" tab (see ingest_available_quests).
# Shape: [{npc_uid, name, quests: [{quest_uid, title, description, level, rewards, type}]}]
var available_npcs: Array = []

# Client-local tracked quest_uid (server has no tracking). "" = none.
var _tracked_uid: String = ""
# Last-known state_version per quest_uid, to drop stale/out-of-order pushes.
var _state_versions: Dictionary = {}

# Objective-type → icon for the UI checklist.
const _OBJ_ICON = {
	"step_threshold": "👣",
	"reach_location": "🗺",
	"gather": "🌿",
	"defeat": "⚔",
	"craft": "⚗",
}
# Objective-type → UI "type" bucket (drives card styling).
const _OBJ_TYPE = {
	"step_threshold": "story",
	"reach_location": "explore",
	"gather": "gather",
	"defeat": "slay",
	"craft": "craft",
}


func _ready() -> void:
	# Refresh quests once account data has loaded after login.
	if has_node("/root/AccountManager") and AccountManager.has_signal("signal_AccountDataReceived"):
		AccountManager.signal_AccountDataReceived.connect(_on_account_data_received)


func _on_account_data_received(_ok: bool) -> void:
	request_quests()


# ── Outbound RPCs ───────────────────────────────────────────────────────────

# get_quests is server-rate-limited to 1/s. One step batch can complete
# several quests at once, each quest_completed_toast requesting a refresh —
# leading edge sends immediately, repeats inside the window coalesce into
# one trailing refresh so the list never goes stale.
var _quests_request_cooldown: bool = false
var _quests_request_queued: bool = false

func request_quests() -> void:
	if _quests_request_cooldown:
		_quests_request_queued = true
		return
	_quests_request_cooldown = true
	ServerConnector.send_message({"cmd": "get_quests"})
	get_tree().create_timer(1.2).timeout.connect(func():
		_quests_request_cooldown = false
		if _quests_request_queued:
			_quests_request_queued = false
			request_quests()
	)


func request_available_quests(location_id: int) -> void:
	ServerConnector.send_message({"cmd": "get_available_quests", "payload": {"location_id": location_id}})


func accept_quest(quest_uid: String) -> void:
	if quest_uid == "":
		return
	ServerConnector.send_message({"cmd": "accept_quest", "payload": {"quest_uid": quest_uid}})


func turn_in(quest_uid: String) -> void:
	if quest_uid == "":
		return
	ServerConnector.send_message({"cmd": "turn_in_quest", "payload": {"quest_uid": quest_uid}})


func resolve_npc_dialogue(npc_uid: String) -> void:
	if npc_uid == "":
		return
	ServerConnector.send_message({"cmd": "resolve_npc_dialogue", "payload": {"npc_uid": npc_uid}})


func location_opened(location_uid: String) -> void:
	if location_uid == "":
		return
	ServerConnector.send_message({"cmd": "location_opened", "payload": {"location_uid": location_uid}})


# Abandon is not supported server-side (no WS verb). Kept for API stability;
# callers should hide/disable the abandon affordance.
func abandon(_quest_uid: String) -> void:
	push_warning("QuestManager.abandon: not supported server-side; ignoring")


func set_tracked(quest_uid: String) -> void:
	_tracked_uid = quest_uid
	for q in quests:
		q["is_tracked"] = (q.get("id") == quest_uid)
	signal_QuestsUpdated.emit()


# ── Inbound (routed here by AccountManager.parse_message) ───────────────────

func ingest_quests(data: Dictionary) -> void:
	# data = {active:[QuestView], ready_to_turn_in:[QuestView], completed:[{...}]}
	var out: Array = []
	for qv in _as_array(data.get("active")):
		out.append(_map_quest(qv, "active"))
	for qv in _as_array(data.get("ready_to_turn_in")):
		out.append(_map_quest(qv, "active"))
	for cq in _as_array(data.get("completed")):
		out.append(_map_completed(cq))
	quests = out
	_refresh_state_versions()
	signal_QuestsUpdated.emit()


func ingest_available_quests(data: Dictionary) -> void:
	# data = {location_id, npcs:[{npc_uid, name, quests:[{quest_uid, title,
	# description, level_requirement, rewards, repeat_mode, objective_type}]}]}
	var out: Array = []
	for npc in _as_array(data.get("npcs")):
		var npc_quests: Array = []
		for q in _as_array(npc.get("quests")):
			var otype: String = q.get("objective_type", "")
			var repeat_mode: String = q.get("repeat_mode", "one_shot")
			npc_quests.append({
				"quest_uid": q.get("quest_uid", ""),
				"title": q.get("title", ""),
				"description": q.get("description", ""),
				"level": int(q.get("level_requirement", 1)),
				"type": _OBJ_TYPE.get(otype, "story"),
				"icon": _OBJ_ICON.get(otype, "•"),
				"is_daily": (repeat_mode != "one_shot"),
				"rewards": _map_rewards(_as_array(q.get("rewards", []))),
			})
		out.append({
			"npc_uid": npc.get("npc_uid", ""),
			"name": npc.get("name", ""),
			"quests": npc_quests,
		})
	available_npcs = out
	signal_AvailableQuestsUpdated.emit()


func ingest_quest_accepted(data: Dictionary) -> void:
	var qv: Dictionary = data.get("quest", {})
	if qv.is_empty():
		return
	_upsert(_map_quest(qv, "active"))
	# Accepted quest leaves the Available list; drop it locally + refresh Active.
	var quid: String = qv.get("quest_uid", "")
	if quid != "":
		for npc in available_npcs:
			npc["quests"] = npc["quests"].filter(func(q): return q.get("quest_uid") != quid)
		available_npcs = available_npcs.filter(func(n): return not n["quests"].is_empty())
		signal_AvailableQuestsUpdated.emit()
	signal_QuestsUpdated.emit()


func ingest_quest_turned_in(data: Dictionary) -> void:
	# data = {quest_uid, state, state_version, rewards_granted, turn_in_mode, ...}
	var uid: String = data.get("quest_uid", "")
	for q in quests:
		if q.get("id") == uid:
			q["status"] = "done"
			q["is_ready_to_turn_in"] = false
			q["is_tracked"] = false
	if _tracked_uid == uid:
		_tracked_uid = ""
	signal_QuestsUpdated.emit()


func ingest_progress(data: Dictionary) -> void:
	# data = {quest_uid, progress, state, state_version}
	var uid: String = data.get("quest_uid", "")
	var sv: int = int(data.get("state_version", 0))
	if _state_versions.has(uid) and sv <= int(_state_versions[uid]):
		return  # stale / out-of-order push
	_state_versions[uid] = sv
	var prog: Dictionary = _as_dict(data.get("progress"))
	var state: String = data.get("state", "active")
	for q in quests:
		if q.get("id") != uid:
			continue
		_apply_progress(q, prog)
		var idx = 0
		for ob in q.get("objectives", []):
			signal_QuestObjectiveProgress.emit(uid, idx, int(ob.get("count", 0)), int(ob.get("total", 0)))
			idx += 1
		if state == "ready_to_turn_in":
			q["is_ready_to_turn_in"] = true
			signal_QuestReadyToTurnIn.emit(uid)
	signal_QuestsUpdated.emit()


# ── Public read helpers (preserved API) ─────────────────────────────────────

func active_quests() -> Array:
	var out: Array = []
	for q in quests:
		if q.get("status") == "active":
			out.append(q)
	return out


func has_ready_quest() -> bool:
	for q in quests:
		if q.get("is_ready_to_turn_in", false):
			return true
	return false


func tracked_quest() -> Dictionary:
	for q in quests:
		if q.get("is_tracked", false):
			return q
	return {}


# ── Mapping helpers ─────────────────────────────────────────────────────────

func _map_quest(qv: Dictionary, status: String) -> Dictionary:
	var objectives: Array = []
	var server_objs: Array = _as_array(qv.get("objectives"))
	var progress: Dictionary = _as_dict(qv.get("progress"))
	for ob in server_objs:
		var otype: String = ob.get("objective_type", "")
		var oid = str(ob.get("objective_id", ""))
		var pr: Dictionary = progress.get(oid, {})
		objectives.append({
			"oid": oid,
			"label": ob.get("description", ""),
			"count": int(pr.get("count", 0)),
			"total": int(pr.get("target", _target_from_params(ob))),
			"icon": _OBJ_ICON.get(otype, "•"),
		})
	var first_type: String = ""
	if not server_objs.is_empty():
		first_type = server_objs[0].get("objective_type", "")
	var repeat_mode: String = qv.get("repeat_mode", "one_shot")
	var ui_status = status
	if repeat_mode != "one_shot" and status == "active":
		ui_status = "daily"
	var is_ready: bool = (qv.get("state", "") == "ready_to_turn_in")
	return {
		"id": qv.get("quest_uid", ""),
		"type": _OBJ_TYPE.get(first_type, "story"),
		"tier": (0 if str(qv.get("chain_id", "")).begins_with("main") else 1),
		"name": qv.get("title", ""),
		"level": int(qv.get("level_requirement", 1)),
		"lore": qv.get("description", ""),
		"giver": qv.get("giver_npc_uid", ""),
		"turnin_location": "",
		"objectives": objectives,
		"rewards": _map_rewards(qv.get("rewards", [])),
		"is_tracked": (qv.get("quest_uid", "") == _tracked_uid),
		"is_ready_to_turn_in": is_ready,
		"status": ui_status,
	}


func _map_completed(cq: Dictionary) -> Dictionary:
	return {
		"id": cq.get("quest_uid", ""),
		"type": "story",
		"tier": 0,
		"name": cq.get("quest_uid", ""),
		"level": 1,
		"lore": "",
		"giver": "",
		"turnin_location": "",
		"objectives": [],
		"rewards": [],
		"is_tracked": false,
		"is_ready_to_turn_in": false,
		"status": "done",
	}


func _map_rewards(server_rewards: Array) -> Array:
	var out: Array = []
	for r in server_rewards:
		var rtype: String = r.get("type", "")
		match rtype:
			"gold":
				out.append({"type": "gold", "value": int(r.get("amount", 0)), "icon": "⛁"})
			"xp":
				out.append({"type": "xp", "value": int(r.get("amount", 0)), "icon": "⦿",
					"kind": String(r.get("kind", "")), "profession": String(r.get("profession", ""))})
			"item":
				out.append({"type": "item", "name": r.get("item_uid", ""), "quality": int(r.get("quality", 1)), "icon": "◆"})
			"title":
				out.append({"type": "title", "name": ServerParams.title_name(r.get("title_id", 0)), "icon": "✦"})
			"world_state_flag":
				pass  # not player-facing
			_:
				out.append({"type": rtype, "value": r.get("amount", 0), "icon": "•"})
	return out


func _target_from_params(ob: Dictionary) -> int:
	var p: Dictionary = ob.get("params", {})
	if p.has("steps"):
		return int(p.get("steps", 1))
	if p.has("count"):
		return int(p.get("count", 1))
	return 1


func _apply_progress(q: Dictionary, server_progress: Dictionary) -> void:
	# server_progress is keyed by objective_id. Match each UI objective by its
	# stored "oid" so progress lands on the right row regardless of dict order.
	for ob in q.get("objectives", []):
		var oid: String = str(ob.get("oid", ""))
		if oid == "" or not server_progress.has(oid):
			continue
		var entry: Dictionary = server_progress[oid]
		ob["count"] = int(entry.get("count", ob.get("count", 0)))
		ob["total"] = int(entry.get("target", ob.get("total", 1)))


func _upsert(mapped: Dictionary) -> void:
	for i in quests.size():
		if quests[i].get("id") == mapped.get("id"):
			quests[i] = mapped
			return
	quests.append(mapped)


func _as_array(v) -> Array:
	return v if typeof(v) == TYPE_ARRAY else []


func _as_dict(v) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else {}


func _refresh_state_versions() -> void:
	# Seed _state_versions from a fresh full load isn't available here (the
	# get_quests payload doesn't include state_version for active rows in the
	# UI map), so progress pushes are gated only against prior pushes. Clearing
	# avoids dropping the first push after a reload.
	_state_versions.clear()
