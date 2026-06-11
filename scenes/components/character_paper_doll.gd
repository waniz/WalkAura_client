extends Control

## Character Paper Doll Component
## Handles rendering character equipment overlays with optional gyroscope parallax.

const BASE_BODY_PATH = "res://assets/equipment_overlays/base_body/base_body_female.png"
const LAYER_ORDER = ["legs", "chest", "shoulder", "head", "gloves", "feet", "belt"]

# Parallax settings
@export var parallax_enabled: bool = true
@export var parallax_intensity: float = 15.0 # Max pixels of offset at full tilt
@export var smooth_speed: float = 8.0

# Battery: poll the motion sensor at ~15 Hz instead of every frame, and skip
# pushing layer positions (which forces a GPU redraw) when the offset hasn't moved
# enough to see. When the device is held steady the offset settles and we stop
# redrawing, letting low_processor_mode idle the GPU on the character screen.
const ACCEL_SAMPLE_INTERVAL: float = 0.066
const PARALLAX_REST_EPS: float = 0.05 # pixels

var _layers: Dictionary = {} # slot_name -> TextureRect
var _target_parallax_offset: Vector2 = Vector2.ZERO
var _current_parallax_offset: Vector2 = Vector2.ZERO
var _accel_sample_timer: float = 0.0

func _ready() -> void:
	_setup_layers()

func _setup_layers() -> void:
	# Clear existing if any
	for child in get_children():
		child.queue_free()
	_layers.clear()

	# Base body
	var body_tex = load(BASE_BODY_PATH) as Texture2D
	_layers["base_body"] = _make_layer("base_body", body_tex)

	# Overlay layers
	for slot in LAYER_ORDER:
		_layers[slot] = _make_layer(slot + "_layer")

func _make_layer(layer_name: String, tex: Texture2D = null) -> TextureRect:
	var layer = TextureRect.new()
	layer.name = layer_name
	layer.texture = tex
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Center pivot for parallax rotation if we want to add that later
	layer.resized.connect(func(): layer.pivot_offset = layer.size / 2)
	add_child(layer)
	return layer

func update_slot(slot_name: String, texture: Texture2D) -> void:
	if _layers.has(slot_name):
		_layers[slot_name].texture = texture

func clear_slot(slot_name: String) -> void:
	if _layers.has(slot_name):
		_layers[slot_name].texture = null

func clear_all() -> void:
	for slot in LAYER_ORDER:
		_layers[slot].texture = null

func _process(delta: float) -> void:
	if not parallax_enabled:
		if _current_parallax_offset != Vector2.ZERO:
			_current_parallax_offset = _current_parallax_offset.lerp(Vector2.ZERO, delta * smooth_speed)
			if _current_parallax_offset.length() < 0.001:
				_current_parallax_offset = Vector2.ZERO
			_apply_parallax()
		else:
			# Fully at rest and disabled — stop running every frame.
			set_process(false)
		return

	# Throttle accelerometer reads to ~15 Hz instead of every frame.
	_accel_sample_timer += delta
	if _accel_sample_timer >= ACCEL_SAMPLE_INTERVAL:
		_accel_sample_timer = 0.0
		# Use accelerometer for tilt
		var accel = Input.get_accelerometer()
		if accel == Vector3.ZERO:
			# Fallback to mouse for testing on desktop if needed,
			# but usually accelerometer is enough for mobile focus.
			_target_parallax_offset = Vector2.ZERO
		else:
			# Map X/Y accelerometer to parallax offset
			# Normalizing: accel values usually range from -10 to 10 m/s^2
			_target_parallax_offset.x = clamp(accel.x / 10.0, -1.0, 1.0)
			_target_parallax_offset.y = clamp(accel.y / 10.0, -1.0, 1.0)

	var prev = _current_parallax_offset
	_current_parallax_offset = _current_parallax_offset.lerp(_target_parallax_offset, delta * smooth_speed)

	# Only redraw when the offset actually moved a visible amount. Device held
	# steady -> offset settles -> no redraw -> GPU idles.
	if (_current_parallax_offset - prev).length() * parallax_intensity >= PARALLAX_REST_EPS:
		_apply_parallax()

func _apply_parallax() -> void:
	# Base body is at 0 offset
	# Each subsequent layer gets more offset
	var base_offset = _current_parallax_offset * parallax_intensity
	
	# base_body: 0
	_layers["base_body"].position = Vector2.ZERO
	
	# Distribute offsets based on layer order
	for i in LAYER_ORDER.size():
		var slot = LAYER_ORDER[i]
		# Layer index i from 0 to 6. 
		# Multiplier grows with index to give depth.
		var depth_factor = (i + 1) * 0.5 
		_layers[slot].position = base_offset * depth_factor
