extends Control

# Test scene for paper doll overlay system.
# Run this scene directly in Godot to preview how equipment overlays
# look on the character body. Each slot has a dropdown to pick variants.

const BASE_BODY_PATH = "res://assets/equipment_overlays/base_body/base_body_female.png"
const LAYER_ORDER = ["legs", "chest", "shoulder", "head", "gloves", "feet", "belt"]

var _paper_doll_layers: Dictionary = {}
var _slot_dropdowns: Dictionary = {}
var _character_container: TextureRect

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color.from_rgba8(16, 18, 24, 255)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Main layout: character on left, controls on right
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(PRESET_FULL_RECT)
	hbox.set("theme_override_constants/separation", 16)
	add_child(hbox)

	# --- Left side: paper doll character ---
	var char_panel = PanelContainer.new()
	char_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_panel.size_flags_stretch_ratio = 1.5
	Styler.style_panel(char_panel, Color.from_rgba8(28, 30, 40, 255), Color.from_rgba8(255, 255, 255, 30))
	hbox.add_child(char_panel)

	_character_container = TextureRect.new()
	_character_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character_container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_panel.add_child(_character_container)

	# Base body
	var body_tex = load(BASE_BODY_PATH) as Texture2D
	_make_layer("base_body", body_tex)

	# Overlay layers in draw order
	for slot in LAYER_ORDER:
		_paper_doll_layers[slot] = _make_layer(slot + "_layer")

	# --- Right side: controls ---
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.0
	hbox.add_child(scroll)

	var controls_vbox = VBoxContainer.new()
	controls_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_vbox.set("theme_override_constants/separation", 8)
	scroll.add_child(controls_vbox)

	# Title
	var title = Label.new()
	title.text = "Paper Doll Test"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Styler.style_title(title)
	title.add_theme_color_override("font_color", Styler.GOLD_COLOR)
	controls_vbox.add_child(title)

	# Create dropdown for each slot
	for slot in LAYER_ORDER:
		_add_slot_control(controls_vbox, slot)

	# Clear all button
	var clear_btn = Button.new()
	clear_btn.text = "Clear All"
	Styler.style_button_small(clear_btn, Color.from_rgba8(180, 60, 60))
	clear_btn.pressed.connect(_on_clear_all)
	controls_vbox.add_child(clear_btn)

func _make_layer(layer_name: String, tex: Texture2D = null) -> TextureRect:
	var layer = TextureRect.new()
	layer.name = layer_name
	layer.texture = tex
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_character_container.add_child(layer)
	return layer

func _add_slot_control(parent: VBoxContainer, slot_name: String) -> void:
	var row = HBoxContainer.new()
	row.set("theme_override_constants/separation", 8)
	parent.add_child(row)

	# Slot label
	var lbl = Label.new()
	lbl.text = slot_name.capitalize()
	lbl.custom_minimum_size.x = 100
	lbl.add_theme_color_override("font_color", Styler.GOLD_COLOR)
	row.add_child(lbl)

	# Dropdown with available variants
	var dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dropdown.add_item("-- none --", 0)

	# Find all icon keys for this slot from ItemDB overlay paths
	var keys = _get_overlay_keys_for_slot(slot_name)
	for i in keys.size():
		dropdown.add_item(keys[i], i + 1)

	dropdown.item_selected.connect(_on_slot_changed.bind(slot_name, keys))
	row.add_child(dropdown)
	_slot_dropdowns[slot_name] = dropdown

func _get_overlay_keys_for_slot(slot_name: String) -> Array:
	var keys: Array = []
	for key in ItemDB._item_overlay_paths:
		if key.begins_with(slot_name + "_") or key == slot_name:
			keys.append(key)
	keys.sort()
	return keys

func _on_slot_changed(index: int, slot_name: String, keys: Array) -> void:
	var layer = _paper_doll_layers.get(slot_name)
	if not layer:
		return
	if index == 0:
		layer.texture = null
	else:
		var icon_key = keys[index - 1]
		layer.texture = ItemDB.get_item_overlay(icon_key)

func _on_clear_all() -> void:
	for slot in _paper_doll_layers:
		_paper_doll_layers[slot].texture = null
	for slot in _slot_dropdowns:
		_slot_dropdowns[slot].selected = 0
