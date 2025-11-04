class_name InventoryGrid extends Control

signal equipped_item(slot_name: String, item_id: String)
signal unequipped_item(slot_name: String, item_id: String)

@onready var request_inventory: Button = $PanelContainer/VBoxContainer/RequestInventory
@onready var request_equipment: Button = $PanelContainer/VBoxContainer/RequestEquipment
@onready var _grid: GridContainer = $TabContainer/Hero_Inventory/Margin/VBoxContainer/GridContainer
@onready var equipment_vbox: VBoxContainer = $TabContainer/Hero_Equipment/Margin/equipment_vbox

# --- Layout/config ---
@export var columns: int = 10
@export var rows: int = 10
@export var slot_size: Vector2i = Vector2i(32, 48)
@export var slot_padding: int = 6
@export var show_stack_count: bool = true
@export var show_tooltips: bool = true

@export var slot_size_eq: Vector2i = Vector2i(96, 96)
@export var bottom_slot_size_eq: Vector2i = Vector2i(128, 128)
@export var slot_padding_eq: int = 8

@export var tooltip_long_press_ms = 350
@export var tooltip_move_cancel_px = 8.0
@export var tooltip_tap_to_dismiss = true

@export var slots_left: Array[String]  = ["head","neck","shoulder","cloak","chest","wrist"]
@export var slots_right: Array[String] = ["gloves","belt","legs","feet","ring1","ring2","trinket1","trinket2"]
@export var slots_bottom: Array[String] = ["mainHand","offHand"]

# touch tracking
var _touch_active = true
var _touch_slot = -1
var _press_time_ms = 0
var _press_pos = Vector2.ZERO
var _last_pointer_pos = Vector2.ZERO
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
	item_defs = ItemDB.ITEM_DEFS
	item_icons = ItemDB.ITEM_ICONS
	
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	set_process(true)
	set_process_unhandled_input(true)
	
	_build_grid()
	
	_build_ui_eq()
	
func _process(_dt: float) -> void:
	# follow finger/mouse
	if _tooltip_visible:
		_update_tooltip_position_to_point(_last_pointer_pos)
	# long-press detection
	if _touch_active and not _tooltip_visible:
		if Time.get_ticks_msec() - _press_time_ms >= tooltip_long_press_ms:
			_show_tooltip_for(_touch_slot)
			_update_tooltip_position_to_point(_press_pos)

func _unhandled_input(event: InputEvent) -> void:
	# tap anywhere hides the tooltip (unless it's our long press)
	if _tooltip_visible and event is InputEventScreenTouch and event.pressed:
		_hide_tooltip()
		
func _normalize_code(code: String) -> String:
	if code.begins_with("herb_"):
		return code.substr(5)
	if code.begins_with("alchemy_"):
		return code.substr(8)
	return code
	
# Public API -------------------------------------------------------------
func set_card_box(card_box_callable: Callable) -> void:
	_card_box_ref = card_box_callable
	# refresh slot visuals
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
	# deep-copy snapshot
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

func add_item(id_:String, qty:int) -> int:
	# Returns leftover qty that didn't fit
	if qty <= 0:
		return 0
	var def = item_defs.get(id_, null)
	var stackable = def and def.get("stackable", true)
	var max_stack := int(def.get("max_stack", 99)) if def else 99

	var remaining := qty

	if stackable:
		# 1) Fill existing stacks
		for i in _slots.size():
			if remaining <= 0: break
			var s = _slots[i]
			if s == null: continue
			if s["id_"] == id_:
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
				_slots[i] = {"id_": id_, "qty": push}
				remaining -= push
				_refresh_slot(i)
	else:
		# non-stackable ⇒ one per empty slot
		for i in _slots.size():
			if remaining <= 0: break
			if _slots[i] == null:
				_slots[i] = {"id_": id_, "qty": 1}
				remaining -= 1
				_refresh_slot(i)
	return remaining

func remove_at(index:int, qty:int=2147483647) -> Dictionary:
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
	#if is_instance_valid(_grid):
		#_grid.queue_free()
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
	btn.gui_input.connect(func(e): _on_slot_gui_input_touch(index, e))
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
	
	## Drag & drop
	#btn.gui_input.connect(func(e): _on_slot_gui_input(index, e))
	#panel.get_drag_data = func(at_position: Vector2) -> Variant:
		#return _slot_drag_data(index)
	#panel.can_drop_data = func(at_position: Vector2, data: Variant) -> bool:
		#return _slot_can_drop(index, data)
	#panel.drop_data = func(at_position: Vector2, data: Variant) -> void:
		#_slot_drop(index, data)

	# Tooltip
	if show_tooltips:
		panel.mouse_entered.connect(func(): _show_tooltip_for(index))
		panel.mouse_exited.connect(func(): _hide_tooltip())
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

	var id_ = String(s["id_"])
	var qty = int(s["qty"])
	icon.texture = item_icons.get(id_, null)
	btn.disabled = false
	count.text = str(qty) if (show_stack_count and qty > 1) else ""

	if show_tooltips:
		var def = item_defs.get(id_, {})
		var nm = String(def.get("name", id_))
		var ds = String(def.get("descr", ""))
		slot.tooltip_text = nm + ("\n" + ds if ds != "" else "")
		
func _update_tooltip(index:int, panel:Control) -> void:
	# Refresh tooltip when mouse enters (in case defs changed)
	_refresh_slot(index)
	
func _ensure_tooltip() -> void:
	if _tooltip == null:
		_tooltip = WowTooltip.new()
		_tooltip.visible = false
		_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_tooltip)
		
func _show_tooltip_for(index:int) -> void:
	_ensure_tooltip()
	var s = _slots[index]
	if s == null:
		return
	var id_ = String(s["id_"])
	var def = item_defs[id_]
	# Accept both flat attrs or nested; adapt as you store them
	if not def.has("attrs") and def.has("attributes"):
		def["attrs"] = def["attributes"]
	_tooltip.set_data(def, int(s.get("qty", 1)))
	_tooltip.visible = true
	_tooltip_visible = true
	_update_tooltip_position()
	
func _on_slot_gui_input_touch(index:int, e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		_last_pointer_pos = e.position
		if e.pressed:
			_touch_active = true
			_touch_slot = index
			_press_time_ms = Time.get_ticks_msec()
			_press_pos = e.position
		else:
			# finger lifted
			if _tooltip_visible and tooltip_tap_to_dismiss:
				_hide_tooltip()
			_touch_active = false
			_touch_slot = -1
	elif e is InputEventScreenDrag:
		_last_pointer_pos = e.position
		if _tooltip_visible:
			_update_tooltip_position_to_point(_last_pointer_pos)
		# cancel long-press if user starts moving (likely a drag)
		if _touch_active and e.position.distance_to(_press_pos) > tooltip_move_cancel_px:
			_touch_active = false

func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false
	_tooltip_visible = false

func _update_tooltip_position() -> void:
	if _tooltip == null or not _tooltip.visible:
		return
	var m = get_viewport().get_mouse_position()
	var ofs = Vector2(18, 12)
	var pos = m + ofs
	var vp = get_viewport_rect().size
	var min_size = _tooltip.get_combined_minimum_size()
	pos.x = min(pos.x, vp.x - min_size.x - 6)
	pos.y = min(pos.y, vp.y - min_size.y - 6)
	_tooltip.position = pos
	
func _update_tooltip_position_to_point(p: Vector2) -> void:
	if _tooltip == null or not _tooltip.visible:
		return
	var ofs := Vector2(18, 12)
	var pos := p + ofs
	var vp := get_viewport_rect().size
	var min_size := _tooltip.get_combined_minimum_size()
	pos.x = min(pos.x, vp.x - min_size.x - 6)
	pos.y = min(pos.y, vp.y - min_size.y - 6)
	_tooltip.position = pos
	
# Drag & Drop ------------------------------------------------------------
func _on_slot_gui_input(index:int, e:InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		# start drag if slot has item
		if _slots[index] != null:
			panel_get(index).set_drag_preview(_make_drag_preview(index))
			panel_get(index).drag_started()
			
func panel_get(index:int) -> PanelContainer:
	return _grid.get_child(index)
	
func _make_drag_preview(index:int) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(slot_size)
	var tr = TextureRect.new()
	tr.texture = item_icons.get(String(_slots[index]["id"]), null)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	p.add_child(tr)
	return p
	
func _slot_drag_data(idx: int) -> Variant:
	var s = _slots[idx]
	if s == null:
		return null
	var data := {
		"from": idx,
		"id": String(s["id"]),
		"qty": int(s["qty"])
	}
	set_drag_preview(_make_drag_preview(idx))
	return data
	
func _slot_can_drop(idx: int, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("from"):
		return false
	if data["from"] == idx:
		return false
	return true
	
func _slot_drop(idx: int, data: Dictionary) -> void:
	#if not _can_drop_data(idx, data):
		#return
	var from := int(data["from"])
	var src = _slots[from]
	var dst = _slots[idx]
	if src == null:
		return

	var id := String(src["id"])
	var moved_qty := int(src["qty"])

	var def = item_defs.get(id, null)
	var stackable = def and def.get("stackable", true)
	var max_stack := int(def.get("max_stack", 99)) if def else 99

	if dst == null:
		# move entire stack
		_slots[idx] = src
		_slots[from] = null
	elif dst["id"] == id and stackable:
	# merge
		var space := max_stack - int(dst["qty"])
		if space > 0:
			var push = min(space, moved_qty)
			dst["qty"] += push
			src["qty"] -= push
			if src["qty"] <= 0:
				_slots[from] = null
		else:
			# no space, swap
			var tmp = _slots[idx]
			_slots[idx] = _slots[from]
			_slots[from] = tmp
	else:
		# different items, swap
		var tmp2 = _slots[idx]
		_slots[idx] = _slots[from]
		_slots[from] = tmp2

	_refresh_slot(idx)
	_refresh_slot(from)
	
# Helpers ----------------------------------------------------------------
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

# Equipment ====================================
func _build_ui_eq() -> void:

	equipment_vbox.name = "Root"
	equipment_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipment_vbox.add_theme_constant_override("separation", slot_padding * 2)

	# --- TOP: two vertical columns (WoW armory)
	var top = HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", slot_padding * 12) # wide gap between columns
	equipment_vbox.add_child(top)
	
	var col_left = VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", slot_padding)
	top.add_child(col_left)
	
	var col_right = VBoxContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.add_theme_constant_override("separation", slot_padding)
	top.add_child(col_right)

	# Build slots
	for s in slots_left:
		col_left.add_child(_make_slot_eq(s, slot_size, true))
	for s in slots_right:
		col_right.add_child(_make_slot_eq(s, slot_size, false))
		
	# --- BOTTOM: centered weapon row
	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_theme_constant_override("separation", slot_padding * 2)
	equipment_vbox.add_child(bottom)

	for s in slots_bottom:
		if s == "MainHand":
			bottom.add_child(_make_slot_eq(s, bottom_slot_size_eq, true))
		else:
			bottom.add_child(_make_slot_eq(s, bottom_slot_size_eq, false))

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
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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
		
	## Click to unequip
	#btn.pressed.connect(func():
		#if _equipped.has(slot_name):
			#var id = String(_equipped[slot_name]["id"])
			#_equipped.erase(slot_name)
			#_update_slot_eq(slot_name)
			#emit_signal("unequipped_item", slot_name, id)
	#)

	_slot_nodes[slot_name] = {"panel": panel, "btn": btn, "icon": icon, "label": lbl}
	_update_slot_eq(slot_name)
	return panel

func _update_slot_eq(slot_name: String) -> void:
	var nodes: Dictionary = _slot_nodes.get(slot_name, {})
	if nodes.is_empty(): return
	var panel: PanelContainer = nodes["panel"]
	var icon: TextureRect = nodes["icon"]
	var lbl: Label = nodes["label"]

	var sb: StyleBox = panel.get_theme_stylebox("panel")
	if _equipped.has(slot_name):
		var id = String(_equipped[slot_name]["id"])
		var def = item_defs.get(id, {"name": id, "quality": 1})
		var tex: Texture2D = item_icons.get(id, null)
		icon.texture = tex
		lbl.text = String(def.get("name", slot_name))
		# quality border
		var q = int(def.get("quality", 1))
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).border_color = QUALITY_COLORS.get(q, QUALITY_COLORS[1])
		# tooltips
		#panel.tooltip_text = _build_builtin_tooltip(def)		
	else:
		icon.texture = null
		lbl.text = slot_name
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
	
func _is_item_allowed_for_slot(slot_name: String, id: String) -> bool:
	var def = item_defs.get(id, null)
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
	_update_slot_eq(slot_name)
	emit_signal("equipped_item", slot_name, id)
	return true

func unequip(slot_name: String) -> void:
	if _equipped.has(slot_name):
		var id = String(_equipped[slot_name]["id"])
		_equipped.erase(slot_name)
		_update_slot_eq(slot_name)
		emit_signal("unequipped_item", slot_name, id)


func _on_request_inventory_pressed() -> void:
	SignalManager.signal_RequestInventory.emit("get")
	var inventory_data = await AccountManager.signal_InventoryReceived

	clear_inventory()
		
	if inventory_data.data.inventory:
		for element in inventory_data.data.inventory:
			add_item(_normalize_code(element["code"]), element["qty"])


func _on_request_equipment_pressed() -> void:
	equip("head", "default_head")
	equip("neck", "default_neck")
	equip("shoulder", "default_shoulder")
	equip("cloak", "default_cloak")
	equip("chest", "default_chest")
	equip("wrist", "default_wrist")
