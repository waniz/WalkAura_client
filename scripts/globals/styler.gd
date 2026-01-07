extends Node


const QUALITY_COLORS := {
	0: Color(0.62, 0.62, 0.62), # Poor
	1: Color(1, 1, 1),          # Common
	2: Color(0.12, 1, 0),       # Uncommon
	3: Color(0, 0.44, 0.87),    # Rare
	4: Color(0.64, 0.21, 0.93), # Epic
	5: Color(1, 0.5, 0),        # Legendary
	6: Color(0.9, 0.8, 0.2)     # Artifact
}

var COL_PRIMARY  = Color.from_rgba8(255, 200, 66)
var COL_OFFENSE  = Color.from_rgba8(255, 120, 90)
var COL_DEFENSE  = Color.from_rgba8(64, 180, 255)
var COL_PANEL_BG = Color.from_rgba8(16, 18, 24, 220)
var COL_PANEL_BR = Color.from_rgba8(255, 255, 255, 30)
var COL_PANEL_GRAY = Color.from_rgba8(110, 96, 96, 255)


# ------------------- Styling helpers -------------------
func style_name_label(lbl: Label, gold: Color) -> void:
	var ls := LabelSettings.new()
	# font: replace with your font if you have one
	# ls.font = preload("res://fonts/YourFont.ttf")
	ls.font_size = 14
	ls.font_color = gold
	# nice outline & shadow for readability
	ls.outline_size = 3
	ls.outline_color = Color(0, 0, 0, 0.75)
	ls.shadow_size = 2
	ls.shadow_color = Color(0, 0, 0, 0.5)
	ls.shadow_offset = Vector2(0, 2)
	lbl.label_settings = ls
	#lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func style_title(lbl: Label) -> void:
	var ls := LabelSettings.new()
	ls.font_size = 24
	ls.font_color = Color.from_rgba8(255,215,128)
	ls.outline_size = 3
	ls.outline_color = Color(0,0,0,0.7)
	lbl.label_settings = ls
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
func style_button(btn, base: Color) -> void:
	btn.custom_minimum_size = Vector2(30, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Normal
	var normal = StyleBoxFlat.new()
	normal.bg_color = base
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.shadow_color = Color(0,0,0,0.25)
	normal.shadow_size = 4
	normal.border_color = base.darkened(0.35)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	# Hover
	var hover := normal.duplicate()
	hover.bg_color = base.lightened(0.10)
	hover.shadow_size = 6
	# Pressed
	var pressed = normal.duplicate()
	pressed.bg_color = base.darkened(0.10)
	pressed.shadow_size = 2
	pressed.content_margin_top = 2  # subtle “press” feel
	# Disabled
	var disabled = normal.duplicate()
	disabled.bg_color = base.darkened(0.55)
	disabled.border_color = base.darkened(0.6)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)

	# Font color states
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_color_override("font_hover_color", Color.BLACK)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	btn.add_theme_color_override("font_disabled_color", Color(0,0,0,0.6))
	btn.add_theme_font_size_override("font_size", 18)
	
func style_button_small(btn, base: Color) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Normal
	var normal = StyleBoxFlat.new()
	normal.bg_color = base
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.shadow_color = Color(0,0,0,0.25)
	normal.shadow_size = 4
	normal.border_color = base.darkened(0.35)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	# Hover
	var hover := normal.duplicate()
	hover.bg_color = base.lightened(0.10)
	hover.shadow_size = 5
	# Pressed
	var pressed = normal.duplicate()
	pressed.bg_color = base.darkened(0.10)
	pressed.shadow_size = 2
	pressed.content_margin_top = 2  # subtle “press” feel
	# Disabled
	var disabled = normal.duplicate()
	disabled.bg_color = base.darkened(0.55)
	disabled.border_color = base.darkened(0.6)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)

	# Font color states
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_color_override("font_hover_color", Color.BLACK)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	btn.add_theme_color_override("font_disabled_color", Color(0,0,0,0.6))
	btn.add_theme_font_size_override("font_size", 12)

func wire_button_anim(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		var t := btn.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12))
	btn.mouse_exited.connect(func():
		var t := btn.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE, 0.12))
		
func style_panel(p, bg: Color, border: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_left = 12
	box.corner_radius_bottom_right = 12
	box.shadow_color = Color(0,0,0,0.15)
	box.shadow_size = 6
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 20
	box.content_margin_bottom = 20
	p.add_theme_stylebox_override("panel", box)
	
func style_panel_no_margins(p, bg: Color, border: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_left = 12
	box.corner_radius_bottom_right = 12
	box.shadow_color = Color(0,0,0,0.15)
	box.shadow_size = 6
	p.add_theme_stylebox_override("panel", box)
	
func style_nameplate(panel: PanelContainer, bg: Color, border: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	# rounded corners
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	# thin border + soft shadow
	box.border_color = border.darkened(0.6)
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 4
	# a bit of padding so text breathes
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", box)

func style_line_edit(le: LineEdit, secret := false) -> void:
	le.secret = secret
	le.custom_minimum_size = Vector2(0, 36)
	# background
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color.from_rgba8(28,30,40,255)
	bg.border_color = Color.from_rgba8(255,255,255,25)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	le.add_theme_stylebox_override("normal", bg)
	# focus ring
	var focus := bg.duplicate()
	focus.border_color = Color.from_rgba8(64,180,255,200)
	focus.border_width_left = 2
	focus.border_width_right = 2
	focus.border_width_top = 2
	focus.border_width_bottom = 2
	le.add_theme_stylebox_override("focus", focus)

func style_bar(bar: ProgressBar, fill_col: Color, bg_col: Color) -> void:
	# background
	var bg = StyleBoxFlat.new()
	bg.bg_color = bg_col
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.border_color = bg_col.darkened(0.5)
	for r in ["top_left","top_right","bottom_left","bottom_right"]:
		bg.set("corner_radius_" + r, 10)

	# fill
	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_col
	fill.shadow_color = Color(0, 0, 0, 0.25)
	fill.shadow_size = 3
	for r in ["top_left","top_right","bottom_left","bottom_right"]:
		fill.set("corner_radius_" + r, 10)

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	bar.min_value = 0
	bar.value = 0

func style_mini_progress(bar: ProgressBar, accent: Color) -> void:
	# Track/background
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color.from_rgba8(28, 30, 40, 255)
	bg.border_color = Color.from_rgba8(255, 255, 255, 30)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6

	# Fill/foreground
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.shadow_color = Color(0, 0, 0, 0.20)
	fill.shadow_size = 2
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

func card_box() -> StyleBoxFlat:
	
	var box := StyleBoxFlat.new()
	box.bg_color = Color.from_rgba8(28,30,40,255)
	box.border_color = Styler.COL_PANEL_BR
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 16
	box.corner_radius_top_right = 16
	box.corner_radius_bottom_left = 16
	box.corner_radius_bottom_right = 16
	box.shadow_color = Color(0,0,0,0.25)
	box.shadow_size = 4
	box.content_margin_left = 10; box.content_margin_right = 10
	box.content_margin_top = 12;   box.content_margin_bottom = 10
	return box
