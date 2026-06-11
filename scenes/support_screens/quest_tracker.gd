extends PanelContainer

# HUD quest tracker pill. Shows the currently-tracked quest's name + its first
# unfinished objective + a thin progress bar. Reads QuestManager.tracked_quest()
# and refreshes on signal_QuestsUpdated / signal_QuestObjectiveProgress. Hides
# itself when no quest is tracked. Tapping it opens the quest detail overlay.

const QUEST_DETAIL = preload("res://scenes/secondary_scenes/quest_detail.gd")

var _name_lbl: Label = null
var _obj_lbl: Label = null
var _bar: ProgressBar = null
var _tracked_id: String = ""


func _ready() -> void:
	_build_ui()
	QuestManager.signal_QuestsUpdated.connect(_refresh)
	QuestManager.signal_QuestObjectiveProgress.connect(_on_obj_progress)
	gui_input.connect(_on_gui_input)
	_refresh()


func _build_ui() -> void:
	var accent: Color = Styler.COL_PRIMARY
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.35)
	sb.border_color = Color(accent, 0.5)
	sb.border_width_left = 3
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	add_theme_stylebox_override("panel", sb)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	add_child(vb)

	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	vb.add_child(head)

	var pin = Label.new()
	pin.text = "📌"
	pin.add_theme_font_size_override("font_size", 12)
	head.add_child(pin)

	_name_lbl = Label.new()
	_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	_name_lbl.add_theme_font_size_override("font_size", 13)
	_name_lbl.add_theme_color_override("font_color", accent)
	head.add_child(_name_lbl)

	_obj_lbl = Label.new()
	_obj_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_obj_lbl.add_theme_font_size_override("font_size", 12)
	_obj_lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 212, 192))
	vb.add_child(_obj_lbl)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 4)
	_bar.min_value = 0
	_bar.max_value = 1
	Styler.make_painted_progressbar(_bar, accent, accent.darkened(0.4), 2)
	vb.add_child(_bar)


func _on_obj_progress(quest_id: String, _idx: int, _progress: int, _total: int) -> void:
	if quest_id == _tracked_id:
		_refresh()


func _refresh(_a = null) -> void:
	var q: Dictionary = QuestManager.tracked_quest()
	if q.is_empty():
		_tracked_id = ""
		visible = false
		return
	visible = true
	_tracked_id = String(q.get("id", ""))
	_name_lbl.text = String(q.get("name", ""))

	var objs: Array = q.get("objectives", [])
	var target: Dictionary = {}
	for ob in objs:
		if int(ob.get("count", 0)) < int(ob.get("total", 1)):
			target = ob
			break
	if target.is_empty() and not objs.is_empty():
		target = objs[objs.size() - 1]   # all done → show the last

	if target.is_empty():
		_obj_lbl.text = ""
		_bar.value = 0
		return
	var count: int = int(target.get("count", 0))
	var total: int = maxi(1, int(target.get("total", 1)))
	_obj_lbl.text = "%s   %d / %d" % [String(target.get("label", "")), count, total]
	_bar.max_value = total
	_bar.value = clampi(count, 0, total)


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		if _tracked_id == "":
			return
		var overlay = QUEST_DETAIL.new()
		overlay.quest_id = _tracked_id
		# Add to the scene root so the overlay covers the full screen.
		get_tree().current_scene.add_child(overlay)
