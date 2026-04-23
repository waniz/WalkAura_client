extends Control

## Pre-fight loadout screen for rift milestone battles.
## Shows enemy preview with stats/weaknesses and lets the player
## swap gear before confirming the fight.

var pending_monster: Dictionary = {}

var _enemy_name_label: Label
var _enemy_level_label: Label
var _enemy_hp_label: Label
var _enemy_weakness_label: Label
var _fight_btn: Button


func _ready() -> void:
	_build_ui()
	_populate()


func _build_ui() -> void:
	anchor_left = 0.0; anchor_top = 0.0
	anchor_right = 1.0; anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_STOP

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
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
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header
	var title = Label.new()
	title.text = "PREPARE FOR BATTLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Styler.COLOR_TEXT_DARK)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_font_override("font", Styler.JANDA_FONT)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Enemy preview section
	var enemy_box = PanelContainer.new()
	var esb = StyleBoxFlat.new()
	esb.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	esb.border_color = Color.from_rgba8(200, 60, 60)
	esb.border_width_top = 2
	esb.set_corner_radius_all(6)
	enemy_box.add_theme_stylebox_override("panel", esb)
	vbox.add_child(enemy_box)

	var enemy_margin = MarginContainer.new()
	enemy_margin.add_theme_constant_override("margin_left", 12)
	enemy_margin.add_theme_constant_override("margin_right", 12)
	enemy_margin.add_theme_constant_override("margin_top", 10)
	enemy_margin.add_theme_constant_override("margin_bottom", 10)
	enemy_box.add_child(enemy_margin)

	var enemy_vbox = VBoxContainer.new()
	enemy_vbox.add_theme_constant_override("separation", 4)
	enemy_margin.add_child(enemy_vbox)

	_enemy_name_label = Label.new()
	_enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_name_label.add_theme_font_override("font", Styler.JANDA_FONT)
	_enemy_name_label.add_theme_font_size_override("font_size", 20)
	_enemy_name_label.add_theme_color_override("font_color", Color.from_rgba8(220, 60, 60))
	enemy_vbox.add_child(_enemy_name_label)

	_enemy_level_label = Label.new()
	_enemy_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(_enemy_level_label, Styler.COLOR_TEXT_DARK)
	enemy_vbox.add_child(_enemy_level_label)

	_enemy_hp_label = Label.new()
	_enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(_enemy_hp_label, Styler.COLOR_TEXT_DARK)
	enemy_vbox.add_child(_enemy_hp_label)

	_enemy_weakness_label = Label.new()
	_enemy_weakness_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(_enemy_weakness_label, Color.from_rgba8(50, 100, 200))
	enemy_vbox.add_child(_enemy_weakness_label)

	# Milestone info
	var milestone_label = Label.new()
	milestone_label.name = "milestone_label"
	milestone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(milestone_label, Styler.COLOR_TEXT_DARK)
	enemy_vbox.add_child(milestone_label)

	vbox.add_child(HSeparator.new())

	# Player stats summary
	var stats_label = Label.new()
	stats_label.name = "stats_label"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_parchment_label(stats_label, Styler.COLOR_TEXT_DARK)
	vbox.add_child(stats_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var later_btn = Button.new()
	later_btn.text = "Later"
	later_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	later_btn.custom_minimum_size = Vector2(0, 48)
	Styler.style_button(later_btn, Color.from_rgba8(100, 100, 100))
	later_btn.add_theme_color_override("font_color", Color.WHITE)
	later_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	later_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	later_btn.pressed.connect(queue_free)
	btn_row.add_child(later_btn)

	_fight_btn = Button.new()
	_fight_btn.text = "FIGHT!"
	_fight_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_btn.custom_minimum_size = Vector2(0, 48)
	Styler.style_button(_fight_btn, Color.from_rgba8(200, 50, 50))
	_fight_btn.add_theme_color_override("font_color", Color.WHITE)
	_fight_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_fight_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	_fight_btn.pressed.connect(_on_fight_pressed)
	btn_row.add_child(_fight_btn)


func _populate() -> void:
	var is_raid: bool = pending_monster.get("is_raid", false)
	var milestone_idx: int = int(pending_monster.get("milestone_index", 0))
	var is_boss: bool = pending_monster.get("is_final_boss", false)

	if is_raid:
		_populate_raid(milestone_idx, is_boss)
	else:
		_populate_single(milestone_idx, is_boss)

	# Milestone info
	var milestone_lbl = get_node_or_null("*/*/milestone_label")
	if milestone_lbl:
		milestone_lbl.text = "Milestone %d" % (milestone_idx + 1)

	# Player stats
	var stats_lbl = get_node_or_null("*/*/stats_label")
	if stats_lbl:
		var hp_val: int = int(Account.hp) if Account.hp != null else 0
		var mp_val: int = int(Account.mp) if Account.mp != null else 0
		var shield_val: int = int(Account.shield) if Account.shield != null else 0
		stats_lbl.text = "Your stats: HP %d  |  MP %d  |  Shield %d" % [hp_val, mp_val, shield_val]


func _populate_single(milestone_idx: int, is_boss: bool) -> void:
	var name_text: String = str(pending_monster.get("name", "Unknown"))
	var level: int = int(pending_monster.get("level", 1))
	var hp: int = int(pending_monster.get("hp", 0))
	var atk = pending_monster.get("atk", 0)
	var attack_type: String = str(pending_monster.get("attack_type", "p"))
	var weaknesses: Dictionary = pending_monster.get("weaknesses", {})

	if is_boss:
		_enemy_name_label.text = "BOSS: " + name_text
	else:
		_enemy_name_label.text = name_text
	_enemy_level_label.text = "Level %d  |  %s" % [level, "Physical" if attack_type == "p" else "Magical"]
	_enemy_hp_label.text = "HP: %d  |  ATK: %s" % [hp, str(atk)]

	if weaknesses.is_empty():
		_enemy_weakness_label.text = "No known weaknesses"
	else:
		var parts: Array = []
		for element in weaknesses:
			var pct: int = int(float(weaknesses[element]) * 100)
			parts.append("Weak to %s (+%d%%)" % [str(element).capitalize(), pct])
		_enemy_weakness_label.text = " | ".join(parts)


func _populate_raid(milestone_idx: int, is_boss: bool) -> void:
	var encounter_monsters: Array = pending_monster.get("encounter_monsters", [])
	var rec_gear_score: int = int(pending_monster.get("recommended_gear_score", 0))
	var rec_resistances: Array = pending_monster.get("recommended_resistances", [])

	# Title: show encounter count
	if is_boss:
		_enemy_name_label.text = "FINAL ENCOUNTER (%d enemies)" % encounter_monsters.size()
	else:
		_enemy_name_label.text = "RAID ENCOUNTER (%d enemies)" % encounter_monsters.size()

	# Enemy list
	var enemy_names: Array = []
	for em in encounter_monsters:
		var role_text = ""
		var r = em.get("role", "")
		if r != "" and r != null:
			role_text = " [%s]" % str(r).to_upper()
		enemy_names.append("%s Lv%d%s" % [str(em.get("name", "?")), int(em.get("level", 1)), role_text])
	_enemy_level_label.text = "\n".join(enemy_names)
	_enemy_level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Total HP across all enemies
	var total_hp: int = 0
	for em in encounter_monsters:
		total_hp += int(em.get("hp", 0))
	_enemy_hp_label.text = "Total HP: %d" % total_hp

	# Preparation checklist
	var checklist_parts: Array = []

	# Gear score check
	if rec_gear_score > 0:
		var raw_gs = Account.get("gear_score")
		var player_gear_score: int = int(raw_gs) if raw_gs != null else 0
		var gs_status = "OK" if player_gear_score >= rec_gear_score else "LOW"
		checklist_parts.append("Gear Score: %d / %d  [%s]" % [player_gear_score, rec_gear_score, gs_status])

	# Resistance check
	for resist in rec_resistances:
		checklist_parts.append("Recommended: %s resistance" % str(resist).capitalize())

	if checklist_parts.is_empty():
		_enemy_weakness_label.text = "No special preparation needed"
	else:
		_enemy_weakness_label.text = "\n".join(checklist_parts)


func _on_fight_pressed() -> void:
	_fight_btn.disabled = true
	_fight_btn.text = "Fighting..."
	var skill_ids: Array = []
	var player_skills = Account.raw_structures.account_skills if Account.raw_structures.account_skills != null else {}
	if player_skills is Dictionary:
		for slot in player_skills:
			var skill = player_skills[slot]
			if skill is Dictionary:
				skill_ids.append(int(skill.get("skill_id", 0)))
	ServerConnector.send_message({
		"cmd": "confirm_fight",
		"payload": {"skill_loadout": skill_ids}
	})
	AccountManager.signal_ActivityProgressReceived.connect(_on_fight_result, CONNECT_ONE_SHOT)


func _on_fight_result(_data: Dictionary) -> void:
	queue_free()
