class_name StepsUpdateView extends Control

@onready var panel_container: PanelContainer = $PanelContainer
@onready var steps_label: Label = $PanelContainer/MarginContainer/StepsLabel

var _hide_timer: Timer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	Styler.style_panel_no_margins(panel_container, Color.from_rgba8(16, 18, 24, 220), Color.from_rgba8(255, 200, 66, 200))
	var sb := panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_left = 12
		sb.corner_radius_bottom_right = 12
	Styler.style_name_label(steps_label, Color.from_rgba8(255, 215, 128))

	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = 10.0
	_hide_timer.timeout.connect(func(): visible = false)
	add_child(_hide_timer)

	SignalManager.signal_StepsReceivedFromServer.connect(_on_steps_received)
	visible = false

func _on_steps_received(amount: int) -> void:
	if amount <= 0:
		return
	steps_label.text = "+%d steps received" % amount
	visible = true
	_hide_timer.start()
