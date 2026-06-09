class_name OfflineProgressView extends CanvasLayer

# Full-screen "While You Were Away" summary, shown once after login when
# offline steps were credited. Added to the tree ROOT by AccountManager —
# never parent under app_scenes_handler (its pager sweeps children into
# the swipe carousel).

var data: Dictionary = {}

const GOLD = Color.from_rgba8(255, 200, 66)
const TEXT_LIGHT = Color.from_rgba8(220, 215, 200)
const TEXT_DIM = Color.from_rgba8(150, 140, 120)
const BG_DARK = Color.from_rgba8(20, 16, 11, 250)
const PANEL_BG = Color.from_rgba8(36, 28, 18, 255)
const BORDER_GOLD = Color.from_rgba8(176, 141, 63)


func _ready() -> void:
	layer = 120

	var root_ctl = Control.new()
	root_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctl)

	var bg = ColorRect.new()
	bg.color = BG_DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctl.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctl.add_child(center)

	var panel = PanelContainer.new()
	Styler.style_panel(panel, PANEL_BG, BORDER_GOLD)
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_add_label(vbox, "While You Were Away", 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	var away_seconds = float(data.get("away_seconds", 0))
	if away_seconds > 60.0:
		_add_label(vbox, "%s offline" % _format_away(away_seconds), 13, TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)

	var steps = int(data.get("steps", 0))
	_add_label(vbox, "%s" % _format_thousands(steps), 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(vbox, "steps walked", 13, TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)

	var profession = ""
	if data.get("profession") != null:
		profession = str(data.get("profession", ""))
	var xp_gained = int(data.get("xp_gained", 0))
	var completed = int(data.get("activities_completed", 0))
	if profession != "" and (xp_gained > 0 or completed > 0):
		vbox.add_child(_make_separator())
		_add_stat_row(vbox, _display_profession(profession), "+%s XP" % _format_thousands(xp_gained))
		_add_stat_row(vbox, "Activities done", str(completed))
		var level_from = data.get("level_from")
		var level_to = data.get("level")
		if level_from != null and level_to != null and int(level_to) > int(level_from):
			_add_stat_row(vbox, "Level up!", "%d → %d" % [int(level_from), int(level_to)])

	var loot_counts = {}
	if data.get("loot_counts") != null:
		loot_counts = data.get("loot_counts", {})
	if not loot_counts.is_empty():
		vbox.add_child(_make_separator())
		_add_label(vbox, "Loot gained", 13, TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
		vbox.add_child(_build_loot_grid(loot_counts, data.get("mapping", {})))

	var btn = Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_override("font", Styler.QUADRAT_FONT)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.from_rgba8(26, 20, 14))
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = GOLD
	btn_sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", btn_sb)
	var btn_sb_pressed = StyleBoxFlat.new()
	btn_sb_pressed.bg_color = BORDER_GOLD
	btn_sb_pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", btn_sb_pressed)
	btn.pressed.connect(queue_free)
	vbox.add_child(btn)

	# Fade in
	root_ctl.modulate.a = 0.0
	create_tween().tween_property(root_ctl, "modulate:a", 1.0, 0.25)


func _make_separator() -> HSeparator:
	# Default theme separator is near-black — invisible on the dark panel
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(1.0, 1.0, 1.0, 0.08))
	return sep


func _add_label(parent: Control, text: String, size: int, color: Color, align: int) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = align
	lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


func _add_stat_row(parent: Control, left_text: String, right_text: String) -> void:
	var row = HBoxContainer.new()
	var left = Label.new()
	left.text = left_text
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_font_override("font", Styler.QUADRAT_FONT)
	left.add_theme_font_size_override("font_size", 15)
	left.add_theme_color_override("font_color", TEXT_LIGHT)
	row.add_child(left)
	var right = Label.new()
	right.text = right_text
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_theme_font_override("font", Styler.QUADRAT_FONT)
	right.add_theme_font_size_override("font_size", 15)
	right.add_theme_color_override("font_color", GOLD)
	row.add_child(right)
	parent.add_child(row)


func _build_loot_grid(loot_counts: Dictionary, mapping) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var map_dict = {}
	if mapping is Dictionary:
		map_dict = mapping
	for key in loot_counts.keys():
		var qty = int(loot_counts[key])
		var icon_key = str(map_dict.get(key, key))
		var cell = VBoxContainer.new()
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon = TextureRect.new()
		icon.texture = ItemDB.get_item_icon(icon_key, ItemDB.get_item_icon("default_bag"))
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(icon)
		var qty_lbl = Label.new()
		qty_lbl.text = "×%d" % qty
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_lbl.add_theme_font_size_override("font_size", 12)
		qty_lbl.add_theme_color_override("font_color", TEXT_LIGHT)
		cell.add_child(qty_lbl)
		grid.add_child(cell)
	return grid


func _format_away(seconds: float) -> String:
	var total_minutes = int(seconds / 60.0)
	var hours = total_minutes / 60
	var minutes = total_minutes % 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	return "%dm" % minutes


func _format_thousands(n: int) -> String:
	var s = str(n)
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


func _display_profession(s: String) -> String:
	if s == "blacksmithing":
		return "Crafting"
	var result = PackedStringArray()
	for w in s.split("_"):
		result.append(w.capitalize())
	return " ".join(result)
