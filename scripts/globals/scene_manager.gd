extends Node

var current_scene: Node

func _ready() -> void:
	current_scene = get_tree().current_scene

func goto(path: String) -> void:
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("SceneManager: could not load %s" % path)
		return

	var new_scene := ps.instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	if current_scene:
		current_scene.queue_free()
	current_scene = new_scene

# Reload the current scene
func reload() -> void:
	if not current_scene or current_scene.scene_file_path == "":
		return
	var path := current_scene.scene_file_path
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("SceneManager: could not reload %s" % path)
		return
	var new_scene := ps.instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	current_scene.queue_free()
	current_scene = new_scene
