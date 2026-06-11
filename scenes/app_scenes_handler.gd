extends Control
class_name AppScenesHandler

@export var swipe_slop_px = 12.0
@export var snap_threshold_px = 80.0
@export var fling_velocity_px_s = 600.0
@export var anim_time = 0.18

var _track: HBoxContainer = null
var _page = 2
var _pages = 0

var _maybe_swipe = false       # pressed, but not sure it's a swipe yet
var _swiping = false           # once true, we take over events
var _start_pos = Vector2.ZERO
var _last_x = 0.0
var _last_t = 0.0
var _velocity = 0.0

const ACTIVITY_PROGRESS_SCENE = preload("uid://bjvtquos2r8cj")
const RIFT_DETAIL_SCENE = preload("res://scenes/secondary_scenes/rift_detail.tscn")
const RIFT_ACTIVE_SCENE = preload("res://scenes/secondary_scenes/rift_active.tscn")
const RIFT_FIGHT_RESULT = preload("res://scenes/secondary_scenes/rift_fight_result.gd")
const AVATARS_SCENE = preload("uid://dp38cogt60cii")
const DISENCHANT_RESULT_SCENE = preload("res://scenes/support_screens/disenchant_result.tscn")
const PROFESSION_DETAIL_SCENE = preload("res://scenes/secondary_scenes/profession_detail.tscn")
const NPC_DIALOGUE_SCENE = preload("res://scenes/secondary_scenes/npc_dialogue.gd")
const QUEST_REWARD_MODAL = preload("res://scenes/secondary_scenes/quest_reward_modal.gd")
const _SKIP_LAYOUT_NAMES = ["ProgressUpdate", "ProgressSteps", "GlobalHud", "DisenchantResult"]
var overlay = null
var _rift_overlay = null
var _avatars_overlay = null
var _disenchant_overlay = null
var _profession_overlay = null
var _npc_dialogue_overlay = null
var _quest_reward_overlay = null
var _snap_tween: Tween = null
var _first_progress_after_login: bool = true


func _enter_tree() -> void:
	_track = HBoxContainer.new()
	_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_track.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_track.add_theme_constant_override("separation", 0)
	add_child(_track)

func _ready() -> void:
	AccountManager.signal_ActivityProgressReceived.connect(_show_progress_hud)
	SignalManager.signal_PageChanged.connect(_on_page_change)
	SignalManager.signal_ShowRift.connect(_show_rift)
	AccountManager.signal_AccountDataReceived.connect(_on_account_rift_check)
	SignalManager.signal_ShowAvatars.connect(_show_avatars)
	SignalManager.signal_DisenchantResultReceived.connect(_show_disenchant_result)
	SignalManager.signal_ShowProfession.connect(_show_profession)
	SignalManager.signal_RequestNpcDialogue.connect(_show_npc_dialogue)
	SignalManager.signal_QuestTurnedIn.connect(_on_quest_turned_in)
	SignalManager.signal_QuestCompletedToast.connect(_on_quest_completed_toast)

	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS

	var to_move = get_children()
	for n in to_move:
		if n != _track:
			if n.name == "ProgressSteps":
				continue  # keep as direct child of AppScenesHandler, rendered above _track
			remove_child(n)
			_track.add_child(n)

	_layout_pages()
	_snap_to(_page, 0.0)
	
	
# ------ Handle global update window ------
func _show_progress_hud(payload):
	var d: Dictionary = payload.get("data", {}).get("data", {})
	var steps_in = int(d.get("steps_in", 0))
	var has_fights = not d.get("milestone_fights", []).is_empty()
	if steps_in == 0 and int(d.get("xp_gained", 0)) == 0 and not has_fights:
		return

	# Rift pending_fight: don't interrupt the player with a loadout screen.
	# Just show steps via the toast — the player will fight when they open the rift.
	if d.get("pending_fight", false):
		if steps_in > 0:
			SignalManager.signal_StepToastUpdate.emit(steps_in, {}, {}, [])
		return

	# Rift fight results — show dedicated fight result screen
	var rift_complete = d.get("rift_complete", false)
	var rift_died = d.get("rift_died", false)
	var is_rift_event = has_fights or rift_complete or rift_died

	if is_rift_event and has_fights:
		_first_progress_after_login = false
		var fights = d.get("milestone_fights", [])
		if fights.size() > 0:
			var result_screen = RIFT_FIGHT_RESULT.new()
			result_screen.fight_data = fights[0]
			result_screen.progress_data = d
			add_child(result_screen)
		return

	# Non-rift: gathering/crafting/first-login progress
	if _first_progress_after_login:
		_first_progress_after_login = false
		overlay = ACTIVITY_PROGRESS_SCENE.instantiate()
		add_child(overlay)
		overlay.apply_activity_progress(d)
		overlay.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)
	else:
		_first_progress_after_login = false
		var loot = d.get("loot_counts", {})
		var mapping = d.get("mapping", {})
		var new_items = d.get("new_items", [])
		SignalManager.signal_StepToastUpdate.emit(steps_in, loot, mapping, new_items)

	# Notify player if activity was auto-stopped due to full inventory
	if d.get("inventory_full", false):
		SignalManager.signal_GameNotification.emit(
			"Inventory full - activity stopped!", Color.from_rgba8(255, 100, 100))
	
func _on_child_closed() -> void:
	overlay = null

func _show_rift(location_id: int) -> void:
	if _rift_overlay != null and is_instance_valid(_rift_overlay):
		return
	var rift_id = int(Account.rift_id) if Account.rift_id != null else 0
	if rift_id > 0:
		_rift_overlay = RIFT_ACTIVE_SCENE.instantiate()
	else:
		_rift_overlay = RIFT_DETAIL_SCENE.instantiate()
		_rift_overlay.location_id = location_id
	add_child(_rift_overlay)
	_rift_overlay.tree_exited.connect(func(): _rift_overlay = null, Object.CONNECT_ONE_SHOT)


func _on_account_rift_check(_ok) -> void:
	# If player just entered a rift and detail screen is showing, it will self-close.
	# If rift ended and active screen is showing, it will self-close.
	# This handler exists for the case where rift starts and we need to show active view.
	pass

func _show_avatars() -> void:
	if _avatars_overlay != null and is_instance_valid(_avatars_overlay):
		return
	_avatars_overlay = AVATARS_SCENE.instantiate()
	add_child(_avatars_overlay)
	_avatars_overlay.tree_exited.connect(func(): _avatars_overlay = null, Object.CONNECT_ONE_SHOT)

func _show_profession(profession_name: String) -> void:
	if _profession_overlay != null and is_instance_valid(_profession_overlay):
		return
	_profession_overlay = PROFESSION_DETAIL_SCENE.instantiate()
	_profession_overlay.set_profession(profession_name)
	add_child(_profession_overlay)
	_profession_overlay.tree_exited.connect(func(): _profession_overlay = null, Object.CONNECT_ONE_SHOT)

func _show_npc_dialogue(npc_uid: String) -> void:
	if _npc_dialogue_overlay != null and is_instance_valid(_npc_dialogue_overlay):
		return
	_npc_dialogue_overlay = NPC_DIALOGUE_SCENE.new()
	_npc_dialogue_overlay.npc_uid = npc_uid
	add_child(_npc_dialogue_overlay)
	_npc_dialogue_overlay.tree_exited.connect(func(): _npc_dialogue_overlay = null, Object.CONNECT_ONE_SHOT)

func _on_quest_turned_in(data: Dictionary) -> void:
	var rewards = data.get("rewards_granted", [])
	_show_quest_reward(String(data.get("quest_uid", "")), rewards if typeof(rewards) == TYPE_ARRAY else [])

func _on_quest_completed_toast(data: Dictionary) -> void:
	var result = data.get("result", {})
	var rewards = result.get("rewards_granted", []) if typeof(result) == TYPE_DICTIONARY else []
	_show_quest_reward(String(data.get("quest_uid", "")), rewards if typeof(rewards) == TYPE_ARRAY else [])

func _show_quest_reward(quest_uid: String, rewards: Array) -> void:
	if _quest_reward_overlay != null and is_instance_valid(_quest_reward_overlay):
		_quest_reward_overlay.queue_free()
	_quest_reward_overlay = QUEST_REWARD_MODAL.new()
	_quest_reward_overlay.quest_uid = quest_uid
	_quest_reward_overlay.rewards = rewards
	add_child(_quest_reward_overlay)
	_quest_reward_overlay.tree_exited.connect(func(): _quest_reward_overlay = null, Object.CONNECT_ONE_SHOT)

func _show_disenchant_result(data: Dictionary) -> void:
	if _disenchant_overlay != null and is_instance_valid(_disenchant_overlay):
		_disenchant_overlay.queue_free()
	_disenchant_overlay = DISENCHANT_RESULT_SCENE.instantiate()
	add_child(_disenchant_overlay)
	_disenchant_overlay.apply_result(data)
	_disenchant_overlay.tree_exited.connect(func(): _disenchant_overlay = null, Object.CONNECT_ONE_SHOT)

# ------ API ------
func _notification(what):
	if what == NOTIFICATION_RESIZED and _track:
		_layout_pages()
		_snap_to(_page, 0.0)

func _layout_pages() -> void:
	var i = 0
	for c in _track.get_children():
		if c.name in _SKIP_LAYOUT_NAMES:
			continue
		if c is Control:
			var cc = c as Control
			cc.custom_minimum_size = size
			cc.set_deferred("size", size)
			cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cc.size_flags_vertical   = Control.SIZE_EXPAND_FILL
			cc.position = Vector2(i * size.x, 0)
			i += 1
	_pages = max(0, i - 1)

# ---------------------- INPUT ----------------------
func _input(e: InputEvent) -> void:
	var inside = get_global_rect().has_point(get_viewport().get_mouse_position())

	# TOUCH
	if e is InputEventScreenTouch:
		var t = e as InputEventScreenTouch
		if t.pressed and inside:
			_maybe_swipe = true
			_swiping = false
			_start_pos = t.position
			_last_x = t.position.x
			_last_t = Time.get_ticks_msec() / 1000.0
			_velocity = 0.0
			# Do NOT accept yet. Let children see the press for clicks.
		elif not t.pressed:
			if _swiping:
				_end_swipe(t.position.x)
				accept_event()    # we owned the gesture, so consume the release
				# else: not swiping => let it pass as a normal tap

	elif e is InputEventScreenDrag:
		var d = e as InputEventScreenDrag
		if _maybe_swipe and not _swiping:
			var dx = d.position.x - _start_pos.x
			var dy = d.position.y - _start_pos.y
			if abs(dx) > swipe_slop_px and abs(dx) > abs(dy):
				# We’re confident it’s a horizontal swipe → take over
				_swiping = true
				_snap_to(_page, 0.0)  # cancel any running tween
		if _swiping:
			_move_track(d.position.x)
			accept_event()  # consume while swiping so buttons don't get dragged

	# MOUSE (desktop testing)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and inside:
			_maybe_swipe = true
			_swiping = false
			_start_pos = e.position
			_last_x = e.position.x
			_last_t = Time.get_ticks_msec() / 1000.0
			_velocity = 0.0
		elif not e.pressed:
			if _swiping:
				_end_swipe(e.position.x)
				accept_event()
				
	elif e is InputEventMouseMotion:
		if _maybe_swipe and not _swiping and e.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			var dx = e.position.x - _start_pos.x
			var dy = e.position.y - _start_pos.y
			if abs(dx) > swipe_slop_px and abs(dx) > abs(dy):
				_swiping = true
				_snap_to(_page, 0.0)
		if _swiping and (e.button_mask & MOUSE_BUTTON_MASK_LEFT != 0):
			_move_track(e.position.x)
			accept_event()

# ---------------------- SWIPE HELPERS ----------------------
func _move_track(curr_x: float) -> void:
	var dx = curr_x - _start_pos.x
	var base = -_page * size.x
	var target = base + dx

	# rubber band at edges
	var min_x = -_pages * size.x
	var max_x = 0.0
	if target < min_x:
		target = lerpf(min_x, target, 0.5)
	elif target > max_x:
		target = lerpf(max_x, target, 0.5)

	_track.position.x = target

	var now = Time.get_ticks_msec() / 1000.0
	var dt = max(0.001, now - _last_t)
	_velocity = (curr_x - _last_x) / dt
	_last_x = curr_x
	_last_t = now

func _end_swipe(end_x: float) -> void:
	_maybe_swipe = false
	var drag = end_x - _start_pos.x
	var next = _page

	if abs(_velocity) > fling_velocity_px_s:
		if _velocity < 0.0: next += 1
		else: next -= 1
	elif abs(drag) >= snap_threshold_px:
		if drag < 0.0: next += 1
		else: next -= 1

	next = clamp(next, 0, _pages)
	_go_to(next)

func _go_to(index: int) -> void:
	if index != _page:
		_page = index
		SignalManager.signal_PageChanged.emit(_page)
	_snap_to(_page, anim_time)
	_swiping = false

func _snap_to(index: int, duration: float) -> void:
	if is_instance_valid(_snap_tween):
		_snap_tween.kill()
	_snap_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_snap_tween.tween_property(_track, "position:x", -index * size.x, duration)
	
func _on_page_change(index) -> void:
	_page = index
	_snap_to(index, anim_time)
	_swiping = false
