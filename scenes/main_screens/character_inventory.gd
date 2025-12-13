class_name InventoryGrid extends Control

@onready var _grid: GridContainer = $TabContainer/Hero_Inventory/Margin/VBoxContainer/GridContainer
@onready var equipment_vbox: VBoxContainer = $TabContainer/Hero_Equipment/Margin/equipment_vbox
@onready var top_container: HBoxContainer = $TabContainer/Hero_Equipment/Margin/equipment_vbox/top_container
@onready var col_right: VBoxContainer = $TabContainer/Hero_Equipment/Margin/equipment_vbox/top_container/col_right
@onready var col_left: VBoxContainer = $TabContainer/Hero_Equipment/Margin/equipment_vbox/top_container/col_left
@onready var pirat_texture: TextureRect = $TabContainer/Hero_Equipment/Margin/equipment_vbox/top_container/pirat_texture


# --- Layout/config ---
@export var columns: int = 10
@export var rows: int = 10
@export var slot_size: Vector2i = Vector2i(64, 64)
@export var slot_padding: int = 6
@export var show_stack_count: bool = true
@export var show_tooltips: bool = true

@export var slot_size_eq: Vector2i = Vector2i(64, 64)
@export var bottom_slot_size_eq: Vector2i = Vector2i(96, 96)
@export var slot_padding_eq: int = 10

const TOOLTIP_MARGIN = 8.0

# touch tracking
var _last_pointer_pos = Vector2.ZERO
var hero_equipment_dict = {}
var _equipped:   Dictionary = {}   # slot_name -> {id:String, qty:int}
var _slot_nodes: Dictionary = {}   # slot_name -> {panel, btn, icon, label}

# Optional: provide your style box for slots
var _card_box_ref: Callable = Callable() # e.g. FuncRef(self, "_card_box")

# Item data hooks (assign from your game)
@export var item_defs: Dictionary = {} # id -> {name, descr, stackable:bool, max_stack:int}
@export var item_icons: Dictionary = {} # id -> Texture2D

# Inventory model: fixed-size Array of Dictionaries or null for empty slot
var _slots: Array = [] # [{"id_":String, "qty":int}] or null
var _tooltip: WowTooltip
var _tooltip_visible = false
var _tooltip_slot: int = -1

const QUALITY_COLORS := {
	0: Color(0.62, 0.62, 0.62), # poor (gray)
	1: Color(1, 1, 1),          # common (white)
	2: Color(0.12, 1, 0),       # uncommon (green)
	3: Color(0, 0.44, 0.87),    # rare (blue)
	4: Color(0.64, 0.21, 0.93), # epic (purple)
	5: Color(1, 0.5, 0),        # legendary (orange)
	6: Color(0.9, 0.8, 0.2)     # artifact (gold-ish)
}


func _ready() -> void:
	
	AccountManager.signal_InventoryReceived.connect(_on_request_inventory)
	item_icons = ItemDB.ITEM_ICONS
	
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	set_process(true)
	set_process_unhandled_input(true)
	
	_build_grid()
	_build_ui_eq()
	
	var pirat_tex = load("res://assets/background/pirat.png") as Texture2D
	pirat_texture.texture = pirat_tex
	
func _process(_dt: float) -> void:	
	if _tooltip_visible:
		_update_tooltip_position_to_point(_last_pointer_pos)

func _unhandled_input(event: InputEvent) -> void:
	if _tooltip_visible:
		if event is InputEventScreenTouch:
			_hide_tooltip()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_hide_tooltip()
	
# Public API -------------------------------------------------------------
func set_card_box(card_box_callable: Callable) -> void:
	_card_box_ref = card_box_callable
	_rebuild_grid()

func resize_grid(new_cols:int, new_rows:int) -> void:
	columns = max(1, new_cols)
	rows = max(1, new_rows)
	_resize_slots(columns*rows)
	_rebuild_grid()

func clear_inventory() -> void:
	_slots.resize(columns*rows)
	for i in _slots.size():
		_slots[i] = null
	_refresh_all()
	
	_hide_tooltip()

func get_inventory() -> Array:
	var out := []
	for s in _slots:
		if s == null:
			out.append(null)
		else:
			out.append({"id": s.id if s.has("id") else s["id"], "qty": int(s.qty if s.has("qty") else s["qty"])})
	return out

func set_inventory(arr: Array) -> void:
	_slots.resize(columns*rows)
	for i in _slots.size():
		_slots[i] = null
	for i in min(arr.size(), _slots.size()):
		var v = arr[i]
		if v is Dictionary and v.has("id") and v.has("qty"):
			_slots[i] = {"id": String(v["id"]), "qty": int(v["qty"])}
	_refresh_all()

func add_item(code:String, qty:int, def: Dictionary) -> int:
	# Returns leftover qty that didn't fit
	if qty <= 0:
		return 0

	var stackable = def and def.get("stackable", true)
	var max_stack := int(def.get("max_stack", 99)) if def else 99

	var remaining := qty

	if stackable:
		# 1) Fill existing stacks
		for i in _slots.size():
			if remaining <= 0: break
			var s = _slots[i]
			if s == null: continue
			if s["code"] == code:
				var space := max_stack - int(s["qty"])
				if space > 0:
					var push = min(space, remaining)
					s["qty"] += push
					remaining -= push
					_refresh_slot(i)
		# 2) Create new stacks
		for i in _slots.size():
			if remaining <= 0: break
			if _slots[i] == null:
				var push = min(max_stack, remaining)
				_slots[i] = {"code": code, "qty": push}
				remaining -= push
				_refresh_slot(i)
	else:
		# non-stackable ⇒ one per empty slot
		for i in _slots.size():
			if remaining <= 0: break
			if _slots[i] == null:
				_slots[i] = {"code": code, "qty": 1}
				remaining -= 1
				_refresh_slot(i)
	return remaining

func remove_at(index:int, qty:int) -> Dictionary:
	# Removes up to qty from slot index. Returns {removed_id, removed_qty} or {} if none.
	if index < 0 or index >= _slots.size():
		return {}
	var s = _slots[index]
	if s == null:
		return {}
	var take = min(int(s["qty"]), max(1, qty))
	s["qty"] -= take
	var id := String(s["id"])
	if s["qty"] <= 0:
		_slots[index] = null
	_refresh_slot(index)
	return {"removed_id": id, "removed_qty": take}
	
# Internal UI ------------------------------------------------------------
func _build_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
		
	_grid.columns = columns
	_grid.add_theme_constant_override("h_separation", slot_padding)
	_grid.add_theme_constant_override("v_separation", slot_padding)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_resize_slots(columns*rows)
	for i in range(columns*rows):
		_grid.add_child(_make_slot(i))
		
func _resize_slots(n:int) -> void:
	var old = _slots
	_slots = []
	_slots.resize(n)
	for i in range(n):
		_slots[i] = old[i] if i < old.size() else null
		
func _rebuild_grid() -> void:
	_build_grid()
	_refresh_all()
	
func _refresh_all() -> void:
	for i in _grid.get_child_count():
		_refresh_slot(i)
		
func _make_slot(index:int) -> Control:
	var panel = PanelContainer.new()
	panel.name = "Slot_%d" % index
	panel.custom_minimum_size = Vector2(slot_size)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if _card_box_ref.is_valid():
		var sb = _card_box_ref.call()
		if typeof(sb) == TYPE_OBJECT:
			panel.add_theme_stylebox_override("panel", sb)
			
	var btn = Button.new()
	btn.name = "Btn"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.gui_input.connect(func(e): _on_slot_gui_input_touch(btn, index, e))
	panel.add_child(btn)
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.anchor_left = 0
	icon.anchor_top = 0
	icon.anchor_right = 1
	icon.anchor_bottom = 1
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	btn.add_child(icon)
	
	var count = Label.new()
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_font_size_override("font_size", 12)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	count.text = ""
	count.anchor_right = 1
	count.anchor_bottom = 1
	count.offset_right = -4
	count.offset_bottom = -2
	btn.add_child(count)
	
	return panel
	
func _refresh_slot(index:int) -> void:
	if index < 0 or index >= _grid.get_child_count():
		return
	var slot = _grid.get_child(index)
	var btn: Button = slot.get_node("Btn")
	var icon: TextureRect = btn.get_node("Icon")
	var count: Label = btn.get_node("Count")

	var s = _slots[index]
	if s == null:
		icon.texture = null
		count.text = ""
		btn.disabled = true
		slot.tooltip_text = ""
		return

	var code = String(s["code"])
	var qty = int(s["qty"])
	icon.texture = item_icons.get(code, null)
	btn.disabled = false
	count.text = str(qty) if (show_stack_count and qty > 1) else ""

	if show_tooltips:
		var def = item_defs.get(code, {})
		var nm = String(def.get("name", code))
		var ds = String(def.get("descr", ""))
		slot.tooltip_text = nm + ("\n" + ds if ds != "" else "")
		
func _ensure_tooltip() -> void:
	if _tooltip:
		return
		
	_tooltip = WowTooltip.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)
	
	SignalManager.signal_UseItem.connect(_on_tooltip_use_pressed)
	#_tooltip.equip_pressed.connect(_on_tooltip_equip_pressed)
		
func _show_tooltip_for(index:int) -> void:
	_ensure_tooltip()
	
	if index < 0 or index >= _slots.size():
		return
	
	var stack = _slots[index]
	if stack == null:
		return

	var def = item_defs[stack["code"]]
	if def.is_empty():
		return
		
	_tooltip.set_data(def, stack.get("quantity", 1))
	_update_tooltip_position()
	_tooltip.visible = true
	_tooltip_visible = true
	_tooltip_slot = index
	
func _on_slot_gui_input_touch(btn: Button, index:int, event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_last_pointer_pos = btn.get_global_rect().position + event.position
			if _tooltip_visible:
				_hide_tooltip()
				return
				
			_show_tooltip_for(index)
			_tooltip_visible = true
			_tooltip_slot = index
			_update_tooltip_position_to_point(event.position)
		return
	
	if event is InputEventScreenDrag:
		_last_pointer_pos = btn.get_global_rect().position + event.position
		if _tooltip_visible:
			_update_tooltip_position_to_point(event.position)

func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false
	_tooltip_visible = false

func _update_tooltip_position() -> void:
	if _tooltip == null or not _tooltip.visible:
		return
		
	_tooltip.position = _last_pointer_pos
	
func _update_tooltip_position_to_point(global_point: Vector2) -> void:
	if _tooltip == null or not _tooltip.visible:
		return

	var vp_rect = get_viewport().get_visible_rect()
	var vp_size: Vector2 = vp_rect.size
	
	var tooltip_size: Vector2 = _tooltip.get_combined_minimum_size()
	if tooltip_size == Vector2.ZERO:
		_tooltip.size = Vector2.ZERO
		_tooltip.reset_size()
		tooltip_size = _tooltip.get_combined_minimum_size()
	
	var pos = global_point
	
	var space_right = vp_size.x - global_point.x
	if space_right >= tooltip_size.x + TOOLTIP_MARGIN:
		pos.x += TOOLTIP_MARGIN
	else:
		pos.x -= tooltip_size.x + TOOLTIP_MARGIN
		
	var space_bottom = vp_size.y - global_point.y
	if space_bottom >= tooltip_size.y + TOOLTIP_MARGIN:
		pos.y += TOOLTIP_MARGIN
	else:
		pos.y -= tooltip_size.y + TOOLTIP_MARGIN
		
	pos.x = clampf(pos.x, 0.0, max(0.0, vp_size.x - tooltip_size.x))
	pos.y = clampf(pos.y, 0.0, max(0.0, vp_size.y - tooltip_size.y))
	
	_tooltip.global_position = pos
	
# Helpers ----------------------------------------------------------------------
func find_first(id:String) -> int:
	for i in _slots.size():
		var s = _slots[i]
		if s != null and s["id"] == id:
			return i
	return -1

func count_total(id:String) -> int:
	var total := 0
	for s in _slots:
		if s != null and s["id"] == id:
			total += int(s["qty"])
	return total

# Equipment ====================================================================
func _build_ui_eq() -> void:

	equipment_vbox.name = "Root"
	equipment_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipment_vbox.add_theme_constant_override("h_separation", slot_padding)
	equipment_vbox.add_theme_constant_override("v_separation", slot_padding)

	# --- TOP: two vertical columns (WoW armory)
	top_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	top_container.add_theme_constant_override("separation", slot_padding_eq)

	#col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", slot_padding_eq)

	#col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", slot_padding_eq)

	# Build slots
	for s in ItemDB.slots_left:
		col_left.add_child(_make_slot_eq(s, slot_size_eq, true))
	for s in ItemDB.slots_right:
		col_right.add_child(_make_slot_eq(s, slot_size_eq, false))

func _make_slot_eq(slot_name: String, size: Vector2i, left: bool) -> Control:
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
	
	var btn = Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.custom_minimum_size = Vector2(size)
	btn.gui_input.connect(func(e): _on_eq_slot_gui_input(btn, slot_name, e))
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.anchor_left = 0; icon.anchor_top = 0; icon.anchor_right = 1; icon.anchor_bottom = 1
	icon.offset_left = 2; icon.offset_top = 2; icon.offset_right = -2; icon.offset_bottom = -2
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if left:
		hb.add_child(btn)
		btn.add_child(icon)
	else:
		hb.add_child(btn)
		btn.add_child(icon)
		
	_slot_nodes[slot_name] = {"panel": panel, "btn": btn, "icon": icon}
	_update_slot_eq(slot_name)
	return panel
	
func _on_eq_slot_gui_input(btn: Button, slot_name: String, event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_last_pointer_pos = btn.get_global_rect().position + event.position
			if _tooltip_visible:
				_hide_tooltip()
				return

		# Call the new equipment tooltip function
		_show_tooltip_for_eq(slot_name)
		_tooltip_visible = true
		# We set the inventory slot to -1 so "Use" logic doesn't get confused
		_tooltip_slot = -1 
		_update_tooltip_position_to_point(event.position)
	return

	if event is InputEventScreenDrag:
		_last_pointer_pos = btn.get_global_rect().position + event.position
		if _tooltip_visible:
			_update_tooltip_position_to_point(event.position)

func _show_tooltip_for_eq(slot_name: String) -> void:
	_ensure_tooltip()

	# Check if we actually have something equipped in this slot
	if not _equipped.has(slot_name):
		return

	var item_data = _equipped[slot_name]
	var id = item_data["code"]

	# Get the full definition (name, stats, description)
	var def = hero_equipment_dict.get(id, {})
	if def.is_empty():
		# Fallback if def is missing but we have an ID
		def = {"code": id, "descr": "Unknown Item"}

	# Set data to tooltip. 
	# quantity is usually 1 for equipment, but we check just in case.
	_tooltip.set_data(def, item_data.get("qty", 1))

	_update_tooltip_position()
	_tooltip.visible = true
	_tooltip_visible = true

func _update_slot_eq(slot_name: String) -> void:
	var nodes: Dictionary = _slot_nodes.get(slot_name, {})
	if nodes.is_empty(): return
	var panel: PanelContainer = nodes["panel"]
	var icon: TextureRect = nodes["icon"]

	var sb: StyleBox = panel.get_theme_stylebox("panel")
	if _equipped.has(slot_name):
		var id = String(_equipped[slot_name]["code"])
		var def = item_defs.get(id, {"code": id, "quality": 1})
		var tex: Texture2D = item_icons.get(id, null)
		icon.texture = tex
		# quality border
		var q = int(def.get("quality", 1))
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).border_color = QUALITY_COLORS.get(q, QUALITY_COLORS[1])
	else:
		icon.texture = null
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).border_color = Color(0.25,0.25,0.3)
		panel.tooltip_text = ""

func set_equipment(d: Dictionary) -> void:
	# d: slot_name -> {"id": String, "qty": int}
	_equipped = d.duplicate(true)
	for k in _equipped.keys():
		_update_slot_eq(k)

func get_equipment() -> Dictionary:
	return _equipped.duplicate(true)
	
# Optional external API: programmatic equip/unequip
func equip(slot_name: String, id: String) -> bool:
	_equipped[slot_name] = {"code": id, "qty": 1}
	_update_slot_eq(slot_name)
	
	emit_signal("equipped_item", slot_name, id)
	return true

func unequip(slot_name: String) -> void:
	if _equipped.has(slot_name):
		var id = String(_equipped[slot_name]["id"])
		_equipped.erase(slot_name)
		_update_slot_eq(slot_name)
		emit_signal("unequipped_item", slot_name, id)

func _on_request_inventory(server_json) -> void:
	clear_inventory()
	
	# handle inventory
	if server_json.data.inventory:
		for element in server_json.data.inventory:
			add_item(element["code"], element["qty"], element)
			item_defs[element["code"]] = element
			
	# handle equipment		
	if server_json.data.equipment:
		for element in server_json.data.equipment:
			hero_equipment_dict[element["code"]] = element
			equip(element["slot"], element["code"])

func _on_tooltip_use_pressed(def: Dictionary) -> void:
	if _tooltip_slot < 0 or _tooltip_slot >= _slots.size():
		return
		
	var stack = _slots[_tooltip_slot]
	if stack.is_empty():
		return

	_hide_tooltip()
	
func _on_tooltip_equip_pressed(def: Dictionary) -> void:
	pass
