extends Control

# NPC dialogue popup. Set `npc_uid` before add_child(); _ready requests the
# server dialogue (QuestManager.resolve_npc_dialogue) and rebuilds when
# SignalManager.signal_NpcDialogueReceived arrives. Shows the resolved line and
# one Accept button per offer (offers come from the server — see
# QUEST_PROTOCOL.md). Accepting calls QuestManager.accept_quest; the
# authoritative gate is server-side, so a rejected accept surfaces via the
# normal error path.

var npc_uid: String = ""
var npc_name: String = ""   # optional display name; falls back to npc_uid

var _line: String = "..."
var _offers: Array = []
var _content: VBoxContainer = null


func _ready() -> void:
	anchor_left = 0; anchor_top = 0
	anchor_right = 1; anchor_bottom = 1
	mouse_filter = MOUSE_FILTER_STOP
	SignalManager.signal_NpcDialogueReceived.connect(_on_dialogue_received)
	_build_ui()
	if npc_uid != "":
		QuestManager.resolve_npc_dialogue(npc_uid)


func _on_dialogue_received(data: Dictionary) -> void:
	# Ignore responses for other NPCs (a different popup may be open/closing).
	if String(data.get("npc_uid", "")) != npc_uid:
		return
	_line = String(data.get("line", ""))
	var offers = data.get("offers", [])
	_offers = offers if typeof(offers) == TYPE_ARRAY else []
	_rebuild_content()


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			queue_free()
	)
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mo = Styler.get_modal_offsets()
	panel.offset_left = mo["left"]
	panel.offset_right = mo["right"]
	panel.offset_top = mo["top"]
	panel.offset_bottom = mo["bottom"]
	var accent: Color = Styler.COL_PRIMARY
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.from_rgba8(16, 18, 24, 245)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(accent, 0.4)
	sb.shadow_size = 16
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	# Header: NPC name + close.
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	vb.add_child(head)

	var name_lbl = Label.new()
	name_lbl.text = (npc_name if npc_name != "" else npc_uid).to_upper()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", Styler.JANDA_FONT)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	head.add_child(name_lbl)

	var close = Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(40, 40)
	close.add_theme_font_override("font", Styler.JANDA_FONT)
	close.add_theme_font_size_override("font_size", 18)
	close.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	for s in ["normal", "hover", "pressed", "focus"]:
		var b_sb = StyleBoxFlat.new()
		b_sb.bg_color = Color(0, 0, 0, 0.3)
		b_sb.border_color = Color(Styler.COL_PRIMARY, 0.4)
		b_sb.set_border_width_all(1)
		b_sb.set_corner_radius_all(4)
		close.add_theme_stylebox_override(s, b_sb)
	close.pressed.connect(queue_free)
	head.add_child(close)

	# Content (dialogue line + offers) rebuilt when the server responds.
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	vb.add_child(_content)
	_rebuild_content()


func _rebuild_content() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()

	# Dialogue line.
	var line_panel = PanelContainer.new()
	var lp_sb = StyleBoxFlat.new()
	lp_sb.bg_color = Color(1, 1, 1, 0.04)
	lp_sb.border_color = Color(Styler.COL_PRIMARY, 0.3)
	lp_sb.border_width_left = 2
	lp_sb.set_corner_radius_all(4)
	lp_sb.content_margin_left = 10
	lp_sb.content_margin_right = 10
	lp_sb.content_margin_top = 8
	lp_sb.content_margin_bottom = 8
	line_panel.add_theme_stylebox_override("panel", lp_sb)
	var line_lbl = Label.new()
	line_lbl.text = _line
	line_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	line_lbl.add_theme_font_size_override("font_size", 14)
	line_lbl.add_theme_color_override("font_color", Color.from_rgba8(200, 192, 170))
	line_panel.add_child(line_lbl)
	_content.add_child(line_panel)

	# Offers.
	if _offers.is_empty():
		var none = Label.new()
		none.text = "Nothing for you right now."
		none.add_theme_font_override("font", Styler.JANDA_FONT)
		none.add_theme_font_size_override("font_size", 12)
		none.add_theme_color_override("font_color", Color(Styler.COL_PRIMARY, 0.5))
		_content.add_child(none)
		return

	_content.add_child(_section_header("QUESTS", Styler.COL_PRIMARY))
	for offer in _offers:
		_content.add_child(_offer_row(offer))


func _offer_row(offer: Dictionary) -> Control:
	var quest_uid: String = String(offer.get("quest_uid", ""))
	var title: String = String(offer.get("title", quest_uid))
	var lvl: int = int(offer.get("level_requirement", 1))
	var btn = Button.new()
	btn.text = "%s   (Lvl %d)" % [title, lvl]
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 46)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Styler.JANDA_FONT)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Styler.COL_PRIMARY)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(Styler.COL_PRIMARY, 0.15)
		sb.border_color = Color(Styler.COL_PRIMARY, 0.55)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(5)
		if state_name == "hover":
			sb.shadow_color = Color(Styler.COL_PRIMARY, 0.4)
			sb.shadow_size = 6
		btn.add_theme_stylebox_override(state_name, sb)
	btn.pressed.connect(func():
		_accept(quest_uid, title)
	)
	return btn


func _accept(quest_uid: String, title: String) -> void:
	if quest_uid == "":
		return
	QuestManager.accept_quest(quest_uid)
	SignalManager.signal_GameNotification.emit("Quest accepted: %s" % title, Styler.COL_PRIMARY)
	queue_free()


func _section_header(text: String, accent: Color) -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var hdr = Label.new()
	hdr.text = text
	hdr.add_theme_font_override("font", Styler.JANDA_FONT)
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", accent.lightened(0.1))
	v.add_child(hdr)
	var rule = ColorRect.new()
	rule.color = Color(accent, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	v.add_child(rule)
	return v
