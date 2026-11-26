extends RefCounted

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaMaps = preload("res://scripts/arena_maps.gd")
const MAP_IDS := ["lockwater", "kiln", "orchard", "quarry", "observatory"]

var check: Callable


func run(record: Callable) -> void:
	check = record
	for id in MAP_IDS:
		_check_arena(id)
		_check_footprint(id)
	_check_arena_isolation()
	_check_cast_events()


func _new_match(id: String):
	var arena = ArenaMatch.new()
	arena.start_match("breakwater", 711, -1, id)
	for bot in arena.fighters.slice(1):
		bot.stun = 50.0
		bot.break_free_available = false
	return arena


func _check_arena(id: String) -> void:
	var arena = _new_match(id)
	var cover_counts := {"lockwater": 2, "kiln": 4, "orchard": 6, "quarry": 4, "observatory": 4}
	check.call(arena.map_id == id and arena.terrain.size() == cover_counts[id], id + " starts with its own cover layout")
	for piece: Dictionary in arena.terrain:
		var center: Vector2 = piece.position
		var matching: Array = arena.terrain.filter(func(other): return (other.position as Vector2).is_equal_approx(-center) and is_equal_approx(other.radius, piece.radius))
		check.call(matching.size() == 1 and arena._blocked(center, 0.0), id + " mirrors a physical cover piece at %s" % center)
	arena.step(4.5, Vector2.ZERO, Vector2.ZERO)
	var zones: Array = arena.environment_zones
	check.call(zones.size() == 2, id + " presents matched objectives to each side")
	if zones.size() != 2:
		return
	check.call((zones[0].position as Vector2).is_equal_approx(-zones[1].position) and is_equal_approx(zones[0].radius, zones[1].radius), id + " has mirror-symmetric zone placements")
	check.call(zones[0].phase == "warning" and zones[1].phase == "warning", id + " telegraphs the first activation")

	var a: Dictionary = arena.fighters[0]
	var b: Dictionary = arena.fighters[3]
	a.position = zones[0].position
	b.position = zones[1].position
	var a_health: float = a.health
	var b_health: float = b.health
	var a_origin: Vector2 = a.position
	var b_origin: Vector2 = b.position
	arena.step(0.2, Vector2.ZERO, Vector2.ZERO)
	check.call(a.health == a_health and b.health == b_health and a.position == a_origin and b.position == b_origin, id + " warning inflicts no damage or motion")
	var warning_speed := 0.0
	var boundary: Vector2 = zones[0].position + Vector2.UP * (float(zones[0].radius) + 0.6)
	if id == "lockwater":
		arena.step(0.05, Vector2.RIGHT, Vector2.ZERO)
		warning_speed = (a.position as Vector2).distance_to(a_origin) / 0.05
		a.position = a_origin
	elif id in ["quarry", "observatory"]:
		check.call(arena._has_sight(a_origin, boundary), id + " starts with a clear sightline at warning")
	# Advance past the telegraphed start in one call, exercising substep timing.
	arena.step(1.8, Vector2.ZERO, Vector2.ZERO)
	zones = arena.environment_zones
	check.call(zones[0].phase == "active" and zones[1].phase == "active", id + " activates both zones together")
	match id:
		"lockwater":
			var start: Vector2 = a.position
			arena.step(0.05, Vector2.RIGHT, Vector2.ZERO)
			var speed: float = (a.position as Vector2).distance_to(start) / 0.05
			check.call(is_equal_approx(speed / warning_speed, 0.6), "High tide slows movement by 40 percent")
		"kiln":
			var damage_a: float = a_health - a.health
			var damage_b: float = b_health - b.health
			check.call(damage_a > 0.0 and is_equal_approx(damage_a, damage_b), "Both furnace vents deal equal damage")
			var before: float = a.health
			arena.step(0.3, Vector2.ZERO, Vector2.ZERO)
			check.call(absf((before - a.health) - 3.0) < 0.05, "Kiln vent damage advances at ten health per second")
		"orchard":
			var drift_a: Vector2 = a.position - a_origin
			var drift_b: Vector2 = b.position - b_origin
			check.call(drift_a.length() > 0.5 and (drift_a + drift_b).length() < 0.01, "Orchard currents move passive fighters in opposite directions")
		"quarry":
			check.call((a.position as Vector2).distance_to(a_origin) >= float(zones[0].radius), "Rising quarry cover displaces an occupant")
			check.call(not arena._has_sight(a_origin, boundary), "Raised quarry cover blocks line of sight")
			a.position = boundary
			arena._move(a, a_origin - boundary, false)
			check.call((a.position as Vector2).distance_to(a_origin) >= float(zones[0].radius), "A fighter cannot move through raised cover")
		"observatory":
			check.call(not arena._has_sight(a_origin, boundary), "Observatory veil blocks targeting across its boundary")
			check.call(arena._has_sight(a_origin, a_origin + Vector2.UP * 0.5), "Fighters inside the same veil keep sight")
			a.position = boundary
			arena._move(a, a_origin - boundary, false)
			check.call((a.position as Vector2).distance_to(a_origin) < 0.1, "Observatory veil permits physical traversal")
	arena.step(6.0, Vector2.ZERO, Vector2.ZERO)
	check.call(arena.environment_zones.all(func(zone): return zone.phase != "active"), id + " ends its initial active window")


func _check_arena_isolation() -> void:
	var left = _new_match("quarry")
	var right = _new_match("observatory")
	left.step(6.5, Vector2.ZERO, Vector2.ZERO)
	check.call(left.map_id == "quarry" and right.map_id == "observatory", "Concurrent arena instances retain independent selections")
	check.call(right.environment_zones.all(func(zone): return zone.phase != "active") and right.round_time == 60.0, "One instance's terrain clock cannot advance another")
	for rival in left.fighters.slice(3):
		rival.health = 0.0
		rival.alive = false
	left.step(0.016, Vector2.ZERO, Vector2.ZERO)
	left.next_round()
	check.call(left.map_id == "quarry" and left.environment_zones.all(func(zone): return zone.phase != "active"), "Intermission restores the selected map's opening state")


func _check_cast_events() -> void:
	var arena = _new_match("lockwater")
	var player: Dictionary = arena.fighters[0]
	var rival: Dictionary = arena.fighters[3]
	player.position = Vector2.ZERO
	rival.position = Vector2(1.5, 0.0)
	var count: int = arena.cast_events.size()
	check.call(not arena.try_ability(0, 1) and arena.cast_events.size() == count, "Rejected friendly-target strike produces no cast event")
	check.call(arena.try_ability(0, 3) and arena.cast_events.size() == count + 1, "An accepted human cast records exactly one event")
	if arena.cast_events.size() <= count:
		return
	var event: Dictionary = arena.cast_events[-1]
	check.call(event.source_id == 0 and event.class_id == "breakwater" and event.slot == 0 and event.target_id == 3, "Human cast event identifies the class, slot, and target")
	check.call(event.origin == player.position and event.destination == rival.position, "Human cast captures impact geometry")
	check.call(not arena.try_ability(0, 3) and arena.cast_events.size() == count + 1, "A cooldown rejection does not emit another event")
	rival.stun = 0.0
	rival.bot_wait = 0.0
	rival.cooldowns.fill(15.0)
	rival.cooldowns[0] = 0.0
	arena.step(0.02, Vector2.ZERO, Vector2.ZERO)
	var bot_casts: Array = arena.cast_events.filter(func(item): return item.source_id == 3)
	check.call(not bot_casts.is_empty(), "A real bot turn emits the same kind of cast event")
	if not bot_casts.is_empty():
		event = bot_casts[-1]
		check.call(event.class_id == rival.class_id and event.slot == 0 and event.target_id == player.id, "Bot cast records its actual loadout and victim")


func _check_footprint(id: String) -> void:
	var outline: PackedVector2Array = ArenaMaps.outline(id)
	var arena = _new_match(id)
	for fighter in arena.fighters:
		check.call(Geometry2D.is_point_in_polygon(fighter.position, outline) and not arena._blocked(fighter.position, 0.3), "%s fighter %d spawns on clear ground" % [id, fighter.id])
	var half := outline.size() >> 1
	var mirrored := outline.size() >= 4 and half * 2 == outline.size()
	for index in half:
		if outline[index].distance_to(-outline[index + half]) > 0.001:
			mirrored = false
			break
	check.call(mirrored, id + " footprint is centrally symmetric")
	var player: Dictionary = arena.fighters[0]
	var east := _edge_distance(outline, Vector2.RIGHT)
	var north := _edge_distance(outline, Vector2.UP)
	if id in ["quarry", "orchard"]:
		check.call(east > north + 1.0, id + " has a wider east-west reach")
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
		var edge := _edge_distance(outline, direction)
		check.call(edge > 0.0, "%s has an edge in direction %s" % [id, direction])
		if edge <= 0.0:
			continue
		player.position = direction * (edge - 1.6)
		arena.step(0.65, direction, direction)
		var after_walk: Vector2 = player.position
		check.call(Geometry2D.is_point_in_polygon(after_walk, outline) and absf(after_walk.dot(direction) - edge) <= 0.7, "%s walking stops near its actual edge in direction %s" % [id, direction])
		player.position = direction * (edge - 1.6)
		player.dodge_cooldown = 0.0
		check.call(arena.try_dodge(direction), id + " permits a dodge approaching the outer wall")
		var after_dodge: Vector2 = player.position
		check.call(Geometry2D.is_point_in_polygon(after_dodge, outline) and absf(after_dodge.dot(direction) - edge) <= 0.7, "%s dodge is clipped at the walkable footprint in direction %s" % [id, direction])

	arena.start_match("echo_duelist", 711, -1, id)
	player = arena.fighters[0]
	player.position = Vector2(0, north - 1.6)
	player.facing = Vector2.DOWN
	check.call(arena.try_ability(1) and Geometry2D.is_point_in_polygon(player.position, outline) and player.position.y < north, id + " clips the Duelist's outward Tracecut dash")


func _edge_distance(outline: PackedVector2Array, direction: Vector2) -> float:
	for index in outline.size():
		var next := (index + 1) % outline.size()
		var point: Variant = Geometry2D.segment_intersects_segment(Vector2.ZERO, direction * 30.0, outline[index], outline[next])
		if point is Vector2:
			return point.length()
	return -1.0
