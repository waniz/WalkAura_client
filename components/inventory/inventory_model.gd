class_name InventoryModel extends Node

signal changed()

var slots: Array = []   # each slot: {id:String, qty:int} or null

func setup(size: int):
	slots.resize(size)
	for i in slots.size():
		slots[i] = null
	emit_signal("changed")

func to_dict() -> Dictionary:
	return {"slots": slots}
	
func from_dict(d: Dictionary):
	slots = d.get("slots", [])
	emit_signal("changed")
	
func add_item(id: String, qty: int) -> int:
	var item = ItemDB.get(id)
	if item == null: return qty
	# fill existing stacks
	for i in slots.size():
		var s = slots[i]
		if s and s.id == id and s.qty < item.stack_max:
			var take = min(qty, item.stack_max - s.qty)
			s.qty += take
			qty -= take
			if qty == 0: emit_signal("changed"); return 0
	# fill empty slots
	for i in slots.size():
		if slots[i] == null:
			var take = min(qty, item.stack_max)
			slots[i] = {"id": id, "qty": take}
			qty -= take
			if qty == 0: emit_signal("changed"); return 0
	emit_signal("changed")
	return qty  # leftover

func move_or_merge(a: int, b: int):
	if a == b: return
	var A = slots[a]; var B = slots[b]
	if A == null: return
	if B == null:
		slots[b] = A; slots[a] = null
	elif A.id == B.id:
		var max_stack = ItemDB.get(A.id).stack_max
		var can = max_stack - B.qty
		var moved = min(can, A.qty)
		B.qty += moved
		A.qty -= moved
		if A.qty <= 0: slots[a] = null
	else:
		var tmp = slots[b]
		slots[b] = A
		slots[a] = tmp
	emit_signal("changed")
