class_name WowTooltip extends PanelContainer

# Style
@export var bg_color = Color(0.06, 0.06, 0.08, 0.92)  # dark, 92% opacity
@export var border_width = 2
@export var corner_radius = 8

# WoW-ish quality colors
const QUALITY_COLORS := {
	0: Color(0.62, 0.62, 0.62), # poor (gray)
	1: Color(1, 1, 1),          # common (white)
	2: Color(0.12, 1, 0),       # uncommon (green)
	3: Color(0, 0.44, 0.87),    # rare (blue)
	4: Color(0.64, 0.21, 0.93), # epic (purple)
	5: Color(1, 0.5, 0),        # legendary (orange)
	6: Color(0.9, 0.8, 0.2)     # artifact (gold-ish)
}

var _title: Label
var _lines: VBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # ignore pointer, don't steal input
	# Panel styling
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_bottom_left = corner_radius
	sb.corner_radius_bottom_right = corner_radius
	sb.corner_radius_top_left = corner_radius
	sb.corner_radius_top_right = corner_radius
	sb.border_width_bottom = border_width
	sb.border_width_left = border_width
	sb.border_width_right = border_width
	sb.border_width_top = border_width
	sb.border_color = QUALITY_COLORS[1]
	add_theme_stylebox_override("panel", sb)

	# Layout
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.custom_minimum_size = Vector2(220, 0)
	add_child(root)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	root.add_child(_title)

	var sep = HSeparator.new()
	root.add_child(sep)

	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 2)
	root.add_child(_lines)

func set_data(item_def: Dictionary, qty: int=1) -> void:
	# item_def expected keys: name, descr, quality:int, attrs:Dictionary
	var q = int(item_def.get("quality", 1))
	var color = QUALITY_COLORS.get(q, QUALITY_COLORS[1])

	# Title colored by quality
	_title.text = String(item_def.get("name", "Unknown"))
	_title.add_theme_color_override("font_color", color)

	# Border color by quality
	var sb: StyleBox = get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		sb.border_color = color

	# Clear previous lines
	for c in _lines.get_children():
		c.queue_free()

	# Description (faded)
	var descr = String(item_def.get("descr", ""))
	if descr != "":
		var d = Label.new()
		d.text = descr
		d.modulate = color
		#d.modulate = Color(1,1,1,0.9)
		_lines.add_child(d)

	# Attributes (key: value)
	var attrs: Dictionary = item_def.get("attrs", {})
	for k in attrs.keys():
		var h = HBoxContainer.new()
		var lk = Label.new()
		lk.text = String(k).capitalize() + ":"
		lk.modulate = Color(0.85,0.85,0.95,1)
		var lv = Label.new()
		lv.text = str(attrs[k])
		lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(lk)
		h.add_child(lv)
		_lines.add_child(h)

	# Stack count
	if qty > 1:
		var st := Label.new()
		st.text = "Stack: %d" % qty
		st.modulate = Color(0.9, 0.9, 0.9, 0.9)
		_lines.add_child(st)
