class_name MapHUD extends Control

# --- Configuration ---
@export var mini_map_size: Vector2 = Vector2(142, 142)

@onready var mini_map_frame: PanelContainer = $MiniMapFrame
@onready var mini_map_mask: Control = $MiniMapFrame/Mask
@onready var mini_map_texture: TextureRect = $MiniMapFrame/Mask/MapTexture
@onready var mini_player_marker: TextureRect = $MiniMapFrame/Mask/PlayerMarker
@onready var mini_map_btn: Button = $MiniMapFrame/Button

@onready var full_map_overlay: Panel = $FullMapOverlay
@onready var scroll_container: ScrollContainer = $FullMapOverlay/ScrollContainer
@onready var big_map_texture: TextureRect = $FullMapOverlay/ScrollContainer/BigMapTexture
@onready var big_player_marker: TextureRect = $FullMapOverlay/ScrollContainer/BigMapTexture/BigPlayerMarker
@onready var close_btn: Button = $FullMapOverlay/CloseButton

# --- State ---
var initial_player_pos_ratio: Vector2 = Vector2(0.33, 0.42) # 0.0 to 1.0 (Percentage of map)
var map_texture = load("res://assets/world_map_v1.png") as Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Setup Mini Map
	mini_map_frame.custom_minimum_size = mini_map_size
	mini_map_texture.texture = map_texture

	# Setup Full Map
	full_map_overlay.visible = false
	big_map_texture.texture = map_texture

	# Connect Signals
	mini_map_btn.pressed.connect(_on_mini_map_clicked)
	close_btn.pressed.connect(_on_close_clicked)
	
	update_location(initial_player_pos_ratio)
	
# Call this function from your game whenever the player moves
# pos_ratio: Vector2(x, y) where x/y are 0.0 to 1.0 relative to total map size
func update_location(pos_ratio: Vector2):
	_update_mini_map_position(pos_ratio)
	_update_full_map_marker(pos_ratio)


func _update_mini_map_position(pos_ratio: Vector2):
	if not map_texture: return

	# Calculate pixel position on the real map
	var map_size = map_texture.get_size()
	var target_pixel = map_size * pos_ratio

	# We move the MAP texture, not the camera. 
	# To center the player, we shift the map in the negative direction + half the view size.
	var center_offset = mini_map_size / 2.0
	mini_map_texture.position = -target_pixel + center_offset

	# Keep the marker strictly in the center of the mini-map window
	mini_player_marker.position = center_offset - (mini_player_marker.size / 2.0)


func _update_full_map_marker(pos_ratio: Vector2):
	if not map_texture: return

	var map_size = map_texture.get_size()
	big_player_marker.position = (map_size * pos_ratio) - (big_player_marker.size / 2.0)

func _on_mini_map_clicked():
	full_map_overlay.visible = true

	await get_tree().process_frame  # Wait for UI to layout
	_center_scroll_on_player(initial_player_pos_ratio)

func _on_close_clicked():
	full_map_overlay.visible = false

func _center_scroll_on_player(pos_ratio: Vector2):
	var map_size = map_texture.get_size()
	var target = map_size * pos_ratio
	big_player_marker.position = (map_size * pos_ratio) - (big_player_marker.size / 2.0)

	# Center the scroll container
	var scroll_size = big_player_marker.size
	scroll_container.scroll_horizontal = target.x - (scroll_size.x / 2.0)
	scroll_container.scroll_vertical = target.y - (scroll_size.y / 2.0)
