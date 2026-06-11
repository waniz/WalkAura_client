extends PanelContainer
## One achievement card — parchment cream bg with 3px tier-color left edge,
## following the Alchemy recipe-card rhythm. See DESIGN.md "Achievements Tab".
##
## States: LOCKED / IN_PROGRESS / READY_TO_CLAIM / CLAIMED / SECRET.
## Server entry drives state; _refresh_visuals paints per state.

signal claim_pressed(entry: Dictionary)

const TIER_EASY   = 1
const TIER_MEDIUM = 2
const TIER_HARD   = 3
const TIER_META   = 4
const TIER_SECRET = 5

var _entry: Dictionary = {}
var _style: StyleBoxFlat
var _icon: TextureRect
var _name_label: Label
var _desc_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _reward_line: Label
var _claim_button: Button
var _claimed_label: Label

var _claim_inflight: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(0, 120)

	# Parchment card with 3px left edge (tier accent, set per-card in _refresh_visuals)
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.93, 0.89, 0.80)        # warm cream, slightly darker than page
	_style.border_width_left = 3
	_style.border_width_top = 1
	_style.border_width_right = 1
	_style.border_width_bottom = 1
	_style.border_color = Styler.COLOR_CARD_BORDER
	_style.corner_radius_bottom_left = 4
	_style.corner_radius_bottom_right = 4
	_style.corner_radius_top_left = 4
	_style.corner_radius_top_right = 4
	_style.content_margin_left = 10
	_style.content_margin_right = 10
	_style.content_margin_top = 8
	_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", _style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(hbox)

	# Icon (left). Tall rectangle slot 64 wide × 96 tall. Texture keeps 1:1
	# aspect (STRETCH_KEEP_ASPECT, top-aligned) — fills full 64 px width,
	# 64 px of the 96 px height, with 32 px of breathing room below for the
	# text stack on the right to align nicely.
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(64, 96)
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_icon.size_flags_vertical = SIZE_FILL
	hbox.add_child(_icon)

	# Middle column: name + desc + progress + reward
	var middle = VBoxContainer.new()
	middle.size_flags_horizontal = SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 3)
	hbox.add_child(middle)

	_name_label = Label.new()
	_name_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	middle.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_desc_label.add_theme_font_size_override("font_size", 12)
	_desc_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(_desc_label)

	# Progress row: "Progress: ▓▓▓▓░░  25 / 50"
	var progress_row = HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 8)
	middle.add_child(progress_row)

	var progress_lead = Label.new()
	progress_lead.text = "Progress:"
	progress_lead.add_theme_font_override("font", Styler.QUADRAT_FONT)
	progress_lead.add_theme_font_size_override("font_size", 12)
	progress_lead.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)
	progress_row.add_child(progress_lead)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 20)
	_progress_bar.show_percentage = false
	_progress_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	progress_row.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	progress_row.add_child(_progress_label)

	# Reward payoff line — mirrors alchemy's "Recovery HP +25.0" bold green gain line.
	# Green reads cleanly on cream parchment; gold does not.
	_reward_line = Label.new()
	_reward_line.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_reward_line.add_theme_font_size_override("font_size", 13)
	_reward_line.add_theme_color_override("font_color", Color.from_rgba8(60, 120, 50))
	middle.add_child(_reward_line)

	# Right-column: CLAIM button / CLAIMED stamp
	var right = VBoxContainer.new()
	right.size_flags_vertical = SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right)

	_claim_button = Button.new()
	_claim_button.text = "CLAIM"
	_claim_button.custom_minimum_size = Vector2(96, 44)
	_claim_button.visible = false
	_claim_button.pressed.connect(_on_claim_pressed)
	right.add_child(_claim_button)

	_claimed_label = Label.new()
	_claimed_label.text = "✓ CLAIMED"
	_claimed_label.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_claimed_label.add_theme_font_size_override("font_size", 12)
	_claimed_label.add_theme_color_override("font_color", Color.from_rgba8(80, 120, 60))   # muted green, like "Recovery HP"
	_claimed_label.visible = false
	right.add_child(_claimed_label)


func set_data(entry: Dictionary) -> void:
	_entry = entry.duplicate(true)
	_claim_inflight = false   # server responded → re-enable UI
	_refresh_visuals()


func _on_claim_pressed() -> void:
	if _claim_inflight:
		return
	_claim_inflight = true
	_claim_button.disabled = true
	_claim_button.text = "..."
	claim_pressed.emit(_entry)
	_schedule_inflight_timeout()


func _schedule_inflight_timeout() -> void:
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_on_claim_inflight_timeout)


func _on_claim_inflight_timeout() -> void:
	if not _claim_inflight:
		return
	_claim_inflight = false
	_refresh_visuals()


func _refresh_visuals() -> void:
	if _entry.is_empty():
		return
	var tier = int(_entry.get("tier", 1))
	var tier_color = _color_for_tier(tier)
	var is_hidden = _entry.get("is_hidden", false)
	var is_locked = _entry.get("is_locked", false)
	var is_claimed = _entry.get("claimed", false)
	var current = int(_entry.get("current", 0))
	var target = int(_entry.get("target", 0))
	var is_ready = (not is_locked) and (not is_claimed) and (not is_hidden) and current >= target and target > 0

	# Left-edge tier accent
	_style.border_color = Styler.COLOR_CARD_BORDER
	_style.border_width_left = 3
	# Per-card tier accent is painted by overriding only the left-edge color
	# via a combined stylebox, but StyleBoxFlat takes one border color. Trick:
	# set the full border to CARD_BORDER and overlay tier color on left via
	# larger width. Simplest achievable with current StyleBox: set bg_color
	# subtly tinted to tier, left border bold. Compromise: full border in
	# tier_color at low alpha, plus thicker left edge.
	var tinted_border = Color(tier_color.r, tier_color.g, tier_color.b, 0.5)
	if is_claimed:
		tinted_border = Color(tier_color.r, tier_color.g, tier_color.b, 0.3)
	elif is_locked or is_hidden:
		tinted_border = Color(0.50, 0.45, 0.35, 0.4)
	_style.border_color = tinted_border
	_style.border_width_left = 4 if (is_ready or is_claimed) else 3

	# Icon
	if ItemDB.has_method("get_achievement_icon"):
		_icon.texture = ItemDB.get_achievement_icon(int(_entry.get("id", 0)))
	_icon.modulate = Color(0.55, 0.50, 0.40, 1) if (is_locked or is_hidden) else Color(1, 1, 1, 1)

	# Name
	_name_label.text = _entry.get("name", "")
	_name_label.add_theme_color_override(
		"font_color",
		Color(0.45, 0.40, 0.30) if (is_locked or is_hidden) else Styler.COLOR_TEXT_DARK,
	)

	# Desc
	if is_locked:
		var prereq_txt = ""
		var prereqs = _entry.get("prereq_ids", [])
		if prereqs.size() > 0:
			prereq_txt = "Complete required achievements to unlock."
		else:
			prereq_txt = _entry.get("desc", "")
		_desc_label.text = prereq_txt
		_desc_label.add_theme_color_override("font_color", Color.from_rgba8(160, 60, 50))
	else:
		_desc_label.text = _entry.get("desc", "")
		_desc_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20))

	# Progress row
	var show_progress = (not is_hidden) and (not is_locked) and target > 0
	_progress_bar.visible = show_progress
	_progress_label.visible = show_progress
	if show_progress:
		_progress_bar.max_value = max(target, 1)
		_progress_bar.value = clamp(current, 0, target)
		_progress_label.text = "%s / %s" % [_fmt_num(current), _fmt_num(target)]
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = tier_color
		bar_style.corner_radius_bottom_left = 2
		bar_style.corner_radius_bottom_right = 2
		bar_style.corner_radius_top_left = 2
		bar_style.corner_radius_top_right = 2
		_progress_bar.add_theme_stylebox_override("fill", bar_style)
		var track_style = StyleBoxFlat.new()
		track_style.bg_color = Color(0, 0, 0, 0.15)
		track_style.corner_radius_bottom_left = 2
		track_style.corner_radius_bottom_right = 2
		track_style.corner_radius_top_left = 2
		track_style.corner_radius_top_right = 2
		_progress_bar.add_theme_stylebox_override("background", track_style)

	# Reward payoff line
	if is_hidden:
		_reward_line.text = ""
		_reward_line.visible = false
	else:
		_reward_line.text = _format_reward_line(_entry.get("reward_spec", []))
		_reward_line.visible = _reward_line.text != ""

	# Right column
	_claim_button.visible = is_ready
	_claim_button.disabled = false
	_claim_button.text = "CLAIM"
	_claimed_label.visible = is_claimed

	# Embossed tier-colored CLAIM button — lightened top border, darker
	# bottom border + tier-tinted halo. Matches the rift/quest CTA family.
	_claim_button.add_theme_font_override("font", Styler.JANDA_FONT)
	_claim_button.add_theme_font_size_override("font_size", 14)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = tier_color
		btn_style.set_corner_radius_all(5)
		btn_style.border_color = tier_color.lightened(0.25)
		btn_style.border_width_top = 1
		btn_style.border_width_left = 1
		btn_style.border_width_right = 1
		btn_style.border_width_bottom = 2
		btn_style.shadow_color = Color(tier_color, 0.45)
		btn_style.shadow_size = 10
		match state_name:
			"hover":
				btn_style.bg_color = tier_color.lightened(0.1)
				btn_style.shadow_size = 14
			"pressed":
				btn_style.bg_color = tier_color.darkened(0.08)
				btn_style.shadow_size = 4
				btn_style.content_margin_top = 2
		_claim_button.add_theme_stylebox_override(state_name, btn_style)
	# Dark text reads on every tier-color background (bronze / silver / gold).
	_claim_button.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	_claim_button.add_theme_color_override("font_hover_color", Styler.COLOR_TEXT_DARK)
	_claim_button.add_theme_color_override("font_pressed_color", Styler.COLOR_TEXT_DARK)
	_claim_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_claim_button.add_theme_constant_override("outline_size", 1)

	# Claimed date stamp (under "✓ CLAIMED")
	if is_claimed:
		var ca = _entry.get("claimed_at")
		if ca:
			var date_only = str(ca).substr(0, 10)   # "YYYY-MM-DD"
			_claimed_label.text = "✓ CLAIMED\n%s" % date_only


func _format_reward_line(rewards: Array) -> String:
	# Produce one bold payoff line like "Reward: +2 STR  ★ Title  ◆ Frame"
	if rewards.is_empty():
		return ""
	var parts: Array[String] = []
	for r in rewards:
		match r.get("type", ""):
			"stat":
				parts.append("+%s %s" % [r.get("amount", 0), r.get("attr", "")])
			"player_choice_stat":
				parts.append("+%s (choose stat)" % r.get("amount", 0))
			"title":
				parts.append("★ Title")
			"frame":
				parts.append("◆ Frame")
	return "Reward: " + "   ".join(parts)


func play_claim_animation() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.15)
	tween.tween_property(_icon, "scale", Vector2(1.15, 1.15), 0.15)
	tween.tween_property(_icon, "scale", Vector2(1.0, 1.0), 0.15)


func _color_for_tier(tier: int) -> Color:
	match tier:
		TIER_EASY:   return Styler.COLOR_TIER_BRONZE
		TIER_MEDIUM: return Styler.COLOR_TIER_SILVER
		TIER_HARD:   return Styler.COLOR_GOLD
		TIER_META:   return Styler.COLOR_GOLD
		TIER_SECRET: return Color.from_rgba8(128, 60, 140)
		_:           return Styler.COLOR_TIER_BRONZE


func _fmt_num(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 10_000:
		return "%dk" % (n / 1000)
	return str(n)
