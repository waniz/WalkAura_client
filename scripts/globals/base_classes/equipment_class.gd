class_name EquipmentPane extends Control

signal equipped_item(slot_name: String, item_id: String)
signal unequipped_item(slot_name: String, item_id: String)


@export var slot_size: Vector2i = Vector2i(64, 64)
@export var bottom_slot_size: Vector2i = Vector2i(72, 72)
@export var slot_padding: int = 8
@export var item_defs: Dictionary = {}
@export var item_icons: Dictionary = {}
@export var inventory_grid_path: NodePath


# Top layout (left/right columns)
@export var slots_left: Array[String]  = ["Head","Neck","Shoulder","Cloak","Chest","Wrist"]
@export var slots_right: Array[String] = ["Gloves","Belt","Legs","Feet","Ring1","Ring2","Trinket1","Trinket2"]

# NEW: bottom weapon row
@export var slots_bottom: Array[String] = ["MainHand","OffHand"]


const QUALITY_COLORS := {
	0: Color(0.62, 0.62, 0.62), # poor (gray)
	1: Color(1, 1, 1),          # common (white)
	2: Color(0.12, 1, 0),       # uncommon (green)
	3: Color(0, 0.44, 0.87),    # rare (blue)
	4: Color(0.64, 0.21, 0.93), # epic (purple)
	5: Color(1, 0.5, 0),        # legendary (orange)
	6: Color(0.9, 0.8, 0.2)     # artifact (gold-ish)
}

var _equipped:   Dictionary = {}   # slot_name -> {id:String, qty:int}
var _slot_nodes: Dictionary = {}   # slot_name -> {panel, btn, icon, label}
var _inv: Node = null
var _built = false
#const USE_WOW_TOOLTIP = true
#var _tooltip: Node = null


func _ready() -> void:
	item_defs = ItemDB.ITEM_DEFS
	item_icons = ItemDB.ITEM_ICONS
	
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL
	
	_build_ui()
	
	if inventory_grid_path != NodePath(""):
		_inv = get_node_or_null(inventory_grid_path)

func set_equipment(d: Dictionary) -> void:
	# d: slot_name -> {"id": String, "qty": int}
	_equipped = d.duplicate(true)
	for k in _equipped.keys():
		_update_slot(k)

func get_equipment() -> Dictionary:
	return _equipped.duplicate(true)

# ---------------- UI -----------------
func _build_ui() -> void:

	var root = VBoxContainer.new()
	root.name = "Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", slot_padding * 2)
	add_child(root)

	# --- TOP: two vertical columns (WoW armory)
	var top = HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", slot_padding * 12) # wide gap between columns
	root.add_child(top)
	
	var col_left = VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", slot_padding)
	top.add_child(col_left)
	
	var col_right = VBoxContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", slot_padding)
	top.add_child(col_right)

	# Build slots
	var created = 0
	for s in slots_left:
		col_left.add_child(_make_slot(s, slot_size, true))
		created += 1
	for s in slots_right:
		col_right.add_child(_make_slot(s, slot_size, false))
		created += 1
		
	# --- BOTTOM: centered weapon row
	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_theme_constant_override("separation", slot_padding * 2)
	root.add_child(bottom)

	for s in slots_bottom:
		if s == "MainHand":
			bottom.add_child(_make_slot(s, bottom_slot_size, true))
		else:
			bottom.add_child(_make_slot(s, bottom_slot_size, false))
		created += 1
		
	print("EquipmentPane: built UI with ", created, " slots")

# Create a single equipment slot control
func _make_slot(slot_name: String, size: Vector2i, left: bool) -> Control:
	var panel = PanelContainer.new()
	panel.name = slot_name
	panel.custom_minimum_size = Vector2(slot_size)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Style: subtle background + border (quality changes border color)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.4)
	sb.border_width_bottom = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_color = Color(0.25, 0.25, 0.3)
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	panel.add_theme_stylebox_override("panel", sb)

	var hb = HBoxContainer.new() # name label + icon
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 8)
	panel.add_child(hb)

	var lbl = Label.new()
	lbl.text = slot_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var btn = Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.custom_minimum_size = Vector2(size)
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.anchor_left = 0; icon.anchor_top = 0; icon.anchor_right = 1; icon.anchor_bottom = 1
	icon.offset_left = 2; icon.offset_top = 2; icon.offset_right = -2; icon.offset_bottom = -2
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if left:
		hb.add_child(lbl)
		hb.add_child(btn)
		btn.add_child(icon)
	else:
		hb.add_child(btn)
		btn.add_child(icon)
		hb.add_child(lbl)
		
	# Click to unequip
	btn.pressed.connect(func():
		if _equipped.has(slot_name):
			var id = String(_equipped[slot_name]["id"])
			_equipped.erase(slot_name)
			_update_slot(slot_name)
			emit_signal("unequipped_item", slot_name, id)
	)
	
	## Drag & drop from inventory
	#panel.can_drop_data = func(_pos: Vector2, data: Variant) -> bool:
		#return _can_drop_data(slot_name, data)
	#panel.drop_data = func(_pos: Vector2, data: Variant) -> void:
		#_on_drop_data(slot_name, data)

	_slot_nodes[slot_name] = {"panel": panel, "btn": btn, "icon": icon, "label": lbl}
	_update_slot(slot_name)
	return panel
	
func _update_slot(slot_name: String) -> void:
	print("INSIDE _update_slot")
	var nodes: Dictionary = _slot_nodes.get(slot_name, {})
	print(nodes)
	if nodes.is_empty(): return
	var panel: PanelContainer = nodes["panel"]
	var icon: TextureRect = nodes["icon"]
	var lbl: Label = nodes["label"]

	var sb: StyleBox = panel.get_theme_stylebox("panel")
	if _equipped.has(slot_name):
		print("INSIDE _equipped")
		var id = String(_equipped[slot_name]["id"])
		var def = ItemDB.ITEM_DEFS.get(id, {"name": id, "quality": 1})
		var tex: Texture2D = ItemDB.ITEM_ICONS.get(id, null)
		icon.texture = tex
		lbl.text = String(def.get("name", slot_name))
		# quality border
		var q = int(def.get("quality", 1))
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).border_color = QUALITY_COLORS.get(q, QUALITY_COLORS[1])
		# tooltips
		panel.tooltip_text = _build_builtin_tooltip(def)
	else:
		icon.texture = null
		lbl.text = slot_name
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).border_color = Color(0.25,0.25,0.3)
		panel.tooltip_text = ""

func _build_builtin_tooltip(def: Dictionary) -> String:
	var lines = []
	lines.append(String(def.get("name", "Item")))
	var descr = String(def.get("descr", ""))
	if descr != "":
		lines.append(descr)
	return "\n".join(lines)

func _is_item_allowed_for_slot(slot_name: String, id: String) -> bool:
	var def = ItemDB.ITEM_DEFS.get(id, null)
	if def == null: return false
	var item_slot = String(def.get("slot", ""))
	if item_slot == slot_name: return true
	# accommodate generic types (Ring/Trinket/Hand) to numbered slots
	var alt := {
		"Ring1": ["Ring","Finger"],
		"Ring2": ["Ring","Finger"],
		"Trinket1": ["Trinket"],
		"Trinket2": ["Trinket"],
		"MainHand": ["MainHand","OneHand","TwoHand"],
		"OffHand": ["OffHand","Shield","Tome","OneHand"],
	}
	if alt.has(slot_name) and alt[slot_name].has(item_slot):
		return true
	return false
	
# Optional external API: programmatic equip/unequip
func equip(slot_name: String, id: String) -> bool:
	print(slot_name, id)
	if not _is_item_allowed_for_slot(slot_name, id):
		print("   <Not Allowed")
		return false
	_equipped[slot_name] = {"id": id, "qty": 1}
	_update_slot(slot_name)
	emit_signal("equipped_item", slot_name, id)
	return true

func unequip(slot_name: String) -> void:
	if _equipped.has(slot_name):
		var id := String(_equipped[slot_name]["id"])
		_equipped.erase(slot_name)
		_update_slot(slot_name)
		emit_signal("unequipped_item", slot_name, id)
