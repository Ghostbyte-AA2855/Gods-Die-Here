extends Node3D

# Each entry follows its class spellbook in slot order. Team color stays in
# the impact accent while the class supplies the spell's color and silhouette.
const STYLES = {
	"breakwater": ["a7c6d9", "plate", ["cut","ward","thread","interrupt","dash","sweep","crush","rally"]],
	"threadkeeper": ["cd95f4", "thread", ["needle","heal","ward","heal","thread","dash","thread","rally"]],
	"echo_duelist": ["62d9ff", "echo", ["cut","dash","sweep","ward","dash","cut","interrupt","sweep"]],
	"forgecaller": ["ff9356", "ember", ["bolt","brand","chain","ward","field","wave","ward","crush"]],
	"lamplighter": ["ffd16a", "flame", ["bolt","heal","field","ward","wave","thread","dash","rally"]],
	"longwatch": ["92db87", "fletch", ["needle","brand","needle","dash","interrupt","volley","field","needle"]],
	"sluicecaller": ["51dce0", "water", ["wave","field","wave","field","dash","wave","field","field"]],
	"glassmage": ["a4f7ea", "prism", ["bolt","field","dash","ward","brand","ward","thread","burst"]],
	"blood_cantor": ["f16b92", "blood", ["thread","heal","thread","ward","interrupt","rally","sweep","heal"]],
	"bellwarden": ["f2ca83", "bell", ["crush","ward","wave","wave","dash","interrupt","ward","rally"]],
	"ash_dancer": ["ff8548", "ember", ["cut","dash","cut","sweep","interrupt","ward","dash","sweep"]],
	"winter_scribe": ["aecdfc", "frost", ["needle","field","burst","dash","ward","brand","interrupt","field"]],
	"dream_shepherd": ["deb2ff", "dream", ["bolt","heal","ward","dash","cleanse","brand","field","rally"]],
	"chainrunner": ["b5b9dd", "links", ["cut","chain","dash","chain","sweep","dash","thread","crush"]],
	"coilwright": ["f5da73", "spark", ["zap","brand","zap","zap","dash","ward","interrupt","field"]],
	"duskmoth": ["f0a6e5", "moth", ["cut","swarm","dash","ward","needle","swarm","cleanse","burst"]],
}
const TEAM_ACCENTS = [Color("74f4ef"), Color("ff9070")]
const MAX_TRANSIENTS := 22
const MAX_BACKGROUND_ATTACKS := 7
const SPARK_MESH := preload("res://scripts/fx/shard.tres")
const RIBBON_SHADER := preload("res://scripts/fx/energy_ribbon.gdshader")

var _spark_surface := StandardMaterial3D.new()


func _ready() -> void:
	_spark_surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spark_surface.vertex_color_use_as_albedo = true


func clear() -> void:
	for effect in get_children():
		remove_child(effect)
		effect.queue_free()


func play_windup(event: Dictionary, delay: float) -> void:
	var style: Array = STYLES.get(event.class_id, [])
	var slot: int = event.slot
	if style.is_empty() or slot <= 0 or slot >= 8 or delay < 0.055:
		return
	var cast := _begin_cast(3 if _features_player(event) else 2)
	if cast == null:
		return
	var tint := Color(str(style[0]))
	var hand: Vector3 = event.get("hand_origin", _floor_point(event.origin) + Vector3.UP)
	cast.position = hand
	var ink := _ink(tint.lightened(0.35), 0.77)
	# Converging wedges draw attention to the casting hand during the windup.
	for shard in 3:
		var angle := shard * TAU / 3.0
		_ribbon(cast, _arc(Vector3.ZERO, 0.54, angle - 0.56, angle + 0.56, 7), 0.24, ink, 0.9)
	cast.rotate_x(PI / 5.0)
	var motion := cast.create_tween().set_parallel()
	motion.tween_property(cast, "scale", Vector3.ONE * 0.28, delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	motion.tween_property(cast, "rotation:y", 1.8, delay)
	_fade(cast, [ink], delay * 0.55, delay)


func play_cast(event: Dictionary) -> void:
	var slot: int = event.slot
	var style: Array = STYLES.get(event.class_id, [])
	if slot < 0 or slot >= 8 or style.is_empty():
		return
	var pattern: String = style[2][slot]
	var motif: String = style[1]
	var strong := slot == 7 or (slot > 0 and pattern in ["burst", "crush", "rally"])
	var player_visible := _features_player(event)
	var background_attack := slot == 0 and not player_visible
	var cast := _begin_cast(1 if background_attack else (4 if strong else (3 if player_visible else 2)))
	if cast == null:
		return

	var tint := Color(str(style[0]))
	var accent: Color = TEAM_ACCENTS[clampi(event.team, 0, 1)]
	var origin := _floor_point(event.origin)
	var landing := _floor_point(event.source_after)
	var destination := _floor_point(event.destination)
	var direction := origin.direction_to(destination)
	if direction.is_zero_approx():
		var facing: Vector2 = event.get("facing", Vector2.UP)
		direction = Vector3(facing.x, 0, facing.y).normalized()
		if direction.is_zero_approx():
			direction = Vector3.FORWARD
	var chest := Vector3.UP * 0.94
	var hand: Vector3 = event.get("hand_origin", origin + chest)
	var ink := _ink(tint, 0.95 if not background_attack else 0.73)
	if background_attack:
		_background_attack(cast, origin, hand, destination + chest, direction, pattern, ink)
		return
	var rim := _ink(accent, 0.78)
	var highlight := _ink(tint.lightened(0.26), 0.96)
	var strength := 1.57 if strong else (1.15 if slot > 0 else 0.86)
	var impact_delay := 0.055
	var duration := 0.93 if strong else (0.71 if slot > 0 else 0.44)
	if slot > 0:
		_release_flash(cast, hand, direction, strength, highlight)
	match pattern:
		"cut", "sweep", "crush":
			_weapon_arc(cast, origin, direction, pattern, strength, ink)
			if pattern == "crush":
				_ripple(cast, destination, 1.07 * strength, rim, 0.36)
		"dash":
			_dash(cast, origin, landing, destination, motif, ink, highlight)
		"bolt", "needle", "volley":
			impact_delay = _projectiles(cast, hand, destination + chest, direction, pattern, motif, strength, ink, highlight)
			duration = maxf(duration, impact_delay + 0.35)
		"zap", "chain", "thread":
			impact_delay = _tether(cast, hand, destination + chest, pattern, motif, strength, ink, highlight)
			duration = maxf(duration, impact_delay + 0.30)
			if motif == "spark" and slot == 2:
				var hits: Dictionary = event.get("affected_positions", {})
				var jumps := 0
				for fighter_id in hits:
					if fighter_id != event.target_id:
						_tether(cast, destination + chest, _floor_point(hits[fighter_id]) + chest, pattern, motif, 0.72, ink, highlight)
						jumps += 1
						if jumps == 2:
							break
		"wave":
			impact_delay = _wave(cast, origin, destination, direction, strength, ink, highlight)
		"ward":
			_ward(cast, destination, motif, strength, ink, rim)
			_spark_fan(cast, destination + Vector3.UP * 0.2, Vector3.UP, tint, 8, 0.34, 0.7)
		"heal", "cleanse", "rally":
			if pattern == "heal" and hand.distance_squared_to(destination + chest) > 0.35:
				_tether(cast, hand, destination + chest, "thread", motif, 0.88, ink, highlight)
			_benediction(cast, destination, motif, strength, ink, highlight)
			_spark_fan(cast, destination + Vector3.UP * 0.23, Vector3.UP, tint, 9 if strong else 5, 0.36, 0.75)
		"field", "brand", "burst", "interrupt", "swarm":
			_ritual(cast, destination, pattern, motif, strength, ink, highlight)
	if strong and pattern in ["burst", "rally", "sweep", "wave", "field"]:
		_ripple(cast, destination, 1.45, rim, 0.38)
	if pattern in ["cut", "sweep", "crush", "dash", "bolt", "needle", "volley", "zap", "chain", "wave", "interrupt", "burst"] or (pattern == "thread" and event.get("target_kind", "enemy") == "enemy"):
		_schedule_impacts(cast, event, direction, strength, tint, highlight, impact_delay)
	_fade(cast, [ink, highlight, rim], maxf(0.18 if slot > 0 else 0.11, impact_delay + 0.11), duration)


func _features_player(event: Dictionary) -> bool:
	return event.get("source_id", 0) == 0 or event.get("target_id", -1) == 0 or event.get("affected_positions", {}).has(0)


func _begin_cast(priority: int) -> Node3D:
	var oldest_lower_priority: Node3D
	var lowest_priority := priority
	var background_count := 0
	for active in get_children():
		var active_priority: int = active.get_meta("priority")
		if active_priority == 1:
			background_count += 1
		if active_priority < lowest_priority or (oldest_lower_priority == null and active_priority == lowest_priority):
			oldest_lower_priority = active
			lowest_priority = active_priority
	if priority == 1 and background_count >= MAX_BACKGROUND_ATTACKS:
		return null
	if get_child_count() >= MAX_TRANSIENTS:
		if oldest_lower_priority == null or priority == 1:
			return null
		remove_child(oldest_lower_priority)
		oldest_lower_priority.queue_free()
	var cast := Node3D.new()
	cast.set_meta("priority", priority)
	add_child(cast)
	return cast


func _background_attack(parent: Node3D, origin: Vector3, hand: Vector3, target: Vector3, direction: Vector3, pattern: String, ink: ShaderMaterial) -> void:
	if pattern in ["cut", "crush"]:
		_weapon_arc(parent, origin, direction, pattern, 0.68, ink)
	elif pattern in ["thread", "zap"]:
		var middle := hand.lerp(target, 0.50) + Vector3.UP * 0.27
		_ribbon(parent, PackedVector3Array([hand, middle, target]), 0.25, ink, 0.85)
	else:
		var bolt := _pivot(parent, hand)
		_ribbon(bolt, PackedVector3Array([-direction * 0.58, Vector3.ZERO, direction * 0.2]), 0.26, ink, 0.75)
		var flight := bolt.create_tween()
		flight.tween_property(bolt, "position", target, clampf(hand.distance_to(target) / 39.0, 0.08, 0.20))
		flight.tween_property(bolt, "scale", Vector3.ONE * 0.01, 0.07)
	_fade(parent, [ink], 0.13, 0.32)


func _release_flash(parent: Node3D, hand: Vector3, direction: Vector3, strength: float, ink: Material) -> void:
	var launch := _pivot(parent, hand)
	var side := direction.cross(Vector3.UP)
	var radius := 0.28 * strength
	_diamond(launch, Vector3.ZERO, side, radius, ink)
	_ribbon(launch, PackedVector3Array([-direction * radius, Vector3.ZERO, direction * radius * 2.1]), radius, ink, 0.9)
	var flicker := launch.create_tween()
	flicker.tween_property(launch, "scale", Vector3.ONE * 1.50, 0.075).from(Vector3.ONE * 0.73)
	flicker.tween_property(launch, "scale", Vector3.ONE * 0.01, 0.115).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flicker.tween_callback(launch.queue_free)


func _weapon_arc(parent: Node3D, position: Vector3, direction: Vector3, pattern: String, strength: float, ink: Material) -> void:
	var swing := _pivot(parent, position + Vector3.UP * 1.22)
	var yaw := atan2(-direction.x, -direction.z)
	var spread: float = {"sweep": 2.15, "cut": 1.32, "crush": 0.89}[pattern]
	var radius := 1.74 * strength
	swing.rotation = Vector3(-1.02 if pattern == "crush" else 0.19, yaw - 0.73, -0.24)
	swing.scale = Vector3.ONE * 0.74
	_ribbon(swing, _arc(Vector3.ZERO, radius, -spread, spread, 20), 0.80 * strength, ink, 0.97)
	var follow := swing.create_tween().set_parallel()
	follow.tween_property(swing, "scale", Vector3.ONE * 1.13, 0.29).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	follow.tween_property(swing, "rotation:y", yaw + 0.74, 0.29).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if pattern == "crush":
		follow.tween_property(swing, "rotation:x", 0.44, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _dash(parent: Node3D, origin: Vector3, landing: Vector3, destination: Vector3, motif: String, ink: Material, core: Material) -> void:
	if origin.distance_squared_to(landing) < 0.04:
		_sigil(parent, destination, 0.73, motif, ink)
		return
	var route := origin.direction_to(landing)
	var side := route.cross(Vector3.UP)
	for offset in [-0.38, 0.38]:
		var wake := PackedVector3Array()
		for i in range(9):
			var t := i / 8.0
			wake.append(origin.lerp(landing, t) + side * offset * (0.70 + t) + Vector3.UP * (0.20 + t * t * 0.65))
		_ribbon(parent, wake, 0.49, ink, 0.73)
	_ripple(parent, landing, 0.95, core, 0.32)


func _projectiles(parent: Node3D, start: Vector3, finish: Vector3, direction: Vector3, pattern: String, motif: String, strength: float, ink: Material, core: Material) -> float:
	var travel := clampf(start.distance_to(finish) / 25.0, 0.15, 0.36)
	var tail := -direction * (1.40 if pattern == "needle" else 1.12) * strength
	var tip := direction * 0.34 * strength
	var side := direction.cross(Vector3.UP)
	var shots := 3 if pattern == "volley" else 1
	for shot in range(shots):
		var gap := (shot - (shots - 1) * 0.5) * 0.42
		var departure := start + side * gap * 0.3
		var arrival := finish + side * gap
		var bolt := _pivot(parent, departure)
		var stream := PackedVector3Array([tail, tail * 0.60 + Vector3.UP * 0.08, Vector3.ZERO, tip])
		_ribbon(bolt, stream, 0.60 * strength, ink, 0.57)
		if motif in ["ember", "flame", "fletch"]:
			for wing in [-0.30, 0.30]:
				_ribbon(bolt, PackedVector3Array([tail + side * wing, tail * 0.45 + side * wing * 1.2, tip]), 0.19 * strength, ink, 1.0)
		else:
			var jewel := _pivot(bolt, tip * 0.37)
			_diamond(jewel, Vector3.ZERO, side, 0.31 * strength, core)
			jewel.create_tween().tween_property(jewel, "rotation:y", PI * 0.72, travel)
		var motion := bolt.create_tween()
		motion.tween_method(func(t: float):
			bolt.position = departure.lerp(arrival, t) + Vector3.UP * sin(t * PI) * 0.36
		, 0.0, 1.0, travel)
		motion.tween_property(bolt, "scale", Vector3.ONE * 0.01, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		motion.tween_callback(bolt.queue_free)
	return travel


func _tether(parent: Node3D, start: Vector3, finish: Vector3, pattern: String, motif: String, strength: float, ink: Material, core: Material) -> float:
	if start.distance_squared_to(finish) <= 0.016:
		_sigil(parent, finish - Vector3.UP * 0.68, 0.55, motif, ink)
		return 0.055
	var axis := start.direction_to(finish)
	var across := axis.cross(Vector3.UP).normalized()
	var count := clampi(ceili(start.distance_to(finish) * 2.2), 6, 20)
	var path := PackedVector3Array()
	var braid := PackedVector3Array()
	for i in range(count + 1):
		var t := float(i) / count
		var point := start.lerp(finish, t)
		var envelope := sin(PI * t)
		match pattern:
			"zap":
				point += across * sin(i * 2.43) * envelope * 0.40
				point.y += sin(i * 1.94) * envelope * 0.41
			"chain":
				point.y -= envelope * 0.45
				if i % 4 == 2:
					_diamond(parent, point, across, 0.18 * strength, ink)
			"thread":
				point += across * sin(t * TAU) * envelope * 0.18
				point.y += envelope * 0.34
				braid.append(point + across * sin(t * TAU * 2.0) * envelope * 0.21)
		path.append(point)
	_ribbon(parent, path, 0.49 * strength, ink, 0.38)
	if pattern == "thread":
		_ribbon(parent, braid, 0.21 * strength, core, 0.55)
	var charge := _pivot(parent, path[0])
	_diamond(charge, Vector3.ZERO, across, 0.28 * strength, core)
	var travel := clampf(start.distance_to(finish) / 23.0, 0.13, 0.34)
	var chase := charge.create_tween()
	chase.tween_method(func(t: float):
		var offset := t * (path.size() - 1)
		var sample := mini(floori(offset), path.size() - 2)
		charge.position = path[sample].lerp(path[sample + 1], offset - sample)
	, 0.0, 1.0, travel)
	chase.tween_property(charge, "scale", Vector3.ONE * 0.03, 0.12)
	chase.tween_callback(charge.queue_free)
	return travel


func _wave(parent: Node3D, origin: Vector3, destination: Vector3, direction: Vector3, strength: float, ink: Material, core: Material) -> float:
	var wave := _pivot(parent, origin + Vector3.UP * 0.38)
	wave.rotation.y = atan2(-direction.x, -direction.z)
	var crest := _arc(Vector3(0, 0.20, 0), 1.10 * strength, -1.42, 1.42, 18)
	_ribbon(wave, crest, 0.59 * strength, ink, 0.65)
	_ribbon(wave, _arc(Vector3(0, 0.43, 0.18), 0.84 * strength, -1.22, 1.22, 16), 0.26 * strength, core, 0.87)
	wave.scale = Vector3.ONE * 0.61
	var seconds := clampf(origin.distance_to(destination) / 22.0, 0.16, 0.31)
	var travel := wave.create_tween().set_parallel()
	travel.tween_property(wave, "position", destination + Vector3.UP * 0.47, seconds)
	travel.tween_property(wave, "scale", Vector3(1.39, 1.27, 1.15), seconds + 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return seconds


func _ward(parent: Node3D, at: Vector3, motif: String, strength: float, ink: Material, rim: Material) -> void:
	var shell := _pivot(parent, at)
	for i in 3:
		var angle := TAU * i / 3.0
		var spine := PackedVector3Array()
		for j in 11:
			var t := j / 10.0
			var side := Vector3(cos(angle + t * 0.22), 0, sin(angle + t * 0.22))
			spine.append(side * (0.32 + sin(t * PI) * 0.63) * strength + Vector3.UP * (0.13 + t * 1.6))
		_ribbon(shell, spine, 0.34, ink, 0.73)
	_ribbon(shell, _arc(Vector3.UP * 0.93, strength * 0.96, -1.18, 1.77, 15), 0.26, rim, 0.86)
	shell.scale = Vector3(0.84, 0.18, 0.84)
	var deploy := shell.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	deploy.tween_property(shell, "scale", Vector3.ONE, 0.23)
	deploy.tween_property(shell, "rotation:y", 0.65, 0.32)
	_sigil(parent, at, 0.77 * strength, motif, rim)


func _benediction(parent: Node3D, at: Vector3, motif: String, strength: float, ink: Material, core: Material) -> void:
	var ribbons := _pivot(parent, at)
	for i in 3:
		var start := i * TAU / 3.0
		var ascent := PackedVector3Array()
		for j in 9:
			var t := j / 8.0
			var angle := start + t * 1.65
			var radius := strength * (0.72 - t * 0.41)
			ascent.append(Vector3(radius * cos(angle), 0.14 + t * 1.44, radius * sin(angle)))
		_ribbon(ribbons, ascent, 0.39, ink, 0.74)
	ribbons.scale = Vector3(0.8, 0.35, 0.8)
	var ascend := ribbons.create_tween().set_parallel()
	ascend.tween_property(ribbons, "scale", Vector3(1.1, 1.2, 1.1), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ascend.tween_property(ribbons, "rotation:y", 1.37, 0.40)
	_sigil(parent, at, 0.89 * strength, motif, core)


func _ritual(parent: Node3D, at: Vector3, pattern: String, motif: String, strength: float, ink: Material, core: Material) -> void:
	_sigil(parent, at, (0.63 if pattern == "brand" else 1.05) * strength, motif, ink)
	match pattern:
		"interrupt":
			var impact := at + Vector3.UP * 1.40
			for side in [-0.72, 0.72]:
				_ribbon(parent, PackedVector3Array([impact + Vector3(side, -0.42, 0), impact + Vector3(-side, 0.47, 0)]), 0.42, core, 0.77)
		"swarm", "burst":
			var shock := _pivot(parent, at + Vector3.UP * 0.70)
			for n in 6:
				var angle := TAU * n / 6.0
				var outward := Vector3(cos(angle), 0.23 + 0.36 * (n % 2), sin(angle)) * strength
				_ribbon(shock, PackedVector3Array([outward * 0.14, outward * 0.64 + Vector3.UP * 0.20, outward * 1.08]), 0.46, ink, 0.78)
			shock.scale = Vector3.ONE * 0.35
			var force := shock.create_tween().set_parallel()
			force.tween_property(shock, "scale", Vector3.ONE * 1.4, 0.43).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			force.tween_property(shock, "rotation:y", 0.64, 0.42)
		"brand":
			var rune := _pivot(parent, at + Vector3.UP * 1.52)
			_diamond(rune, Vector3.ZERO, Vector3.RIGHT, 0.46, core)
			_diamond(rune, Vector3.ZERO, Vector3.BACK, 0.40, ink)
			rune.create_tween().tween_property(rune, "position:y", 1.84 + at.y, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _schedule_impacts(parent: Node3D, event: Dictionary, direction: Vector3, strength: float, tint: Color, core: Material, delay: float) -> void:
	var hits: Dictionary = event.get("affected_positions", {})
	if hits.is_empty():
		return
	var main_id: int = event.get("target_id", -1)
	if not hits.has(main_id):
		main_id = hits.keys()[0]
	parent.create_tween().tween_callback(func():
		_contact(parent, _floor_point(hits[main_id]), direction, strength, tint, core, true)
		var total := 1
		for fighter_id in hits:
			if fighter_id != main_id:
				_contact(parent, _floor_point(hits[fighter_id]), direction, strength * 0.70, tint, core, false)
				total += 1
			if total == 3:
				break
	).set_delay(delay)


func _contact(parent: Node3D, at: Vector3, direction: Vector3, strength: float, tint: Color, core: Material, primary: bool) -> void:
	var flash := _pivot(parent, at + Vector3.UP * 1.08)
	var side := direction.cross(Vector3.UP)
	var rays := 4 if primary else 2
	for i in rays:
		var angle := i * TAU / rays + 0.47
		var vector := (side * sin(angle) + Vector3.UP * cos(angle)) * 0.65 * strength
		_ribbon(flash, PackedVector3Array([vector * 0.14, vector * 0.74, vector * 1.33]), 0.43 * strength, core, 0.91)
	flash.scale = Vector3.ONE * 0.75
	var dissipate := flash.create_tween()
	dissipate.tween_property(flash, "scale", Vector3.ONE * 1.32, 0.09)
	dissipate.tween_interval(0.045)
	dissipate.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dissipate.tween_callback(flash.queue_free)
	if primary:
		_spark_fan(parent, flash.position, direction, tint, 12 if strength >= 1.2 else 7, 0.40, strength)
		if strength >= 1.0:
			_hit_marker(parent, at, strength, core)


func _hit_marker(parent: Node3D, at: Vector3, strength: float, ink: Material) -> void:
	var impression := _pivot(parent, at + Vector3.UP * 0.13)
	var radius := 0.62 * strength
	for quadrant in 4:
		var angle := quadrant * PI * 0.5 + PI * 0.25
		_ribbon(impression, _arc(Vector3.ZERO, radius, angle - 0.23, angle + 0.23, 4), 0.24, ink, 0.46)
	impression.scale = Vector3.ONE * 0.55
	impression.create_tween().tween_property(impression, "scale", Vector3.ONE, 0.27).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _spark_fan(parent: Node3D, origin: Vector3, direction: Vector3, tint: Color, count: int, seconds: float, strength: float) -> void:
	var spark := MultiMeshInstance3D.new()
	spark.multimesh = MultiMesh.new()
	spark.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	spark.multimesh.use_colors = true
	spark.multimesh.mesh = SPARK_MESH
	spark.multimesh.instance_count = count
	spark.material_override = _spark_surface
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(spark)
	spark.position = origin
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(origin) + count * 31
	var drifts := PackedVector3Array()
	var sizes := PackedFloat32Array()
	for i in count:
		var deviance := Vector3(rng.randf_range(-0.75, 0.75), rng.randf_range(0.06, 0.62), rng.randf_range(-0.75, 0.75))
		drifts.append((direction * rng.randf_range(0.25, 0.9) + deviance) * strength)
		sizes.append(rng.randf_range(0.05, 0.125) * strength)
		spark.multimesh.set_instance_color(i, tint.lerp(Color.WHITE, rng.randf_range(0.24, 0.83)))
	var scatter := func(t: float):
		for i in count:
			var drift := drifts[i]
			var pos := drift * (1.0 - pow(1.0 - t, 1.7)) + Vector3.DOWN * (0.18 * t * t)
			var scale := sizes[i] * maxf(0.01, 1.0 - t * t)
			var axes := Vector3(0.62, 0.59, 2.2).normalized()
			var basis := Basis(axes, t * (3.2 + i)).scaled(Vector3(scale * 0.55, scale * 0.54, scale * 2.20))
			spark.multimesh.set_instance_transform(i, Transform3D(basis, pos))
	scatter.call(0.0)
	spark.create_tween().tween_method(scatter, 0.0, 1.0, seconds).finished.connect(spark.queue_free)


func _sigil(parent: Node3D, at: Vector3, radius: float, motif: String, ink: Material) -> void:
	var sides := 22
	match motif:
		"frost": sides = 6
		"prism", "plate": sides = 4
		"ember", "flame": sides = 3
		"links", "spark": sides = 8
		"moth", "fletch": sides = 5
		"blood": sides = 7
	var glyph := _pivot(parent, at + Vector3.UP * 0.091)
	_ribbon(glyph, _arc(Vector3.ZERO, radius, -PI, PI, sides), 0.36, ink)
	_ribbon(glyph, _arc(Vector3.ZERO, radius * 0.68, -1.62, 1.62, 14), 0.20, ink, 0.68)
	_ribbon(glyph, _arc(Vector3.ZERO, radius * 0.68, 1.86, 4.32, 14), 0.20, ink, 0.68)
	glyph.scale = Vector3.ONE * 0.68
	var unfold := glyph.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	unfold.tween_property(glyph, "scale", Vector3.ONE * 1.09, 0.30)
	unfold.tween_property(glyph, "rotation:y", 0.31, 0.32)


func _ripple(parent: Node3D, at: Vector3, radius: float, ink: Material, duration: float) -> void:
	var ripple := _pivot(parent, at + Vector3.UP * 0.12)
	_ribbon(ripple, _arc(Vector3.ZERO, radius, -PI, PI, 26), 0.34, ink)
	ripple.scale = Vector3.ONE * 0.34
	ripple.create_tween().tween_property(ripple, "scale", Vector3.ONE * 1.14, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _diamond(parent: Node3D, at: Vector3, right: Vector3, radius: float, ink: Material) -> void:
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var side := right * radius
	var top := Vector3.UP * radius
	_ribbon(parent, PackedVector3Array([at + top, at + side, at - top, at - side, at + top]), radius * 0.56, ink)


func _arc(center: Vector3, radius: float, start: float, finish: float, steps: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in range(steps + 1):
		var angle := lerpf(start, finish, float(i) / steps)
		points.append(center + Vector3(sin(angle), 0.0, -cos(angle)) * radius)
	return points


func _ribbon(parent: Node3D, points: PackedVector3Array, width: float, ink: Material, taper: float = 0.0) -> void:
	if points.size() < 2:
		return
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var count := points.size()
	var closed := points[0].is_equal_approx(points[-1])
	for i in count:
		var before := points[i - 1] if i > 0 else points[count - 2] if closed else points[0]
		var after := points[i + 1] if i < count - 1 else points[1] if closed else points[-1]
		var side := (after - before).normalized().cross(Vector3.UP)
		if side.length_squared() < 0.06:
			side = Vector3.RIGHT
		var progress := i / float(count - 1)
		var coverage := lerpf(1.0, pow(maxf(0.004, sin(progress * PI)), 0.56), taper)
		var half := side.normalized() * width * 0.5 * coverage
		vertices.append(points[i] - half)
		vertices.append(points[i] + half)
		uv.append(Vector2(progress, 0.0))
		uv.append(Vector2(progress, 1.0))
		if i < count - 1:
			var start := i * 2
			indices.append_array(PackedInt32Array([start, start + 2, start + 1, start + 1, start + 2, start + 3]))
	var surfaces := []
	surfaces.resize(Mesh.ARRAY_MAX)
	surfaces[Mesh.ARRAY_VERTEX] = vertices
	surfaces[Mesh.ARRAY_TEX_UV] = uv
	surfaces[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfaces)
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = ink
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(strip)


func _ink(color: Color, opacity: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = RIBBON_SHADER
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("opacity", opacity)
	return material


func _fade(effect: Node3D, inks: Array[ShaderMaterial], hold: float, end: float) -> void:
	var fade := effect.create_tween()
	fade.tween_interval(hold)
	fade.tween_property(inks[0], "shader_parameter/opacity", 0.0, end - hold)
	for i in range(1, inks.size()):
		fade.parallel().tween_property(inks[i], "shader_parameter/opacity", 0.0, end - hold)
	fade.tween_callback(effect.queue_free)


func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.position = at
	return pivot


func _floor_point(plane: Vector2) -> Vector3:
	return Vector3(plane.x, 0.0, plane.y)
