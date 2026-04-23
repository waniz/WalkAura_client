class_name StepsUpdateView extends Control

# Toast popup — bottom-right, renders on top via CanvasLayer, fades in/out
var _canvas_layer: CanvasLayer
var _vbox: VBoxContainer
var _fade_tween: Tween
const DISPLAY_TIME = 4.0
const FADE_TIME = 0.6

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true

	# CanvasLayer ensures the toast renders above all other UI
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	# Anchor container — full screen, passthrough input
	var anchor = Control.new()
	anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(anchor)

	_vbox = VBoxContainer.new()
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_vbox.offset_left = -320
	_vbox.offset_top = -220
	_vbox.offset_right = -16
	_vbox.offset_bottom = -110
	_vbox.add_theme_constant_override("separation", 4)
	anchor.add_child(_vbox)

	_vbox.modulate.a = 0.0

	SignalManager.signal_StepsReceivedFromServer.connect(_on_steps_received)
	SignalManager.signal_StepToastUpdate.connect(_on_toast_update)
	SignalManager.signal_GameNotification.connect(_on_game_notification)


func _on_steps_received(amount: int) -> void:
	if amount <= 0:
		return
	_show_toast(amount, {}, {}, [])


func _on_toast_update(steps: int, loot: Dictionary, mapping: Dictionary, new_items: Array) -> void:
	_show_toast(steps, loot, mapping, new_items)


func _on_game_notification(message: String, color: Color) -> void:
	for child in _vbox.get_children():
		child.queue_free()
	var lbl = Label.new()
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	if "GROBOLT_FONT" in Styler:
		lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
	_vbox.add_child(lbl)
	_vbox.modulate.a = 1.0
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_interval(DISPLAY_TIME)
	_fade_tween.tween_property(_vbox, "modulate:a", 0.0, FADE_TIME)


func _show_toast(steps: int, loot: Dictionary, mapping: Dictionary, new_items: Array) -> void:
	# Clear previous content
	for child in _vbox.get_children():
		child.queue_free()

	# Steps line
	if steps > 0:
		var steps_lbl = Label.new()
		steps_lbl.text = "+%d steps" % steps
		steps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		steps_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		steps_lbl.add_theme_font_size_override("font_size", 20)
		steps_lbl.add_theme_color_override("font_color", Color.from_rgba8(255, 215, 128))
		steps_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		steps_lbl.add_theme_constant_override("shadow_offset_x", 1)
		steps_lbl.add_theme_constant_override("shadow_offset_y", 1)
		if "GROBOLT_FONT" in Styler:
			steps_lbl.add_theme_font_override("font", Styler.GROBOLT_FONT)
		_vbox.add_child(steps_lbl)

	# Loot lines (icon + name + count)
	if loot != null and not loot.is_empty():
		for key in loot.keys():
			var qty = int(loot[key])
			var icon_key = str(mapping.get(key, key))
			var row = _create_loot_line(icon_key, _format_name(icon_key), qty)
			_vbox.add_child(row)

	# Equipment lines
	if new_items != null and not new_items.is_empty():
		for item_data in new_items:
			var item_name = str(item_data.get("name", "Unknown Item"))
			var quality = int(item_data.get("quality", 1))
			var quality_color = Styler.QUALITY_COLORS.get(quality, Color.WHITE)
			var eq_lbl = Label.new()
			eq_lbl.text = item_name
			eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			eq_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			eq_lbl.add_theme_font_size_override("font_size", 14)
			eq_lbl.add_theme_color_override("font_color", quality_color)
			eq_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
			eq_lbl.add_theme_constant_override("shadow_offset_x", 1)
			eq_lbl.add_theme_constant_override("shadow_offset_y", 1)
			_vbox.add_child(eq_lbl)

	# Fade in, hold, fade out
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_vbox, "modulate:a", 1.0, 0.3)
	_fade_tween.tween_interval(DISPLAY_TIME)
	_fade_tween.tween_property(_vbox, "modulate:a", 0.0, FADE_TIME)


func _create_loot_line(icon_key: String, display_name: String, qty: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 6)

	var icon = TextureRect.new()
	icon.texture = ItemDB.get_item_icon(icon_key, ItemDB.get_item_icon("default_bag"))
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var lbl = Label.new()
	lbl.text = "%s x%d" % [display_name, qty]
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.from_rgba8(220, 220, 200))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(lbl)

	return row


func _format_name(s: String) -> String:
	var result = PackedStringArray()
	for w in s.split("_"):
		result.append(w.capitalize())
	return " ".join(result)
