extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var log: RichTextLabel = $Panel/VBox/Log
@onready var pause: CheckButton = $Panel/VBox/ToolBar/Pause
@onready var clear_button: Button = $Panel/VBox/ToolBar/ClearButton
@onready var tool_bar: HBoxContainer = $Panel/VBox/ToolBar

const MAX_LINES = 1000
var _line_count = 0

func _ready() -> void:
	Debugger.signalLogUpdated.connect(_on_log_update)
	
	Styler.style_panel(panel, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))

	var font: FontFile = load("res://assets/_fonts/JetBrainsMono-Regular.ttf")
	# Font & size for all normal text
	log.add_theme_font_override("normal_font", font)
	log.add_theme_font_size_override("normal_font_size", 14)
	# Colors & outline
	log.add_theme_color_override("default_color", Color.from_rgba8(220, 220, 220))
	log.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	log.add_theme_constant_override("outline_size", 2)

	clear_button.pressed.connect(_on_clear)
	
func _on_log_update(msg):
	if pause.button_pressed:
		return
		
	log.append_text(msg)
	log.append_text("\n")
	
	_line_count += 1
	if _line_count > MAX_LINES:
		_trim_head(int(MAX_LINES * 0.2))  # drop oldest 20% in one go

func _on_clear() -> void:
	log.clear()
	_line_count = 0

func _trim_head(n: int) -> void:
	# Efficient-ish: rebuild from tail
	var text := log.get_parsed_text()         # current bbcode text
	var lines := text.split("\n")
	if lines.size() <= n: return
	lines = lines.slice(n, lines.size())
	log.clear()
	log.append_text("\n".join(lines))
	_line_count = lines.size()
