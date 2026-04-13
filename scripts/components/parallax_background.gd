class_name ParallaxBackground2D
extends TextureRect
# Depth-map parallax background driven by touch drag + idle breathing.
#
# Drop this on a TextureRect, set `texture` to the background, and it will
# automatically load `<path_without_ext>_depth.png` next to it. Drag on the
# node past DRAG_THRESHOLD_PX to reveal depth. Taps under the threshold are
# forwarded untouched to any sibling controls (activity markers). Released
# drags spring back with critical damping.

const SHADER_PATH = "res://shaders/depth_parallax.gdshader"
const DRAG_THRESHOLD_PX: float = 8.0

@export_range(0.0, 0.15, 0.005) var displacement_strength: float = 0.06
@export_range(0.0, 1.0, 0.05) var far_ratio: float = 0.15
# Stiffness in (rad/s)^2. Damping is derived from it as 2*sqrt(stiffness) for
# true critical damping.
@export_range(1.0, 400.0, 1.0) var spring_stiffness: float = 120.0
@export_range(0.0, 1.0, 0.01) var idle_sway_amplitude: float = 0.35
@export_range(0.0, 2.0, 0.05) var idle_sway_speed: float = 0.35
@export var parallax_enabled: bool = true

var _material: ShaderMaterial = null
var _depth_tex: Texture2D = null
var _target_offset: Vector2 = Vector2.ZERO
var _current_offset: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _press_active: bool = false
var _drag_active: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _last_texture_rid: RID = RID()


func _ready() -> void:
	if parallax_enabled == false:
		return
	_setup_for_current_texture()
	var tick = Timer.new()
	tick.wait_time = 0.25
	tick.autostart = true
	tick.one_shot = false
	tick.timeout.connect(_on_texture_poll)
	add_child(tick)


func _on_texture_poll() -> void:
	if texture == null:
		return
	var rid: RID = texture.get_rid()
	if rid == _last_texture_rid:
		return
	_setup_for_current_texture()


func _setup_for_current_texture() -> void:
	_current_offset = Vector2.ZERO
	_velocity = Vector2.ZERO
	_target_offset = Vector2.ZERO
	_press_active = false
	_drag_active = false

	if texture == null:
		material = null
		_material = null
		_last_texture_rid = RID()
		return
	_last_texture_rid = texture.get_rid()

	var depth_path = _derive_depth_path(texture)
	if depth_path == "":
		push_warning("ParallaxBackground2D: cannot derive depth path from texture — falling back to flat")
		material = null
		_material = null
		return

	var depth_res = load(depth_path)
	if depth_res == null:
		push_warning("ParallaxBackground2D: depth map not found at " + depth_path + " — falling back to flat")
		material = null
		_material = null
		return
	_depth_tex = depth_res

	if _material == null:
		var shader = load(SHADER_PATH)
		if shader == null:
			push_error("ParallaxBackground2D: shader missing at " + SHADER_PATH)
			return
		_material = ShaderMaterial.new()
		_material.shader = shader

	_material.set_shader_parameter("depth_tex", _depth_tex)
	_material.set_shader_parameter("displacement_strength", displacement_strength)
	_material.set_shader_parameter("far_ratio", far_ratio)
	_material.set_shader_parameter("parallax_offset", Vector2.ZERO)
	material = _material

	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(true)


func _gui_input(event: InputEvent) -> void:
	if _material == null:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_press_active = true
			_drag_active = false
			_drag_origin = event.position
			return
		# Release.
		if _drag_active:
			_velocity = Vector2.ZERO
			_target_offset = Vector2.ZERO
			accept_event()
		_press_active = false
		_drag_active = false
		return

	if _press_active and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		var pos = event.position
		var delta = pos - _drag_origin
		if _drag_active == false:
			if delta.length() < DRAG_THRESHOLD_PX:
				return
			_drag_active = true
		# Avoid div-by-zero before Control has been sized by its parent layout.
		var half = size * 0.5
		if half.x < 1.0 or half.y < 1.0:
			return
		var norm = Vector2(delta.x / half.x, delta.y / half.y)
		norm.x = clamp(norm.x, -1.0, 1.0)
		norm.y = clamp(norm.y, -1.0, 1.0)
		_target_offset = norm
		accept_event()


func _process(delta: float) -> void:
	if _material == null:
		return
	_time += delta

	var idle = Vector2.ZERO
	if _drag_active == false and idle_sway_amplitude > 0.0:
		var t = _time * idle_sway_speed
		idle.x = sin(t) * idle_sway_amplitude
		idle.y = sin(t * 2.0) * idle_sway_amplitude * 0.5

	var damping = 2.0 * sqrt(spring_stiffness)
	var goal = _target_offset + idle
	var accel = (goal - _current_offset) * spring_stiffness - _velocity * damping
	_velocity += accel * delta
	_current_offset += _velocity * delta

	_material.set_shader_parameter("parallax_offset", _current_offset)


static func _derive_depth_path(tex: Texture2D) -> String:
	if tex == null:
		return ""
	var path = tex.resource_path
	if path == "":
		return ""
	var stem = path.get_basename()
	if stem == "":
		return ""
	return stem + "_depth.png"
