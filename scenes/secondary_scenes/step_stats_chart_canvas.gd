extends Control

## Paints the bars + annotations + x-axis labels for the step stats chart.
## All state is read from node meta (set by the parent step_stats_chart.gd).
## Two-tone: today/current bucket = COLOR_GOLD; history = COLOR_TIER_BRONZE.

const BAR_GAP_PX = 6.0
const MIN_BAR_WIDTH_PX = 26.0        # wide enough for "Wed"/"Thu"/"W13" at 12px
const MAX_BAR_WIDTH_PX = 40.0        # cap so day view (7 bars) doesn't look like slabs
const BAR_CORNER = 4.0
const BAR_OUTLINE_PX = 2.0
const BAR_AREA_BOTTOM_MARGIN = 26.0  # leaves room for x-axis labels (12px font)
const BAR_AREA_TOP_MARGIN = 20.0     # leaves room for annotations (13px font)
const ANNOTATION_FONT_SIZE = 13
const AXIS_FONT_SIZE = 12
const STATE_LABEL_FONT_SIZE = 13

# Re-usable styleboxes (avoid per-frame GC on mobile)
var _sb_gold: StyleBoxFlat
var _sb_bronze: StyleBoxFlat


func _ready() -> void:
	_sb_gold = _make_bar_sb(Styler.COLOR_GOLD)
	_sb_bronze = _make_bar_sb(Styler.COLOR_TIER_BRONZE)
	resized.connect(queue_redraw)


func _make_bar_sb(fill: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(BAR_CORNER))
	sb.border_width_left = int(BAR_OUTLINE_PX)
	sb.border_width_right = int(BAR_OUTLINE_PX)
	sb.border_width_top = int(BAR_OUTLINE_PX)
	sb.border_width_bottom = int(BAR_OUTLINE_PX)
	sb.border_color = Styler.COLOR_SECTION_HDR
	return sb


func _draw() -> void:
	var state = get_meta("state", "LOADING")
	var buckets: Array = get_meta("buckets", [])
	var period: String = get_meta("period", "day")

	match state:
		"LOADING":
			_draw_loading(period)
		"EMPTY":
			_draw_empty()
		"ONE_BAR":
			_draw_one_bar(buckets)
		"ERROR":
			_draw_error()
		_:
			_draw_bars(buckets, period)


# ─────────────────────────── state renderers ───────────────────────────

func _draw_loading(period: String) -> void:
	var count = 7 if period == "day" else 12
	var ch = _chart_rect()
	var bw = _bar_width(ch.size.x, count)
	var total_w = count * bw + (count - 1) * BAR_GAP_PX
	var x_origin = ch.position.x + max(0.0, (ch.size.x - total_w) * 0.5)
	var faded = Styler.COLOR_TIER_BRONZE
	faded.a = 0.4
	for i in range(count):
		var x = x_origin + i * (bw + BAR_GAP_PX)
		var h = ch.size.y * 0.3
		draw_rect(Rect2(x, ch.position.y + ch.size.y - h, bw, h), faded, false, 2.0)
	_draw_centered_label("Loading...", Styler.COLOR_SECTION_HDR, STATE_LABEL_FONT_SIZE, ch.position.y - 2)


func _draw_empty() -> void:
	_draw_centered_label("Every journey begins with one step.",
		Styler.COLOR_SECTION_HDR, STATE_LABEL_FONT_SIZE, size.y * 0.5 - 6, true)


func _draw_one_bar(buckets: Array) -> void:
	if buckets.is_empty():
		_draw_empty()
		return
	var ch = _chart_rect()
	var steps = int(buckets[-1].get("steps", 0))
	var bw = MAX_BAR_WIDTH_PX
	var cx = ch.position.x + ch.size.x * 0.5 - bw * 0.5
	var h_max = ch.size.y
	_draw_bar(cx, ch.position.y, bw, h_max, _sb_gold)
	_draw_annotation_above(cx + bw * 0.5, ch.position.y, _format_k(steps))
	_draw_centered_label("Walk tomorrow to start a trend.",
		Styler.COLOR_SECTION_HDR, AXIS_FONT_SIZE, ch.position.y + ch.size.y + 2)


func _draw_error() -> void:
	_draw_centered_label("Couldn't read your step log — tap to retry.",
		Color.from_rgba8(160, 60, 50), STATE_LABEL_FONT_SIZE, size.y * 0.5 - 6)


func _draw_bars(buckets: Array, period: String) -> void:
	if buckets.is_empty():
		_draw_empty()
		return

	var ch = _chart_rect()
	var count = buckets.size()
	var bw = _bar_width(ch.size.x, count)
	# Center the bar cluster when capped width leaves spare room.
	var total_w = count * bw + (count - 1) * BAR_GAP_PX
	var x_origin = ch.position.x + max(0.0, (ch.size.x - total_w) * 0.5)

	var max_steps = 1
	for b in buckets:
		max_steps = max(max_steps, int(b.get("steps", 0)))

	var compact_annotations = bw < 32.0

	for i in range(count):
		var b = buckets[i]
		var steps = int(b.get("steps", 0))
		var is_current = (i == count - 1)
		var x = x_origin + i * (bw + BAR_GAP_PX)
		var h = 0.0
		if steps > 0:
			h = ch.size.y * (float(steps) / float(max_steps))
		if h > 0.0:
			var y = ch.position.y + (ch.size.y - h)
			var sb = _sb_gold if is_current else _sb_bronze
			_draw_bar(x, y, bw, h, sb)
			var ann = _format_k(steps, compact_annotations)
			_draw_annotation_above(x + bw * 0.5, y, ann)

		var x_lbl = _axis_label_for(b, i, count, period, is_current)
		_draw_axis_label(x + bw * 0.5, ch.position.y + ch.size.y + 2, x_lbl, is_current)


# ─────────────────────────── primitives ───────────────────────────

func _chart_rect() -> Rect2:
	# Reserves top margin for annotations, bottom margin for x-axis labels.
	var x = 6.0
	var y = BAR_AREA_TOP_MARGIN
	var w = size.x - 12.0
	var h = size.y - BAR_AREA_TOP_MARGIN - BAR_AREA_BOTTOM_MARGIN
	if h < 20.0:
		h = 20.0
	return Rect2(x, y, w, h)


func _bar_width(area_w: float, count: int) -> float:
	if count <= 0:
		return MIN_BAR_WIDTH_PX
	var w = (area_w - (count - 1) * BAR_GAP_PX) / count
	return clamp(w, MIN_BAR_WIDTH_PX, MAX_BAR_WIDTH_PX)


func _draw_bar(x: float, y: float, w: float, h: float, sb: StyleBoxFlat) -> void:
	draw_style_box(sb, Rect2(x, y, w, h))


func _draw_annotation_above(cx: float, y_top: float, text: String) -> void:
	var font = Styler.QUADRAT_FONT
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, ANNOTATION_FONT_SIZE)
	draw_string(font, Vector2(cx - text_size.x * 0.5, y_top - 4),
		text, HORIZONTAL_ALIGNMENT_CENTER, -1, ANNOTATION_FONT_SIZE, Styler.COLOR_TEXT_SUCCESS)


func _draw_axis_label(cx: float, y: float, text: String, highlight: bool) -> void:
	var font = Styler.QUADRAT_FONT
	var col = Styler.COLOR_TEXT_SUCCESS if highlight else Styler.COLOR_SECTION_HDR
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, AXIS_FONT_SIZE)
	draw_string(font, Vector2(cx - text_size.x * 0.5, y + AXIS_FONT_SIZE),
		text, HORIZONTAL_ALIGNMENT_CENTER, -1, AXIS_FONT_SIZE, col)


func _draw_centered_label(text: String, col: Color, size_px: int, y: float, italic: bool = false) -> void:
	var font = Styler.QUADRAT_FONT
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size_px)
	draw_string(font, Vector2(size.x * 0.5 - text_size.x * 0.5, y + size_px),
		text, HORIZONTAL_ALIGNMENT_CENTER, -1, size_px, col)


# ─────────────────────────── formatters ───────────────────────────

func _format_k(n: int, compact: bool = false) -> String:
	if n < 1000:
		return str(n)
	var k = float(n) / 1000.0
	if compact or k >= 10.0:
		return "%dk" % int(round(k))
	return "%.1fk" % k


func _axis_label_for(bucket: Dictionary, index: int, count: int, period: String, is_current: bool) -> String:
	var iso = String(bucket.get("date", ""))
	if iso.is_empty():
		return ""
	var parts = iso.split("-")
	if parts.size() != 3:
		return iso
	var year = int(parts[0]); var month = int(parts[1]); var day = int(parts[2])
	match period:
		"day":
			if is_current:
				return "Today"
			var names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
			var t = Time.get_unix_time_from_datetime_string(iso)
			var dict = Time.get_datetime_dict_from_unix_time(int(t))
			# Godot 4.6: Time.Weekday is MONDAY=1..SUNDAY=7 via Time.get_datetime_dict_from_unix_time.
			# But when derived from a unix time, `weekday` keys follow the
			# enum DAY_SUNDAY=0..DAY_SATURDAY=6 convention. The remap
			# `(wd + 6) % 7` folds either convention to Mon=0..Sun=6 as long
			# as the weekday space is 0..6 or 1..7 contiguous; validated via
			# tests in the design plan.
			var wd = int(dict.weekday)
			var idx = (wd + 6) % 7
			if idx < 0 or idx >= names.size():
				return ""
			return names[idx]
		"week":
			# ISO week number — approximate via day-of-year / 7 when Godot lacks ISO week.
			var t2 = Time.get_unix_time_from_datetime_string(iso)
			var jan1 = Time.get_unix_time_from_datetime_string("%04d-01-01" % year)
			var doy = int((t2 - jan1) / 86400.0) + 1
			var wk = int(ceil(float(doy) / 7.0))
			return "W%d" % wk
		"month":
			var months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
			return months[month - 1]
	return iso
