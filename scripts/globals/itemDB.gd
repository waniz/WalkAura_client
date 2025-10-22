extends Node

var itemsdict: Dictionary = {}

func _ready():
	for f in DirAccess.get_files_at("res://data/items"):
		if f.ends_with(".tres"):
			var item: ItemData = load("res://data/items/%s" % f)
			itemsdict[item.id] = item

func get_item(id: String):
	return itemsdict.get(id)
