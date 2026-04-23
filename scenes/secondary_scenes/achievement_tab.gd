extends VBoxContainer
## Achievements tab — parchment/civic-family styling to match Professions.
##
## Visual family: civic/study (parchment cream background + dark-brown text).
## Matches the Alchemy/Herbalism/Enchanting profession_detail aesthetic.
## See DESIGN.md "Achievements Tab — AAA Design Spec".
##
## Server-authoritative: on show, emits signal_RequestAchievements and rebuilds
## from signal_AchievementsReceived.

const AchievementCardScene = preload("res://scenes/secondary_scenes/achievement_card.tscn")
const SelectorPopupScene   = preload("res://scenes/secondary_scenes/selector_popup.tscn")

const TIER_EASY   = 1
const TIER_MEDIUM = 2
const TIER_HARD   = 3
const TIER_META   = 4
const TIER_SECRET = 5

const PRIMARY_STATS = ["STR", "AGI", "VIT", "INT", "SPI", "LCK"]

const _REFRESH_DEBOUNCE_MSEC = 1200

# Deep forest green — reads cleanly on parchment. Used for payoff/subtitle
# text that would otherwise be gold-on-cream (unreadable). Matches the
# alchemy "Recovery HP +25" green-payoff tone.
const COLOR_PARCHMENT_ACCENT = Color(0.235, 0.470, 0.196, 1.0)   # rgba8(60, 120, 50)

var _header_bar: PanelContainer = null
var _header_title_lbl: Label = null
var _header_stats_lbl: Label = null
var _trophy_wall_section: VBoxContainer = null
var _trophy_wall_scroll: ScrollContainer = null
var _trophy_wall_strip: HBoxContainer = null
var _trophy_wall_empty: Label = null
var _tier_easy_box: VBoxContainer = null
var _tier_medium_box: VBoxContainer = null
var _tier_hard_box: VBoxContainer = null
var _secret_box: VBoxContainer = null
var _card_by_id: Dictionary = {}
var _titles_known: Array = []
var _active_title: Variant = null
var _requested_once: bool = false
var _last_refresh_ts_msec: int = 0


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	_build_shell()
	SignalManager.signal_AchievementsReceived.connect(_on_achievements_received)
	SignalManager.signal_AchievementClaimed.connect(_on_achievement_claimed)
	SignalManager.signal_ActiveTitleSet.connect(_on_active_title_set)


func request_refresh() -> void:
	var now = Time.get_ticks_msec()
	if _requested_once and now - _last_refresh_ts_msec < _REFRESH_DEBOUNCE_MSEC:
		return
	_last_refresh_ts_msec = now
	SignalManager.signal_RequestAchievements.emit()
	_requested_once = true


# ── UI shell ──────────────────────────────────────────────────────────────────

func _build_shell() -> void:
	_header_bar = _build_header_bar()
	add_child(_header_bar)

	# Trophy Wall section: "TROPHIES" header + gold underline + scroll strip.
	# Entire section hides when no trophies claimed (avoids stray header above
	# an empty-state line). Visibility driven in _rebuild_trophy_wall.
	_trophy_wall_section = VBoxContainer.new()
	_trophy_wall_section.add_theme_constant_override("separation", 4)
	_trophy_wall_section.visible = false
	add_child(_trophy_wall_section)

	var trophy_header_row = HBoxContainer.new()
	trophy_header_row.add_theme_constant_override("separation", 8)
	_trophy_wall_section.add_child(trophy_header_row)

	var trophy_title_lbl = Label.new()
	trophy_title_lbl.text = "TROPHIES"
	trophy_title_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	trophy_title_lbl.add_theme_font_size_override("font_size", 16)
	trophy_title_lbl.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)
	trophy_header_row.add_child(trophy_title_lbl)

	var trophy_subtitle_lbl = Label.new()
	trophy_subtitle_lbl.text = "· earned achievements"
	trophy_subtitle_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	trophy_subtitle_lbl.add_theme_font_size_override("font_size", 12)
	trophy_subtitle_lbl.add_theme_color_override("font_color", COLOR_PARCHMENT_ACCENT)
	trophy_subtitle_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trophy_header_row.add_child(trophy_subtitle_lbl)

	var underline = Panel.new()
	underline.custom_minimum_size = Vector2(0, 1)
	var rule_sb = StyleBoxFlat.new()
	rule_sb.bg_color = Styler.COLOR_GOLD
	underline.add_theme_stylebox_override("panel", rule_sb)
	underline.modulate = Color(1, 1, 1, 0.35)
	_trophy_wall_section.add_child(underline)

	_trophy_wall_scroll = ScrollContainer.new()
	_trophy_wall_scroll.custom_minimum_size = Vector2(0, 88)
	_trophy_wall_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_trophy_wall_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_trophy_wall_section.add_child(_trophy_wall_scroll)

	_trophy_wall_strip = HBoxContainer.new()
	_trophy_wall_strip.add_theme_constant_override("separation", 8)
	_trophy_wall_scroll.add_child(_trophy_wall_strip)

	# Legacy empty-state label — no longer used (section hides entirely when empty).
	# Kept as null so references elsewhere don't crash; _rebuild_trophy_wall
	# now toggles the whole section instead.
	_trophy_wall_empty = null

	# Tier subtitles all use the same parchment-readable green. Tier identity
	# is already communicated by the card left-edge and the medal framing;
	# text legibility on cream trumps color coding here.
	_tier_easy_box   = _build_section("Easy",   "+2 primary stat",   COLOR_PARCHMENT_ACCENT)
	_tier_medium_box = _build_section("Medium", "+5 primary stat",   COLOR_PARCHMENT_ACCENT)
	_tier_hard_box   = _build_section("Hard",   "+10 + title",       COLOR_PARCHMENT_ACCENT)
	_secret_box      = _build_section("Hidden", "reveal on discovery", COLOR_PARCHMENT_ACCENT)


func _build_header_bar() -> PanelContainer:
	# Dark ornate header bar — matches ALCHEMY header in profession_detail.
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 48)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(28, 30, 40, 240)
	sb.border_width_bottom = 2
	sb.border_color = Styler.COLOR_GOLD
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	panel.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_header_title_lbl = Label.new()
	_header_title_lbl.text = "ACHIEVEMENTS"
	_header_title_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	_header_title_lbl.add_theme_font_size_override("font_size", 22)
	_header_title_lbl.add_theme_color_override("font_color", Styler.COLOR_GOLD)
	_header_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_header_title_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)

	_header_stats_lbl = Label.new()
	_header_stats_lbl.text = "Loading..."
	_header_stats_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	_header_stats_lbl.add_theme_font_size_override("font_size", 13)
	_header_stats_lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 210, 180))
	_header_stats_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_header_stats_lbl)

	return panel


func _build_section(title_text: String, subtitle_text: String, accent: Color) -> VBoxContainer:
	# Section header: uppercase title in dark brown + gold subtitle, gold underline.
	var wrap = VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	add_child(wrap)

	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	wrap.add_child(header_row)

	var title_lbl = Label.new()
	title_lbl.text = title_text.to_upper()
	title_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Styler.COLOR_SECTION_HDR)
	header_row.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "· " + subtitle_text
	subtitle_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", accent)
	subtitle_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(subtitle_lbl)

	# Gold underline — 1px horizontal rule, matches professions
	var underline = Panel.new()
	underline.custom_minimum_size = Vector2(0, 1)
	var rule_sb = StyleBoxFlat.new()
	rule_sb.bg_color = Styler.COLOR_GOLD
	rule_sb.content_margin_left = 0
	rule_sb.content_margin_right = 0
	underline.add_theme_stylebox_override("panel", rule_sb)
	underline.modulate = Color(1, 1, 1, 0.35)
	wrap.add_child(underline)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	return vbox


# ── Data → cards ──────────────────────────────────────────────────────────────

func _on_achievements_received(data: Dictionary) -> void:
	var entries: Array = data.get("achievements", [])
	_titles_known  = data.get("titles", [])
	_active_title  = data.get("active_title")
	_rebuild_cards(entries)
	_rebuild_header(entries)
	_rebuild_trophy_wall(entries)


func _on_achievement_claimed(data: Dictionary) -> void:
	_on_achievements_received(data)
	var result = data.get("claim_result", {})
	if not result.is_empty() and not result.get("already_claimed", false):
		var aid = result.get("achievement_id")
		if aid != null and _card_by_id.has(aid):
			var card = _card_by_id[aid]
			if card.has_method("play_claim_animation"):
				card.play_claim_animation()


func _on_active_title_set(active_title) -> void:
	_active_title = active_title
	var parent = get_parent()
	while parent and not parent.has_method("set_active_title_display"):
		parent = parent.get_parent()
	if parent:
		parent.set_active_title_display(active_title, _titles_known)


func _rebuild_cards(entries: Array) -> void:
	for child in _tier_easy_box.get_children():
		child.queue_free()
	for child in _tier_medium_box.get_children():
		child.queue_free()
	for child in _tier_hard_box.get_children():
		child.queue_free()
	for child in _secret_box.get_children():
		child.queue_free()
	_card_by_id.clear()

	var sorted: Array = entries.duplicate()
	sorted.sort_custom(func(a, b): return a.get("id", 0) < b.get("id", 0))

	for entry in sorted:
		var card = AchievementCardScene.instantiate()
		var tier = int(entry.get("tier", 0))
		var target_box
		match tier:
			TIER_EASY:   target_box = _tier_easy_box
			TIER_MEDIUM: target_box = _tier_medium_box
			TIER_HARD:   target_box = _tier_hard_box
			TIER_META:
				match int(entry.get("meta_parent_tier", TIER_HARD)):
					TIER_EASY:   target_box = _tier_easy_box
					TIER_MEDIUM: target_box = _tier_medium_box
					TIER_HARD:   target_box = _tier_hard_box
					_:           target_box = _tier_hard_box
			TIER_SECRET: target_box = _secret_box
			_:           target_box = _tier_easy_box
		target_box.add_child(card)
		if card.has_method("set_data"):
			card.set_data(entry)
		if card.has_signal("claim_pressed"):
			card.claim_pressed.connect(_on_card_claim_pressed)
		_card_by_id[int(entry.get("id", 0))] = card


func _rebuild_header(entries: Array) -> void:
	var total = 0
	var claimed = 0
	var ready = 0
	var stats_earned = 0
	for e in entries:
		if e.get("is_hidden", false):
			continue
		total += 1
		if e.get("claimed", false):
			claimed += 1
			var rewards = e.get("reward_spec", [])
			if rewards is Array:
				for r in rewards:
					if r is Dictionary and r.get("type") == "stat":
						stats_earned += int(r.get("amount", 0))
		elif int(e.get("current", 0)) >= int(e.get("target", 0)) and not e.get("is_locked", false):
			ready += 1

	_header_stats_lbl.text = "%d/%d claimed  ·  %d ready  ·  +%d stats earned" % [claimed, total, ready, stats_earned]


func _rebuild_trophy_wall(entries: Array) -> void:
	for child in _trophy_wall_strip.get_children():
		child.queue_free()

	var any_claimed = false
	for e in entries:
		if not e.get("claimed", false):
			continue
		if e.get("is_hidden", false):
			continue
		any_claimed = true
		var tile = _build_trophy_tile(e)
		_trophy_wall_strip.add_child(tile)

	# Hide the entire "TROPHIES" section when nothing is claimed. No stray
	# header above an empty strip.
	_trophy_wall_section.visible = any_claimed


func _build_trophy_tile(entry: Dictionary) -> Control:
	# Painted wooden plaque — warm parchment-tinted base, tier-colored border,
	# subtle inner bevel (simulated via a second stylebox layer).
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(72, 72)
	var tier_color = _color_for_tier(int(entry.get("tier", 1)))

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.88, 0.82, 0.70, 1.0)   # warm wood tone on parchment
	sb.border_width_bottom = 2
	sb.border_width_top = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_color = tier_color
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	p.add_theme_stylebox_override("panel", sb)
	p.tooltip_text = entry.get("name", "")

	var icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ItemDB.has_method("get_achievement_icon"):
		var tex = ItemDB.get_achievement_icon(int(entry.get("id", 0)))
		if tex != null:
			icon_rect.texture = tex
	p.add_child(icon_rect)
	return p


func _color_for_tier(tier: int) -> Color:
	match tier:
		TIER_EASY:   return Styler.COLOR_TIER_BRONZE
		TIER_MEDIUM: return Styler.COLOR_TIER_SILVER
		TIER_HARD:   return Styler.COLOR_GOLD
		TIER_META:   return Styler.COLOR_GOLD
		TIER_SECRET: return Color.from_rgba8(128, 60, 140)   # muted mythic purple
		_:           return Styler.COLOR_TIER_BRONZE


# ── Claim flow ────────────────────────────────────────────────────────────────

func _on_card_claim_pressed(entry: Dictionary) -> void:
	var rewards = entry.get("reward_spec", [])
	var needs_choice = false
	for r in rewards:
		if r.get("type") == "player_choice_stat":
			needs_choice = true
			break
	if needs_choice:
		_open_stat_picker(entry)
	else:
		SignalManager.signal_ClaimAchievement.emit(int(entry.get("id", 0)), "")


func _open_stat_picker(entry: Dictionary) -> void:
	var popup = SelectorPopupScene.instantiate()
	get_tree().root.add_child(popup)
	popup.configure("Choose a stat to boost", PRIMARY_STATS,
		func(picked): SignalManager.signal_ClaimAchievement.emit(int(entry.get("id", 0)), picked))
