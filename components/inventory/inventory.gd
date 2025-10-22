class_name InventoryUI extends Control

@export var columns: int = 6
@export var inventory_size: int = 24
var model = InventoryModel.new()

@onready var grid_container: GridContainer = $Panel/GridContainer

const SLOT_SCENE = preload("res://components/inventory/item_slot.tscn")

func _ready():
	grid_container.columns = columns
	model.setup(inventory_size)
	
	# clear any existing slot nodes
	for child in grid_container.get_children():
		child.queue_free()
		
	# build slots
	for i in inventory_size:
		var slot = SLOT_SCENE.instantiate() as ItemSlot
		grid_container.add_child(slot)
		slot.bind(model, i)

# Helper to clear children
func _free_children():
	for c in grid_container.get_children():
		c.queue_free()

# API to add items
func add_item(id: String, qty: int) -> int:
	return model.add_item(id, qty)
	
func set_data(d: Dictionary):
	model.from_dict(d)

func get_data() -> Dictionary:
	return model.to_dict()
