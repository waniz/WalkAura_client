extends CanvasLayer

const PAGE_LABELS = ["Profile", "Inventory", "Location", "Skills", "Quests"]
const PAGE_ICONS = [
	"res://assets/general_icons/hud/buttom_hud_character_without_face.png",
	"res://assets/general_icons/hud/buttom_hud_inventory.png",
	"res://assets/general_icons/hud/buttom_hud_location.png",
	"res://assets/general_icons/hud/buttom_hud_skills.png",
	"res://assets/general_icons/hud/buttom_hud_quest.png",
]
const NAV_COUNT = 4  # Quests (index 4) shows icon+label but is disabled until a Quests scene exists

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

	return {btn = btn, icon = icon, label = lbl, is_nav = is_nav}


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

	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, sb_set[state])


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
