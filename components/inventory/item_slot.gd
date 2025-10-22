class_name ItemSlot extends Control

@export var slot_index: int = -1
var model: InventoryModel

@onready var icon: TextureRect = %Icon
@onready var count: Label = %Count

func bind(model_ref: InventoryModel, index: int):
	model = model_ref
	slot_index = index
	model.changed.connect(_try_update)
	_try_update()

func _try_update() -> void:
	# Guard: onready not initialized yet?
	if icon == null or count == null:
		return
	if model == null or slot_index < 0 or slot_index >= model.slots.size():
		_clear_slot()
		return

	var s = model.slots[slot_index]
	if s:
		var it = ItemDB.get(s.id)
		if it:
			icon.texture = it.icon
			icon.visible = true
			if s.qty > 1:
				count.text = str(s.qty)
			else:
				count.text = ""
			tooltip_text = "%s\n%s" % [it.name, it.description]
		else:
			_clear_slot()
	else:
		_clear_slot()

func _clear_slot() -> void:
	if icon:
		icon.texture = null
		icon.visible = false
	if count:
		count.text = ""
	tooltip_text = ""
		
# -------- Drag & Drop ----------
func get_drag_data(at_pos):
	var s = model.slots[slot_index]
	if s == null: return null
	var db = {"from": slot_index}
	var preview = TextureRect.new()
	preview.texture = ItemDB.get(s.id).icon
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return db
	
func can_drop_data(at_pos, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("from")

func drop_data(at_pos, data):
	model.move_or_merge(data.from, slot_index)
