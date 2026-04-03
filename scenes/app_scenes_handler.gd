extends Control
class_name AppScenesHandler

@export var swipe_slop_px = 12.0
@export var snap_threshold_px = 80.0
@export var fling_velocity_px_s = 600.0
@export var anim_time = 0.18

var _track: HBoxContainer = null
var _page = 0
var _pages = 0

var _maybe_swipe = false       # pressed, but not sure it's a swipe yet
var _swiping = false           # once true, we take over events
var _start_pos = Vector2.ZERO
var _last_x = 0.0
var _last_t = 0.0
var _velocity = 0.0

const ACTIVITY_PROGRESS_SCENE = preload("uid://bjvtquos2r8cj")
const RIFT_SCENE = preload("uid://cdghj6jcvmuy5")
const AVATARS_SCENE = preload("uid://dp38cogt60cii")
const DISENCHANT_RESULT_SCENE = preload("res://scenes/support_screens/disenchant_result.tscn")
const PROFESSION_DETAIL_SCENE = preload("res://scenes/secondary_scenes/profession_detail.tscn")
const _SKIP_LAYOUT_NAMES = ["ProgressUpdate", "ProgressSteps", "GlobalHud", "DisenchantResult"]
var overlay = null
var _rift_overlay = null
var _avatars_overlay = null
var _disenchant_overlay = null
var _profession_overlay = null
var _snap_tween: Tween = null
var _first_progress_after_login: bool = true


func _enter_tree() -> void:
	_track = HBoxContainer.new()
	_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_track.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	add_child(_track)

func _ready() -> void:
	AccountManager.signal_ActivityProgressReceived.connect(_show_progress_hud)
	SignalManager.signal_PageChanged.connect(_on_page_change)
	SignalManager.signal_ShowRift.connect(_show_rift)
	SignalManager.signal_ShowAvatars.connect(_show_avatars)
	SignalManager.signal_DisenchantResultReceived.connect(_show_disenchant_result)
	SignalManager.signal_ShowProfession.connect(_show_profession)

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

	# Big overlay triggers:
	# - First update after login (AFK catch-up)
	# - Rift milestone fights happened
	# - Rift completed or died
	# - Level up
	var has_milestone_fights = not d.get("milestone_fights", []).is_empty()
	var rift_complete = d.get("rift_complete", false)
	var rift_died = d.get("rift_died", false)
	var leveled_up = int(d.get("levels_gained", 0)) > 0
	var is_big_update = has_milestone_fights or rift_complete or rift_died or leveled_up

	if _first_progress_after_login or is_big_update:
		_first_progress_after_login = false
		overlay = ACTIVITY_PROGRESS_SCENE.instantiate()
		add_child(overlay)
		overlay.apply_activity_progress(d)
		overlay.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)
	else:
		# Gathering/crafting progress: route to the toast with steps + loot
		_first_progress_after_login = false
		var loot = d.get("loot_counts", {})
		var mapping = d.get("mapping", {})
		var new_items = d.get("new_items", [])
		SignalManager.signal_StepToastUpdate.emit(steps_in, loot, mapping, new_items)
	
func _on_child_closed() -> void:
	overlay = null

func _show_rift() -> void:
	if _rift_overlay != null and is_instance_valid(_rift_overlay):
		return
	_rift_overlay = RIFT_SCENE.instantiate()
	add_child(_rift_overlay)
	_rift_overlay.tree_exited.connect(func(): _rift_overlay = null, Object.CONNECT_ONE_SHOT)

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
