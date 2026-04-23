extends HBoxContainer

## Horizontal encounter node path: ◆━━━◆━━━◇───◇───◇
## Shows progression through rift encounters as connected diamond nodes.

var total: int = 4
var current: int = 0
var tier_color: Color = Color.from_rgba8(31, 255, 0)

const COLOR_DIM = Color(0.47, 0.47, 0.47)
const COLOR_CURRENT_GLOW = Color(1, 1, 1, 0.9)
const NODE_FONT_SIZE = 12
const CONNECTOR_MIN_W = 12


func setup(p_total: int, p_current: int, p_tier_color: Color) -> void:
	total = p_total
	current = p_current
	tier_color = p_tier_color
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	add_theme_constant_override("separation", 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for i in range(total):
		# Node diamond
		var node_col: Color
		var symbol: String
		if i < current:
			node_col = tier_color
			symbol = "◆"
		elif i == current:
			node_col = COLOR_CURRENT_GLOW
			symbol = "◇"
		else:
			node_col = COLOR_DIM
			symbol = "◇"

		var diamond = Label.new()
		diamond.text = symbol
		diamond.add_theme_font_size_override("font_size", 18)
		diamond.add_theme_color_override("font_color", node_col)
		diamond.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		diamond.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		add_child(diamond)

		# Connector line between nodes
		if i < total - 1:
			var connector = Label.new()
			if i < current:
				connector.text = "━━"
				connector.add_theme_color_override("font_color", tier_color)
			elif i == current:
				connector.text = "──"
				connector.add_theme_color_override("font_color", Color(tier_color, 0.5))
			else:
				connector.text = "──"
				connector.add_theme_color_override("font_color", COLOR_DIM)
			connector.add_theme_font_size_override("font_size", 10)
			connector.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			connector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			connector.custom_minimum_size.x = CONNECTOR_MIN_W
			add_child(connector)


func _ready() -> void:
	if total > 0:
		_rebuild()
