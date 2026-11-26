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
	if style.is_empty() or slot <= 0 or slot >= 8 or delay < 0.07:
		return
	var cast := _begin_cast(false)
	if cast == null:
		return
	var tint := Color(str(style[0]))
	var hand: Vector3 = event.get("hand_origin", _floor_point(event.origin) + Vector3.UP)
	cast.position = hand
	var ink := _ink(tint.lightened(0.35), 0.77)
	# Converging scales catch the eye during a windup and disappear at release.
	_ribbon(cast, _arc(Vector3.ZERO, 0.40, -0.56, 0.56, 8), 0.15, ink, 0.9)
	_ribbon(cast, _arc(Vector3.ZERO, 0.40, 1.52, 2.64, 8), 0.15, ink, 0.9)
	_ribbon(cast, _arc(Vector3.ZERO, 0.40, 3.62, 4.74, 8), 0.15, ink, 0.9)
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
	var cast := _begin_cast(strong)
	if cast == null:
		return

	var tint := Color(str(style[0]))
	var accent: Color = TEAM_ACCENTS[clampi(event.team, 0, 1)]
	var ink := _ink(tint, 0.88)
	var core := _ink(tint.lightened(0.56), 0.92)
	var rim := _ink(accent, 0.67)
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
	var strength := 1.37 if strong else (1.0 if slot > 0 else 0.78)
	var impact_delay := 0.026
	var duration := 0.63 if strong else 0.43
	match pattern:
		"cut", "sweep", "crush":
			_weapon_arc(cast, origin, direction, pattern, strength, ink, core)
			if pattern == "crush":
				_ripple(cast, destination, 1.24 * strength, rim, 0.28)
		"dash":
			_dash(cast, origin, landing, destination, direction, motif, ink, core)
		"bolt", "needle", "volley":
			impact_delay = _projectiles(cast, hand, destination + chest, direction, pattern, motif, strength, ink, core)
			duration = maxf(duration, impact_delay + 0.24)
		"zap", "chain", "thread":
			_tether(cast, hand, destination + chest, pattern, motif, strength, ink, core)
			if motif == "spark" and slot == 2:
				var hits: Dictionary = event.get("affected_positions", {})
				for fighter_id in hits:
					if fighter_id != event.target_id:
						_tether(cast, destination + chest, _floor_point(hits[fighter_id]) + chest, pattern, motif, 0.72, ink, core)
		"wave":
			_wave(cast, origin, destination, direction, strength, ink, core)
			impact_delay = 0.16
		"ward":
			_ward(cast, destination, motif, strength, ink, rim)
			_spark_fan(cast, destination + Vector3.UP * 0.2, Vector3.UP, tint, 8, 0.34, 0.7)
		"heal", "cleanse", "rally":
			if pattern == "heal" and hand.distance_squared_to(destination + chest) > 0.35:
				_tether(cast, hand, destination + chest, "thread", motif, 0.72, ink, core)
			_benediction(cast, destination, motif, strength, ink, core)
			_spark_fan(cast, destination + Vector3.UP * 0.23, Vector3.UP, tint, 9 if strong else 5, 0.36, 0.75)
		"field", "brand", "burst", "interrupt", "swarm":
			_ritual(cast, destination, pattern, motif, strength, ink, core)
	if strong and pattern in ["burst", "rally", "sweep", "wave", "field"]:
		_ripple(cast, destination, 1.45, rim, 0.38)
	if pattern in ["cut", "sweep", "crush", "dash", "bolt", "needle", "volley", "zap", "chain", "wave", "interrupt", "burst"]:
		_schedule_impacts(cast, event, direction, strength, tint, core, impact_delay)
	_fade(cast, [ink, core, rim], maxf(0.11, impact_delay + 0.06), duration)


func _begin_cast(priority: bool) -> Node3D:
	if get_child_count() >= MAX_TRANSIENTS:
		if not priority:
			return null
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var cast := Node3D.new()
	add_child(cast)
	return cast


func _weapon_arc(parent: Node3D, position: Vector3, direction: Vector3, pattern: String, strength: float, ink: Material, core: Material) -> void:
	var swing := _pivot(parent, position + Vector3.UP * 1.02)
	var yaw := atan2(-direction.x, -direction.z)
	var spread: float = {"sweep": 2.15, "cut": 1.32, "crush": 0.89}[pattern]
	var radius := 1.65 * strength
	swing.rotation = Vector3(-1.02 if pattern == "crush" else 0.19, yaw - 0.73, -0.24)
	swing.scale = Vector3.ONE * 0.62
	_ribbon(swing, _arc(Vector3.ZERO, radius, -spread, spread, 22), 0.58 * strength, ink, 0.97)
	_ribbon(swing, _arc(Vector3.UP * 0.04, radius * 0.92, -spread * 0.90, spread * 0.92, 18), 0.17 * strength, core, 1.0)
	var follow := swing.create_tween().set_parallel()
	follow.tween_property(swing, "scale", Vector3.ONE * 1.13, 0.19).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	follow.tween_property(swing, "rotation:y", yaw + 0.68, 0.20).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if pattern == "crush":
		follow.tween_property(swing, "rotation:x", 0.44, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _dash(parent: Node3D, origin: Vector3, landing: Vector3, destination: Vector3, direction: Vector3, motif: String, ink: Material, core: Material) -> void:
	if origin.distance_squared_to(landing) < 0.04:
		_sigil(parent, destination, 0.73, motif, ink)
		return
	var side := direction.cross(Vector3.UP)
	for offset in [-0.31, 0.31]:
		var wake := PackedVector3Array()
		for i in range(9):
			var t := i / 8.0
			wake.append(origin.lerp(landing, t) + side * offset * (0.70 + t) + Vector3.UP * (0.20 + t * t * 0.65))
		_ribbon(parent, wake, 0.42, ink, 1.0)
		_ribbon(parent, wake, 0.12, core, 1.0)
	_ripple(parent, landing, 0.86, core, 0.26)


func _projectiles(parent: Node3D, start: Vector3, finish: Vector3, direction: Vector3, pattern: String, motif: String, strength: float, ink: Material, core: Material) -> float:
	var travel := clampf(start.distance_to(finish) / 38.0, 0.055, 0.24)
	var tail := -direction * (1.24 if pattern == "needle" else 0.88) * strength
	var tip := direction * 0.30 * strength
	var side := direction.cross(Vector3.UP)
	var shots := 3 if pattern == "volley" else 1
	for shot in range(shots):
		var gap := (shot - (shots - 1) * 0.5) * 0.42
		var bolt := _pivot(parent, start + side * gap * 0.3)
		var stream := PackedVector3Array([tail, tail * 0.60 + Vector3.UP * 0.08, Vector3.ZERO, tip])
		_ribbon(bolt, stream, 0.42 * strength, ink, 0.85)
		_ribbon(bolt, stream, 0.19 * strength, core, 0.8)
		if motif in ["ember", "flame", "fletch"]:
			for wing in [-0.21, 0.21]:
				_ribbon(bolt, PackedVector3Array([tail + side * wing, tail * 0.45 + side * wing * 1.2, tip]), 0.15 * strength, ink, 1.0)
		else:
			var jewel := _pivot(bolt, tip * 0.37)
			_diamond(jewel, Vector3.ZERO, side, 0.23 * strength, core)
			jewel.create_tween().tween_property(jewel, "rotation:y", PI * 0.72, travel)
		var motion := bolt.create_tween()
		motion.tween_property(bolt, "position", finish + side * gap, travel).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		motion.tween_property(bolt, "scale", Vector3.ONE * 0.01, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return travel


func _tether(parent: Node3D, start: Vector3, finish: Vector3, pattern: String, motif: String, strength: float, ink: Material, core: Material) -> void:
	if start.distance_squared_to(finish) <= 0.016:
		_sigil(parent, finish - Vector3.UP * 0.68, 0.55, motif, ink)
		return
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
				if i % 3 == 1:
					_diamond(parent, point, across, 0.120 * strength, ink)
			"thread":
				point += across * sin(t * TAU) * envelope * 0.18
				point.y += envelope * 0.34
				braid.append(point + across * sin(t * TAU * 2.0) * envelope * 0.21)
		path.append(point)
	_ribbon(parent, path, 0.31 * strength, ink, 0.66)
	_ribbon(parent, path, 0.11 * strength, core, 0.55)
	if pattern == "thread":
		_ribbon(parent, braid, 0.14 * strength, ink, 0.75)


func _wave(parent: Node3D, origin: Vector3, destination: Vector3, direction: Vector3, strength: float, ink: Material, core: Material) -> void:
	var wave := _pivot(parent, origin + Vector3.UP * 0.38)
	wave.rotation.y = atan2(-direction.x, -direction.z)
	var crest := _arc(Vector3(0, 0.14, 0), 0.94 * strength, -1.42, 1.42, 18)
	_ribbon(wave, crest, 0.40 * strength, ink, 0.85)
	_ribbon(wave, _arc(Vector3(0, 0.18, -0.17), 0.78 * strength, -1.28, 1.28, 16), 0.15 * strength, core, 0.94)
	wave.scale = Vector3.ONE * 0.48
	var travel := wave.create_tween().set_parallel()
	travel.tween_property(wave, "position", destination + Vector3.UP * 0.35, 0.20)
	travel.tween_property(wave, "scale", Vector3(1.37, 1.23, 1.12), 0.29).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _ward(parent: Node3D, at: Vector3, motif: String, strength: float, ink: Material, rim: Material) -> void:
	var shell := _pivot(parent, at)
	for i in 3:
		var angle := TAU * i / 3.0
		var spine := PackedVector3Array()
		for j in 11:
			var t := j / 10.0
			var side := Vector3(cos(angle + t * 0.22), 0, sin(angle + t * 0.22))
			spine.append(side * (0.32 + sin(t * PI) * 0.63) * strength + Vector3.UP * (0.13 + t * 1.6))
		_ribbon(shell, spine, 0.22, ink, 0.82)
	_ribbon(shell, _arc(Vector3.UP * 0.86, strength * 0.90, -1.18, 1.77, 15), 0.12, rim, 0.92)
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
		_ribbon(ribbons, ascent, 0.27, ink, 0.86)
		_ribbon(ribbons, ascent, 0.07, core, 0.9)
	ribbons.scale = Vector3(0.8, 0.35, 0.8)
	var ascend := ribbons.create_tween().set_parallel()
	ascend.tween_property(ribbons, "scale", Vector3(1.1, 1.2, 1.1), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ascend.tween_property(ribbons, "rotation:y", 1.37, 0.40)
	_sigil(parent, at, 0.83 * strength, motif, core)


func _ritual(parent: Node3D, at: Vector3, pattern: String, motif: String, strength: float, ink: Material, core: Material) -> void:
	_sigil(parent, at, (0.63 if pattern == "brand" else 1.05) * strength, motif, ink)
	match pattern:
		"interrupt":
			var impact := at + Vector3.UP * 1.3
			for side in [-0.58, 0.58]:
				_ribbon(parent, PackedVector3Array([impact + Vector3(side, -0.31, 0), impact + Vector3(-side, 0.32, 0)]), 0.26, core, 0.85)
		"swarm", "burst":
			var shock := _pivot(parent, at + Vector3.UP * 0.56)
			for n in 5:
				var angle := TAU * n / 5.0
				var outward := Vector3(cos(angle), 0.19 + 0.31 * (n % 2), sin(angle)) * strength
				_ribbon(shock, PackedVector3Array([outward * 0.14, outward * 0.54 + Vector3.UP * 0.20, outward * 0.93]), 0.33, ink, 0.88)
			shock.scale = Vector3.ONE * 0.18
			var force := shock.create_tween().set_parallel()
			force.tween_property(shock, "scale", Vector3.ONE * 1.4, 0.36).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			force.tween_property(shock, "rotation:y", 0.64, 0.35)
		"brand":
			var rune := _pivot(parent, at + Vector3.UP * 1.52)
			_diamond(rune, Vector3.ZERO, Vector3.RIGHT, 0.29, core)
			_diamond(rune, Vector3.ZERO, Vector3.BACK, 0.26, ink)
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
	var flash := _pivot(parent, at + Vector3.UP * 0.92)
	var side := direction.cross(Vector3.UP)
	var rays := 4 if primary else 2
	for i in rays:
		var angle := i * TAU / rays + 0.47
		var vector := (side * sin(angle) + Vector3.UP * cos(angle)) * 0.54 * strength
		_ribbon(flash, PackedVector3Array([vector * 0.14, vector * 0.74, vector * 1.33]), 0.29 * strength, core, 1.0)
	flash.scale = Vector3.ONE * 0.75
	var dissipate := flash.create_tween()
	dissipate.tween_property(flash, "scale", Vector3.ONE * 1.32, 0.06)
	dissipate.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if primary:
		_spark_fan(parent, flash.position, direction, tint, 12 if strength >= 1.2 else 7, 0.28, strength)


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
	_ribbon(glyph, _arc(Vector3.ZERO, radius, -PI, PI, sides), 0.23, ink)
	_ribbon(glyph, _arc(Vector3.ZERO, radius * 0.76, -1.62, 1.62, 14), 0.12, ink, 0.79)
	_ribbon(glyph, _arc(Vector3.ZERO, radius * 0.76, 1.86, 4.32, 14), 0.12, ink, 0.79)
	glyph.scale = Vector3.ONE * 0.68
	var unfold := glyph.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	unfold.tween_property(glyph, "scale", Vector3.ONE * 1.09, 0.30)
	unfold.tween_property(glyph, "rotation:y", 0.31, 0.32)


func _ripple(parent: Node3D, at: Vector3, radius: float, ink: Material, duration: float) -> void:
	var ripple := _pivot(parent, at + Vector3.UP * 0.12)
	_ribbon(ripple, _arc(Vector3.ZERO, radius, -PI, PI, 28), 0.27, ink)
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
