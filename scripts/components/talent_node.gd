extends Control
# Single talent node for the astrolabe wheel. Built entirely in code.

signal node_tapped(talent_id: String)
signal node_long_pressed(talent_id: String)
signal node_long_released()

const DRAG_THRESHOLD_PX: float = 8.0
const LONG_PRESS_TIME: float = 0.4

var talent_id: String = ""
var talent_data: Dictionary = {}
var accent_color: Color = Color.WHITE
var _press_start: float = 0.0
var _press_pos: Vector2 = Vector2.ZERO
var _press_active: bool = false
var _long_press_fired: bool = false

var _frame: PanelContainer
var _icon_rect: TextureRect
var _name_label: Label
var _tier_dots: Array = []  # 3 ColorRect
var _pending_data: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(62, 62)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	if not _pending_data.is_empty():
		update_data(_pending_data)
		_pending_data = {}


func _build_ui() -> void:
	_frame = PanelContainer.new()
	_frame.custom_minimum_size = Vector2(62, 62)
	_frame.size = Vector2(62, 62)
	_frame.clip_contents = true
	_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_frame)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	_frame.add_child(vbox)

	# Top row: spacer + tier dots
	var top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(top_row)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var dots_box = HBoxContainer.new()
	top_row.add_child(dots_box)
	for i in range(3):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = Color(1, 1, 1, 0.25)
		dots_box.add_child(dot)
		_tier_dots.append(dot)

	# Icon
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(34, 34)
	_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(_icon_rect)

	# Name (2-line wrap)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name_label.max_lines_visible = 2
	vbox.add_child(_name_label)



func setup(id: String, data: Dictionary, color: Color) -> void:
	talent_id = id
	accent_color = color
	if _name_label != null:
		update_data(data)
	else:
		_pending_data = data


func update_data(data: Dictionary) -> void:
	talent_data = data
	if _name_label == null:
		_pending_data = data
		return

	var allocated = int(data.get("allocated", 0))
	var tier = int(data.get("tier", 1))
	var cost_next = int(data.get("cost_next_rank", 1))
	var max_rank = 50

	_name_label.text = str(data.get("name", ""))

	# Tier dots
	for i in range(_tier_dots.size()):
		if i < tier:
			_tier_dots[i].color = accent_color
		else:
			_tier_dots[i].color = Color(1, 1, 1, 0.25)

	# Icon
	var icon_key = str(data.get("icon", talent_id))
	var icon_path = "res://assets/general_icons/passive_talents/%s.png" % icon_key
	if ResourceLoader.exists(icon_path):
		_icon_rect.texture = load(icon_path)

	_apply_frame_style(allocated)


func _apply_frame_style(allocated: int) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.063, 0.071, 0.094, 0.86)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2

	if allocated >= 50:
		sb.border_color = Color("#FFC842")
		sb.set_border_width_all(2)
	elif allocated > 0:
		sb.border_color = Color(accent_color, 0.8)
		sb.set_border_width_all(2)
	else:
		sb.border_color = Color(1, 1, 1, 0.12)
		sb.set_border_width_all(1)

	_frame.add_theme_stylebox_override("panel", sb)

	if allocated == 0:
		modulate = Color(1, 1, 1, 0.45)
	else:
		modulate = Color.WHITE


func _process(delta: float) -> void:
	if _press_active and not _long_press_fired:
		if Time.get_ticks_msec() / 1000.0 - _press_start >= LONG_PRESS_TIME:
			_long_press_fired = true
			node_long_pressed.emit(talent_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_press_active = true
			_press_pos = event.position
			_press_start = Time.get_ticks_msec() / 1000.0
			_long_press_fired = false
			return
		_press_active = false
		if _long_press_fired:
			node_long_released.emit()
			_long_press_fired = false
			accept_event()
			return
		var delta_pos = event.position - _press_pos
		if delta_pos.length() < DRAG_THRESHOLD_PX:
			node_tapped.emit(talent_id)
			accept_event()
		return

	if _press_active and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		var delta_pos = event.position - _press_pos
		if delta_pos.length() >= DRAG_THRESHOLD_PX:
			_press_active = false
			if _long_press_fired:
				node_long_released.emit()
				_long_press_fired = false


func play_tier_pulse() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)
