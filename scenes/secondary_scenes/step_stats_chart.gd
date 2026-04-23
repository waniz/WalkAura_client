extends PanelContainer

## Step Statistics Chart — renders a bar chart of daily/weekly/monthly step totals.
## Emits signal_RequestStepStats on mount and on dropdown change; listens for
## signal_StepStatsReceived to refresh bars. Bars drawn by StepStatsChartCanvas
## child node via _draw(). See character_profile.DESIGN.md for visual spec.

const _PERIODS = ["day", "week", "month"]
const _PERIOD_LABELS = ["Day", "Week", "Month"]
const _MIN_LOADING_MS = 200
const _LIVENESS_DEBOUNCE_MS = 6000   # min interval between live-refetches on step pushes
const _ERROR_TIMEOUT_MS = 8000       # time to wait for a response before surfacing ERROR

@onready var _title_label: Label = $Margin/VBox/Header/Title
@onready var _period_btn: OptionButton = $Margin/VBox/Header/PeriodBtn
@onready var _canvas: Control = $Margin/VBox/Canvas

var _current_period: String = "day"
var _state: String = "LOADING"   # LOADING | EMPTY | ONE_BAR | IN_PROGRESS | ERROR
var _buckets: Array = []
var _last_request_msec: int = 0
var _last_liveness_refetch_msec: int = 0
var _in_flight: bool = false
var _request_token: int = 0      # bumped per request; stale-timeout callbacks check this


func _ready() -> void:
	Styler._apply_parchment_style(self)
	_title_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)

	for i in range(_PERIODS.size()):
		_period_btn.add_item(_PERIOD_LABELS[i], i)
	_period_btn.selected = 0
	_period_btn.tooltip_text = "Change time range"
	_style_period_btn()
	_period_btn.item_selected.connect(_on_period_selected)

	_canvas.custom_minimum_size = Vector2(0, 180)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.gui_input.connect(_on_canvas_gui_input)

	focus_mode = Control.FOCUS_ALL

	SignalManager.signal_StepStatsReceived.connect(_on_stats_received)
	SignalManager.signal_StepsReceivedFromServer.connect(_on_today_step_received)

	_enter_loading_state()
	_emit_request(_current_period)


func _exit_tree() -> void:
	if SignalManager.signal_StepStatsReceived.is_connected(_on_stats_received):
		SignalManager.signal_StepStatsReceived.disconnect(_on_stats_received)
	if SignalManager.signal_StepsReceivedFromServer.is_connected(_on_today_step_received):
		SignalManager.signal_StepsReceivedFromServer.disconnect(_on_today_step_received)


func _style_period_btn() -> void:
	# Inline minimal civic-family styling if the central helper isn't present.
	_period_btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_period_btn.add_theme_font_size_override("font_size", 14)
	_period_btn.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	_period_btn.custom_minimum_size = Vector2(96, 44)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.88, 0.84, 0.74)
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.border_width_top = 1;  sb.border_width_bottom = 1
	sb.border_color = Styler.COLOR_SECTION_HDR
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 6;   sb.content_margin_bottom = 6
	_period_btn.add_theme_stylebox_override("normal", sb)
	_period_btn.add_theme_stylebox_override("hover", sb)
	_period_btn.add_theme_stylebox_override("pressed", sb)


func _emit_request(period: String) -> void:
	_last_request_msec = Time.get_ticks_msec()
	_in_flight = true
	_request_token += 1
	var my_token = _request_token
	SignalManager.signal_RequestStepStats.emit(period)
	_arm_error_timeout(my_token)


func _arm_error_timeout(token: int) -> void:
	await get_tree().create_timer(_ERROR_TIMEOUT_MS / 1000.0).timeout
	if token != _request_token:
		return  # superseded by a later request
	if _in_flight:
		_in_flight = false
		show_error()


func _on_period_selected(idx: int) -> void:
	_current_period = _PERIODS[idx]
	_enter_loading_state()
	_emit_request(_current_period)


func _on_stats_received(data: Dictionary) -> void:
	# Guard: ignore packets for a different period (user flipped dropdown fast).
	var period = data.get("period", "")
	if period != _current_period:
		return

	_in_flight = false
	_buckets = data.get("buckets", [])
	var elapsed = Time.get_ticks_msec() - _last_request_msec
	if elapsed < _MIN_LOADING_MS:
		await get_tree().create_timer((_MIN_LOADING_MS - elapsed) / 1000.0).timeout

	_resolve_state_from_buckets()
	_update_accessibility_text()
	_canvas.queue_redraw()


func _on_today_step_received(_amount: int) -> void:
	# Today-liveness: coalesce bursts. Steps fire frequently during a walk;
	# one refetch every _LIVENESS_DEBOUNCE_MS is enough to keep today's bar
	# visibly alive without flooding the socket.
	if _state == "LOADING" or _in_flight:
		return
	var now_ms = Time.get_ticks_msec()
	if now_ms - _last_liveness_refetch_msec < _LIVENESS_DEBOUNCE_MS:
		return
	_last_liveness_refetch_msec = now_ms
	_emit_request(_current_period)


func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			# Retry on tap while in ERROR state.
			if _state == "ERROR":
				_enter_loading_state()
				_emit_request(_current_period)


func _enter_loading_state() -> void:
	_state = "LOADING"
	_canvas.set_meta("state", _state)
	_canvas.set_meta("buckets", [])
	_canvas.set_meta("period", _current_period)
	_canvas.queue_redraw()


func _resolve_state_from_buckets() -> void:
	var non_empty = 0
	for b in _buckets:
		if int(b.get("steps", 0)) > 0:
			non_empty += 1
	if _buckets.is_empty() or non_empty == 0:
		_state = "EMPTY"
	elif non_empty == 1 and _current_period == "day":
		_state = "ONE_BAR"
	else:
		_state = "IN_PROGRESS"
	_canvas.set_meta("state", _state)
	_canvas.set_meta("buckets", _buckets)
	_canvas.set_meta("period", _current_period)


func _update_accessibility_text() -> void:
	var latest = 0
	if not _buckets.is_empty():
		latest = int(_buckets[-1].get("steps", 0))
	var count = _buckets.size()
	tooltip_text = "Step statistics, %s, %d bars, latest %d steps" % [_current_period, count, latest]


func show_error() -> void:
	_state = "ERROR"
	_canvas.set_meta("state", _state)
	_canvas.queue_redraw()
