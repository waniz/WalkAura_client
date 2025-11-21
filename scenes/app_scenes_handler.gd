extends Control
class_name AppScenesHandler

signal page_changed(index: int)

@export var swipe_slop_px := 12.0
@export var snap_threshold_px := 80.0
@export var fling_velocity_px_s := 600.0
@export var anim_time := 0.18

var _track: HBoxContainer = null
var _page := 0
var _pages := 0

var _maybe_swipe := false       # pressed, but not sure it's a swipe yet
var _swiping := false           # once true, we take over events
var _start_pos := Vector2.ZERO
var _last_x := 0.0
var _last_t := 0.0
var _velocity := 0.0

const ACTIVITY_PROGRESS_SCENE = preload("uid://bjvtquos2r8cj")
var overlay = null


func _enter_tree() -> void:
	_track = HBoxContainer.new()
	_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_track.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	add_child(_track)

func _ready() -> void:
	AccountManager.signal_ActivityProgressReceived.connect(_show_progress_hud)

	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS

	var to_move := get_children()
	for n in to_move:
		if n != _track:
			remove_child(n)
			_track.add_child(n)

	_layout_pages()
	_snap_to(_page, 0.0)
	
	
# ------ Handle global update window ------
func _show_progress_hud(payload):
	overlay = ACTIVITY_PROGRESS_SCENE.instantiate()
	add_child(overlay)
	
	overlay.apply_activity_progress(payload["data"]["data"])
	overlay.tree_exited.connect(_on_child_closed, Object.CONNECT_ONE_SHOT)
	
func _on_child_closed() -> void:
	overlay = null

# ------ API ------
func _notification(what):
	if what == NOTIFICATION_RESIZED and _track:
		_layout_pages()
		_snap_to(_page, 0.0)

func _layout_pages() -> void:
	var i := 0
	for c in _track.get_children():
		if c.name == "ProgressUpdate":
			continue
		if c.name == "GlobalHud":
			continue
		if c is Control:
			var cc := c as Control
			cc.custom_minimum_size = size
			cc.size = size
			cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cc.size_flags_vertical   = Control.SIZE_EXPAND_FILL
			cc.position = Vector2(i * size.x, 0)
			i += 1
	_pages = max(0, i - 1)

# ---------------------- INPUT ----------------------
func _input(e: InputEvent) -> void:
	var inside := get_global_rect().has_point(get_viewport().get_mouse_position())

	# TOUCH
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
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
		var d := e as InputEventScreenDrag
		if _maybe_swipe and not _swiping:
			var dx := d.position.x - _start_pos.x
			var dy := d.position.y - _start_pos.y
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
	var dx := curr_x - _start_pos.x
	var base := -_page * size.x
	var target := base + dx

	# rubber band at edges
	var min_x := -_pages * size.x
	var max_x := 0.0
	if target < min_x:
		target = lerpf(min_x, target, 0.5)
	elif target > max_x:
		target = lerpf(max_x, target, 0.5)

	_track.position.x = target

	var now := Time.get_ticks_msec() / 1000.0
	var dt = max(0.001, now - _last_t)
	_velocity = (curr_x - _last_x) / dt
	_last_x = curr_x
	_last_t = now

func _end_swipe(end_x: float) -> void:
	_maybe_swipe = false
	var drag := end_x - _start_pos.x
	var next := _page

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
		emit_signal("page_changed", _page)
	_snap_to(_page, anim_time)
	_swiping = false

func _snap_to(index: int, duration: float) -> void:
	var target := -index * size.x
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_track, "position:x", target, duration)
