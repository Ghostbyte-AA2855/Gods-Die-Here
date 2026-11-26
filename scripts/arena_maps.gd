extends RefCounted

# Each cover entry describes one of a mirrored pair (position, radius, height).
# The same geometry drives walking, ability sight checks and the client stage.
const MAPS = {
	"lockwater": {
		"name":"Lockwater Gatehouse",
		"description":"Duel around two offset piers. High tide slows movement on both outer flanks.",
		"style":"pillar", "cover":[[Vector2(-3.8,-2.8),1.05,1.24]],
		"kind":"tide", "center":Vector2(0,8.5), "radius":2.8, "duration":5.0, "period":16.0,
		"warning":"Water rising on both flanks", "active":"High tide · 40% slower inside the water",
	},
	"kiln": {
		"name":"Copperbell Kiln",
		"description":"Four brick stacks shelter the outer routes. Paired floor vents burn their marked circles when their fires ignite.",
		"style":"chimney", "cover":[[Vector2(3.5,4.6),1.1,2.3],[Vector2(-4.7,3.9),0.84,1.95]],
		"kind":"vent", "center":Vector2(3.6,0), "radius":2.2, "duration":3.0, "period":12.0,
		"warning":"Kiln vents heating up", "active":"Vents burning · leave the marked circles",
	},
	"orchard": {
		"name":"Ironleaf Orchard",
		"description":"Gusts run through gaps in the trees. Crosswind circles carry both teams in the direction of their arrows.",
		"style":"tree", "cover":[[Vector2(4.3,4.8),0.88,2.35],[Vector2(-5.0,2.5),0.83,2.05],[Vector2(1.9,0.2),0.72,1.9]],
		"kind":"wind", "center":Vector2(0,4), "radius":2.5, "duration":3.0, "period":12.0,
		"warning":"Crosswinds gathering between the trees", "active":"Crosswinds · follow the arrows to ride the gust",
	},
	"quarry": {
		"name":"Shale Quarry",
		"description":"Fight between stone outcrops. Paired slabs periodically lift from the floor and temporarily divide the central lane.",
		"style":"rock", "cover":[[Vector2(4.7,4.4),1.35,1.72],[Vector2(-6.3,2.5),0.92,1.45]],
		"kind":"rise", "center":Vector2(2.5,1), "radius":1.1, "duration":6.0, "period":16.0,
		"warning":"Stone lifting · clear the marked circles", "active":"Slabs raised · central sightlines have changed",
	},
	"observatory": {
		"name":"Hollowglass Observatory",
		"description":"Sightlines run between the lens mounts. Eclipse veils block sight across their edges while fighters move freely through them.",
		"style":"lens", "cover":[[Vector2(0,5.7),0.9,1.8],[Vector2(5.4,3.5),0.88,1.63]],
		"kind":"veil", "center":Vector2(3.6,0), "radius":2.0, "duration":6.0, "period":16.0,
		"warning":"Eclipse veils forming", "active":"Eclipse · step through a veil to target fighters inside",
	},
}

const WARNING_START := 4.0
const ACTIVE_START := 6.0
const TIDE_SLOW := 0.4
const WIND_SPEED := 3.0
const VENT_DAMAGE_PER_SECOND := 10.0
const RADIUS := 14.0
const FIGHTER_PADDING := 0.3

static var _outlines: Dictionary = {}
static var _walking_outlines: Dictionary = {}


static func _static_init() -> void:
	var circle := PackedVector2Array()
	for i in 96:
		circle.append(Vector2.RIGHT.rotated(TAU * i / 96.0) * RADIUS)
	var orchard := PackedVector2Array()
	for i in 6:
		orchard.append(Vector2.RIGHT.rotated(TAU * i / 6.0) * 13.8)
	_outlines = {
		"lockwater":circle, "observatory":circle, "orchard":orchard,
		"kiln":PackedVector2Array([
			Vector2(11.4,-8),Vector2(11.4,8),Vector2(8,11.4),Vector2(-8,11.4),
			Vector2(-11.4,8),Vector2(-11.4,-8),Vector2(-8,-11.4),Vector2(8,-11.4),
		]),
		"quarry":PackedVector2Array([
			Vector2(13.2,-3.9),Vector2(13.2,3.9),Vector2(8.2,8),Vector2(-8.2,8),
			Vector2(-13.2,3.9),Vector2(-13.2,-3.9),Vector2(-8.2,-8),Vector2(8.2,-8),
		]),
	}
	for id in ["kiln", "orchard", "quarry"]:
		_walking_outlines[id] = _inset_polygon(_outlines[id], FIGHTER_PADDING)


static func outline(id: String) -> PackedVector2Array:
	var boundary: PackedVector2Array = _outlines.get(id, _outlines.lockwater)
	return boundary.duplicate()


# Clip the convex boundary against each inward-offset wall. This also handles
# padding large enough to eliminate a short bevel or consume the whole floor.
static func _inset_polygon(boundary: PackedVector2Array, padding: float) -> PackedVector2Array:
	var result := boundary
	for i in boundary.size():
		var start := boundary[i]
		var edge := boundary[(i + 1) % boundary.size()] - start
		var normal := Vector2(-edge.y, edge.x).normalized()
		var clipped := PackedVector2Array()
		if result.is_empty():
			break
		var previous := result[-1]
		var old_distance := (previous - start).dot(normal) - padding
		for point in result:
			var distance := (point - start).dot(normal) - padding
			if (distance >= 0.0) != (old_distance >= 0.0):
				clipped.append(previous.lerp(point, old_distance / (old_distance - distance)))
			if distance >= 0.0:
				clipped.append(point)
			previous = point
			old_distance = distance
		result = clipped
	return result


static func constrain(id: String, point: Vector2, padding: float = 0.0) -> Vector2:
	padding = maxf(0.0, padding)
	if not _walking_outlines.has(id):
		return point.limit_length(maxf(0.0, RADIUS - padding))
	var boundary: PackedVector2Array = _outlines[id]
	if is_equal_approx(padding, FIGHTER_PADDING):
		boundary = _walking_outlines[id]
	elif padding > 0.0:
		boundary = _inset_polygon(boundary, padding)
	if boundary.is_empty():
		return Vector2.ZERO
	if Geometry2D.is_point_in_polygon(point, boundary):
		return point
	var nearest := boundary[0]
	for i in boundary.size():
		var start := boundary[i]
		var end := boundary[(i + 1) % boundary.size()]
		if start.is_equal_approx(end):
			continue
		var candidate := Geometry2D.get_closest_point_to_segment(point, start, end)
		if candidate.distance_squared_to(point) < nearest.distance_squared_to(point):
			nearest = candidate
	return nearest


static func base_terrain(id: String) -> Array[Dictionary]:
	var layout: Dictionary = MAPS[id]
	var result: Array[Dictionary] = []
	for pair in layout.cover:
		for side in [-1, 1]:
			result.append({
				"id":"cover_%d" % result.size(), "style":layout.style,
				"position":(pair[0] as Vector2) * side, "radius":pair[1], "height":pair[2],
			})
	return result


static func prepare(game) -> void:
	var layout: Dictionary = MAPS[game.map_id]
	game.terrain = base_terrain(game.map_id)
	game.environment_zones.clear()
	for side in [-1, 1]:
		game.environment_zones.append({
			"id":"%s_%d" % [layout.kind, side], "kind":layout.kind,
			"position":(layout.center as Vector2) * side, "radius":layout.radius,
			"direction":Vector2.RIGHT * side if layout.kind == "wind" else Vector2.ZERO,
			"phase":"idle", "phase_left":WARNING_START,
		})
	game.map_hint = ""


static func update(game, elapsed: float, delta: float) -> void:
	var layout: Dictionary = MAPS[game.map_id]
	var cycle := fposmod(elapsed, layout.period)
	var end_active: float = ACTIVE_START + layout.duration
	var phase: String
	var time_left: float
	if cycle < WARNING_START:
		phase = "idle"
		time_left = WARNING_START - cycle
	elif cycle < ACTIVE_START:
		phase = "warning"
		time_left = ACTIVE_START - cycle
	elif cycle < end_active:
		phase = "active"
		time_left = end_active - cycle
	else:
		phase = "idle"
		time_left = layout.period - cycle + WARNING_START
	var changed: bool = game.environment_zones[0].phase != phase
	for zone in game.environment_zones:
		zone.phase = phase
		zone.phase_left = time_left
	if changed:
		game.map_hint = layout.get(phase, "")
		if layout.kind == "rise":
			_update_quarry(game, phase == "active")
	if layout.kind in ["vent", "wind"]:
		# Charge only the portion of this simulation tick inside the active window.
		var active_dt := _active_elapsed(elapsed, layout) - _active_elapsed(maxf(0.0, elapsed - delta), layout)
		if active_dt > 0.0:
			_apply_zones(game, layout.kind, active_dt)


static func _active_elapsed(elapsed: float, layout: Dictionary) -> float:
	var cycles := floorf(elapsed / layout.period)
	var offset := fposmod(elapsed, layout.period)
	return cycles * layout.duration + clampf(offset - ACTIVE_START, 0.0, layout.duration)


static func _apply_zones(game, kind: String, seconds: float) -> void:
	for zone in game.environment_zones:
		for fighter in game.fighters:
			if not fighter.alive or not _contains(zone, fighter.position):
				continue
			if kind == "vent":
				game._apply_damage(fighter, VENT_DAMAGE_PER_SECOND * seconds)
			elif kind == "wind":
				game._move(fighter, (zone.direction as Vector2) * WIND_SPEED * seconds, false)


static func _contains(zone: Dictionary, point: Vector2) -> bool:
	return point.distance_squared_to(zone.position) < zone.radius * zone.radius


static func avoidance_direction(game, origin: Vector2, intended: Vector2) -> Vector2:
	for zone in game.environment_zones:
		if zone.phase == "idle" or zone.kind not in ["vent", "rise"]:
			continue
		if zone.kind == "rise" and zone.phase == "active":
			continue  # The raised slab now participates in normal obstacle avoidance.
		var offset: Vector2 = origin - zone.position
		var clearance: float = zone.radius + 0.35
		if offset.length_squared() < clearance * clearance:
			var escape := offset.normalized()
			if escape.is_zero_approx():
				escape = -(zone.position as Vector2).normalized()
			if (origin + escape * 0.75).length() > game.safe_radius - 0.25:
				escape = -origin.normalized()
			return escape
		if not intended.is_zero_approx() and (offset + intended * 0.75).length_squared() < clearance * clearance:
			var tangent := offset.orthogonal().normalized()
			return tangent if tangent.dot(intended) >= 0.0 else -tangent
	return Vector2.ZERO


static func tide_slow(game, point: Vector2) -> float:
	if game.map_id == "lockwater":
		for zone in game.environment_zones:
			if zone.phase == "active" and _contains(zone, point):
				return TIDE_SLOW
	return 0.0


static func veil_blocks(zones: Array[Dictionary], start: Vector2, end: Vector2) -> bool:
	for zone in zones:
		if zone.kind != "veil" or zone.phase != "active":
			continue
		if _contains(zone, start) and _contains(zone, end):
			continue
		var nearest := Geometry2D.get_closest_point_to_segment(zone.position, start, end)
		if _contains(zone, nearest):
			return true
	return false


static func _update_quarry(game, raised: bool) -> void:
	game.terrain = base_terrain(game.map_id)
	if not raised:
		return
	for zone in game.environment_zones:
		game.terrain.append({
			"id":zone.id, "position":zone.position, "radius":zone.radius,
			"height":1.8, "style":"slab",
		})
		for fighter in game.fighters:
			var offset: Vector2 = fighter.position - zone.position
			var clearance: float = zone.radius + 0.31
			if not fighter.alive or offset.length_squared() >= clearance * clearance:
				continue
			var direction := offset.normalized()
			if direction.is_zero_approx():
				direction = (zone.position as Vector2).normalized()
			fighter.position = zone.position + direction * clearance
