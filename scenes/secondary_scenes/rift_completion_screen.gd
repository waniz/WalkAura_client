extends Control

## Full-screen celebration on rift completion.
## Shows RIFT CLEARED! or RIFT SURVIVED, reward item, run summary.

var completion_data: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	anchor_left = 0.0; anchor_top = 0.0
	anchor_right = 1.0; anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	Styler._apply_parchment_style(panel)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var d: Dictionary = completion_data.get("data", completion_data)
	var death_count: int = int(d.get("rift_death_count", 0))
	var perfect_clear: bool = d.get("rift_perfect_clear", false)
	var xp_gained: int = int(d.get("rift_total_xp", d.get("xp_gained", 0)))
	var level: int = int(d.get("level", 0))
	var levels_gained: int = int(d.get("levels_gained", 0))
	var fights_won: int = int(d.get("rift_fights_won", d.get("activities_completed", 0)))

	# Banner
	var banner = Label.new()
	if perfect_clear:
		banner.text = "PERFECT CLEAR!"
		banner.add_theme_color_override("font_color", Color.from_rgba8(255, 215, 0))
	elif death_count == 0:
		banner.text = "RIFT CLEARED!"
		banner.add_theme_color_override("font_color", Color.from_rgba8(100, 220, 100))
	else:
		banner.text = "RIFT SURVIVED"
		banner.add_theme_color_override("font_color", Color.from_rgba8(220, 180, 60))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", Styler.JANDA_FONT)
	banner.add_theme_font_size_override("font_size", 28)
	vbox.add_child(banner)

	# Death count (if any)
	if death_count > 0:
		var death_lbl = Label.new()
		death_lbl.text = "%d death%s — reward quality reduced" % [death_count, "s" if death_count > 1 else ""]
		death_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(death_lbl, Color.from_rgba8(220, 100, 100))
		vbox.add_child(death_lbl)

	vbox.add_child(HSeparator.new())

	# Reward item display
	var new_items: Array = d.get("new_items", [])
	if not new_items.is_empty():
		var reward_title = Label.new()
		reward_title.text = "REWARD"
		reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(reward_title, Styler.COLOR_GOLD)
		reward_title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(reward_title)

		# Show the last item (completion reward is appended last)
		var item: Dictionary = new_items[-1]
		var item_box = PanelContainer.new()
		var isb = StyleBoxFlat.new()
		if perfect_clear:
			isb.border_color = Color.from_rgba8(255, 215, 0)
			isb.border_width_top = 2
			isb.border_width_bottom = 2
			isb.border_width_left = 2
			isb.border_width_right = 2
		else:
			isb.border_color = Color.from_rgba8(160, 120, 60)
			isb.border_width_top = 1
			isb.border_width_bottom = 1
			isb.border_width_left = 1
			isb.border_width_right = 1
		isb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
		isb.set_corner_radius_all(8)
		item_box.add_theme_stylebox_override("panel", isb)
		vbox.add_child(item_box)

		var item_margin = MarginContainer.new()
		item_margin.add_theme_constant_override("margin_left", 12)
		item_margin.add_theme_constant_override("margin_right", 12)
		item_margin.add_theme_constant_override("margin_top", 10)
		item_margin.add_theme_constant_override("margin_bottom", 10)
		item_box.add_child(item_margin)

		var item_vbox = VBoxContainer.new()
		item_vbox.add_theme_constant_override("separation", 4)
		item_margin.add_child(item_vbox)

		var quality_names = ["", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
		var quality_colors = [
			Color.WHITE,
			Color.from_rgba8(180, 180, 180),
			Color.from_rgba8(30, 180, 30),
			Color.from_rgba8(50, 100, 220),
			Color.from_rgba8(160, 50, 200),
			Color.from_rgba8(220, 150, 30),
			Color.from_rgba8(220, 50, 50),
		]

		var q: int = int(item.get("quality", 1))
		var q_name: String = quality_names[q] if q < quality_names.size() else "Unknown"
		var q_color: Color = quality_colors[q] if q < quality_colors.size() else Color.WHITE

		var q_lbl = Label.new()
		q_lbl.text = q_name.to_upper()
		q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(q_lbl, q_color)
		q_lbl.add_theme_font_size_override("font_size", 12)
		item_vbox.add_child(q_lbl)

		var item_name_lbl = Label.new()
		item_name_lbl.text = str(item.get("name", "Unknown Item"))
		item_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
		item_name_lbl.add_theme_font_size_override("font_size", 18)
		item_name_lbl.add_theme_color_override("font_color", q_color)
		item_vbox.add_child(item_name_lbl)

		var item_type_lbl = Label.new()
		item_type_lbl.text = str(item.get("slot", "")).capitalize()
		item_type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Styler.style_parchment_label(item_type_lbl, Styler.COLOR_TEXT_DARK)
		item_type_lbl.add_theme_font_size_override("font_size", 12)
		item_vbox.add_child(item_type_lbl)

		# Item stats
		var stats: Dictionary = item.get("stats", {})
		for stat_key in stats:
			var stat_row = Label.new()
			stat_row.text = "%s: +%s" % [str(stat_key).capitalize(), str(stats[stat_key])]
			stat_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			Styler.style_parchment_label(stat_row, Color.from_rgba8(100, 200, 100))
			stat_row.add_theme_font_size_override("font_size", 13)
			item_vbox.add_child(stat_row)

	vbox.add_child(HSeparator.new())

	# Run summary
	var summary_grid = GridContainer.new()
	summary_grid.columns = 2
	summary_grid.add_theme_constant_override("h_separation", 16)
	summary_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(summary_grid)

	var summary_items = [
		["Fights Won", "%d" % fights_won],
		["Deaths", "%d" % death_count],
		["XP Earned", "+%d" % xp_gained],
		["Rift Level", "%d%s" % [level, " (UP!)" if levels_gained > 0 else ""]],
	]
	for pair in summary_items:
		var key_lbl = Label.new()
		key_lbl.text = pair[0]
		Styler.style_parchment_label(key_lbl, Color.from_rgba8(150, 150, 150))
		summary_grid.add_child(key_lbl)
		var val_lbl = Label.new()
		val_lbl.text = pair[1]
		Styler.style_parchment_label(val_lbl, Styler.COLOR_TEXT_DARK)
		summary_grid.add_child(val_lbl)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "CONTINUE"
	close_btn.custom_minimum_size = Vector2(0, 48)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Styler.style_button(close_btn, Color.from_rgba8(60, 130, 70))
	close_btn.pressed.connect(queue_free)
	vbox.add_child(close_btn)
