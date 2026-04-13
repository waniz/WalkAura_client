extends Control
# Astrolabe-style radial talent wheel. Draws synergy arcs via _draw(),
# positions TalentNode children on 4 spokes at inner/outer radii.
# Center hub shows points spent + unspent.

signal talent_tapped(talent_id: String)
signal talent_allocate(talent_id: String)

var TALENT_NODE_SCRIPT = null

# Type accent colors (from DESIGN.md / Styler)
const TYPE_COLORS = {
	"defense": Color("#40B4FF"),
	"offense": Color("#FF785A"),
	"magic_fire": Color("#963CF0"),
	"magic_frost": Color("#963CF0"),
	"magic_holy": Color("#963CF0"),
	"magic_dark": Color("#963CF0"),
	"magic_arcane": Color("#963CF0"),
	"utility": Color("#963CF0"),
	"cross_system": Color("#3CC850"),
}

# Spoke definitions: center_angle (degrees, 0 = top/12 o'clock), arc_width (degrees)
# Talents assigned per spoke with ring (0=inner, 1=outer)
const SPOKE_LAYOUT = [
	{
		"name": "Defense", "center_deg": 330, "arc_deg": 80,
		"color": "defense",
		"talents": [
			{"id": "thick_skin", "ring": 0},
			{"id": "fortitude", "ring": 0},
			{"id": "guardian_shell", "ring": 1},
			{"id": "evasion_training", "ring": 1},
			{"id": "magic_ward", "ring": 1},
			{"id": "second_wind", "ring": 1},
		],
	},
	{
		"name": "Offense", "center_deg": 60, "arc_deg": 55,
		"color": "offense",
		"talents": [
			{"id": "brutal_finish", "ring": 0},
			{"id": "blood_pact", "ring": 1},
			{"id": "battle_rhythm", "ring": 1},
		],
	},
	{
		"name": "Cross", "center_deg": 140, "arc_deg": 70,
		"color": "cross_system",
		"talents": [
			{"id": "step_momentum", "ring": 0},
			{"id": "regenerative_steps", "ring": 0},
			{"id": "gathering_wisdom", "ring": 1},
			{"id": "alchemists_touch", "ring": 1},
		],
	},
	{
		"name": "Magic", "center_deg": 225, "arc_deg": 80,
		"color": "magic_arcane",
		"talents": [
			{"id": "mana_flow", "ring": 0},
			{"id": "arcane_mastery", "ring": 0},
			{"id": "pyromaniac", "ring": 1},
			{"id": "permafrost", "ring": 1},
			{"id": "devotion", "ring": 1},
			{"id": "shadow_mastery", "ring": 1},
		],
	},
]

var _node_map: Dictionary = {}  # talent_id -> node instance
var _node_positions: Dictionary = {}  # talent_id -> Vector2 (center of node)
var _synergies: Array = []
var _talent_data: Dictionary = {}
var _talent_config: Array = []
var _config_by_id: Dictionary = {}
var _unspent: int = 0
var _total_spent: int = 0
var _highlight_talent: String = ""  # for build path preview (long-press)
var _wheel_offset_y: float = 0.0  # shift up when overlay is open
var _has_active_synergies: bool = false  # enables per-frame redraw for shimmer
var _stardust_points: PackedVector2Array = PackedVector2Array()
var _stardust_alphas: PackedFloat64Array = PackedFloat64Array()
var _stardust_speeds: PackedFloat64Array = PackedFloat64Array()

# Hub labels

# Radii (computed from size in _layout)
var _inner_radius: float = 140.0
var _outer_radius: float = 260.0
var _center: Vector2 = Vector2.ZERO


func _ready() -> void:
	TALENT_NODE_SCRIPT = load("res://scripts/components/talent_node.gd")
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_on_resized)
	_build_hub()
	set_process(true)


func _process(_delta: float) -> void:
	# Only redraw every frame when shimmer or stardust is active
	if _has_active_synergies or _stardust_points.size() > 0:
		queue_redraw()


func _on_resized() -> void:
	if size.x < 1 or size.y < 1:
		return
	_compute_radii()
	_layout_nodes()
	_generate_stardust()
	queue_redraw()


func _compute_radii() -> void:
	var short_side = min(size.x, size.y)
	var margin = 20.0
	var max_r = (short_side / 2.0) - margin
	_outer_radius = max_r * 0.95
	_inner_radius = max_r * 0.55
	_center = Vector2(size.x / 2.0, size.y / 2.0 + _wheel_offset_y)


func set_wheel_offset_y(offset: float) -> void:
	_wheel_offset_y = offset
	_compute_radii()
	_layout_nodes()
	queue_redraw()


func setup(config: Array, synergies: Array) -> void:
	_talent_config = config
	_synergies = synergies
	_config_by_id = {}
	for t in config:
		_config_by_id[str(t.get("id", ""))] = t
	_create_nodes()
	if size.x > 1 and size.y > 1:
		_compute_radii()
		_layout_nodes()
		_generate_stardust()
		queue_redraw()


func update_talents(data: Dictionary) -> void:
	_talent_data = data.get("talents", {})
	_unspent = int(data.get("unspent", 0))
	_total_spent = int(data.get("total_points_spent", 0))

	for tid in _node_map:
		var td = _talent_data.get(tid, {})
		td["_unspent"] = _unspent
		td["icon"] = tid
		_node_map[tid].update_data(td)

	_update_hub()
	queue_redraw()


func _build_hub() -> void:
	pass


func _update_hub() -> void:
	pass


func _create_nodes() -> void:
	# Clear existing
	for child in get_children():
		if child.has_method("setup"):
			child.queue_free()
	_node_map.clear()

	for spoke in SPOKE_LAYOUT:
		var color = TYPE_COLORS.get(str(spoke["color"]), Color.WHITE)
		for entry in spoke["talents"]:
			var tid = str(entry["id"])
			var node = Control.new()
			node.set_script(TALENT_NODE_SCRIPT)
			var cfg = _config_by_id.get(tid, {"name": tid, "type": str(spoke["color"])})
			var td = _talent_data.get(tid, {})
			td["_unspent"] = _unspent
			td["icon"] = tid
			if td.get("name", "") == "":
				td["name"] = cfg.get("name", tid)
			node.setup(tid, td, color)
			node.node_tapped.connect(_on_node_tapped)
			node.node_long_pressed.connect(_on_node_long_pressed)
			node.node_long_released.connect(_on_node_long_released)
			add_child(node)
			_node_map[tid] = node


func _layout_nodes() -> void:
	for spoke in SPOKE_LAYOUT:
		var center_rad = deg_to_rad(float(spoke["center_deg"]) - 90.0)
		var arc_rad = deg_to_rad(float(spoke["arc_deg"]))
		var talents = spoke["talents"]

		# Separate inner and outer ring talents
		var inner_talents = []
		var outer_talents = []
		for entry in talents:
			if int(entry["ring"]) == 0:
				inner_talents.append(entry)
			else:
				outer_talents.append(entry)

		_place_ring(inner_talents, center_rad, arc_rad, _inner_radius)
		_place_ring(outer_talents, center_rad, arc_rad, _outer_radius)

	_update_hub()


func _place_ring(talents: Array, center_rad: float, arc_rad: float, radius: float) -> void:
	var count = talents.size()
	if count == 0:
		return
	var start_angle = center_rad - arc_rad / 2.0

	for i in range(count):
		var angle = start_angle + (float(i) + 0.5) * arc_rad / float(count)
		var pos = _center + Vector2(cos(angle), sin(angle)) * radius
		var tid = str(talents[i]["id"])
		if _node_map.has(tid):
			var node = _node_map[tid]
			node.position = pos - node.custom_minimum_size / 2.0
			_node_positions[tid] = pos


# =========================================================================
# Drawing: synergy arcs + hub ring + spoke summary arcs
# =========================================================================

func _draw() -> void:
	if _center == Vector2.ZERO:
		return

	# Background stardust (behind everything)
	_draw_stardust()

	# Hub ring
	draw_arc(_center, 45.0, 0, TAU, 64, Color(1.0, 0.784, 0.259, 0.6), 2.0)
	draw_arc(_center, 44.0, 0, TAU, 64, Color(0.063, 0.071, 0.094, 0.8), 40.0)

	# Spoke summary arcs (CEO expansion #3)
	_draw_spoke_summary_arcs()

	# Synergy arcs
	_has_active_synergies = false
	var _syn_index = 0
	for syn in _synergies:
		var t1 = str(syn.get("talent_a", syn.get("talents", ["", ""])[0] if syn.has("talents") else ""))
		var t2 = str(syn.get("talent_b", syn.get("talents", ["", ""])[1] if syn.has("talents") else ""))
		if t1 == "" or t2 == "":
			# Try alternate key format
			var tlist = syn.get("talents", [])
			if tlist.size() >= 2:
				t1 = str(tlist[0])
				t2 = str(tlist[1])
		if not _node_positions.has(t1) or not _node_positions.has(t2):
			continue

		var p1 = _node_positions[t1]
		var p2 = _node_positions[t2]

		# Determine line state from talent data
		var r1 = int(_talent_data.get(t1, {}).get("allocated", 0))
		var r2 = int(_talent_data.get(t2, {}).get("allocated", 0))
		var threshold = 16

		var color: Color
		var width: float
		if r1 >= threshold and r2 >= threshold:
			color = Color("#FFC842")
			width = 2.0
		elif r1 >= threshold or r2 >= threshold:
			color = Color(1, 1, 1, 0.4)
			width = 1.5
		else:
			color = Color(0.5, 0.5, 0.5, 0.15)
			width = 1.0

		# Build path preview: dim non-highlighted arcs
		if _highlight_talent != "":
			if t1 != _highlight_talent and t2 != _highlight_talent:
				color = Color(color, color.a * 0.15)

		# Quadratic bezier with control point toward center
		var ctrl = _center + (p1 + p2 - _center * 2.0) * 0.15
		var points = _sample_bezier(p1, ctrl, p2, 20)
		draw_polyline(points, color, width, true)

		# Active synergy: shimmer dot + name label
		if r1 >= threshold and r2 >= threshold:
			_has_active_synergies = true
			_draw_synergy_shimmer(p1, ctrl, p2, _syn_index)
			var mid = _bezier_point(p1, ctrl, p2, 0.5)
			var syn_name = str(syn.get("name", ""))
			if syn_name != "":
				draw_string(
					ThemeDB.fallback_font, mid + Vector2(-40, -4),
					syn_name,
					HORIZONTAL_ALIGNMENT_CENTER, 80, 9,
					Color(1.0, 0.784, 0.259, 0.7)
				)
		_syn_index += 1


func _draw_spoke_summary_arcs() -> void:
	var arc_radius = _outer_radius + 8.0
	for spoke in SPOKE_LAYOUT:
		var center_rad = deg_to_rad(float(spoke["center_deg"]) - 90.0)
		var arc_rad = deg_to_rad(float(spoke["arc_deg"]))
		var start = center_rad - arc_rad / 2.0

		# Compute total allocated / total possible for this spoke
		var total_allocated = 0
		var total_possible = 0
		for entry in spoke["talents"]:
			var tid = str(entry["id"])
			total_allocated += int(_talent_data.get(tid, {}).get("allocated", 0))
			total_possible += 50
		if total_possible == 0:
			continue

		var fill_frac = float(total_allocated) / float(total_possible)

		# Background arc (dim)
		draw_arc(_center, arc_radius, start, start + arc_rad, 32,
			Color(1, 1, 1, 0.06), 3.0)

		# Fill arc
		if fill_frac > 0.0:
			var color = TYPE_COLORS.get(str(spoke["color"]), Color.WHITE)
			draw_arc(_center, arc_radius, start, start + arc_rad * fill_frac, 32,
				Color(color, 0.5), 3.0)


func _generate_stardust() -> void:
	# Scatter ~60 subtle star particles across the wheel area
	_stardust_points = PackedVector2Array()
	_stardust_alphas = PackedFloat64Array()
	_stardust_speeds = PackedFloat64Array()
	var count = 60
	for i in range(count):
		var angle = randf() * TAU
		var dist = randf_range(50.0, _outer_radius + 30.0)
		var pt = _center + Vector2(cos(angle), sin(angle)) * dist
		_stardust_points.append(pt)
		_stardust_alphas.append(randf_range(0.0, TAU))  # phase offset
		_stardust_speeds.append(randf_range(0.3, 0.8))  # twinkle speed


func _draw_stardust() -> void:
	if _stardust_points.size() == 0 and _center != Vector2.ZERO:
		_generate_stardust()
	var t = fmod(Time.get_ticks_msec() / 1000.0, 100.0)
	for i in range(_stardust_points.size()):
		var pt = _stardust_points[i]
		var phase = _stardust_alphas[i]
		var spd = _stardust_speeds[i]
		# Twinkle: smooth sine oscillation between 0.03 and 0.15 alpha
		var alpha = 0.03 + 0.12 * (0.5 + 0.5 * sin(t * spd + phase))
		var sz = 1.0 + 0.5 * sin(t * spd * 0.7 + phase)
		draw_circle(pt, sz, Color(1.0, 0.95, 0.8, alpha))


func _draw_synergy_shimmer(p1: Vector2, ctrl: Vector2, p2: Vector2, syn_index: int) -> void:
	# Traveling bright dot along the Bezier arc
	var t = fmod(Time.get_ticks_msec() / 1000.0, 100.0)
	var speed = 0.25
	var phase = float(syn_index) * 0.4  # stagger each synergy's dot
	var pos_t = fmod(t * speed + phase, 1.0)
	var dot_pos = _bezier_point(p1, ctrl, p2, pos_t)

	# Glow layers: large soft outer, small bright inner
	draw_circle(dot_pos, 8.0, Color(1.0, 0.784, 0.259, 0.15))
	draw_circle(dot_pos, 4.0, Color(1.0, 0.784, 0.259, 0.4))
	draw_circle(dot_pos, 1.5, Color(1.0, 0.95, 0.85, 0.9))


func _sample_bezier(p0: Vector2, ctrl: Vector2, p2: Vector2, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		points.append(_bezier_point(p0, ctrl, p2, t))
	return points


func _bezier_point(p0: Vector2, ctrl: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(ctrl, t)
	var q1 = ctrl.lerp(p2, t)
	return q0.lerp(q1, t)


# =========================================================================
# Input handling
# =========================================================================

func _on_node_tapped(talent_id: String) -> void:
	talent_tapped.emit(talent_id)


func _on_node_allocate(talent_id: String) -> void:
	talent_allocate.emit(talent_id)


func _on_node_long_pressed(talent_id: String) -> void:
	_highlight_talent = talent_id
	# Dim non-connected nodes
	for tid in _node_map:
		if tid == talent_id:
			continue
		var connected = false
		for syn in _synergies:
			var tlist = syn.get("talents", [])
			var t1 = str(syn.get("talent_a", tlist[0] if tlist.size() > 0 else ""))
			var t2 = str(syn.get("talent_b", tlist[1] if tlist.size() > 1 else ""))
			if (t1 == talent_id and t2 == tid) or (t2 == talent_id and t1 == tid):
				connected = true
				break
		if not connected:
			_node_map[tid].modulate = Color(1, 1, 1, 0.2)
	queue_redraw()


func _on_node_long_released() -> void:
	_highlight_talent = ""
	# Restore node modulation from their data state
	for tid in _node_map:
		var allocated = int(_talent_data.get(tid, {}).get("allocated", 0))
		if allocated == 0:
			_node_map[tid].modulate = Color(1, 1, 1, 0.45)
		else:
			_node_map[tid].modulate = Color.WHITE
	queue_redraw()
