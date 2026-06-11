extends CanvasLayer

# WalkAura Bottom Nav — Phase 1 chrome restyle (2026-05-16).
# Mockup: design-mockups/index.html (bottom of every phone). Spec: DESIGN.md
# "Bottom Nav — 5 Tabs". Active state = gold rim tick above icon + radial
# brown-glow bg + outer gold glow. Quests slot supports a notification pip
# (driven by QuestManager quest state — pip shows when a quest is ready to turn in).

const PAGE_LABELS = ["Profile", "Inventory", "Location", "Skills", "Quests"]
const PAGE_ICONS = [
	"res://assets/general_icons/hud/buttom_hud_character_without_face.png",
	"res://assets/general_icons/hud/buttom_hud_inventory.png",
	"res://assets/general_icons/hud/buttom_hud_location.png",
	"res://assets/general_icons/hud/buttom_hud_skills.png",
	"res://assets/general_icons/hud/buttom_hud_quest.png",
]
const NAV_COUNT = 5  # All 5 tabs active. Quests scene shipped in P3 boilerplate.
const QUESTS_SLOT_IDX = 4

@onready var _button_panel: PanelContainer = $ButtonPanel

var _slots: Array = []
var _current_page: int = 0
# Pre-built StyleBox sets to avoid allocating new objects on every page change
var _sb_active = {}
var _sb_nav = {}
var _sb_disabled = {}


func _ready() -> void:
	_button_panel.anchor_left = 0.02
	_button_panel.anchor_right = 0.98
	_button_panel.offset_left = 0
	_button_panel.offset_right = 0

	_apply_bar_style()
	_precache_styleboxes()
	_build_buttons()
	SignalManager.signal_PageChanged.connect(_on_page_changed)
	_on_page_changed(2)

	# Quests pip — driven live by QuestManager.signal_QuestsUpdated.
	if has_node("/root/QuestManager"):
		QuestManager.signal_QuestsUpdated.connect(_refresh_quests_pip)
		_refresh_quests_pip()


func _refresh_quests_pip() -> void:
	if has_node("/root/QuestManager"):
		set_quests_pip(QuestManager.has_ready_quest())


func _precache_styleboxes() -> void:
	var bg_a = Color(58.0 / 255.0, 46.0 / 255.0, 22.0 / 255.0, 1.0)
	var bd_a = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 1.0)
	_sb_active = {
		"normal":   _make_sb(bg_a, bd_a, true, 5),
		"hover":    _make_sb(bg_a.lightened(0.08), bd_a, true, 5),
		"pressed":  _make_sb(bg_a.darkened(0.12), bd_a, true, 5),
		"focus":    _make_sb(bg_a, bd_a, true, 5),
		"disabled": _make_sb(bg_a, bd_a, true, 5),
	}
	var bg_n = Color(28.0 / 255.0, 22.0 / 255.0, 14.0 / 255.0, 230.0 / 255.0)
	var bd_n = Color(80.0 / 255.0, 64.0 / 255.0, 40.0 / 255.0, 180.0 / 255.0)
	_sb_nav = {
		"normal":   _make_sb(bg_n, bd_n, false, 0),
		"hover":    _make_sb(bg_n.lightened(0.08), bd_n, false, 0),
		"pressed":  _make_sb(bg_n.darkened(0.12), bd_n, false, 0),
		"focus":    _make_sb(bg_n, bd_n, false, 0),
		"disabled": _make_sb(bg_n, bd_n, false, 0),
	}
	var bg_d = Color(20.0 / 255.0, 16.0 / 255.0, 12.0 / 255.0, 100.0 / 255.0)
	var bd_d = Color(45.0 / 255.0, 36.0 / 255.0, 24.0 / 255.0, 100.0 / 255.0)
	_sb_disabled = {
		"normal":   _make_sb(bg_d, bd_d, false, 0),
		"hover":    _make_sb(bg_d, bd_d, false, 0),
		"pressed":  _make_sb(bg_d, bd_d, false, 0),
		"focus":    _make_sb(bg_d, bd_d, false, 0),
		"disabled": _make_sb(bg_d, bd_d, false, 0),
	}


func _apply_bar_style() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(18.0 / 255.0, 14.0 / 255.0, 10.0 / 255.0, 248.0 / 255.0)
	sb.border_color = Color(180.0 / 255.0, 140.0 / 255.0, 60.0 / 255.0, 1.0)
	sb.border_width_top = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.set_corner_radius_all(18)
	_button_panel.add_theme_stylebox_override("panel", sb)


func _build_buttons() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_button_panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	for i in range(5):
		var slot = _make_slot(i)
		_slots.append(slot)
		hbox.add_child(slot.btn)


func _make_slot(idx: int) -> Dictionary:
	var is_nav: bool = idx < NAV_COUNT

	var btn = Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 74)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_nav:
		btn.pressed.connect(func(): SignalManager.signal_PageChanged.emit(idx))
	else:
		btn.disabled = true

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if PAGE_ICONS[idx] != "":
		icon.texture = load(PAGE_ICONS[idx])
	vbox.add_child(icon)

	var lbl = Label.new()
	lbl.text = PAGE_LABELS[idx]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", Styler.QUADRAT_FONT)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 2)
	vbox.add_child(lbl)

	# Gold rim tick above the icon — visible only on active state. Spans ~60%
	# of the slot width centred at the top edge.
	var rim = Panel.new()
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rim.offset_top = -1
	rim.offset_bottom = 1
	rim.offset_left = 22  # 60% width = leave ~22px margin each side on typical slot
	rim.offset_right = -22
	rim.visible = false
	var rim_sb = StyleBoxFlat.new()
	rim_sb.bg_color = Styler.COL_PRIMARY
	rim_sb.set_corner_radius_all(1)
	rim_sb.shadow_color = Styler.COL_PRIMARY
	rim_sb.shadow_size = 4
	rim.add_theme_stylebox_override("panel", rim_sb)
	btn.add_child(rim)

	# Notification pip — top-right of icon. Driven by live QuestManager quest state.
	var pip = Panel.new()
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip.custom_minimum_size = Vector2(8, 8)
	pip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pip.offset_left = -16
	pip.offset_top = 6
	pip.offset_right = -8
	pip.offset_bottom = 14
	pip.visible = false  # P3 wires visibility via QuestManager.has_ready_quest
	var pip_sb = StyleBoxFlat.new()
	pip_sb.bg_color = Styler.COL_OFFENSE
	pip_sb.border_color = Color.from_rgba8(10, 10, 16, 255)
	pip_sb.set_border_width_all(2)
	pip_sb.set_corner_radius_all(4)
	pip_sb.shadow_color = Color(Styler.COL_OFFENSE, 0.6)
	pip_sb.shadow_size = 4
	pip.add_theme_stylebox_override("panel", pip_sb)
	btn.add_child(pip)

	return {btn = btn, icon = icon, label = lbl, is_nav = is_nav, rim = rim, pip = pip}


func _on_page_changed(idx: int) -> void:
	_current_page = idx
	for i in range(_slots.size()):
		var slot: Dictionary = _slots[i]
		var is_active: bool = (i == idx) and slot.is_nav
		_apply_slot_style(slot, is_active)


func _apply_slot_style(slot: Dictionary, is_active: bool) -> void:
	var btn: Button = slot.btn
	var icon: TextureRect = slot.icon
	var lbl: Label = slot.label
	var is_nav: bool = slot.is_nav
	var rim: Panel = slot.get("rim", null)

	var sb_set: Dictionary
	if is_active:
		sb_set = _sb_active
		icon.modulate = Color.WHITE
		lbl.add_theme_color_override("font_color", Color(255.0 / 255.0, 210.0 / 255.0, 80.0 / 255.0, 1.0))
	elif is_nav:
		sb_set = _sb_nav
		icon.modulate = Color(0.7, 0.65, 0.55, 0.85)
		lbl.add_theme_color_override("font_color", Color(165.0 / 255.0, 140.0 / 255.0, 100.0 / 255.0, 1.0))
	else:
		sb_set = _sb_disabled
		icon.modulate = Color(0.3, 0.3, 0.3, 0.4)
		lbl.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))

	# Gold rim tick: only visible on the active slot (and only nav slots are
	# ever active). Non-nav slots never get a rim shown.
	if rim != null:
		rim.visible = is_active and is_nav

	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, sb_set[state])


# Public API: toggle the Quests slot notification pip. Phase 3 wires this from
# QuestManager.has_ready_quest. Until then, leave pip hidden; debug callers can
# flip via this API.
func set_quests_pip(visible_pip: bool) -> void:
	if _slots.size() <= QUESTS_SLOT_IDX:
		return
	var pip: Panel = _slots[QUESTS_SLOT_IDX].get("pip", null)
	if pip != null:
		pip.visible = visible_pip


func _make_sb(bg: Color, border: Color, use_shadow: bool, shad_size: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_top = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	if use_shadow:
		sb.shadow_color = Color(220.0 / 255.0, 175.0 / 255.0, 68.0 / 255.0, 0.7)
		sb.shadow_size = shad_size
	return sb
