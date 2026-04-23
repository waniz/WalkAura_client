extends Control
## Debug scene: renders one achievement card in each visual state.
## Open this scene directly in Godot editor to visually QA card states
## without running the full game.

const AchievementCardScene = preload("res://scenes/secondary_scenes/achievement_card.tscn")


func _ready() -> void:
	var scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var states = [
		{
			"label": "EASY · IN_PROGRESS",
			"entry": _make_entry("Blooded", "Defeat 50 monsters.", 1, 25, 50, false, false, false, [
				{"type": "stat", "attr": "STR", "amount": 2}
			]),
		},
		{
			"label": "EASY · READY_TO_CLAIM",
			"entry": _make_entry("Blooded", "Defeat 50 monsters.", 1, 60, 50, false, false, false, [
				{"type": "stat", "attr": "STR", "amount": 2}
			]),
		},
		{
			"label": "EASY · CLAIMED",
			"entry": _make_entry("Blooded", "Defeat 50 monsters.", 1, 60, 50, true, false, false, [
				{"type": "stat", "attr": "STR", "amount": 2}
			]),
		},
		{
			"label": "MEDIUM · IN_PROGRESS",
			"entry": _make_entry("Rift Walker", "Complete 25 rift fights.", 2, 7, 25, false, false, false, [
				{"type": "stat", "attr": "SPI", "amount": 5}
			]),
		},
		{
			"label": "HARD · IN_PROGRESS (with title reward)",
			"entry": _make_entry("Million Steps Club", "Walk 1M lifetime steps.", 3, 250_000, 1_000_000, false, false, false, [
				{"type": "stat", "attr": "VIT", "amount": 10},
				{"type": "title", "title_id": 1}
			]),
		},
		{
			"label": "META · LOCKED (prereqs unmet)",
			"entry": _make_entry("Path of the Novice", "Claim all 4 Easy achievements.", 4, 0, 4, false, true, false, [
				{"type": "player_choice_stat", "amount": 3}
			]),
		},
		{
			"label": "META · READY with player_choice reward",
			"entry": _make_entry("Path of the Novice", "Claim all 4 Easy achievements.", 4, 4, 4, false, false, false, [
				{"type": "player_choice_stat", "amount": 3}
			]),
		},
		{
			"label": "SECRET · HIDDEN",
			"entry": _make_entry("???", "A hidden achievement awaits...", 5, 0, 0, false, false, true, []),
		},
	]

	for entry_with_label in states:
		var section_label = Label.new()
		section_label.text = entry_with_label["label"]
		section_label.add_theme_font_size_override("font_size", 12)
		section_label.modulate = Color(1, 1, 1, 0.6)
		vbox.add_child(section_label)

		var card = AchievementCardScene.instantiate()
		vbox.add_child(card)
		if card.has_method("set_data"):
			card.set_data(entry_with_label["entry"])


func _make_entry(name: String, desc: String, tier: int, current: int, target: int,
				 claimed: bool, locked: bool, hidden: bool, rewards: Array) -> Dictionary:
	return {
		"id": randi() % 1000,
		"tier": tier,
		"target": target,
		"current": current,
		"claimed": claimed,
		"claimed_at": null,
		"is_locked": locked,
		"is_hidden": hidden,
		"name": name,
		"name_key": null,
		"desc": desc,
		"reward_spec": rewards,
		"prereq_ids": [],
	}
